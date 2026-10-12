# Local font fallback

The approved reference uses Trebuchet MS. No redistributable Trebuchet file was supplied for the application. The theme keeps that requested family and packages Roboto as a local fallback, with Noto Sans Thai for Thai district names. Android and Web therefore use the same available fallback resources. Do not copy workstation fonts into the project without a distribution-ready source.

Sources: [Roboto](https://github.com/google/fonts/tree/main/ofl/roboto) and [Noto Sans Thai](https://github.com/google/fonts/tree/main/ofl/notosansthai). Their included OFL files describe usage terms. Fonts were retrieved 2026-10-11. UI language currently remains English. Additional writing systems need local glyph coverage before claiming support.

The custom Web bootstrap points automatic fallback requests at the app's own origin. The release Web cache includes the packaged fonts, so play does not depend on a font CDN.
