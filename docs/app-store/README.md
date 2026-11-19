# Apple App Store

What is needed to publish ScannerMApp on the App Store (iPhone and iPad): the listing (in English and Italian), the answers to the App Store Connect forms and how to build and upload the app.

Bundle ID: `eu.andreamagni.ScannerMapp`. Version 2.0.0 (`CFBundleShortVersionString`), build 1 (`CFBundleVersion`: increment it for every upload).

## App information

| Field | Value |
|---|---|
| Name (30) | `ScannerMApp: QR & Barcodes` |
| Subtitle (30) | `Every format. No tracking.` |
| Primary category | Utilities |
| Secondary category | Productivity |
| Content rights | Does not contain, show or access third-party content |
| Age rating | None of the content in the questionnaire: 4+ |
| Price | Free, all countries |
| Copyright | `2026 Andrea Magni` |
| Support URL | https://github.com/andrea-magni/ScannerMApp/issues |
| Marketing URL | https://github.com/andrea-magni/ScannerMApp |
| Privacy Policy URL | https://github.com/andrea-magni/ScannerMApp/blob/master/PRIVACY.md |

## Listing

### English (U.S.)

**Promotional text** (170 characters at most, can change without a new version)

```
Scan QR codes and barcodes from the camera or your photos, in every format. Open links, contacts and events. No ads, no account, no tracking.
```

**Description** (4000 characters at most)

```
ScannerMApp reads QR codes and barcodes, from the camera or from your photos, and keeps a list of what you scanned.

SCAN
• Live scanning from the camera, with a viewfinder and the torch. Decoding runs in the background, so the preview stays smooth.
• A code found but not readable yet? The app tells you: hold the phone still, or move closer.
• Scan a photo from your library: every code in it is read.

EVERY FORMAT
QR code, Micro QR, Data Matrix, Aztec, PDF 417, MaxiCode, Code 39, Code 93, Code 128, EAN-8, EAN-13, UPC-A, UPC-E, ITF, Codabar, GS1 DataBar and more. Choose the formats you need: fewer formats make scanning faster and save battery.

OPEN WHAT A CODE CONTAINS
• Links in Safari
• Phone numbers, ready to call
• E-mails and text messages, ready to send
• Places in Maps
• Contacts (vCard, MECARD) and events (iCalendar), to add from the share sheet
Only these kinds of content can be opened, and only when you tap the button: a code never makes the app launch anything else. Everything else can be copied or shared.

YOUR SCANS
• The list of your scans is kept on your device; scanning the same code again increments its counter.
• Each scan keeps the frame in which it was read: zoom it with a pinch or a double tap.
• Copy, share or delete a scan.

PRIVATE BY DESIGN
No account, no ads, no analytics, no tracking. ScannerMApp does not connect to the internet: your scans stay on your device. The only permission it asks for is the camera, the first time you scan.

OPEN SOURCE
ScannerMApp is open source (Apache License 2.0), built with Delphi and FireMonkey, ZXing.Delphi and TFrameStand: https://github.com/andrea-magni/ScannerMApp
```

**Keywords** (100 characters at most, comma separated, without the words of the name)

```
reader,scan,ean,upc,isbn,datamatrix,aztec,pdf417,code128,vcard,camera,privacy,offline,open source
```

**What's New in This Version** (first version: not asked)

### Italiano

**Nome** `ScannerMApp: QR e codici` · **Sottotitolo** `Ogni formato, nessuna traccia`

**Testo promozionale**

```
Leggi QR code e codici a barre dalla fotocamera o dalle foto, in ogni formato. Apri link, contatti ed eventi. Niente pubblicità, account o tracciamento.
```

**Descrizione**

