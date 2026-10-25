// Match Pi's template argument semantics without depending on private Pi modules.
export function parseArgs(input) {
  const args = [];
  let value = "", quote = "", started = false;
  for (const ch of input) {
    if (quote) {
      if (ch === quote) quote = "";
      else value += ch;
    } else if (ch === '"' || ch === "'") {
      quote = ch;
      started = true;
    } else if (/\s/.test(ch)) {
      if (started) args.push(value);
      value = "";
      started = false;
    } else {
      value += ch;
      started = true;
    }
  }
  if (started) args.push(value);
  return args;
}

export function substituteArgs(content, args) {
  const all = args.join(" ");
  return content.replace(
    /\$\{(\d+|ARGUMENTS|@):-([^}]*)\}|\$\{@:(\d+)(?::(\d+))?\}|\$(ARGUMENTS|@|\d+)/g,
    (_, target, fallback, start, length, simple) => {
      if (target) return (target === "@" || target === "ARGUMENTS" ? all : args[Number(target) - 1]) || fallback;
      if (start) {
        const index = Math.max(0, Number(start) - 1);
        return args.slice(index, length === undefined ? undefined : index + Number(length)).join(" ");
      }
      return simple === "@" || simple === "ARGUMENTS" ? all : args[Number(simple) - 1] ?? "";
    },
  );
}

// Parse everything before executing anything, so malformed input has no side effects.
// Parentheses inside quotes or escaped with a backslash do not close a marker.
export function parseInterpolations(text) {
  const parts = [];
  let cursor = 0;
  while (true) {
    const start = text.indexOf("!!(", cursor);
    if (start < 0) break;
    parts.push(text.slice(cursor, start));
    let depth = 1, quote = "", end = start + 3;
    for (; end < text.length; end++) {
      const ch = text[end];
      if (ch === "\\" && quote !== "'") { end++; continue; }
      if (quote) {
        if (ch === quote) quote = "";
        continue;
      }
      if (ch === "'" || ch === '"' || ch === "`") { quote = ch; continue; }
      if (ch === "(") depth++;
      if (ch === ")" && --depth === 0) break;
    }
    if (depth !== 0) throw new Error("Unclosed !!(...) shell interpolation");
    const command = text.slice(start + 3, end);
    if (!command.trim()) throw new Error("Empty !!(...) shell interpolation");
    parts.push({ command });
    cursor = end + 1;
  }
  parts.push(text.slice(cursor));
  return parts;
}

export async function interpolate(text, execute) {
  const parts = parseInterpolations(text);
  let result = "";
  for (const part of parts) {
    // Do not interpret markers in command output a second time.
    result += typeof part === "string" ? part : (await execute(part.command)).replace(/[\r\n]+$/, "");
  }
  return result;
}
