# mirra-voice

The **Mirra Voice** pack: [Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) int8
neural TTS, running fully on-device in the Mirra app via
[sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx). This repo hosts a **trimmed,
gzip-repackaged** build of the upstream `kokoro-int8-multi-lang-v1_0` pack, optimized
for faster download and much faster on-device extraction.

## The asset

| | Upstream | This pack |
|---|---|---|
| File | `kokoro-int8-multi-lang-v1_0.tar.bz2` | `kokoro-int8-multi-lang-v1_0.tar.gz` |
| Size | 125.7 MB | **118.4 MB** |
| Compression | bzip2 | gzip |
| Extraction on device | slow (pure-Dart bzip2 decode) | **fast** (pure-Dart gzip decode) |

The archive expands to a single `kokoro-int8-multi-lang-v1_0/` directory (same name as
upstream), so nothing downstream needs to know the path changed.

Verify after download:

```sh
shasum -a 256 -c SHA256SUMS
```

## What was trimmed

The app ships every language Kokoro-82M can actually speak: **English, Spanish,
French, Italian, Portuguese (BR), Hindi, Japanese and Mandarin Chinese**. Only the
phoneme data for languages with no Kokoro voice was removed:

- `espeak-ng-data/*_dict` — compiled phoneme dicts for every language **except** the
  ones with a Kokoro voice: `en_dict`, `es_dict`, `fr_dict`, `it_dict`, `pt_dict`,
  `hi_dict`, `ja_dict` (Japanese phonemizes through espeak). `ru_dict` alone was 8.1 MB.

Kept whole: `model.int8.onnx` (109 MB, the hard floor), `voices.bin` (all 54 speakers —
the app selects by speaker id, so the binary is left intact), both English lexicons,
the Chinese pipeline (`dict/` jieba segmentation, `lexicon-zh.txt`, `*-zh.fst`
normalizers), `tokens.txt`, and the shared espeak-ng core.

## Reproducing

`./repackage.sh` downloads the upstream pack and rebuilds this asset byte-for-byte
(verify with `SHA256SUMS`).

## Using it in the app

Point the downloader at wherever this file is hosted and update the extension:

```dart
// app/lib/core/services/mirra_voice_service.dart
static const _packUrl = '<public URL of kokoro-int8-multi-lang-v1_0.tar.gz>';
// ...and in download(): the temp filename must end in .tar.gz, e.g.
final tarPath = '${root.path}/pack.tar.gz';
```

`extractFileToDisk` (package:archive) auto-detects gzip, so no extraction-code change
is needed beyond the `.tar.gz` filename.

## Hosting note

The asset is **>100 MB**, above GitHub's per-file commit limit, and Git LFS media URLs
aren't plain-`GET`-able. So the tarball ships as a **GitHub Release asset** (up to 2 GB,
direct download URL — exactly like the upstream k2-fsa pack), not in git. Rebuild it
locally with `./repackage.sh`. Latest:

    https://github.com/MyAppDesk/mirra-voice/releases/latest/download/kokoro-int8-multi-lang-v1_0.tar.gz

## License

Kokoro model and sherpa-onnx pack are Apache-2.0 — see `LICENSE.kokoro`. This repo only
repackages upstream artifacts; all model credit is upstream.
