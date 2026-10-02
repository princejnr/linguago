# Linguago

Offline, on-device voice translator. MVP: spoken English ↔ French, optional
offline TTS playback, zero network dependency after model assets are present.
Full spec: `linguago_prd.docx` (source of truth — this file is a working
summary, not a replacement).

## Product boundaries (do not cross without asking)

- No accounts/auth, no Firebase/Supabase, no backend server, no cloud
  translation or cloud TTS APIs, no chat history, no generic chatbot UX.
- MVP language set is English + French only. A third language is
  architecturally supported (`SupportedLanguages`) but must stay
  `isEnabled: false` until the full speech → translation → TTS pipeline has
  been proven on real devices for en/fr.
- Never add an online fallback "just in case" — that violates the offline
  promise. If a local capability is missing (e.g. no TTS voice for a
  language), surface it as a capability gap in the UI, don't fetch from the
  network.

## Architecture — feature-first MVVM

```
View → ViewModel → Repository → Data Sources
```

- **View**: renders UI, forwards user actions to the ViewModel. No
  Firebase/network/AI/business logic in widgets, ever.
- **ViewModel**: a Riverpod `Notifier`, owns UI state, calls the repository,
  maps results/errors into state.
- **Repository**: an abstract contract (`TranslationRepository`) the
  ViewModel depends on. Swapping fake data for real Gemma/audio/TTS should
  only ever mean swapping the `Provider` override, never touching the
  ViewModel or View.
- **Data sources** (Milestone 2+): `GemmaDataSource`, `AudioDataSource`,
  `TtsDataSource` — the only places allowed to touch local inference,
  microphone APIs, or offline speech synthesis.

State management: **Riverpod only**, no codegen (`Notifier`/`NotifierProvider`
— not `riverpod_generator`), to keep the dependency surface small. Models:
**Freezed + json_serializable**, generated files (`*.freezed.dart`, `*.g.dart`)
live beside their source and are committed after `dart run build_runner
build --delete-conflicting-outputs`.

## Design system (`linguagodesigns/`)

Source: `designs_system.png` (LinguaLearn Design System v1.0), plus
`Get Started Screen.png`, `Homescreen.png`, `Tranlsate Screen.png` for layout
reference. Tokens live in `lib/app/app_theme.dart` (`AppColors`, `AppTheme`).

| Token | Hex |
|---|---|
| Primary Purple | `#7C3AED` |
| Accent Green | `#10B981` |
| Highlight Yellow | `#F59E0B` |
| Text Gray | `#6B7280` |
| Background Gray | `#E5E7EB` |

Type scale: H1 32/bold, H2 24/semibold, H3 18/medium, body 16/regular.
Currently uses the system font (no bundled custom font yet — `google_fonts`
was intentionally skipped for MVP since its default runtime font-fetching
would conflict with the offline requirement; revisit only with a
locally-bundled font asset).

The mockups show a full multi-language app (Spanish, German, etc.) — that's
the long-term product vision, not the MVP. Build UI generic enough to support
more languages later, but only wire up English/French for real.

Match the mockups' actual composition, not just their color palette — e.g.
the Translate screen mic is a compact button in a bottom toolbar (not a giant
centered circle), and source/target live inside one card split by a swap
button, not two separate floating cards. `Homescreen.png` was deliberately
**not** built (Expert Class/lesson cards are out of MVP scope) — only Get
Started → Translate exist as real screens.

Asset paths are case-sensitive on Android/iOS device builds even though
macOS's filesystem isn't — keep the casing in `pubspec.yaml`'s `assets:` list,
the actual folder/file names, and every `Image.asset(...)` call identical
(project convention: lowercase, e.g. `assets/images/flags.png`).

## Rules for how to work on this codebase (PRD §29)

1. Work incrementally, one milestone at a time — never generate the whole
   app in one pass.
