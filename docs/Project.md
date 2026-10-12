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

The initial Flutter Android/Web project setup is complete. It includes the approved BM branding and artwork, MVVM structure, five-slot local profile metadata, district naming and an empty pannable canvas. A 158-file runtime [asset pack](Assets.md) now supplies backgrounds, buildings, rooms, road tiles, character/transport/effect animations, icons, decorations and audio. Formatting, analysis and all 14 tests pass; Android debug and release Web builds have been verified. Offline Web reload was checked during setup. The user selected **Relaxed idle (Option 1)** on 2026-10-12, with apartment rent paid weekly at in-game Sunday Noon and other income daily at Noon; see [Economy.md](Economy.md). The playable management/economy MVP remains the next implementation milestone, including engine playback/composition for the supplied assets. Finalize the remaining catalogs/tuning and durable game persistence before adding those systems. See [Setup.md](Setup.md) for commands and boundaries.
