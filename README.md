# ScannerMApp

A QR code and barcode scanner app built with Delphi and FireMonkey, using [ZXing.Delphi](https://github.com/Spelt/ZXing.Delphi) for decoding and [TFrameStand](https://github.com/andrea-magni/TFrameStand) for the views.

It started in 2017 as a sample for TFrameStand ([blog post](https://blog.andreamagni.eu/2017/06/scannermapp-a-qrbarcode-scanner-app-with-delphi-zxing-and-tframestand/)). It now builds with RAD Studio 13 and runs on recent Android versions, with a dark UI.

| Scans | Scan result | About |
|:---:|:---:|:---:|
| ![Scans](docs/screenshots/list.png) | ![Scan result](docs/screenshots/result.png) | ![About](docs/screenshots/about.png) |

The screenshots come from the Windows build; on Android the bottom bar has **Gallery** instead of **Open**.

## Features

- Live scanning from the camera, with a square viewfinder, the points found by ZXing and a torch button. The frames are decoded in the background (`ScanAsync`), so the preview stays smooth.
- Scanning from a picture in the photo library (Android) or from a file (Windows).
- Every format ZXing.Delphi 4 reads automatically: QR code, Micro QR, Data Matrix, Aztec, PDF 417, MaxiCode, Code 39/93/128, EAN, UPC, ITF, Codabar, GS1 DataBar… The result card outlines the code in the frame.
- A list of the scans: the same code scanned again increments its counter.
- A result card with the scanned frame (pinch, double tap or mouse wheel to zoom, drag to pan) and **Copy**, **Share** and **Delete**.
- Android 15+ edge-to-edge: the content stays clear of the system bars.

## Requirements

- **RAD Studio 13 Florence** (Delphi 13).
- **Android 64-bit**: min SDK 24, target SDK 36. Win32 and Win64 build too (scanning from a file; the camera has not been tested on Windows).
- **[ZXing.Delphi](https://github.com/Spelt/ZXing.Delphi) 4.0** or later, included as a git submodule in `ThirdParty\ZXing.Delphi` (branch `4.0`). Version 3.x does not build: the app uses `IScanManager` and `ScanAsync`.
- **[TFrameStand](https://github.com/andrea-magni/TFrameStand)** installed in the IDE, `master` or a release after v.2.3 (see below). It is not part of this repository: the project finds it through the IDE library path.

## Building

Clone with the submodules, so that ZXing.Delphi lands in `ThirdParty\ZXing.Delphi`:

```
git clone --recurse-submodules https://github.com/andrea-magni/ScannerMApp.git
```

In a clone made without it, run `git submodule update --init`.

TFrameStand must be installed in RAD Studio, so that its `source` folder is in the library path of every platform you build (**Tools ▸ Options ▸ Language ▸ Delphi ▸ Library**):

- with the setup of the [latest release](https://github.com/andrea-magni/TFrameStand/releases/latest), or with TMS Smart Setup (`tms install andreamagni.tframestand`);
- or from a clone of `master`: open `packages\13Florence\FrameStand.groupproj`, install the design-time package and add the `source` folder to the library path.

The version matters: the app needs the interactive gestures of the frames registered with the hosting form ([#121](https://github.com/andrea-magni/TFrameStand/pull/121)), in `master` and in the releases after v.2.3. With v.2.3 the app builds and runs, but pinch and double-tap zoom on the scanned frame do nothing on Android.

To move ZXing.Delphi to the latest commit of its `4.0` branch: `git submodule update --remote ThirdParty/ZXing.Delphi`, then commit the new submodule commit.

Then open `ScannerMapp.dproj`, pick the platform and run.

For Android:
- In **Tools ▸ Options ▸ Deployment ▸ SDK Manager**, the Android SDK must have a JDK (the **Java** tab). Without it, the deployment stops because `java.exe` is not found.
- The app asks for the camera permission the first time you tap **Scan**; no storage permission is needed.

## Project structure

| Unit | Content |
|---|---|
| `Forms.Main` | Main form: header, bottom bar, permissions, safe area |
| `Data.Main` | Data module: camera, ZXing scanning, the in-memory table of the scans |
| `Frames.Scanning` | Camera preview, viewfinder, torch |
| `Frames.Data` | List of the scans |
| `Frames.ScanResult` | Result card: zoomable frame, value, Copy / Share / Delete |
| `Frames.Info` | About |
| `UI.Theme` | Palette, icons (Material Icons paths), pressed feedback |

## License

[Apache License 2.0](LICENSE).

## Related links

Embarcadero Delphi is a modern, powerful and effective language and development tool. Learn more about it at the following links:
- https://www.embarcadero.com/
- https://learndelphi.org/
