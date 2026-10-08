"""Captures the raw screens for the Play Store screenshots, in one language.

Drives the app with adb on the shared `test-phone` emulator (1080x2400),
already running the app in light theme with SystemUI demo mode on (see
README.md next to this file). Positions are those of that screen size.

    python3 tool/store_screenshots/capture.py <out_dir> <lang> [--fresh]

--fresh first enters the discrete and continuous series (after a restart).

Writes <out_dir>/<lang>/<screen>.png for the screens listed in config.json.
The calculators keep their discrete and continuous series across languages;
the qualitative series and the saved studies are re-entered in each one,
since their labels are words.
"""

import subprocess
import sys
import time
from io import BytesIO
from pathlib import Path

from PIL import Image

PACKAGE = 'com.neteru.tixtat.dev'

# Same order as the language picker in Settings.
LANGS = ['fr', 'en', 'de', 'es', 'pt']

# adb can only type ASCII, hence words without accents.
QUALITATIVE = {
    'fr': [('Voiture', 18), ('Bus', 12), ('Marche', 9), ('Moto', 7), ('Train', 4)],
    'en': [('Car', 18), ('Bus', 12), ('Walking', 9), ('Motorbike', 7), ('Train', 4)],
    'de': [('Auto', 18), ('Bus', 12), ('Fahrrad', 9), ('Motorrad', 7), ('Zug', 4)],
    'es': [('Coche', 18), ('Metro', 12), ('Bicicleta', 9), ('Moto', 7), ('Tren', 4)],
    'pt': [('Carro', 18), ('Autocarro', 12), ('Bicicleta', 9), ('Mota', 7), ('Comboio', 4)],
}
DISCRETE = [(0, 8), (1, 12), (2, 11), (3, 6), (4, 3)]
CONTINUOUS = [(150, 155, 4), (155, 160, 9), (160, 165, 15), (165, 170, 12), (170, 175, 7), (175, 180, 3)]
STUDIES = {  # discrete, continuous, qualitative
    'fr': ['Enfants par famille', 'Tailles en cm', 'Moyens de transport'],
    'en': ['Children per family', 'Heights in cm', 'Means of transport'],
    'de': ['Kinder pro Familie', 'Messwerte in cm', 'Verkehrsmittel'],
    'es': ['Hijos por familia', 'Estaturas en cm', 'Medios de transporte'],
    'pt': ['Filhos por casal', 'Alturas em cm', 'Meios de transporte'],
}
# A word of the median topic that no earlier topic contains, so the median
# is the first result. A single word: Gboard rewrites words (even with
# auto-correction off) once a space is typed after them.
MEDIAN_SEARCH = {'fr': 'partage', 'en': 'splits', 'de': 'untere', 'es': 'divide', 'pt': 'divide'}

# Drawer entries, top to bottom.
DRAWER = {'course': 650, 'discrete': 798, 'continuous': 944, 'qualitative': 1090, 'backups': 1238}
ROW_Y, ROW_STEP, ADD_Y = 690, 168, 824   # first entry row, row height, "add an entry" under row 1


def adb(*args):
    subprocess.run(['adb', 'shell', *map(str, args)], check=True, capture_output=True)


def tap(x, y, wait=0.6):
    adb('input', 'tap', x, y)
    time.sleep(wait)


def type_text(text):
    adb('input', 'text', text.replace(' ', '%s'))
    time.sleep(0.3)


def back(wait=0.6):
    adb('input', 'keyevent', 'KEYCODE_BACK')
    time.sleep(wait)


def swipe(y_from, y_to, ms=800):
    adb('input', 'swipe', 540, y_from, 540, y_to, ms)
    time.sleep(0.8)


def screen():
    return Image.open(BytesIO(subprocess.run(['adb', 'exec-out', 'screencap', '-p'], check=True, capture_output=True).stdout)).convert('RGB')


def scroll_top():
    for _ in range(14):
        adb('input', 'swipe', 540, 600, 540, 2000, 120)
    time.sleep(1.2)


def scroll_bottom():
    for _ in range(14):
        adb('input', 'swipe', 540, 2000, 540, 400, 120)
    time.sleep(1.2)


def open_tab(name):
    tap(72, 206, 1.2)        # drawer
    tap(300, DRAWER[name], 1.5)


def table_top(img):
    """Top border of the first statistical table: a long dark line."""
    for y in range(420, 2200):
        if all(sum(img.getpixel((x, y))) < 200 for x in range(200, 860, 30)):
            return y
    return None


def first_blue_heading(img):
    """First section heading of an explanation (pure blue text)."""
    for y in range(420, 2200):
        blue = sum(1 for x in range(30, 600, 2) if (p := img.getpixel((x, y)))[2] > 200 and p[0] < 40 and p[1] < 40)
        if blue > 10:
            return y
    return None


def dark_clusters(img, x0, x1, y0, y1, gap=4):
    """(top, bottom) of the groups of dark rows in a column band."""
    rows = [y for y in range(y0, y1) if any(sum(img.getpixel((x, y))) < 200 for x in range(x0, x1, 3))]
    groups = []
    for y in rows:
        if groups and y - groups[-1][1] <= gap:
            groups[-1][1] = y
        else:
            groups.append([y, y])
    return groups


