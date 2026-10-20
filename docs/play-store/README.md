# Google Play Store

What is needed to publish ScannerMApp on Google Play: the store listing (in English and Italian), the graphics, the answers to the Play Console forms and how to build the bundle.

Package: `eu.andreamagni.ScannerMapp` (it cannot change after the first release).

## Store listing

### English (en-US)

**App name** (30 characters at most)

```
ScannerMApp: QR & Barcodes
```

**Short description** (80 characters at most)

```
Scan QR codes and barcodes from the camera or your photos. No ads, no tracking.
```

**Full description** (4000 characters at most)

```
ScannerMApp reads QR codes and barcodes, from the camera or from your pictures, and keeps a list of what you scanned.

SCAN
• Live scanning from the camera, with a viewfinder and the torch. Decoding runs in the background, so the preview stays smooth.
• A code found but not readable yet? The app tells you: hold the phone still, or move closer.
• Scan a picture from your gallery: every code in it is read.
• Share pictures with ScannerMApp from Gallery, Photos or a chat, one or many, or open a picture with it: the codes are read right away.

EVERY FORMAT
QR code, Micro QR, Data Matrix, Aztec, PDF 417, MaxiCode, Code 39, Code 93, Code 128, EAN-8, EAN-13, UPC-A, UPC-E, ITF, Codabar, GS1 DataBar and more. Choose the formats you need: fewer formats make scanning faster and save battery.

OPEN WHAT A CODE CONTAINS
• Links in the browser
• Phone numbers in the dialer
• E-mails and text messages, ready to send
• Places in your maps app
• Contacts (vCard, MECARD) and events (iCalendar), ready to add
Only these kinds of content can be opened, and only when you tap Open: a code never makes the app launch anything else. Everything else can be copied or shared.

YOUR SCANS
• The list of your scans is kept on your device; scanning the same code again increments its counter.
• Each scan keeps the frame in which it was read: zoom it with a pinch or a double tap.
• Copy, share or delete a scan.

PRIVATE BY DESIGN
No account, no ads, no analytics, no tracking. ScannerMApp does not even have the permission to access the internet: your scans stay on your device. The only permission it asks for is the camera, the first time you scan.

OPEN SOURCE
ScannerMApp is open source (Apache License 2.0), built with Delphi and FireMonkey, ZXing.Delphi and TFrameStand: https://github.com/andrea-magni/ScannerMApp
```

### Italiano (it-IT)

**Nome dell'app** (30 caratteri al massimo)

```
ScannerMApp: QR e codici
```

**Descrizione breve** (80 caratteri al massimo)

```
Leggi QR code e codici a barre dalla fotocamera o dalle foto. Niente pubblicità.
```

**Descrizione completa** (4000 caratteri al massimo)

```
ScannerMApp legge QR code e codici a barre, dalla fotocamera o dalle tue foto, e tiene l'elenco di quello che hai scansionato.

SCANSIONA
• Scansione dal vivo con la fotocamera, con mirino e torcia. La decodifica avviene in background, così l'anteprima resta fluida.
• Un codice trovato ma non ancora leggibile? L'app te lo dice: tieni fermo il telefono, o avvicinati.
• Scansiona una foto della galleria: vengono letti tutti i codici che contiene.
• Condividi con ScannerMApp una o più immagini da Galleria, Foto o da una chat, oppure apri un'immagine con ScannerMApp: i codici vengono letti subito.

TUTTI I FORMATI
QR code, Micro QR, Data Matrix, Aztec, PDF 417, MaxiCode, Code 39, Code 93, Code 128, EAN-8, EAN-13, UPC-A, UPC-E, ITF, Codabar, GS1 DataBar e altri. Scegli i formati che ti servono: meno formati rendono la scansione più veloce e consumano meno batteria.

APRI IL CONTENUTO DI UN CODICE
• Link nel browser
• Numeri di telefono nel tastierino
• E-mail e SMS pronti da inviare
• Luoghi nell'app delle mappe
• Contatti (vCard, MECARD) ed eventi (iCalendar) pronti da aggiungere
Si possono aprire solo questi tipi di contenuto, e solo quando tocchi Apri: un codice non fa mai avviare altro all'app. Tutto il resto si può copiare o condividere.

LE TUE SCANSIONI
• L'elenco delle scansioni resta sul tuo dispositivo; se scansioni di nuovo lo stesso codice, aumenta il suo contatore.
• Ogni scansione conserva l'immagine in cui il codice è stato letto: ingrandiscila con due dita o con un doppio tocco.
• Copia, condividi o elimina una scansione.

PRIVACY PRIMA DI TUTTO
Nessun account, nessuna pubblicità, nessuna statistica, nessun tracciamento. ScannerMApp non ha nemmeno il permesso di accedere a internet: le tue scansioni restano sul tuo dispositivo. L'unico permesso che chiede è la fotocamera, la prima volta che scansioni.

OPEN SOURCE
ScannerMApp è open source (licenza Apache 2.0), sviluppata con Delphi e FireMonkey, ZXing.Delphi e TFrameStand: https://github.com/andrea-magni/ScannerMApp
```

## Graphics

| Asset | Size | File |
|---|---|---|
| App icon | 512×512 PNG | `Icons/Android/ic_launcher_512.png` |
| Feature graphic | 1024×500 PNG | `docs/play-store/feature-graphic.png` (from `feature-graphic.html`) |
| Phone screenshots | 1080×1920 PNG, 5 per language | `docs/play-store/screenshots/en-1.png` … `en-5.png` and `it-1.png` … `it-5.png` (from the `.html` next to them, with the captures of a phone in `screenshots/phone`) |

## Play Console forms

- **Privacy policy**: https://github.com/andrea-magni/ScannerMApp/blob/master/PRIVACY.md
- **App access**: all functionality is available without special access.
- **Ads**: no, the app does not contain ads.
- **Content rating** (IARC questionnaire): category "Utility, Productivity, Communication, or Other"; no violence, sexual content, profanity, drugs or gambling; users cannot interact or share content with each other, no location sharing, no purchases. Expected rating: everyone (PEGI 3).
- **Target audience**: 13 and over (the app is not designed for children).
- **Data safety**: the app does not collect or share any user data (no data type selected). Data is not encrypted in transit because nothing is transmitted.
- **Advertising ID**: no, the app does not use it.
- **Government app / financial features / health**: no.
- **Category**: Tools.

## Building the bundle

The **Release** configuration of **Android 64-bit** is an **Application Store** build: it produces `ScannerMapp.aab` (arm64-v8a only) in `C:\Android64\Release\ScannerMapp\ScannerMapp\bin`.

1. Create the upload keystore once, and keep it (and its passwords) safe: without it you cannot upload updates (with Play App Signing, Google can reset the upload key, but it takes time).

   ```
   keytool -genkeypair -v -keystore scannermapp-upload.keystore -alias upload -keyalg RSA -keysize 2048 -validity 10000
   ```

2. In RAD Studio, **Project ▸ Options ▸ Application ▸ Provisioning**, target **All configurations - Android 64-bit platform**, build type **Android 64-bit - Application Store**: the keystore file, its password, the alias and its password. They are saved encrypted in the user settings of the IDE, not in the repository.
3. **Project ▸ Options ▸ Application ▸ Version Info**: increment `versionCode` for every upload (and `versionName` when it makes sense).
4. Select **Release**, **Android 64-bit**, then **Project ▸ Deploy**.
5. In the Play Console, accept **Play App Signing** (Google keeps the app signing key, you keep the upload key) and upload the `.aab` to a testing track first (internal testing), then to production.
