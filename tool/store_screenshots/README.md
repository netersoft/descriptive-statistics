# Play Store screenshots

`store/screenshots/<lang>/` holds the 6 phone screenshots of the store listing, one set per
app language: 1080×1920 (9:16) 24-bit PNGs, a title over the app's blue gradient and a
light-theme capture in a phone frame.

## Feature graphic

`store/feature_graphic/<lang>.png` is the 1024×500 banner at the top of the listing: the
app's icon, name and a tagline next to two of the screenshots, cut out of
`store/screenshots/<lang>/`. Rebuild it after the screenshots:

```bash
python3 tool/store_screenshots/feature.py
```

Its icon, screens, names and taglines are under `feature` in `config.json`.

## Regenerate them

1. Start the shared emulator (`test-phone`, 1080×2400) and install a fresh build:

   ```bash
   flutter build apk --profile --flavor dev
   adb install -r build/app/outputs/flutter-apk/app-dev-profile.apk
   adb shell pm clear com.neteru.tixtat.dev
   ```

2. Light theme and a clean status bar (10:00, full battery and Wi-Fi, no notifications):

   ```bash
   adb shell cmd uimode night no
   adb shell settings put global sysui_demo_allowed 1
   adb shell am broadcast -a com.android.systemui.demo -e command enter
   adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 1000
   adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
   adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4 -e fully true
   adb shell am broadcast -a com.android.systemui.demo -e command network -e mobile hide
   adb shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false
   ```

3. In Gboard's settings (Text correction), turn off the suggestion strip and
   auto-correction: otherwise Gboard rewrites the words `adb` types (« mediana » becomes
   « Medina »). Turn them back on afterwards.

4. Open the app once, skip the intro, then capture each language and build the images:

   ```bash
   python3 tool/store_screenshots/capture.py /tmp/captures fr --fresh
   for lang in en de es pt; do python3 tool/store_screenshots/capture.py /tmp/captures $lang; done
   python3 tool/store_screenshots/compose.py /tmp/captures
   ```

   `--fresh` enters the discrete and continuous series; the app keeps them in memory, so the
   next languages reuse them (add `--fresh` again if the app was restarted).

5. Look at every image before uploading them, then exit demo mode
   (`adb shell am broadcast -a com.android.systemui.demo -e command exit`).

`config.json` holds the screen order, the titles in each language and the colors.
`capture.py` drives the app with `adb` taps at the positions of a 1080×2400 screen, and
finds the tables, headings and buttons it scrolls to from the captured pixels.
