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
| Size | 125.7 MB | **112.6 MB** |
| Compression | bzip2 | gzip |
| Extraction on device | slow (pure-Dart bzip2 decode) | **fast** (pure-Dart gzip decode) |

The archive expands to a single `kokoro-int8-multi-lang-v1_0/` directory (same name as
upstream), so nothing downstream needs to know the path changed.

Verify after download:

```sh
shasum -a 256 -c SHA256SUMS
```

## What was trimmed

The Mirra app only speaks **English** and **Spanish**. Everything specific to other
languages was removed — the model weights, all speaker embeddings, and English/Spanish
phonemization are untouched:

- `dict/` — Chinese (jieba) word-segmentation dictionaries (~14 MB)
- `lexicon-zh.txt` — Chinese lexicon (~2.3 MB)
- `*-zh.fst` — Chinese text-normalization FSTs
- `espeak-ng-data/*_dict` — compiled phoneme dicts for every language **except**
  `en_dict` and `es_dict` (~17 MB, e.g. `ru_dict` alone was 8.5 MB)

Kept whole: `model.int8.onnx` (114 MB, the hard floor), `voices.bin` (all speakers —
Mirra selects by speaker id, so the binary is left intact), both English lexicons,
`tokens.txt`, and the shared espeak-ng core.

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
