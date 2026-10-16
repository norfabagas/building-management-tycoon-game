# Project Overview

## Title
Building Management Tycoon Game

## Concept
A 2D offline simulation and management tycoon game where players own, build, and manage an entire Central Business District (CBD). Players start with empty land and strategically construct and micro-manage multiple buildings, floors, and tenants to expand their real estate empire.

## Core Objectives
- **Establish a CBD:** Start the game by naming your CBD area and surveying the empty land.
- **Construct Buildings:** Build various structures such as apartments, food courts, parking areas, and (eventually) highly expensive office towers and malls.
- **Manage Floors:** Micro-manage each building floor-by-floor, including both multi-level underground basements and high-rise above-ground floors.
- **Tenant Management:** Attract, manage, and satisfy tenants for each specific floor and room to maximize revenue.
- **Progression:** Unlock new building types and expand the CBD footprint as income grows.

## Target Audience
Casual to mid-core players who enjoy simulation, strategy, and purely offline idle-tycoon mechanics with deep micro-management.

## Scope
- Minimum Viable Product (MVP): A single CBD area where the player can place initial buildings, manage floors (above/underground), and handle basic tenant mechanics. Playable on Web and Android.
- Future Updates: Broader city integration, VIP tenants, events, and deeper economic customization.

## Current milestone

The user requested a complete gameplay/quality validation after catalog 2. [GameplayValidation.md](GameplayValidation.md) records findings, player-facing corrections, whole-ledger replay and offline performance evidence. Keep approved prices/rules intact; clarify consequential choices and improve responsive floor visibility using the existing art. Publication and platform limitations are recorded in Deployment.md.

The user approved catalog 2 on 2026-10-16, expanding the current implementation task to all four Figma building types and the associated luxury, needs, synergy, gems, decorations, audio and motion systems. [FigmaCatalogProposal.md](FigmaCatalogProposal.md) now records the approved values; [FigmaAssessment.md](FigmaAssessment.md) tracks actual implementation and verification rather than assuming parity from bundled graphics. Source publication and test/build results must be recorded after the final checks. The later request explicitly includes pushing GitHub and deploying the existing Netlify site.

The 2026-10-16 update adds footprint-shaped rectangular apartment exteriors, a 24-hour clock at one hour per real second, midnight book closing and smooth directional daylight gradients. Schema 6 migrates existing clocks without rebilling completed closings or resetting progress. The five save slots, prices, capacities, limits and daily/Sunday billing rules remain unchanged; former Noon references mean 24:00. See Rules.md, Logic.md and Design.md for the current override.

The latest money feedback uses one visible **Balance**, immediate purchase deductions and immediate full cancellation refunds before building opening/upgrade completion. Schema 5 migrates queued orders once without charging already-paid work again; daily/Sunday operating settlement is unchanged. See PROJECTS.md for current validation/publication and Economy.md for the contract.

The 2026-10-14 apartment upgrade iteration adds **Upgrade building** in building detail, with purchases up to 10 floors, 3 basements, 3 standard lifts and 1 executive lift. This replaces the prior one-floor/permanent-floor restriction. See [Economy.md](Economy.md) for the user-approved level/lift costs, upkeep, durations and deferred happiness effects. Schema 4 stores upgrades and migrates schemas 1/2/3 while preserving existing progress. `PROJECTS.md` records validation/publication for this iteration; earlier release notes below describe the starting point.

The current Web release is live on [Netlify](https://bmt.niceblue.biz.id) as of 2026-10-14, including the approved apartment exterior, construction bars/percentages and manual **Open to Business**, alongside Floor 1/B1 detail, 5-second phases and pinch zoom. Existing saves preserve open businesses and migrate safely to schema 3. It was uploaded through the CLI; GitHub continuous deployment is not connected. See [Deployment.md](Deployment.md) for the project identity, update procedure and production validation.

The approved apartment starter now implements the first playable loop: five local profiles, $40,000 starting funds, footprint/cost review, automatic surrounding roads, shell/B1 construction, parking-gated tenants, room management, weekly Sunday rent, daily parking/expenses/taxes and offline catch-up. Full snapshots use local transactional SQLite/IndexedDB storage. The unchanged BM identity and 158-file [asset pack](Assets.md) supply the map, modules, rooms and resident idle animation. The starter has one apartment floor; other building types, lifts/luxury/extra-basement upgrades, synergy, achievements, decorations and audio integration await their catalogs/systems. The user approved these release boundaries on 2026-10-12. See [Gameplay.md](Gameplay.md), [Economy.md](Economy.md) and [Setup.md](Setup.md) for the contract, validation and next work.
