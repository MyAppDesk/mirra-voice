#!/usr/bin/env bash
# Rebuild the trimmed, gzip-repackaged Mirra Voice pack from the upstream
# k2-fsa release. Output: kokoro-int8-multi-lang-v1_0.tar.gz (verify vs SHA256SUMS).
set -euo pipefail

UPSTREAM='https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kokoro-int8-multi-lang-v1_0.tar.bz2'
DIR='kokoro-int8-multi-lang-v1_0'
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "→ downloading upstream pack…"
curl -fsSL -o "$WORK/pack.tar.bz2" "$UPSTREAM"

echo "→ extracting…"
tar xjf "$WORK/pack.tar.bz2" -C "$WORK"
cd "$WORK/$DIR"

echo "→ trimming to Kokoro-supported languages…"
# Keep the espeak phoneme dict for every Kokoro voice language: en/es/fr/it/pt/hi/ja
# (Japanese phonemizes through espeak's ja_dict). Chinese (zh) uses the jieba dict/,
# lexicon-zh.txt and the *-zh.fst text normalizers instead of espeak, so those stay.
# Every other language's *_dict is dropped (ru_dict alone is 8.1 MB).
KEEP='en_dict es_dict fr_dict it_dict pt_dict hi_dict ja_dict'
for f in espeak-ng-data/*_dict; do
  case " $KEEP " in *" $(basename "$f") "*) ;; *) rm -f "$f";; esac
done

echo "→ gzip repackaging…"
# --format=ustar (no PAX headers) + COPYFILE_DISABLE (no AppleDouble ._* junk):
# the pure-Dart `archive` package (app-side) throws on PAX extended headers that
# macOS bsdtar emits by default. ustar decodes cleanly.
cd "$WORK"
COPYFILE_DISABLE=1 tar --format=ustar -czf pack.tar.gz "$DIR"

OUT="$(pwd -P)"; cd - >/dev/null
mv "$WORK/pack.tar.gz" "./$DIR.tar.gz"
echo "→ done: $DIR.tar.gz"
shasum -a 256 "$DIR.tar.gz"
