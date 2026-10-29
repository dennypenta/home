import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { AutocompleteProvider } from "@earendil-works/pi-tui";

export function createModelAutocompleteProvider(
  current: AutocompleteProvider,
  getModels: () => readonly { provider: string; id: string }[],
): AutocompleteProvider {
  return {
    triggerCharacters: current.triggerCharacters,
    async getSuggestions(lines, cursorLine, cursorCol, options) {
      const match = lines[cursorLine]?.slice(0, cursorCol).match(/^#model[\t ]+(\S*)$/);
      if (!match) return current.getSuggestions(lines, cursorLine, cursorCol, options);

      const prefix = match[1];
      const query = prefix.toLowerCase();
      const items = getModels()
        .map((model) => `${model.provider}/${model.id}`)
        .filter((value) => value.toLowerCase().includes(query))
        .sort()
        .map((value) => ({ value, label: value }));
      return items.length ? { items, prefix } : null;
    },
    applyCompletion(lines, cursorLine, cursorCol, item, prefix) {
      if (!/^#model[\t ]+\S*$/.test(lines[cursorLine]?.slice(0, cursorCol) ?? "")) {
        return current.applyCompletion(lines, cursorLine, cursorCol, item, prefix);
      }
      const updated = [...lines];
      const start = cursorCol - prefix.length;
      // Replace the whole model token when completing with the cursor inside it.
      const suffix = lines[cursorLine].slice(cursorCol).replace(/^\S*/, "");
      updated[cursorLine] = lines[cursorLine].slice(0, start) + item.value + suffix;
      return { lines: updated, cursorLine, cursorCol: start + item.value.length };
    },
    shouldTriggerFileCompletion(lines, cursorLine, cursorCol) {
      return current.shouldTriggerFileCompletion?.(lines, cursorLine, cursorCol) ?? true;
    },
  };
}

export function parseFooter(text: string) {
  const lines = text.split("\n");
  let last = lines.length - 1;
  while (last >= 0 && !lines[last].trim()) last--;
  if (last < 0 || !/^#model(?:\s|$)/.test(lines[last])) return undefined;

  // A directive in a fenced example is prompt content, not configuration.
  let fence: string | undefined;
  for (let i = 0; i < last; i++) {
    const match = lines[i].match(/^ {0,3}(`{3,}|~{3,})(.*)$/);
    if (!match) continue;
    if (!fence) {
      if (match[1][0] === "`" && match[2].includes("`")) continue;
      fence = match[1];
    } else if (match[1][0] === fence[0] && match[1].length >= fence.length && !match[2].trim()) {
      fence = undefined;
    }
  }
  if (fence) return undefined;

  const match = lines[last].match(/^#model[\t ]+(\S+)[\t ]*\r?$/);
  if (!match) throw new Error("Usage: #model <model-id> or #model <provider/model-id>");
  return { text: lines.slice(0, last).join("\n").trimEnd(), model: match[1] };
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;
    ctx.ui.addAutocompleteProvider((current) =>
      createModelAutocompleteProvider(current, () => ctx.modelRegistry.getAvailable()),
    );
  });

  pi.on("input", async (event, ctx) => {
    if (event.source === "extension") return { action: "continue" };

    try {
      const footer = parseFooter(event.text);
      if (!footer) return { action: "continue" };

      // Ignore providers without credentials, matching Pi's model selector.
      const models = ctx.modelRegistry.getAvailable();
      const qualified = models.filter((model) => `${model.provider}/${model.id}` === footer.model);
      // Match qualified names first: model IDs themselves may contain slashes.
      const matches = qualified.length ? qualified : models.filter((model) => model.id === footer.model);
      if (!matches.length) throw new Error(`Unknown or unavailable model: ${footer.model}`);
      if (matches.length > 1) {
        throw new Error(`Ambiguous model: ${footer.model}. Use one of: ${matches.map((model) => `${model.provider}/${model.id}`).join(", ")}`);
      }
      if (!(await pi.setModel(matches[0]))) {
        throw new Error(`Cannot switch to ${footer.model}: no API credentials available`);
      }
      if (!footer.text.trim() && !event.images?.length) return { action: "handled" };
      return { action: "transform", text: footer.text, images: event.images };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      ctx.ui.notify(message, "error");
      if (!ctx.hasUI) console.error(`[footer-interpolation] ${message}`);
      // Thrown input hooks normally fall through; consume failures explicitly.
      return { action: "handled" };
    }
  });
}
