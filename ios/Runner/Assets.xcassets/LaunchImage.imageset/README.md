# LaunchImage

Cold-start splash asset for `LaunchScreen.storyboard`.

Source: `assets/branding/app_icon.png` at 96pt (1x / 2x / 3x).
Regenerate with:

```bash
SRC=assets/branding/app_icon.png
OUT=ios/Runner/Assets.xcassets/LaunchImage.imageset
sips -z 96 96 "$SRC" --out "$OUT/LaunchImage.png"
sips -z 192 192 "$SRC" --out "$OUT/LaunchImage@2x.png"
sips -z 288 288 "$SRC" --out "$OUT/LaunchImage@3x.png"
```