```
ScannerMApp legge QR code e codici a barre, dalla fotocamera o dalle tue foto, e tiene l'elenco di quello che hai scansionato.

SCANSIONA
• Scansione dal vivo con la fotocamera, con mirino e torcia. La decodifica avviene in background, così l'anteprima resta fluida.
• Un codice trovato ma non ancora leggibile? L'app te lo dice: tieni fermo il telefono, o avvicinati.
• Scansiona una foto della libreria: vengono letti tutti i codici che contiene.

TUTTI I FORMATI
QR code, Micro QR, Data Matrix, Aztec, PDF 417, MaxiCode, Code 39, Code 93, Code 128, EAN-8, EAN-13, UPC-A, UPC-E, ITF, Codabar, GS1 DataBar e altri. Scegli i formati che ti servono: meno formati rendono la scansione più veloce e consumano meno batteria.

APRI IL CONTENUTO DI UN CODICE
• Link in Safari
• Numeri di telefono, pronti da chiamare
• E-mail e SMS pronti da inviare
• Luoghi in Mappe
• Contatti (vCard, MECARD) ed eventi (iCalendar), da aggiungere dal pannello di condivisione
Si possono aprire solo questi tipi di contenuto, e solo quando tocchi il pulsante: un codice non fa mai avviare altro all'app. Tutto il resto si può copiare o condividere.

LE TUE SCANSIONI
• L'elenco delle scansioni resta sul tuo dispositivo; se scansioni di nuovo lo stesso codice, aumenta il suo contatore.
• Ogni scansione conserva l'immagine in cui il codice è stato letto: ingrandiscila con due dita o con un doppio tocco.
• Copia, condividi o elimina una scansione.

PRIVACY PRIMA DI TUTTO
Nessun account, nessuna pubblicità, nessuna statistica, nessun tracciamento. ScannerMApp non si collega a internet: le tue scansioni restano sul tuo dispositivo. L'unico permesso che chiede è la fotocamera, la prima volta che scansioni.

OPEN SOURCE
ScannerMApp è open source (licenza Apache 2.0), sviluppata con Delphi e FireMonkey, ZXing.Delphi e TFrameStand: https://github.com/andrea-magni/ScannerMApp
```

**Parole chiave**

```
lettore,scansione,ean,upc,isbn,datamatrix,aztec,pdf417,code128,vcard,fotocamera,privacy,open source
```

## Screenshots

| Device | Size (portrait) | Count |
|---|---|---|
| iPhone 6.9" | 1320×2868 (or 1290×2796) | 3 to 10 |
| iPad 13" | 2064×2752 (or 2048×2732) | 3 to 10 |

Taken on the devices (list, a link, a contact, the formats, About), then framed with a caption like the Google Play ones (`docs/play-store/screenshots`).

## App Store Connect forms

- **App Privacy**: Privacy Policy URL above; "Do you or your third-party partners collect data from this app?" **No** (Data Not Collected).
- **Export compliance**: not asked, `ITSAppUsesNonExemptEncryption` is `false` in the Info.plist.
- **Privacy manifest**: `PrivacyInfo.xcprivacy` (deployed in the app bundle): no tracking, no data collected, the reasons for the required-reason APIs of the Delphi runtime.
- **App Review Information**: sign-in not required. Notes: *No account is needed. Tap Scan and point the camera at a QR code or a barcode, or tap Gallery and pick a photo with a code. Tap a scan to see it; the green button opens its content (link, phone number, e-mail, place, contact, event).*
- **Version release**: automatic, or manual if you want to choose the day.

## Building and uploading

1. RAD Studio, **Project ▸ Options ▸ Application ▸ Provisioning**, iOS Device 64-bit, build type **Application Store**: the distribution certificate and the App Store provisioning profile of `eu.andreamagni.ScannerMapp` (they hold no secrets: the keys stay in the keychain of the Mac).
2. Project Manager ▸ iOS Device 64-bit ▸ **Target Configurations**: **Release** ▸ **Application Store**.
3. Select **Release**, **iOS Device 64-bit**, then **Project ▸ Deploy**: PAServer builds the `.ipa` on the Mac.
4. Upload the `.ipa` with **Transporter** (Mac App Store) or `xcrun altool`; it shows up in App Store Connect ▸ TestFlight after the processing.
5. Try it with **TestFlight**, then add the build to the version and **Submit for Review**.