2. Before writing code, list the exact files you're going to create/change.
3. Provide complete files, never partial snippets or "// rest of code".
4. Briefly explain each new/changed file and how it fits
   View → ViewModel → Repository → Data Source.
5. Never put Gemma/audio/TTS logic, or general business logic, in widgets.
6. Never call a data source directly from a View — always through the
   ViewModel → Repository.
7. Verify current package APIs before using them (`flutter_gemma`,
   `flutter_gemma_speech`, etc.) — do not invent methods; these are evolving
   packages.
8. Keep dependencies minimal — justify every new package.
9. Real local inference must be tested on real ARM64 devices, not just
   simulators/emulators.
10. After each milestone, run `flutter analyze` + `flutter test`, and note
    how to run/try what was just built before moving to the next milestone.

## On-device model — verified facts (checked 2026-08-29)

Verified against live docs and the installed package source, not memory. Re-verify
before relying on any of it — these packages move fast (13 releases in the two
weeks before this was written).

**Model: Gemma 4 E2B**, `gemma-4-E2B-it.litertlm`, ~2.59 GB, Apache 2.0 and
**ungated** (no Hugging Face token needed), from `litert-community/gemma-4-E2B-it-litert-lm`.
Config lives in `lib/core/constants/model_config.dart`.

- **Gemma 4 is real** (announced April 2026); E2B/E4B are real product names, "E"
  = *effective* parameters. The PRD's naming was correct.
- **Audio requires the `.litertlm` build.** `.task` files have no audio encoder —
  audio input silently won't work. Always pass `fileType: ModelFileType.litertlm`;
  the parameter *defaults to `.task`*.
- **TranslateGemma is text-only** (Gemma 3-based) despite PRD §6 listing it as a
  speech-path candidate. It also is gated and CPU-only in Flutter. Not usable for
  audio.
- **Audio contract:** 16 kHz mono, **30 second hard maximum**, ~25 tokens/sec.
  Audio must come *after* the text in the prompt — the order `Message.withAudio`
  already produces.
- `supportAudio: true` must be set on **both** `getActiveModel(...)` and the
  session/chat (`enableAudioModality`). Setting only one leaves audio unavailable.
- **MediaPipe LLM Inference is in maintenance mode** per Google. LiteRT-LM is the
  supported path, which is why `main.dart` registers `LiteRtLmEngine()`.

**Packages:** `flutter_gemma` ^1.6.5 is a facade that registers **no engine on its
own** — `flutter_gemma_litertlm` is what actually runs the model.
`FlutterGemma.initialize(inferenceEngines: [LiteRtLmEngine()])` runs once in
`main()`.

**Platform requirements** (already applied): Android `minSdk 24` / `compileSdk 36`,
`arm64-v8a` only — LiteRT-LM's FFI runtime has no x86_64 build, so **x86_64
emulators cannot run this app**; use an arm64 emulator or a real device. iOS
deployment target 15.0 plus the extended-virtual-addressing and
increased-memory-limit entitlements in `ios/Runner/Runner.entitlements` — without
them iOS kills the app when the model is mapped. **Audio input is
physical-iOS-device only**; the Simulator is CPU-only (256 MB Metal cap).

**Downloads cannot resume**, and this is enforced in `flutter_gemma`, not merely a
CDN quirk: `smart_downloader.dart` hardcodes `allowPause: false` for any URL
containing `huggingface.co`, because HF serves weak ETags and a byte-range resume
risks silent corruption. Every retry therefore restarts from 0 — which is why
download progress visibly jumps *backwards* (2% → 1%) when an attempt fails.
`foreground: true` is required on Android or the OS kills the download at 9
minutes (verified: it is the running notification, not `Config.runInForeground`
alone, that activates the service). Never bundle the model as an asset.

