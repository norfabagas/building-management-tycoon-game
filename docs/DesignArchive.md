# Design archive and repository cleanup

On 2026-10-16 the user requested moving repository designs to a new Figma file and reducing repository storage. [Building Management Tycoon — Game Design](https://www.figma.com/design/CCbs9OcpTNV01vqAvylWwZ) contains **348 imported graphics**: all 179 tracked design PNG/SVG files, 148 runtime PNGs and 21 gameplay screenshots. Every upload returned a successful placement. [The manifest](../design/figma-manifest.json) records original paths, byte sizes, SHA-256 values, dimensions, Figma node IDs, image hashes and permanent node links.

The Starter plan permits three pages:

| Page | Contents |
| --- | --- |
| 00 · Guide and approved boards | Read me, 16 approved boards, overview, editable BM vector |
| 01 · Archive and artwork | Rejected historical boards clearly labeled, brand headers, five original atlases, gameplay evidence |
| 02 · Production and runtime | Source animation sheets, contact sheets, editable production vectors, visual runtime catalog |

Original raster bytes remain available through Figma `download_assets` → `rawImages`. A district-atlas recovery matched the original SHA-256 exactly. Approved boards retain their 1600 × 1000 proportions; SVGs import as editable vector trees. Board PNG text remains rasterized. This migration does not recreate native text, component variants, responsive screens or prototype interactions. Archive captions use Inter because the connected font catalog lacks Trebuchet MS; original board typography remains in the images. No shared library was published.

The two PPTX transports are represented by rendered boards, rather than imported as native Figma slides. Their full original bytes remain recoverable at the immutable pre-cleanup Git commit linked in the manifest, alongside their builders and original Canva reference. The connector created a new design file in the connected team's drafts, not a separate project folder.

## What stays in Git

The BM master SVG and compact PNG remain unchanged. All 158 runtime PNG/WAV resources, runtime manifest, fonts, platform icons, procedural SVG sources, audio/font specifications, prompts and authoring/export/validation scripts stay tracked. Normal Flutter and Netlify builds require no Figma access or source restoration. Gameplay, saves and economy are unchanged.

Cleanup removes **73 files / 36,989,962 bytes (35.28 MiB)** from the current tree: large source PNGs, duplicate contact sheets/board previews, screenshots and two generated PPTX files. Restored/generated design PNGs, PPTX files and documentation screenshots are ignored. Markdown image references now link to corresponding Figma nodes. An ignored local safety copy is in `.tools/design-source-backup/` within the release checkout.

This is a normal commit, without shared-history rewriting or force-pushing. Historical blobs remain in Git; GitHub's total repository storage will not immediately shrink by the tree reduction. Fresh shallow clones avoid most historical payload. Removing historical blobs requires a separately coordinated history migration.

## Restore originals before regeneration

1. Find the source path and `nodeId` in `design/figma-manifest.json`.
2. Call Figma `download_assets` for that node and use its **rawImages** URL. The resized node `export` is unsuitable. URLs expire; never commit them.
3. From the repository root, run:

```powershell
node design/production/restore-source.mjs design/tycoon/assets/district.png '<fresh rawImages URL>'
```

The helper accepts archived design PNG paths and HTTPS Figma asset URLs, refuses existing destinations, and checks length/SHA-256 before writing. Restore the five `design/tycoon/assets/` atlases and five `design/production/animation_sources/` sheets for complete regeneration; they remain ignored. Originals can also be recovered from the manifest's pre-cleanup commit. Board/PPTX builders retain their historical workstation-specific dependency paths.

After restoration and regeneration, run:

```powershell
node design/production/validate.mjs --require-local-sources
```

Normal CI runs `validate.mjs` without the flag. It verifies runtime bytes/hashes, image/frame/geometry rules, audio, bundle declarations and present local sources. For missing archived raster sources it matches the source hash to the verified migration record; it **does not fetch or re-audit remote source bytes**. Missing sources without matching archive evidence still fail. A full source audit requires restoring originals and the flag above. Runtime manifests and artwork references are unchanged by this migration.

## Migration verification

All 348 Figma nodes were read back with no missing nodes or aspect-ratio discrepancies. Visual review covered an approved board, source district artwork and the editable building-vector collection. The restoration helper downloaded the district atlas from Figma and verified its original hash. Restoring the ten source PNGs allowed `--require-local-sources` to validate all 158 assets and 124 frames; these temporary originals were then removed again. The cleaned checkout passes ordinary asset validation using ten archived-source records. Formatting, Flutter analysis, all 75 tests and the release Web build passed with unchanged application/runtime files; Android compilation was blocked by the missing SDK. Netlify publication status is recorded separately in [Deployment.md](Deployment.md).
