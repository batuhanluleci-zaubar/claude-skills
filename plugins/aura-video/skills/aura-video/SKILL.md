---
name: aura-video
description: "Pull the newest video recorded on the XREAL Aura (Android XR puck) over adb to this Mac and reveal it in Finder. Use when the user has just recorded on the Aura and wants that clip on the Mac. · v2026-11-26 19:13"
---

# Aura video: newest recording to this Mac

Use when the user recorded on the Aura and asks for "the last video", "bring it to the Mac", "open it in Finder".
This skill only copies. It never deletes or changes anything on the device.

## Steps

1. **Find the device.** `adb devices -l`. Prefer the USB serial (the line without `:5555`, product `axros`, model
   `Android_XR_Puck`). A `ip:5555` line is the same device over Wi-Fi; use it only if no USB line exists. No device:
   ask the user to connect the puck by USB and accept the debugging prompt. Do not guess a serial.

2. **Find the newest video.** The Aura's screen recorder writes `/storage/emulated/0/Movies/screen-YYYYMMDD-HHMMSS.mp4`.
   Android's toybox `find` has no `-printf`, so sort with `stat`:

   ```bash
   adb -s <serial> shell 'find /sdcard /storage/emulated/0 -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) 2>/dev/null | while read f; do echo "$(stat -c %Y "$f") $(stat -c %s "$f") $f"; done | sort -n | tail -8'
   ```

   Columns: mtime (epoch), bytes, path. The last line is the newest. Pick the newest `screen-*.mp4` unless the user
   names another file. Ignore tiny stray files such as `v2m.mp4` (~1 MB) unless they are the only candidate.

3. **Pull it to the Mac.**

   ```bash
   mkdir -p "$HOME/Downloads/aura" && adb -s <serial> pull <device path> "$HOME/Downloads/aura/"
   ```

   Check the result: the pulled byte count must equal the device's `stat -c %s` value. Do not pull every recording;
   one clip per request (100 to 700 MB each).

4. **Reveal it in Finder.** `open -R "$HOME/Downloads/aura/<file>.mp4"`.

5. **Report** the absolute path as a markdown link, for example
   `[/Users/<you>/Downloads/aura/screen-....mp4](/Users/<you>/Downloads/aura/screen-....mp4)`, and its size.

## Pitfalls

- Serial over Wi-Fi drops; if `pull` fails with "device offline", re-run `adb devices -l` and switch to the USB serial.
- `find -printf` does not exist on the device: a command using it prints nothing and looks like "no videos".
- Recordings may sit under `/sdcard/DCIM` or other folders; the search covers `/sdcard` and `/storage/emulated/0`.
- Never `rm` on the device as part of this skill; cleanup is a separate, confirmed request.
