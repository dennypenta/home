import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", (event) => {
    if (event.toolName !== "bash") return;

    // Pi's bash tool accepts seconds. Override explicit timeouts as well.
    event.input.timeout = 5 * 60;
  });
}
