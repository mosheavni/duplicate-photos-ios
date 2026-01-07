# Scripts

## convert_clip_to_coreml.py

Converts the OpenAI CLIP vision model to CoreML format for on-device inference.

### Usage

```bash
python3 scripts/convert_clip_to_coreml.py
```

### Requirements

- Python 3.8+
- coremltools
- transformers
- torch

### Output

- Creates `CLIPVision.mlpackage` in `DuplicatePhotos/Resources/`
- Model size: ~350MB
- Deployment target: iOS 17+

### Notes

- This script should be run before building the iOS app
- The output file is tracked by Git LFS
- Model extraction takes 512-dimensional embeddings from 224x224 RGB images
