"""Sample codes to try ScannerMApp: every kind of content the app opens, and several formats.

Writes the PNG files and README.md next to this script. Needs:
    pip install segno python-barcode pillow ppf.datamatrix aztec_code_generator pdf417gen
All the contents are fictitious (555-01xx phone numbers, example.com addresses).
"""
import io
import pathlib

import barcode
import pdf417gen
import segno
from aztec_code_generator import AztecCode
from barcode.writer import ImageWriter
from PIL import Image, ImageDraw
from ppf.datamatrix import DataMatrix

HERE = pathlib.Path(__file__).parent
CRLF = '\r\n'
SIZE = 900  # every image: a white square, the code in the middle


def square(img):
    img = img.convert('RGB')
    img.thumbnail((SIZE - 160, SIZE - 160), Image.NEAREST)
    canvas = Image.new('RGB', (SIZE, SIZE), 'white')
    canvas.paste(img, ((SIZE - img.width) // 2, (SIZE - img.height) // 2))
    return canvas


def qr(text, micro=False):
    buf = io.BytesIO()
    segno.make(text, micro=micro).save(buf, kind='png', scale=20, border=0)
    return square(Image.open(buf))


def linear(kind, text):
    buf = io.BytesIO()
    barcode.get(kind, text, writer=ImageWriter()).write(buf, {'module_height': 25, 'font_size': 10, 'quiet_zone': 6})
    return square(Image.open(buf))


def datamatrix(text):
    m = DataMatrix(text).matrix
    s = 24
    img = Image.new('1', (len(m[0]) * s, len(m) * s), 1)
    draw = ImageDraw.Draw(img)
    for y, row in enumerate(m):
        for x, v in enumerate(row):
            if v:
                draw.rectangle([x * s, y * s, x * s + s - 1, y * s + s - 1], fill=0)
    return square(img)


def aztec(text):
    return square(AztecCode(text).image(module_size=20, border=0))


def pdf417(text):
    return square(pdf417gen.render_image(pdf417gen.encode(text, columns=6), scale=4, ratio=3, padding=0))


VCARD = CRLF.join(['BEGIN:VCARD', 'VERSION:3.0', 'N:Rossi;Mario;;;', 'FN:Mario Rossi', 'ORG:Example Srl',
                   'TEL;TYPE=CELL:+1-202-555-0123', 'EMAIL:mario.rossi@example.com', 'URL:https://example.com',
                   'END:VCARD'])
EVENT = CRLF.join(['BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:-//ScannerMApp//Samples//EN', 'BEGIN:VEVENT',
                   'UID:scannermapp-sample-1@example.com', 'DTSTAMP:20261101T090000Z',
                   'DTSTART:20261120T170000Z', 'DTEND:20261120T183000Z', 'SUMMARY:Delphi meetup',
                   'LOCATION:Example Hall, Milan', 'DESCRIPTION:A sample event from ScannerMApp',
                   'END:VEVENT', 'END:VCALENDAR'])
VEVENT = CRLF.join(['BEGIN:VEVENT', 'SUMMARY:Coffee with Mario', 'DTSTART:20261121T080000Z',
                    'DTEND:20261121T083000Z', 'END:VEVENT'])

# file, title, what the app does, image
SAMPLES = [
    ('01-link', 'Link', '**Open**: the browser', lambda: qr('https://github.com/andrea-magni/ScannerMApp')),
    ('02-www', 'Link without scheme', '**Open**: the browser (`https://` added)', lambda: qr('www.example.com')),
    ('03-phone', 'Phone number', '**Call**: the dialer', lambda: qr('tel:+12025550123')),
    ('04-sms', 'Text message (SMSTO)', '**Message**: number and text ready', lambda: qr('SMSTO:+12025550123:Hello from ScannerMApp')),
    ('05-email', 'E-mail (mailto)', '**Email**: address, subject and text ready',
     lambda: qr('mailto:mario.rossi@example.com?subject=ScannerMApp&body=Hello%20from%20ScannerMApp')),
    ('06-matmsg', 'E-mail (MATMSG)', '**Email**: address, subject and text ready',
     lambda: qr('MATMSG:TO:mario.rossi@example.com;SUB:ScannerMApp;BODY:Hello from ScannerMApp;;')),
    ('07-geo', 'Place', '**Map**: the maps app (Milan cathedral)', lambda: qr('geo:45.4642,9.1900')),
    ('08-vcard', 'Contact (vCard)', '**Contact**: the contacts app (Android), the share sheet (iOS)', lambda: qr(VCARD)),
    ('09-mecard', 'Contact (MECARD)', '**Contact**: turned into a vCard',
     lambda: qr('MECARD:N:Rossi,Mario;TEL:+12025550123;EMAIL:mario.rossi@example.com;;')),
    ('10-event', 'Event (iCalendar)', '**Event**: the calendar app (Android), the share sheet (iOS)', lambda: qr(EVENT)),
    ('11-vevent', 'Event (VEVENT only)', '**Event**: wrapped in a VCALENDAR', lambda: qr(VEVENT)),
    ('12-text', 'Plain text', 'nothing to open: **Copy** and **Share**', lambda: qr('Hello from Delphi!')),
    ('13-ean13', 'EAN-13', 'a product barcode: **Copy** and **Share**', lambda: linear('ean13', '800123456789')),
    ('14-code128', 'Code 128', 'linear barcode', lambda: linear('code128', 'SCANNERMAPP-2026')),
    ('15-datamatrix', 'Data Matrix', '2D code', lambda: datamatrix('ScannerMApp: Data Matrix')),
    ('16-aztec', 'Aztec', '2D code', lambda: aztec('ScannerMApp: Aztec')),
    ('17-pdf417', 'PDF 417', 'stacked linear code', lambda: pdf417('ScannerMApp: PDF 417')),
    ('18-microqr', 'Micro QR', 'small QR code', lambda: qr('SCANNERMAPP', micro=True)),
]

if __name__ == '__main__':
    rows = []
    for name, title, action, make in SAMPLES:
        make().save(HERE / f'{name}.png')
        rows.append(f'| <img src="{name}.png" width="220" alt="{title}"> | **{title}**<br>{action} |')
    (HERE / 'README.md').write_text(
        '# Sample codes\n\n'
        'Codes to try ScannerMApp: every kind of content the app can open, and several formats. '
        'Show this page on another screen (or print it) and scan the codes, or save the images on the phone and pick them with **Gallery**. '
        'The contents are fictitious (555-01xx phone numbers, `example.com` addresses).\n\n'
        'Generated by `generate.py`.\n\n'
        '| Code | Content |\n|:---:|---|\n' + '\n'.join(rows) + '\n',
        encoding='utf-8', newline='\n')
    print(len(SAMPLES), 'samples')
