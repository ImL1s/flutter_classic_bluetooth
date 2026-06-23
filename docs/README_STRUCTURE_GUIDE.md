# README Structure Guide (flutter_classic_bluetooth)

The spec for authoring this package's `README.md`. It adapts the canonical
cross-package README guide for a **Flutter plugin** with native platform code, so
the per-platform support story is first-class instead of hidden. An AI assistant
(or a human) should follow this verbatim to keep the README consistent,
professional, and **discoverable** on pub.dev.

It blends a clean product spine (cover → descriptive title → overview → table of
contents → … → getting started → support → about) with the pub.dev
search-ranking lessons every package needs, plus the two sections a plugin must
carry that a pure-Dart library does not: **Platform support** and **Platform
setup**.

---

## 0. How to use this guide

1. Read **Global rules** (§1) — they apply to every section.
2. Build the README in the **exact section order** of §2. Include all
   `REQUIRED` sections; include `OPTIONAL` / `RECOMMENDED` ones only when the
   note applies.
3. For each section, copy its **template** from §3 and replace every
   `{{PLACEHOLDER}}`. Never leave a placeholder in the output.
4. Run the **Authoring checklist** (§5) before finishing.
5. Keep the README and `pubspec.yaml` in sync per the **Sync rules** (§4).

Placeholder convention: `{{LIKE_THIS}}`. Anything in `{{ }}` must be filled or
the line/section removed.

---

## 1. Global rules

These are non-negotiable and apply to the whole file.

**Discoverability (pub.dev indexes text, not pixels):**
- The **first ~500 characters** (the title + overview prose) and the **first
  ~5000 characters** carry the most search weight. Front-load real sentences
  containing the primary keywords there — not buried in emoji bullets or code
  blocks (the indexer weights those less).
- State the **primary keywords as plain words** early and naturally: the domain
  nouns (`Bluetooth Classic`, `RFCOMM`, `SPP`, `serial`), the verbs the plugin
  supports (`discover`, `pair`, `connect`, `send`, `receive`), the device classes
  (`ESP32`, `HC-05`, `printer`, `scanner`, `OBD-II`), and the platforms
  (`Android`, `iOS`, `Windows`, `macOS`, `Linux`, `Flutter`). Do not keyword-stuff
  — write natural prose that happens to be keyword-dense.
- Disambiguate from **BLE** explicitly and early. The single most common wrong
  click is a BLE user; say "Bluetooth **Classic** (RFCOMM/SPP), not BLE" in the
  overview and the FAQ.
- Every image **must have descriptive `alt` text** — the indexer cannot read
  images, so the alt text is the only signal it gets.

**Images & links (pub.dev rendering gotcha):**
- pub.dev does **not** render repo-relative image paths. **Any image must use an
  absolute raw URL**, e.g.
  `https://raw.githubusercontent.com/almasumdev/flutter_classic_bluetooth/main/images/{{FILE}}`.
- This package ships **no banner or preview image**. The logo lives at
  `images/logo.png` and is surfaced **only** through the `screenshots:` entry in
  `pubspec.yaml` (the pub.dev sidebar) — it is **not** placed at the top of the
  README. Do not re-add a top logo/banner; the README opens with the badges.
- Internal links (Table of contents) use lowercase-hyphen anchors of the heading
  text: lowercase it, drop punctuation, turn each space into `-` (an em dash `—`
  with surrounding spaces becomes `--`).

**Style:**
- Headings: **sentence case** for top-level (`## Getting started`,
  `## Platform support`), kept stable so TOC anchors don't break.
- The H1 is a **descriptive, keyword-rich title**
  (`# Bluetooth Classic (RFCOMM) Plugin for Flutter`), **not** just the package
  name — pub.dev already shows the name in its own header.
