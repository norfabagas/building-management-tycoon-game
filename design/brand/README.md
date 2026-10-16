# BM tower mark

The unchanged master SVG and PNG remain in Git after the 2026-10-16 [Figma migration](../../docs/DesignArchive.md). The title preview is archived; the small SVG headers and their generator remain available locally.

`bm-tower.svg` is the master artwork, drawn from geometric paths rather than generated imagery. Canvas: 512 × 512, square corners. Colors: evergreen `#203B3A`, ivory `#F5F3EB`.

The B uses two inset window openings. Its right edge joins the M's structural upright, while the M crown creates the tower silhouette. Treat the letters as one mark; do not typeset separate B and M letters over the artwork.

Use the square beside the title **Building Management Tycoon**. Preserve the aspect ratio, keep at least one quarter of the icon's width between it and the title, and avoid effects, gradients, extra skyline silhouettes, faces, or decorative initials. Minimum icon size: 24 px in compact board headers; prefer 32 px or larger in game UI. The supplied PNG is a raster export for previews; the SVG remains the editable source and was uploaded to Canva.

The Flutter project also uses this exact source for Android launcher/splash and Web icons. `export-app-icons.mjs` creates the eleven PNG exports with Sharp available. Set `RUNTIME_NODE_MODULES` to the directory containing Sharp when using the bundled runtime. This export step is optional for normal Flutter builds; the generated icons are checked in.

The production pipeline also exports the unchanged mark at eight runtime sizes to `assets/game/brand/` and combines it with an outlined title using the bundled Roboto fallback. The SVG master and existing platform icons remain unchanged; see [Assets.md](../../docs/Assets.md).

Run `node design/brand/generate-headers.mjs` from the repository root to regenerate the 16 SVG title headers. Each uses the same monogram, game title, colors, and spacing with a board-specific label. Compact headers accommodate existing content; wide pages scale the vector artwork proportionally. `title-preview.png` is a preview of the foundations header.
