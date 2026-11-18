// No model calls or live-session interaction. Uses the installed Pi loader.
import assert from 'node:assert/strict';
import { copyFileSync, mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const host = process.argv[2];
assert.ok(host, 'Pass the installed pi-coding-agent package directory.');
const { loadExtensions } = await import(pathToFileURL(join(host, 'dist/core/extensions/loader.js')).href);
const fixture = mkdtempSync(join(tmpdir(), 'pi-snippets-'));

try {
  copyFileSync(join(root, 'index.ts'), join(fixture, 'index.ts'));
  mkdirSync(join(fixture, 'snippets'));
  const snippets = [
    { name: 'Zulu', order: 20, placement: 'prepend', category: 'development' },
    { name: 'Beta', order: 10, placement: 'prepend', category: 'general' },
    { name: 'Alpha', order: 10, placement: 'prepend', category: 'tools' },
    { name: 'Tail', order: 1, placement: 'append' },
  ];
  for (const [index, item] of snippets.entries()) {
    writeFileSync(join(fixture, 'snippets', `${index}.md`),
      `---\nname: ${item.name}\norder: ${item.order}\nplacement: ${item.placement}\n` +
      (item.category ? `category: ${item.category}\n` : '') + `---\n${item.name} instructions\n`);
  }
  const loaded = await loadExtensions([join(fixture, 'index.ts')], fixture);
  assert.deepEqual(loaded.errors, []);
  const ext = loaded.extensions[0];
  assert.ok(ext.commands.has('snippets'));
  assert.ok(ext.shortcuts.has('alt+s'));
  const renders = [];
  const widgets = new Map();
  const notifications = [];
  let keys = [];
  const theme = { fg: (_color, text) => text, bold: text => text };
  const ctx = {
    mode: 'tui', hasUI: true,
    ui: {
      theme,
      setWidget: (id, value) => widgets.set(id, value),
      notify: text => notifications.push(text),
      custom: async factory => {
        let result;
        const component = factory({ terminal: { rows: 40 }, requestRender() {} }, theme, {}, value => { result = value; });
        renders.push(component.render(100).join('\n'));
        for (const key of keys) {
          component.handleInput(key);
          renders.push(component.render(100).join('\n'));
        }
        assert.notEqual(result, undefined, 'Test menu must close explicitly.');
        return result;
      },
    },
  };
  const emit = async (event, payload = {}) => {
    let result;
    for (const handler of ext.handlers.get(event) ?? []) result = await handler(payload, ctx);
    return result;
  };
  const menu = () => ext.commands.get('snippets').handler('', ctx);
  const input = text => emit('input', { text, source: 'interactive' });
  keys = [' ', '\r'];
  await emit('session_start');
  assert.equal(renders.length > 0, true, 'Interactive startup must open the snippet picker.');
  assert.deepEqual(await input('Startup task'), {
    action: 'transform',
    text: 'Alpha instructions\n\nStartup task',
  });
  assert.equal(await input('Unmodified'), undefined);
  keys = ['\t', '\x1b', ' ', '\x1b[B', ' ', '\x1b[B', ' ', '\x1b[B', ' ', '\r'];
  await menu();
  const rows = renders[0].split('\n').filter(line => line.includes('[ ]'));
  assert.deepEqual(rows.map(line => line.split('[ ] ')[1]), ['Alpha', 'Beta', 'Zulu', 'Tail']);
  assert.doesNotMatch(renders[0], /GENERAL|TOOLS|BASIC DEVELOPMENT/);
  assert.ok(renders.some(text => text.includes('Preview: Alpha')));
  assert.match(widgets.get('prompt-snippets').join('\n'), /prepend: Alpha · Beta · Zulu/);
  assert.match(widgets.get('prompt-snippets').join('\n'), /append: Tail/);
  keys = [' ', '\x1b'];
  await menu();
  assert.deepEqual(await input('Task'), {
    action: 'transform',
    text: ['Alpha instructions', 'Beta instructions', 'Zulu instructions', 'Task', 'Tail instructions'].join('\n\n'),
  });
  assert.equal(widgets.get('prompt-snippets'), undefined);
  assert.equal(await input('Next task'), undefined);
  keys = [' ', '\r'];
  await ext.shortcuts.get('alt+s').handler(ctx);
  keys = ['\x1b'];
  await emit('session_start');
  assert.equal(await input('New session'), undefined);
  ctx.mode = 'rpc';
  const renderCount = renders.length;
  await emit('session_start');
  assert.equal(renders.length, renderCount, 'RPC startup must not open the picker.');
  assert.deepEqual(notifications, []);
  ctx.mode = 'tui';
  ctx.hasUI = false;
  await emit('session_start');
  assert.equal(renders.length, renderCount, 'Headless startup must not open the picker.');
  ctx.mode = 'rpc';
  await menu();
  assert.equal(notifications.at(-1), 'Snippet menu requires interactive mode');
  console.log('PASS: flat ordering, ignored legacy categories, preview, selection, cancellation, insertion, one-shot and session reset, shortcut, RPC warning');
} finally {
  rmSync(fixture, { recursive: true, force: true });
}
