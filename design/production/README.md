# Production game asset tooling

Runtime assets: `../../assets/game/`. Specification and usage: [docs/Assets.md](../../docs/Assets.md). The original BM SVG and approved atlases are preserved. `build.mjs` exports vectors and atlas cells, registers character frames, builds the manifest/Dart constants and renders the gallery/contact sheets.

## Rebuild

Use Node 24, the project's pinned Flutter SDK and Python 3.12 or newer:

```powershell
npm ci --prefix design/production
python -m pip install -r design/production/requirements.txt
python design/production/build_wordmark.py
python design/production/build_audio.py
node design/production/build.mjs
node design/production/validate.mjs
```

Normal app builds do not need Node/Python asset regeneration: exports are checked into Git. Python's font helper needs FontTools; audio uses only the standard library. On this workstation FontTools is installed under ignored `.tools/asset-python`, with `PYTHONPATH` pointing there. `RUNTIME_NODE_MODULES` can point to a directory containing the pinned Sharp package when using the bundled runtime. The generator uses the local pinned Dart formatter, falling back to `dart` on PATH.

The checked-in imagegen source PNGs and [exact prompts](prompts.md) make packaging reproducible without another generation call. Image generation itself is not deterministic. New poses must be reviewed against approved identities before replacing a source; the existing artwork is not silently regenerated.

## Inspect

Serve the repository on localhost and open `/design/production/gallery.html`. The standalone gallery lists all 158 files and plays animation sequences; audio controls require an explicit play action. Pause motion globally or select a sequence per sheet. This is a development asset gallery, not an additional game screen or public deployment.

`previews/asset-overview.png` is a compact overview. Four family contact sheets cover all visual files. Caption/title text is outlined from the bundled Roboto font, keeping the previews reproducible without installed workstation fonts. Every preview reuses the defined BM mark.

`sources/` stores vector outputs and outlined glyph data. `animation_sources/` contains five reference-guided raster sheets. `audio-spec.json` records durations, channel/sample format, loop flags and peaks. `manifest.json` in the runtime folder carries source/output hashes and animation metadata. Do not edit generated Dart path constants by hand.

The generator does not remove arbitrary files. When renaming/removing an asset deliberately, update its source and remove only that obsolete generated file before rebuilding; the manifest and pubspec must remain consistent.
