<p align="center">
  <!-- Placeholder for app icon -->
  <img src="assets/images/squeeze_icon_512.png" alt="Squeeze App Icon" width="128">
</p>

<h1 align="center">Squeeze</h1>

<p align="center">
  <strong>Desktop image compressor & resizer</strong>
</p>

Fast, private, cross‑platform image compression and resizing. Drag & drop folders or files, tweak a couple options, and ship smaller images in seconds.

## Screenshots

<!-- Placeholder for screenshots -->
![Screenshot 1](assets/screenshots/squeeze_screenshot_1.png)
![Screenshot 2](assets/screenshots/squeeze_screenshot_2.png)
![Screenshot 3](assets/screenshots/squeeze_screenshot_3.png)
![Screenshot 4](assets/screenshots/squeeze_screenshot_4.png)

---

## Highlights

- Local and private: no uploads, no telemetry
- Batch-first: drag folders, recursive discovery
- Smart defaults: EXIF orientation, safe PNG→JPEG conversion (protects transparency), non-destructive outputs
- Exact-size modes: Long edge, Fit, Fill (crop), Pad (letterbox)
- Quality vs speed: resampling options (Fast/Quality/Pixel art)
- Parallel processing with cancel
- Optional “Pro optimize” using system tools (jpegoptim, pngquant, oxipng)
 
## Supported platforms

- Windows, macOS, Linux (Flutter desktop)

## Requirements

- Flutter (stable channel)
- Dart SDK bundled with Flutter

## Get started

- Clone and install deps
  - flutter pub get
- Enable desktop targets (run once)
  - flutter config --enable-windows-desktop --enable-macos-desktop --enable-linux-desktop
- Run
  - flutter run -d windows
  - flutter run -d macos
  - flutter run -d linux

## Optional external optimizers (detected automatically)

- macOS (Homebrew)
  - brew install jpegoptim pngquant oxipng
- Ubuntu/Debian
  - sudo apt-get install jpegoptim pngquant oxipng
- Windows (winget or chocolatey)
  - winget install XhmikosR.jpegoptim
  - winget install Kornelski.pngquant
  - winget install Sharkdp.Oxipng
  - or Chocolatey equivalents: choco install jpegoptim, pngquant, oxipng

## Build release

- Windows: flutter build windows
- macOS: flutter build macos
- Linux: flutter build linux

## Troubleshooting

- Drag & drop flaky on some Linux DEs → use Select files/folder buttons
- “Tool not found” in Pro optimize → install tool and restart the app
- HEIC/RAW not supported (for now)
- Color profiles (ICC) are not preserved by the current imaging backend

## User Guide

### Overview of the UI

- Left: Drop zone and live previews
  - Drag & drop images or folders (recursive)
  - Select files/folder via buttons
- Bottom: Job list
  - Shows filename, output path or error, and status (queued/processing/done/error)
- Right: Settings
  - Resize mode, resampling, format, quality, metadata, min size skip, naming, output folder, Pro optimize toggles
  - Start/Cancel and Clear actions
  - Summary and “Open output folder”

## Workflow

- Add images
  - Drop files/folders, or click Select files / Select folder
  - The queue populates with supported images (JPG/JPEG/PNG)
- Choose settings
  - Resize mode:
    - Constrain long edge: scales by the longest side (no crop)
    - Fit within WxH: fit inside a box (no crop)
    - Fill to WxH (crop): fill exact size by cropping overflow
    - Pad to WxH: fit and letterbox to exact size (transparent if PNG, white for JPEG)
  - Resampling:
    - Fast: quick and good for general use
    - Quality: cleaner edges, crisper thumbnails (slower)
    - Pixel art: nearest-neighbor for crisp pixel graphics
  - Output format:
    - Auto: preserves type, converts PNG→JPEG only if no transparency
    - JPEG or PNG: force output type
  - JPEG quality: 30–95; 70–85 is a good range for photos
  - Strip metadata: removes EXIF and other tags
  - Min input size (KB): skip tiny files
  - Filename suffix: appended to outputs; exact-size modes add -WxH
  - Output folder:
    - Default: “Compressed” next to each original
    - Custom: all outputs grouped by parent folder inside your chosen directory
- Pro optimize (optional)
  - Optimize JPEG (jpegoptim): strips metadata, progressive, max quality cap
  - Quantize PNG palette (pngquant): large savings on UI/screenshot PNGs
  - Optimize PNG (oxipng): lossless structural optimization
- Run
  - Click Start; watch statuses update
  - Cancel to stop the queue early
  - Click Open output folder to view results

### Tips and presets

- Photos for web/docs:
  - Resize: Constrain long edge 1600–2048
  - Format: Auto (photos usually end up JPEG)
  - JPEG quality: 78–85
  - Resampling: Quality
- UI screenshots:
  - Format: PNG
  - Pro optimize: pngquant ON (65–85), oxipng ON
  - Resampling: Quality (for scaled screenshots) or leave original size
- Icons/thumbnails:
  - Resize: Fill to WxH or Pad to WxH
  - Resampling: Quality (vector-like art) or Pixel art if needed

### What happens under the hood (short)

- Files discovered recursively; supported: .jpg/.jpeg/.png
- Decode → apply EXIF orientation → resize (selected mode + resampling) → decide format (Auto honors transparency) → encode
- Non-destructive output with suffix and collision-safe naming
- Parallel work with isolates and a bounded concurrency; cancel supported
- Optional external optimizers run after encode
