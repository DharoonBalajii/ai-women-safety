# Raksha Thunai

A hackathon prototype for a voice-powered emergency safety app. One trigger
(a hold-to-arm beacon, or a silent quick-report tile) starts an emergency
session, captures live location, and — via **Sarvam AI** — turns a spoken
description of what's happening into structured emergency context that
keeps updating on a live incident timeline.

## Stack

- **Flutter** (Android / iOS / Web) — single codebase, fastest path to a
  working cross-platform prototype in a hackathon timeframe.
- **Provider** for state management (`EmergencyProvider`, `ContactsProvider`,
  `SettingsProvider`).
- **Sarvam AI** — speech-to-text (`saaras` models) + chat completion
  (`sarvam-105b-conversations`) to transcribe a voice clip and extract a
  threat type + summary from it. See [`lib/services/sarvam_ai_service.dart`](lib/services/sarvam_ai_service.dart).
- **OpenStreetMap** (`flutter_map` + the Overpass API) for the map and
  nearby safe-place lookup — no API key required.
- **On-device storage** (`shared_preferences`) for trusted contacts,
  incident history, and the Sarvam key — there is no backend yet.

## Demo mode

The app runs fully without any credentials: `SarvamAIService` returns a
realistic mocked transcript + threat classification whenever no API key is
configured, so the whole SOS flow is demoable out of the box. Add a real
key in **Settings → Sarvam AI** to switch Voice SOS to live speech-to-text
and AI context extraction.

## What's simulated (by design, for this prototype)

- **Responder dispatch** — the "nearest patrol identified → control room
  notified → dispatched → arrived" timeline is a scripted simulation of the
  intended control-room/responder-network flow, not a real dispatch backend.
- **Trusted-contact alerts** — there's no SMS gateway yet, so "Notify"
  opens the device's own SMS composer prefilled with the emergency
  summary + live-location link; the contact still gets a real text once
  the user hits send.
- **One-tap OS trigger** — implemented as a long-press home-screen quick
  action (`quick_actions`), the closest hackathon-scope equivalent of the
  iPhone Action Button / Android hardware gesture. Full OS-level Action
  Button (App Intents) integration needs native Swift/Kotlin work beyond
  this prototype.

## Getting started

```bash
flutter pub get
flutter run
```

Run `flutter analyze` and `flutter test` before committing — both should
stay clean.
