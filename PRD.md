PRD
Product
- Name: Squeeze — desktop image compressor & resizer
- Elevator pitch: Fast, private, batch-first image shrinking and exact-size generation, with smart defaults and opt‑in pro optimizations.

Problem
- Oversized images slow down sharing and publishing. Web tools are slow/sketchy; pro tools are heavy and fiddly for simple batch jobs.

Goals
- Compress and optionally resize many images quickly
- Keep it private and local
- Make the default path obvious and safe (non-destructive)
- Offer “power knobs” without overwhelming users

Non-goals (v1)
- HEIC/RAW handling
- ICC/color management
- Visual diff/preview before/after
- Installers and OS shell extensions (for later)

Primary user stories
- I drop a folder of images and get smaller files out with the same names plus a suffix
- I can set exact sizes for thumbnails/icons without learning a heavy app
- I can preserve transparency or safely convert PNGs to JPEG when it makes sense
- I can choose faster vs. higher-quality resizing
- If I have pro tools installed, I can squeeze more bytes with one toggle

Feature scope delivered
- Input
  - Drag & drop files/folders; recursive discovery
  - Select files/folder via dialogs
- Options
  - Resize mode: Long edge, Fit, Fill, Pad
  - Target WxH for exact modes
  - No upscale toggle
  - Resampling: Fast/Quality/Pixel art
  - Output format: Auto/JPEG/PNG
  - Safe PNG→JPEG if no transparency
  - JPEG quality slider
  - Strip metadata toggle
  - Min input size skip (KB)
  - Filename suffix
  - Output folder chooser (default: sibling “Compressed”), with per-parent grouping when global output is set
- Processing
  - Parallel jobs with bounded concurrency and cancel
  - Progress and per-job status/errors
  - Non-destructive filenames with collision handling
- Pro optimize (optional)
  - JPEG: jpegoptim (strip, progressive, max)
  - PNG: pngquant (quality range) then oxipng (lossless)
  - Automatic tool detection and UI gating

Tech and architecture
- Flutter desktop with fluent_ui
- image for decode/resize/encode
- desktop_drop and file_selector for UX
- path for paths
- Isolates via compute; concurrency capped to min(numProcessors, 6)
- External tools via Process.runSync, safe and optional

Why this design
- Keeps the default flow simple: drop, tweak one or two options, start
- Quality knobs (resampling, pro optimize) are present but unobtrusive
- Full privacy by default; external tools are local executables
- MVP remains pure-Dart; pro extras are opt-in

Acceptance criteria met
- Drag/drop and selection work across platforms
- Batch jobs run without freezing the UI
- Resize modes yield correct dimensions (no unintended upscales)
- PNG transparency is preserved; PNG→JPEG happens only if safe
- Outputs are collision-safe and non-destructive
- Optional optimizers are detected and gated in the UI

Known constraints
- No HEIC/RAW
- ICC profiles not preserved; rare color shifts on wide-gamut images
- WebP/AVIF not exposed in this build
- External tools must be installed via system package managers

What’s next (backlog)
- WebP/AVIF output profiles
- Multi-size generator and platform presets (favicon/iOS/Android)
- Watch folder mode
- CLI/headless mode
- OS context menu integration
- Visual before/after preview with diff
- Preserve ICC or allow manual assignment
- Packaged installers (.msi/.dmg/.AppImage)

Test plan (light)
- Functional: 5–50 mixed images; verify sizes, suffixes, and no overwrites
- Edge cases: tiny files skipped, transparency preserved, no-upscale behavior
- Performance: 100 images, check UI responsiveness and finishing summary
- Cross-platform smoke: run on Windows/macOS/Linux