**"Installed" and "active" are different state.** `FlutterGemma.isModelInstalled()`
reports file presence; `getActiveModel()` needs an *active model identity*, and
throws a bare `StateError: No active inference model set` when there isn't one.
The identity is persisted, but only restored by
`FlutterGemmaPlugin.instance.modelManager.ensureInitialized()` — which neither
`getActiveModel()` nor `isModelInstalled()` calls for you. Without awaiting it, a
freshly-launched app fails even with the model correctly installed.
`GemmaDataSource` awaits it before any active-model read, and `load()` re-registers
an on-disk model (`installFromFile`) when the identity is missing — which is also
what makes a sideloaded file work on first launch.

**Known `flutter_gemma` bug — stale task records.** When a download is
interrupted, its `background_downloader` task record survives. The next attempt
takes the "attach to existing task" branch, finds the dead record, reports
`Existing download failed: TaskStatus.canceled`, and returns **without deleting
it** — so every retry re-attaches to the corpse and fails instantly, with no way
out but reinstalling the app. `GemmaDataSource._purgeStaleDownloadTasks()` works
around this by cancelling and deleting all records before each download. Don't
remove it without checking the upstream bug is fixed.

**Sideloading.** Because of the above, `GemmaDataSource.findSideloadedModel()`
checks for a hand-copied model before offering the download, and
`installFromFile()` registers it *in place* (no copy, no extra storage):

```
# curl -C - DOES resume, unlike the in-app download
curl -L -C - -o gemma-4-E2B-it.litertlm \
  https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm
adb push gemma-4-E2B-it.litertlm /sdcard/Android/data/com.princejnr.linguago/files/
```

On iOS, drag the file into the app's Documents in Finder (`UIFileSharingEnabled`
is set).

### Device memory is a hard gate (measured 2026-08-30)

A **Galaxy A06 (SM-A065F) cannot run Gemma 4 E2B** — measured 3.55 GB total RAM,
<1 GB available. It downloads and loads the model, then Android's low-memory
killer takes the process the moment the compositor needs frame buffers
(`BLASTBufferQueue: Can't acquire next buffer` → "Lost connection to device").
Switching `PreferredBackend` does not save it; the shortfall is ~2.5 GB.

Note the backend trade-off runs *opposite* to intuition on Android — Google's E2B
figures for a Galaxy S26 Ultra are **CPU 1733 MB vs GPU 676 MB**, so GPU is the
memory-cheaper backend there. On iPhone 17 it inverts: CPU 607 MB / GPU 1450 MB,
with GPU ~5x faster prefill. Don't "fix" memory pressure by switching to CPU
without checking the numbers for that platform.