- Every code fence declares its language (` ```dart `, ` ```xml `, ` ```bash `).
- Code samples must be **copy-paste runnable** and minimal — no pseudo-code, and
  verify every symbol against the plugin's real Dart API before publishing.
- Tone: confident and factual. **Never claim a capability a platform does not
  have.** The capability matrix and the `getPlatformCapabilities()` flags are the
  source of truth — the prose must agree with them.

**Honesty rule (plugin-specific):**
- Bluetooth Classic support genuinely differs per OS. Every "Yes/No" in the
  Platform support matrix must match the real native implementation **and** the
  `BtcPlatformCapabilities` flag the code returns. If a feature is blocked by the
  OS (iOS discovery/server, macOS unpair), say so in a footnote — do not imply
  parity that isn't there.

**Table of contents rule:**
- The TOC lists **only the sections that appear *below* it**. The title and
  Overview sit **above** the TOC, so they are **not** listed — start the TOC at
  **Key features**.
- **Nest the Getting started subsection headings** under the Getting started
  entry, so readers can jump straight to a specific task.

---

## 2. Canonical section order

Build the README top-to-bottom in this order.
`REQUIRED` = always · `RECOMMENDED` = include unless there's a reason not to ·
`OPTIONAL` = include only when the note applies.

| # | Section | Status | Purpose |
|---|---------|--------|---------|
| 1 | Badges | REQUIRED | pub version/points/likes, GitHub stars/forks/issues, CI, license, Dart, Flutter |
| 2 | Descriptive title (H1) + intro | REQUIRED | Keyword-rich `# Bluetooth Classic (RFCOMM) Plugin for Flutter` + one-paragraph pitch |
| 3 | Star/like CTA | RECOMMENDED | One-line blockquote, **top only** — never repeat it at the bottom |
| 4 | Overview | REQUIRED | Keyword-dense "what it is + what it does"; disambiguate from BLE; **What you can do with it** bullets |
| 5 | Table of contents | REQUIRED | Lists only sections **below** it — starts at Key features; **nests Getting started subsections** |
| 6 | Key features | REQUIRED | Grouped `<details>` capability bullets, keyword-rich |
| 7 | Platform support | REQUIRED (plugin) | The per-feature × per-OS capability matrix, with footnotes for OS limits |
| 8 | Example | RECOMMENDED | Pointer to the runnable `example/` app and its screens |
| 9 | Other useful links | RECOMMENDED | API reference, repo, changelog, issues |
| 10 | Installation | REQUIRED | `flutter pub add` + import line |
| 11 | Platform setup | REQUIRED (plugin) | Android manifest perms, iOS Info.plist (MFi + usage), macOS entitlement |
| 12 | Getting started | REQUIRED | **Many small, focused, copy-paste snippets** — one task each |
| 13 | FAQ | RECOMMENDED | Long-tail queries (Classic vs BLE, why iOS differs, multiple connections, pairing on macOS/Linux) |
| 14 | Support and feedback | RECOMMENDED | Issues, discussions, contributing |
| 15 | About | RECOMMENDED | What it is, maintainer, **the license** in prose, contributors image |

> **Plugin deviations from the cross-package guide.** The canonical guide says
> "no dedicated Platform support section" because for a pure-Dart library pub.dev
> derives the platforms automatically. For *this* plugin the matrix is core
> information — *which features* work on *which OS* — so **Platform support** and
> **Platform setup** are REQUIRED sections here. There is still **no Performance,
> Comparison, Migration, Architecture, or License section** (the License lives in
> the `LICENSE` file and is stated in About prose).

> **Getting started** is the workhorse: prefer **many short snippets** (one per
> task — init/support check, discover, list paired, connect, receive, send, watch
> state, disconnect/dispose, server, pair/unpair, adapter control, error handling)
> over a few large ones. Small, titled, copy-paste examples are what users scan
> for, and each heading becomes a nested TOC entry.

---

## 3. Section templates

Copy each block and fill the placeholders.

### 1. Badges
```md
<p align="center">
  <a href="https://pub.dev/packages/flutter_classic_bluetooth"><img src="https://img.shields.io/pub/v/flutter_classic_bluetooth.svg" alt="pub version"></a>
  <a href="https://pub.dev/packages/flutter_classic_bluetooth/score"><img src="https://img.shields.io/pub/points/flutter_classic_bluetooth" alt="pub points"></a>
  <a href="https://pub.dev/packages/flutter_classic_bluetooth"><img src="https://img.shields.io/pub/likes/flutter_classic_bluetooth" alt="pub likes"></a>
  <a href="{{REPO_URL}}/stargazers"><img src="https://badgen.net/github/stars/{{OWNER}}/{{REPO}}?icon=github" alt="GitHub stars"></a>
  <a href="{{REPO_URL}}/actions/workflows/ci.yml"><img src="{{REPO_URL}}/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.3+-0175C2?logo=dart" alt="Dart"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.3+-02569B?logo=flutter" alt="Flutter"></a>
</p>
```
> No banner above the badges — this package has no banner asset, and the logo is
> the pub.dev `screenshots:` entry, not a README image. The badges are the first
> thing in the file. Add a **Flutter** badge alongside the **Dart** one (this is
> a plugin, not a pure-Dart package). The GitHub stars/forks/issues badges only
> resolve once the repo is public and can transiently rate-limit on shields.io —
> drop them if the flakiness isn't worth it; keep pub + CI + license + SDK.

### 2. Descriptive title (H1) + intro
```md
# Bluetooth Classic (RFCOMM) Plugin for Flutter

**flutter_classic_bluetooth** is a Flutter plugin for **Bluetooth Classic serial
communication over RFCOMM (the Serial Port Profile, SPP)**. It lets you
**discover, pair, connect to, and exchange data with** Bluetooth Classic devices
— {{ESP32, HC-05/HC-06 modules, barcode scanners, printers, OBD-II adapters}} —
from a single Dart API on **Android, Windows, macOS, Linux, and iOS (MFi)**.
{{One more sentence on the streamed-I/O value proposition.}}
```

### 3. Star/like CTA (top only)
```md
> ⭐ **Find this useful?** [Star it on GitHub]({{REPO_URL}})
> and 👍 [like it on pub.dev](https://pub.dev/packages/flutter_classic_bluetooth) —
> it helps other Flutter developers find a maintained Bluetooth Classic plugin.
```
> Place this **once**, directly under the intro. **Do not** repeat a star/like
> line in About/Contributors — the bottom closes with "Pull requests are welcome"
> instead (see §15). Duplicating the CTA reads as nagging.

### 4. Overview ← highest-weighted text on the page
```md
## Overview

flutter_classic_bluetooth speaks **RFCOMM/SPP**, the classic Bluetooth serial
transport — **not** Bluetooth Low Energy (BLE). {{2–3 sentences on how it wraps
each platform's native stack, client vs server, multiple connections, and the
adapter/discovery/bond streams.}}

**What you can do with it:**

- {{capability 1, keyword-bearing}}
- {{capability 2}}
- {{capability 3}}
```
> No preview image — this package ships none. The BLE disambiguation belongs in
> the very first sentence.

### 5. Table of contents
```md
## Table of contents

- [Key features](#key-features)
- [Platform support](#platform-support)
- [Example](#example)
- [Other useful links](#other-useful-links)
- [Installation](#installation)
- [Platform setup](#platform-setup)
- [Getting started](#getting-started)
  - [{{First task}}](#{{first-task}})
  - [{{Second task}}](#{{second-task}})
- [FAQ](#faq)
- [Support and feedback](#support-and-feedback)
- [About](#about)
  - [Contributors](#contributors)
```
> Starts at **Key features** (the title/Overview are above the TOC). Every
> Getting started subsection heading is **nested** beneath it.

### 6. Key features
```md
## Key features

A complete Bluetooth Classic (RFCOMM/SPP) client + server toolkit behind one
Dart API. Expand a group for details:

<details>
<summary><b>📡 {{Group}}</b></summary>

- **{{Keyword}}** — {{short benefit}}
- **{{Keyword}}** — {{short benefit}}

</details>
```
> Group related capabilities under collapsible `<details>` (Connectivity,
> Discovery & pairing, Streamed I/O, Adapter & capabilities, Reliability). Put the
> searchable keyword first in each bullet.

### 7. Platform support (REQUIRED for this plugin)
```md
## Platform support

Bluetooth Classic capabilities differ by OS, so the plugin reports what each one
can actually do (also queryable at runtime via `getPlatformCapabilities()`):

| Feature | Android | Windows | macOS | Linux | iOS |
|---------|---------|---------|-------|-------|-----|
| {{Feature}} | ✅ | ✅ | ✅ | ✅ | ❌ |

{{Numbered footnotes for every OS-specific caveat — MFi on iOS, IOBluetoothDevicePair
on macOS, BlueZ D-Bus on Linux, no-unpair-API on macOS, etc.}}
```
> Each cell must match the real native implementation **and** the matching
> `BtcPlatformCapabilities` flag. A ✅ the code can't back is a bug in the README.
> Keep the column order Android → Windows → macOS → Linux → iOS (most→least
> capable) so the strong story reads first.

### 8. Example
```md
## Example

A complete, runnable demo app lives in the [`example/`]({{REPO_URL}}/tree/main/example)
directory, with screens for {{adapter control, discovery, paired devices,
client/server, capabilities}}. Clone the repository and run it, or copy any
snippet from [Getting started](#getting-started) below.
```

### 9. Other useful links
```md
## Other useful links

- [API reference](https://pub.dev/documentation/flutter_classic_bluetooth/latest/)
- [Source code on GitHub]({{REPO_URL}})
- [Changelog]({{REPO_URL}}/blob/main/CHANGELOG.md)
- [Issue tracker]({{REPO_URL}}/issues)
```

### 10. Installation
```md
## Installation

```bash
flutter pub add flutter_classic_bluetooth
```

Then import it:

```dart
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
```
```

### 11. Platform setup (REQUIRED for this plugin)
```md
## Platform setup

**Android** — add the Bluetooth permissions to `AndroidManifest.xml` ({{both the
≤ API 30 and the API 31+ permission sets}}).

**iOS** — declare the MFi protocol(s) in `UISupportedExternalAccessoryProtocols`
and a `NSBluetoothAlwaysUsageDescription` usage string in `Info.plist`.

**macOS** — add the `com.apple.security.device.bluetooth` entitlement and a usage
string.
```
> Show the actual XML each platform needs, copy-paste ready. This is the section
> that prevents "it builds but does nothing" bug reports.

### 12. Getting started ← many small snippets, one task each
```md
## Getting started

### {{Most common task}}

```dart
{{minimal, runnable example}}
```

### {{Next task}}

```dart
{{snippet}}
```
```
> One focused, copy-paste snippet per heading. Aim for the full common surface:
> init/support check, discover, list paired, connect (with timeout/secure),
> receive, send (`add`/`writeBytes`/`writeString`/`allSent`), watch state,
> disconnect/dispose, run a server, pair/unpair, adapter state & control, error
> handling. Each heading becomes a nested TOC entry. Verify every symbol against
> the real Dart API.

### 13. FAQ
```md
## FAQ

**Is this Bluetooth Classic or Bluetooth Low Energy (BLE)?**
{{answer — Classic/RFCOMM, point BLE users elsewhere}}

**{{question repeating target keywords}}**
{{answer}}
```
> Cover the long-tail reassurance queries: Classic vs BLE, which platforms, why
> iOS differs (MFi), multiple simultaneous connections, how pairing works on
> macOS/Linux.

### 14. Support and feedback
```md
## Support and feedback

- Found a bug or want a feature? Open an issue on the [issue tracker]({{REPO_URL}}/issues).
- Questions and ideas are welcome via [GitHub Discussions]({{REPO_URL}}/discussions).
- Pull requests are welcome — see the repository for contribution guidelines.
```

### 15. About
```md
## About

flutter_classic_bluetooth is an open-source, MIT-licensed Flutter plugin for
Bluetooth Classic (RFCOMM/SPP) serial communication across Android, Windows,
macOS, Linux, and iOS (MFi), {{one-line positioning}}.

flutter_classic_bluetooth is created and owned by **Nurullah Al Masum**.

### Contributors

flutter_classic_bluetooth grows with its community — every contributor is listed here:

<a href="{{REPO_URL}}/graphs/contributors">
  <img src="https://contrib.rocks/image?repo={{OWNER}}/{{REPO}}" alt="flutter_classic_bluetooth contributors"/>
</a>

Want to help? Pull requests are welcome — see [Support and feedback](#support-and-feedback).
```
> State the license in prose here (no separate License section); the `LICENSE`
> file remains the source of truth. Use an **ownership declaration with the
> author's full name**. The Contributors block closes with "Pull requests are
> welcome" — **not** a second star/like CTA (that lives once, at the top).

---

## 4. Sync rules (README ↔ pubspec.yaml)

Keep these aligned on every release:

- **`description`** (pubspec): ≤ 180 chars (pana's sweet spot 60–180),
  keyword-front-loaded. Pattern:
  `Flutter plugin for Bluetooth Classic (RFCOMM) across {{platforms}}. {{verbs}}.`
- **`topics`** (pubspec): **max 5**, lowercase, hyphenated
  (`bluetooth`, `bluetooth-classic`, `rfcomm`, `serial`, `iot`). Mirror the
  README's primary keywords; don't waste a slot on a low-intent tag.
- **`screenshots`** (pubspec): the `images/logo.png` entry that surfaces the logo
  on pub.dev. This is the **only** place the logo appears — keep it in sync with
  the file on disk; do not add the logo to the README.
- **Platform support matrix** must agree with the `BtcPlatformCapabilities` flags
  returned by `getPlatformCapabilities()` and with the native implementations. If
  a capability flag flips, update the matrix, the footnotes, and the relevant
  CHANGELOG entry in the same change.
- **License**: lives in the `LICENSE` file (pub.dev reads it) and is stated in the
  **About** section — no separate README section.
- **`repository` / `issue_tracker`**: set and consistent with the links used in
  the README and the badges.

---

## 5. Authoring checklist

Before publishing, confirm:

- [ ] No top logo/banner image — the README opens with the badges; the logo is the
      pubspec `screenshots:` entry only.
- [ ] Badges include **Dart and Flutter** (plugin) plus CI status.
- [ ] Descriptive, keyword-rich H1 (not just the package name).
- [ ] Overview is plain prose, disambiguates **Classic vs BLE** in the first
      sentence, and the primary keywords appear in the first ~500 chars.
- [ ] Star/like CTA appears **once** (top); the bottom closes with "Pull requests
      are welcome", not a second CTA.
- [ ] Table of contents **starts at Key features** and **nests the Getting started
      subsections**; every anchor resolves.
- [ ] **Platform support** matrix present, with footnotes, and every cell matches
      the `BtcPlatformCapabilities` flags + native code.
- [ ] **Platform setup** shows the real Android/iOS/macOS configuration XML.
- [ ] Getting started has many small, single-task, runnable snippets; every symbol
      verified against the real Dart API.
- [ ] FAQ disambiguates Classic vs BLE and explains the iOS/MFi limitation.
- [ ] About states the license; `LICENSE` file present.
- [ ] No Performance / Comparison / Migration / Architecture / dedicated License
      section.
- [ ] pubspec `description` ≤180 chars and `topics` ≤5, both keyword-aligned.
- [ ] No `{{PLACEHOLDER}}` left anywhere.

---

## 6. Relationship to the cross-package guide

This document is the **plugin-specialized** form of the canonical
`README_STRUCTURE_GUIDE.md` used across all of the author's pub.dev packages. It
keeps that guide's spine and pub.dev SEO rules and changes only what a native
plugin requires:

- **Adds** `Platform support` and `Platform setup` as REQUIRED sections.
- **Drops** `Performance`, `Comparison`, and `Migration` (not applicable here).
- **Replaces** the banner/preview imagery with a single pub.dev `screenshots:`
  logo and **no** in-README image.
- **Adds** the *honesty rule*: every capability claim must match the runtime
  `getPlatformCapabilities()` flags and the native implementation.

When in doubt on anything not covered here, defer to the canonical guide.
