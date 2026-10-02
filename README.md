# Linguago

**Offline voice translation that runs entirely on your phone.**

Speak a phrase, see it translated, hear it spoken back — with the network
switched off. No accounts, no servers, no API keys. Your voice never leaves the
device.

Linguago runs Google's **Gemma 4 E2B** locally via LiteRT-LM. The model does
speech recognition *and* translation in a single pass, so there's no cloud
round-trip and nothing to intercept.

```
┌─ Translate ──────────────────────┐
│  🎙  🔊   🇬🇧 English  ▾          │
│                                  │
│  Can you help me?                │
│  ─────────────  ⇄  ───────────── │
│  🇫🇷 French ▾        📋  🔊      │
│                                  │
│  Pouvez-vous m'aider ?           │
└──────────────────────────────────┘
```

---

## Status

Working and verified on real hardware, but **not production-ready**. See
[Known limitations](#known-limitations) before depending on it.

| | Android | iOS |
|---|---|---|
| Model loads on device | ✅ Galaxy S22+ | ✅ iPhone 17 |
| Speech → translation | ✅ | ✅ |
| 15 languages selectable | ✅ | ✅ |
| Text input / editing | ✅ | ✅ |
| Offline text-to-speech | ⚠️ voice-dependent | ⚠️ voice-dependent |
| Reverse direction (fr→en) | ⏳ untested | ⏳ untested |

Measured on a Galaxy S22+ (CPU backend), ~5 seconds of speech:

```
[Linguago] audio=163884B en->fr in 4734ms
Hello, I'm a bit tired.
Bonjour, je suis un peu fatigué.
```

---

## Requirements

**A real device.** x86_64 emulators cannot run this — LiteRT-LM's runtime ships
`arm64-v8a` only. iOS Simulator can't do audio input either.

| | Minimum |
|---|---|
| Device RAM | **6 GB** (the app blocks below ~5 GB) |
| Free storage | ~3 GB |
| Android | API 24+, arm64 |
| iOS | 15.0+, physical device |
| Flutter | 3.44+ / Dart 3.12+ |

**iOS additionally needs a paid Apple Developer account.** The
`extended-virtual-addressing` and `increased-memory-limit` entitlements are
required to memory-map a 2.6 GB model, and a free Personal Team cannot sign
them.

`DEVELOPMENT_TEAM` is intentionally blank in the checked-in project, so set
your own before building for iOS: open `ios/Runner.xcworkspace`, select the
Runner target, and pick your team under **Signing & Capabilities**. If Xcode
says the profile lacks an entitlement, add *Increased Memory Limit* and
*Extended Virtual Addressing* via **+ Capability** — editing
`Runner.entitlements` alone doesn't register them with Apple.

---

## Getting started

```bash
git clone https://github.com/Darkbeast-glitch/linguago.git
cd linguago

flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Getting the model onto the device

The model is **2.6 GB** and is not bundled — app stores cap bundles far below
that. On first launch the app offers to download it.

That download **cannot be resumed** (see [Known
limitations](#known-limitations)), so for development it's far less painful to
fetch it once on your machine and copy it across:

```bash
# curl -C - resumes; the in-app download does not.
# Re-run this exact command if it drops.
curl -L -C - -o gemma-4-E2B-it.litertlm \
  https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm
```

Verify it's the full **2,588,147,712 bytes** before copying.

**Android** — install the app first, then:

```bash
adb push gemma-4-E2B-it.litertlm \
  /sdcard/Android/data/com.princejnr.linguago/files/
```

**iOS** — install the app first, then:

```bash
xcrun devicectl device copy to \
  --device <device-id> \
  --domain-type appDataContainer \
  --domain-identifier com.princejnr.linguago \
  --source gemma-4-E2B-it.litertlm \
  --destination Documents/gemma-4-E2B-it.litertlm
```

Or drag the file into the app's folder via Finder → *your iPhone* → **Files** →
**Linguago**.

The app finds a hand-copied model before offering the download, and registers it
**in place** — no second copy, no extra storage. Note that uninstalling the app
deletes it.

---

## How it works

```
   🎙 microphone
        │  16 kHz mono WAV
        ▼
  AudioDataSource ──────┐
                        │
   TranslationRepository┤──► GemmaDataSource ──► Gemma 4 E2B (LiteRT-LM)
                        │         │                    on-device
   TtsDataSource ◄──────┘         ▼
        │              TranslationOutputParser
        ▼
   🔊 platform TTS
```

One pass, one model. The audio goes straight to Gemma, which returns the
transcription and the translation together — there's no separate
speech-recognition stage.

**Feature-first MVVM**, with a strict dependency direction:

```
View → ViewModel → Repository → Data Source
```

Views never touch inference, the microphone, or speech synthesis. Swapping the
model or the runtime means changing one provider override, and nothing above the
repository notices. State is [Riverpod](https://riverpod.dev); models are
[Freezed](https://pub.dev/packages/freezed).

```
lib/
├── app/                  theme, routing, root widget
├── core/                 constants, errors, storage, device checks, shared widgets
└── features/
    ├── onboarding/       first-launch intro
    ├── model_setup/      download / sideload / load, device capability gate
    ├── home/             landing screen, language search, menu
    ├── translation/      the translator — the heart of the app
    │   ├── data/         datasources (gemma, audio, tts), repository, parser
    │   ├── view/
    │   └── viewmodel/
    └── settings/
```

---

## Adding a language

**15 languages ship enabled:** English, French, Spanish, German, Italian,
Portuguese, Dutch, Russian, Arabic, Hindi, Chinese, Japanese, Korean, Turkish
and Polish. Each has a base text-to-speech voice on both iOS and Android, so
hearing the result back actually works.

Gemma 4 E2B handles **140+ languages** natively, so adding another is a data
change — not a model change. Add an entry to `SupportedLanguages` in
[`lib/features/translation/data/models/language.dart`](lib/features/translation/data/models/language.dart):

```dart
static const spanish = Language(
  code: 'es',
  displayName: 'Spanish',
  flagEmoji: '🇪🇸',
  ttsLocale: 'es-ES',
);

static const all = [english, french, spanish, /* … */];
```

Everything else — the picker, search, swap, prompt construction — reads from
that list.

Two things genuinely vary by language and deserve testing rather than
assumption:

- **Speech recognition quality.** Gemma's CoVoST average of 33.47 hides a wide
  spread. Well-resourced languages do considerably better; low-resource ones do
  considerably worse.
- **Voice availability.** iOS ships base voices for major languages; Android
  depends on what the user has downloaded. Set `supportsTts: false` only when no
  mainstream engine has a voice — the app checks at runtime and shows a
  capability gap rather than failing silently.

---

## Known limitations

**The model download cannot resume.** This is enforced in `flutter_gemma`, not a
network fluke: it hardcodes `allowPause: false` for any `huggingface.co` URL,
because Hugging Face serves weak ETags and a byte-range resume risks silent
corruption. An interruption at 90% restarts from zero, and download progress
visibly jumps *backwards* when an attempt fails and retries. Mirroring the model
to storage with strong ETags (GCS, Firebase Storage, self-hosted) restores
resume — `flutter_gemma` supports it for those hosts.

**Low-memory devices are turned away.** A Galaxy A06 (3.55 GB RAM) downloads the
model, loads it, then gets killed by Android's low-memory killer. The app checks
RAM *before* offering the download and shows an unsupported-device screen, since
spending 2.6 GB of someone's bandwidth to reach a crash helps nobody.

**Text-to-speech depends on installed voices.** A missing voice is surfaced as a
capability gap — the translation stays on screen with an explanation. There is
deliberately **no cloud fallback**; that would break the offline guarantee.

**Backend choice is platform-specific and counterintuitive.** Google's E2B
figures:

| Platform | CPU | GPU |
|---|---|---|
| Galaxy S26 Ultra | 1733 MB | **676 MB** |
| iPhone 17 Pro | **607 MB** | 1450 MB |

GPU is both faster *and* lighter on Android; on iOS it buys speed at double the
memory. The app picks per platform and falls back to CPU if the preferred
backend is unavailable.

---

## Privacy

Full policy: **[PRIVACY.md](PRIVACY.md)**, also readable inside the app under
Settings → Privacy (embedded rather than linked, since an offline app
shouldn't need a connection to explain itself).

- Audio is recorded to a temporary file, read once, and **deleted immediately**.
- Nothing you say is transmitted anywhere. There is no analytics SDK, no
  crash reporter, and no backend.
- Debug logging of transcripts is `kDebugMode`-guarded, so speech content cannot
  reach a release build's logs.
- The only network request the app ever makes is the one-time model download.
- **One caveat, disclosed honestly:** tapping the speaker hands translated
  *text* to the platform speech engine. iOS synthesises on-device; on Android
  it depends on the engine the user has selected, and some send text to their
  own servers. That's the engine's behaviour, not the app's, but it is the only
  path by which translated text could leave the device.

---

## Tech stack

| | |
|---|---|
| Model | Gemma 4 E2B (`.litertlm`, ~2.6 GB, Apache 2.0) |
| Runtime | LiteRT-LM via `flutter_gemma` + `flutter_gemma_litertlm` |
| Audio in | `record` — 16 kHz mono WAV, the model's native format |
| Audio out | `flutter_tts` — platform speech engines, offline |
| Typography | Plus Jakarta Sans, bundled — never fetched at runtime |
| State | Riverpod (no codegen) |
| Models | Freezed + json_serializable |

Deliberately **not** used: Firebase, any backend, cloud translation, cloud TTS.
See [CONTRIBUTING.md](CONTRIBUTING.md) for why those are out of scope.

---

## Contributing

Contributions welcome — please read [CONTRIBUTING.md](CONTRIBUTING.md) first. It
covers the architecture rules, the code-generation step, and a few sharp edges in
the toolchain that will otherwise cost you an afternoon.

---

## License

[Apache License 2.0](LICENSE).

Plus Jakarta Sans is bundled under the [SIL Open Font License
1.1](assets/fonts/OFL.txt).

The Gemma 4 model is distributed under Apache 2.0 by Google and is **not**
redistributed here — the app downloads it from
[litert-community](https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm)
at runtime.
