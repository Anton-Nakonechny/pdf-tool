# CLAUDE.md — pdf-tool

Client-side PDF workspace: add PDFs/images, reorder, rotate, crop, straighten, merge,
and export a combined PDF. Everything runs in the browser — no server, no network calls
at runtime (PDF engine is bundled).

## The one file

The entire app is a single self-contained artifact: **`PDF-workspace.html`** (~1.1 MB,
391 physical lines). It is a *bundler* artifact, not normal source:

- **Line 377** — `<script>` with a JSON map of gzip+base64 resources (pdf-lib, pdfjs, fonts).
- **Lines 388–390** — `<script type="__bundler/template">` whose content (**line 389**) is
  the ENTIRE real app HTML encoded as ONE JSON string, with every `</` escaped as `/`.

The actual app — `class Component extends DCLogic` plus its HTML template — lives inside
that JSON string on line 389. **Do NOT hand-edit the escaped bytes.**

## Editing workflow (the only safe way)

In Python:
1. `html = json.loads(lines[388])`  (physical line 389 = index 388)
2. Do plain string replacements on the decoded HTML. **Assert each anchor matches exactly once.**
3. Re-encode: `enc = json.dumps(html, ensure_ascii=False)`, then escape every `</` → `/`.
4. Assert round-trip: `json.loads(enc) == html`.
5. Write back `lines[388] = enc + '\n'`.
6. Verify: extract the `class Component` script and `node --check` it.

## Framework binding syntax (inside the template)

- Events: `sc-camel-on-click` / `-mouse-down` / `-input` / `-change="{{ handler }}"`
- Interpolation: `{{ value }}`
- Conditionals: `<sc-if value="{{ flag }}" hint-placeholder-val="{{ false }}"> … </sc-if>`
- State: `this.setState({ ... })`; the view model is built in `renderVals()`.

## Architecture notes

- **State** lives in `class Component` (`state = { pages, sel, busy, modal, ... }`).
  `modal` is a string tag (`'image'`/`'merge'`/`'crop'`/`'straighten'`/…) driving `sc-if` dialogs.
- **In-memory stores** (instance fields, not React state): `this.docs` (`{docId: {name, bytes}}`),
  `this.imgs` (`{imgId: {bytes, type, url, el, w, h}}` — `url` is a `URL.createObjectURL`
  that must be revoked to free memory), `this.pending`, `this.uid`.
- **Page object**: `{ id, kind: 'pdf'|'image'|'merge', rot, crop, fine, base, thumb, ... }`.
  Transforms are stored declaratively and applied at render/export time (crop → 90° rot →
  fine-straighten+auto-crop), so edits are reversible.
- **Export**: pdf-lib rotates only in 90° steps; a straightened page (`fine` set) is
  rasterized from its `base` on export; untouched pages stay vector.

## Build / test

No build system, no `package.json`, no automated test framework. **Verification is manual
in-browser** (needs the Claude Chrome extension connected), plus a static `node --check`
on the extracted `Component` script. Plans and test plans for in-flight features live in
`.md/`.

## Conventions

- Preserve the monochrome "blueprint" theme. Available button classes: `btn-primary`,
  `btn-secondary`, `btn-ghost` — there is **no** danger/red style; reuse `btn-primary`
  for confirm/destructive-confirm actions.
- New dialogs mirror the existing `sc-if` + `.dialog.blueprint` + corner `<i>` structure
  and reuse `cancelModal` for their Cancel button.
