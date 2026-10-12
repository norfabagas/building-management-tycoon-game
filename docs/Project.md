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

The current Web release is live on [Netlify](https://building-management-tycoon-game.netlify.app) as of 2026-10-12. It was uploaded manually; GitHub continuous deployment is not connected. See [Deployment.md](Deployment.md) for the project identity, update procedure and production validation.

The approved apartment starter now implements the first playable loop: five local profiles, $40,000 starting funds, footprint/cost review, automatic surrounding roads, shell/B1 construction, parking-gated tenants, room management, weekly Sunday rent, daily parking/expenses/taxes and offline catch-up. Full snapshots use local transactional SQLite/IndexedDB storage. The unchanged BM identity and 158-file [asset pack](Assets.md) supply the map, modules, rooms and resident idle animation. The starter has one apartment floor; other building types, lifts/luxury/extra-basement upgrades, synergy, achievements, decorations and audio integration await their catalogs/systems. The user approved these release boundaries on 2026-10-12. See [Gameplay.md](Gameplay.md), [Economy.md](Economy.md) and [Setup.md](Setup.md) for the contract, validation and next work.
