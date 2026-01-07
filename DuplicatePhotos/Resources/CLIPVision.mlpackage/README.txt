# CLIP Vision Model Placeholder

⚠️ This is a PLACEHOLDER model structure, not a functional CoreML model.

## How to create the real model:

1. Use Python 3.10, 3.11, or 3.12 (not 3.14):
   ```
   brew install python@3.11
   python3.11 -m pip install coremltools transformers torch
   python3.11 scripts/convert_clip_to_coreml.py
   ```

2. Or use a virtual environment:
   ```
   python3.11 -m venv venv
   source venv/bin/activate
   pip install coremltools transformers torch
   python scripts/convert_clip_to_coreml.py
   ```

## Why this placeholder exists:

Python 3.14 is too new for current PyTorch (2.9.1) and has compatibility
issues with the quantization modules. The conversion script requires
Python 3.10-3.12 for proper execution.

## Development without the real model:

The app is designed with a placeholder embedding service that returns
random embeddings. This allows you to:
- Build and run the app
- Test the UI and navigation
- Test the scanning pipeline
- Verify photo library access

The similarity detection won't work correctly without the real model,
but you can still develop and test the app structure.