def delete_icons(img):
    """Centres of the saved studies' delete icons, top to bottom: dark
    shapes about 46 px tall and 35 px wide, unlike the text above them."""
    icons = []
    for top, bottom in dark_clusters(img, 900, 925, 420, 2250, gap=20):
        xs = [x for x in range(860, 980) if any(sum(img.getpixel((x, y))) < 200 for y in range(top, bottom + 1))]
        if 40 <= bottom - top <= 55 and xs[-1] - xs[0] <= 45:
            icons.append((top + bottom) // 2)
    return icons


def dialog_confirm(img):
    """The dialog's right-hand button (yes): lowest text row of the dialog."""
    top, bottom = dark_clusters(img, 700, 820, 1000, 1700)[-1]
    return (top + bottom) // 2


def scroll_to(detect, target):
    """Scrolls until detect(screen()) is at target (within a few pixels)."""
    for _ in range(6):
        y = detect(screen())
        if y is None:
            swipe(1600, 900)
            continue
        delta = y - target
        if abs(delta) <= 6:
            return
        # Flutter only starts scrolling after the touch slop (~21 px measured
        # here), so add it, or small corrections would not move at all.
        step = max(-1000, min(1000, delta))
        step += 21 if step > 0 else -21
        swipe(1400, 1400 - step, 1500)
    raise RuntimeError(f'could not scroll to {target}')


def set_language(lang):
    tap(1016, 206, 1.5)                       # settings
    tap(540, 356, 1.2)                        # language
    tap(320, 1676 + 146 * LANGS.index(lang), 3)
    if sum(screen().getpixel((540, 600))) < 600:
        back(1)                               # already in that language: the list stays open
    tap(56, 206, 2)                           # back to the main screen


def fill_rows(rows):
    """Fills entry rows (the first one already exists), adding rows as needed."""
    columns = {2: (270, 680), 3: (210, 476, 744)}[len(rows[0])]
    for i, row in enumerate(rows):
        for x, value in zip(columns, row):
            tap(x, ROW_Y + ROW_STEP * i, 0.3)
            type_text(str(value))
        back()
        if i < len(rows) - 1:
            tap(300, ADD_Y + ROW_STEP * i, 0.8)


def action_row_top(img):
    """Top of the Save / Share / PDF buttons at the end of the results:
    the first dark outline found going up from above the navigation bar
    is their bottom edge, and they are 162 px tall."""
    y = next(y for y in range(2300, 1000, -1) if sum(img.getpixel((240, y))) < 360)
    return y - 162


def dialog_open(img):
    """A dialog dims the app bar behind it."""
    return sum(img.getpixel((540, 120))) < 120


def save_study(name):
    scroll_bottom()
    time.sleep(2)                             # let the previous snackbar go
    tap(200, action_row_top(screen()) + 81, 1.5)
    if not dialog_open(screen()):
        raise RuntimeError(f'the save dialog did not open for {name}')
    type_text(name)
    tap(720, 980, 2.5)


def enter_series():
    """Enters and calculates the discrete and continuous series (the
    calculators only keep them while the app runs)."""
    open_tab('discrete')
    scroll_top()
    tap(300, 656, 0.8)                        # "add an entry" with no rows
    fill_rows(DISCRETE)
    tap(540, 2010, 3)                         # calculate
    open_tab('continuous')
    scroll_top()
    tap(300, 656, 0.8)
    fill_rows(CONTINUOUS)
    tap(540, 2140, 3)


def bring_to_front():
    subprocess.run(['adb', 'shell', 'monkey', '-p', PACKAGE, '-c', 'android.intent.category.LAUNCHER', '1'], check=True, capture_output=True)
    time.sleep(3)


def capture(out, lang):
    out = Path(out) / lang
    out.mkdir(parents=True, exist_ok=True)
    bring_to_front()
    set_language(lang)

    # Discrete: table and bar chart (the series stays from the first language).
    open_tab('discrete')
    scroll_top()
    swipe(1800, 1000)
    scroll_to(table_top, 580)
    screen().save(out / 'table.png')

    # Continuous: the entry form, then the explanation from its first heading.
    open_tab('continuous')
    scroll_top()
    screen().save(out / 'cont_input.png')
    # Scroll down until the first heading (the means) comes into view.
    while first_blue_heading(screen()) is None:
        swipe(1900, 1200)
    scroll_to(first_blue_heading, 530)
    screen().save(out / 'explain.png')

    # Qualitative: replace the series with this language's words, then the pie.
    open_tab('qualitative')
    scroll_top()
    for _ in QUALITATIVE[lang]:
        tap(943, ROW_Y, 0.5)                  # remove the first row
    tap(300, 656, 0.8)                        # "add an entry" with no rows
    fill_rows(QUALITATIVE[lang])
    tap(540, 2010, 3)                         # calculate
    swipe(1800, 1000)
    scroll_to(table_top, 580)
    tap(974, 1528, 1.5)                       # next chart: the pie
    screen().save(out / 'pie.png')
    tap(104, 1528, 1)                         # back to the bar chart

    # Course: the median topic.
    open_tab('course')
    tap(974, 510, 0.5)                        # clear any earlier query
    tap(540, 510, 0.5)
    type_text(MEDIAN_SEARCH[lang])
    tap(300, 780, 2)
    img = screen()
    if sum(img.getpixel((540, 340))) < 300:   # still under the tab bar: no topic opened
        raise RuntimeError(f'the median topic did not open for {lang}')
    img.save(out / 'course.png')
    back(1)
    tap(974, 510, 0.5)                        # clear the search

    # Backups: one study per calculator, named in this language.
    open_tab('backups')
    while icons := delete_icons(screen()):
        tap(911, icons[0], 1)
        tap(760, dialog_confirm(screen()), 1.5)
    for tab, name in zip(['discrete', 'continuous', 'qualitative'], STUDIES[lang]):
        open_tab(tab)
        save_study(name)
    open_tab('backups')
    tap(400, delete_icons(screen())[2], 2)    # expand the third study
    screen().save(out / 'backups.png')


if __name__ == '__main__':
    if '--fresh' in sys.argv:
        bring_to_front()
        enter_series()
    capture(*[a for a in sys.argv[1:] if a != '--fresh'])