`DeviceCapability` (`lib/core/device/device_capability.dart`) therefore gates
setup on ≥5 GB RAM (and Android's `isLowRamDevice`) **before** offering the
download, surfacing `ModelSetupStatus.unsupportedDevice` — deliberately with no
retry action, since burning 2.6 GB to reach an OOM kill helps nobody. An
unreadable RAM figure is treated as supported: a wrong lock-out is worse than a
failed load attempt.

**This is the PRD-sanctioned response to low-end hardware (§20, §22) — do not
redesign the model architecture around one cheap test device.** Known-good test
device: iPhone 17 (8 GB), which is also what Google benchmarked E2B on.

### iOS entitlements need a paid Apple Developer account (open issue)

The three entitlements in `ios/Runner/Runner.entitlements` are **commented out** —
a free Personal Team cannot sign them, and Xcode refuses to build with them. This
does **not** affect launching the app, navigating, or downloading the model; it is
expected to bite when *loading* the 2.6 GB model, because
`extended-virtual-addressing` is what permits an mmap that large.

Unmeasured, so don't state it as fact either way: Google's own E2B figures are
~607 MB resident (CPU) / ~1.45 GB (GPU) on an iPhone 17 Pro, comfortably inside
normal iOS limits — it is the 2.6 GB *virtual mapping*, not resident memory, that
needs the entitlement. Whether iOS kills the app without it has not been tested.

**Therefore validate the model pipeline on Android first** — no equivalent
entitlement gate there. Resolve the iOS entitlement question (i.e. a paid account)
before treating iOS as supported.

## First working translation (measured 2026-08-30)

The pipeline is **proven on real hardware** — Galaxy S22+ (SM-S906U, 7.05 GB RAM),
Gemma 4 E2B sideloaded, `PreferredBackend.cpu`:

```
[Linguago] audio=163884B en->fr in 4734ms
--- raw model reply ---
Hello, I'm a bit tired.
Bonjour, je suis un peu fatigué.
```

~5s of speech → 4.7s end-to-end (prefill 2251ms + decode 1126ms, 20 chunks).
Accurate, natural French. Fully offline.

**The model ignores the prompt's requested `Transcription:` / `Translation:`
labels** and answers positionally — transcription on line 1, translation on
line 2. `TranslationOutputParser` therefore falls back to reading two bare
lines when no labels are found; labelled replies still take priority, and three
or more bare lines are refused as too ambiguous to guess at. Don't "fix" the
parser by tightening it back to labels-only without re-checking real output.

Untested and still open: **fr→en**, GPU backend (expected faster and, on
Android, *lower* memory), and TTS (Milestone 6, `speak()` currently throws
`TtsUnavailableException` by design).

## Milestone status

- [x] **Milestone 1 — Flutter shell.** Theme, navigation (Get Started →
      Translator → Settings), translator UI wired to Riverpod with a
      `FakeTranslationRepositoryImpl` (canned data, no real audio/model),
      settings screen, Freezed models (`Language`, `TranslationResult`,
      `TranslationState`, `AppSettings`).
- [x] **Milestone 2 — Gemma boot.** `flutter_gemma` + `flutter_gemma_litertlm`
      wired up; Android/iOS native config for a 2.6 GB memory-mapped model;
      `GemmaDataSource` (the only file touching `flutter_gemma`); model-setup
      feature (check → download with progress/cancel/cellular warning → load →
      ready) gating entry to the app. **Not yet run on a real device** — the
      download and inference paths are unverified until then.
- [x] **Milestone 3 — Audio capture (code complete, unverified on device).**
      `AudioDataSource` (the only file touching the mic) records 16 kHz mono
      WAV via `package:record` — the model's native format, so no resampling.
      `GemmaTranslationRepositoryImpl` orchestrates mic → Gemma → parsed
      result and is now the live `translationRepositoryProvider`.
      `TranslationOutputParser` recovers transcription/translation from the
      model's reply and is unit-tested against markdown, code fences, French
      labels, wrapped lines, and empty/garbled replies. Recording auto-stops
      at `AppConstants.maxRecordingSeconds` (15s), well inside the model's 30s
      ceiling. Temp audio is deleted immediately after being read (PRD §23).
      **Nothing here has run against a real model** — no inference has ever
      executed, so the prompt format and the parser's assumptions about the
      model's reply shape are unvalidated guesses until it does.
- [ ] Milestone 4 — Reliable English → French short-phrase translation.
- [ ] Milestone 5 — French → English + language swap (swap UI already built).
- [ ] Milestone 6 — Offline TTS wired to `speak()`/`stopSpeaking()`.
- [ ] Milestone 7 — Third language (Ewe), only after 2–6 are proven.
- [ ] Milestone 8 — Hardening: errors, performance, permissions, privacy,
      device testing, release build.

## Try it

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after touching any @freezed model
flutter analyze
flutter test
flutter run
```

Current flow (Milestone 1, fake data): launch → Get Started → tap the arrow
FAB → Translator screen → tap the mic → after ~1s of fake "recording" +
"processing", the PRD's sample sentence ("Where is the nearest pharmacy?" →
"Où est la pharmacie la plus proche ?") appears in the two bubbles. Tap the
speaker icon on the translation bubble — it toggles `isSpeaking` state but
doesn't play real audio yet (no TTS wired up). Settings is reachable via the
gear icon in the app bar.
