# import-photos.sh

A small, dependency-light bash script that copies RAW photo files from an SD
card or tethered camera into a date-sorted photo library — the same
`<year>/<YYYY-MM-DD>/` structure that Lightroom Classic (and most other
catalog tools) work with cleanly.

Built for a NAS-backed Lightroom workflow, but it works against any local
folder, external drive, or mounted network share.

## Why

Most camera import tools either:
- lock you into their own app (Lightroom's built-in importer is slow and
  duplicates previews), or
- dump everything into one flat folder with camera-generated filenames.

This script does one thing: reads the actual capture date from each file's
EXIF data and copies it into a clean, predictable folder structure — so your
existing Lightroom catalog (or any other tool) can just point at the new
date folders and add them.

## Features

- Reads true capture date from EXIF (`DateTimeOriginal`), not file
  modification time — so it's correct even for cards that have been
  reformatted, backed up, or copied around
- Copy-only — never touches or deletes the originals on the card
- Safe to re-run: files that already exist at the destination are skipped
- Configurable file extensions (works with any RAW format your camera
  produces, not just Fuji/Leica)
- No dependencies beyond `exiftool`, which most photographers already have

## Requirements

- macOS or Linux
- [`exiftool`](https://exiftool.org/)
  - macOS: `brew install exiftool`
  - Linux: `sudo apt install libimage-exiftool-perl`

## Usage

```bash
chmod +x import-photos.sh

# Import from an SD card mounted at /Volumes/NO_NAME into ./Photography
./import-photos.sh /Volumes/NO_NAME

# Import into a specific library location
DEST_BASE="/Volumes/Photos/Photography" ./import-photos.sh /Volumes/NO_NAME

# Only import specific RAW formats
EXTENSIONS="RAF DNG" ./import-photos.sh /Volumes/NO_NAME
```

### Options (environment variables)

| Variable     | Default                              | Description                                  |
|--------------|---------------------------------------|-----------------------------------------------|
| `DEST_BASE`  | `./Photography`                       | Root folder of your photo library             |
| `EXTENSIONS` | `RAF DNG CR2 CR3 NEF ARW ORF`         | Space-separated list of RAW extensions to import |

## Example output

```
Scanning /Volumes/NO_NAME for: RAF DNG CR2 CR3 NEF ARW ORF ...
Found 214 file(s). Sorting by capture date into /Volumes/Photos/Photography ...

  Copied: DSCF1234.RAF  ->  2026/2026-07-20/
  Copied: DSCF1235.RAF  ->  2026/2026-07-20/
  Skipped (already exists): L1000456.DNG  [2026/2026-07-19]
  ...

-------------------------------------
Import complete.
  Copied:  198
  Skipped: 14 (already existed at destination)
  Failed:  2 (no EXIF date or copy error)
-------------------------------------

Originals on /Volumes/NO_NAME were left untouched.
Next step: in Lightroom, use File > Add Photos to Catalog and point at the new date folder(s) above.
```

## Notes

- Files with no readable EXIF capture date (rare, but happens with some
  corrupted files or non-standard formats) are flagged as failed and left
  for manual review — nothing is silently dropped.
- The script does not touch Lightroom itself; after copying, use
  **File > Add Photos to Catalog** (not Import) so Lightroom doesn't try to
  re-copy files that are already in place.

## License

MIT — see [LICENSE](LICENSE).
