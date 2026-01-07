# Scripts

## convert_clip_to_coreml.py

Converts the OpenAI CLIP vision model to CoreML format for on-device inference.

### ⚠️ Python Version Requirement

**IMPORTANT**: This script requires Python 3.10, 3.11, or 3.12. It does NOT work with Python 3.14 due to PyTorch compatibility issues.

### Usage

#### Option 1: Using Python 3.11 (Recommended)

```bash
# Install Python 3.11 if not already installed
brew install python@3.11

# Install dependencies
python3.11 -m pip install coremltools transformers torch

# Run conversion
python3.11 scripts/convert_clip_to_coreml.py
```

#### Option 2: Using virtual environment

```bash
# Create virtual environment with compatible Python
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install coremltools transformers torch

# Run conversion
python scripts/convert_clip_to_coreml.py
```

### Requirements

- Python 3.10, 3.11, or 3.12 (NOT 3.14)
- coremltools
- transformers
- torch

### Output

- Creates `CLIPVision.mlpackage` in `DuplicatePhotos/Resources/`
- Model size: ~350MB
- Deployment target: iOS 17+

### Known Issues

- **Python 3.14**: PyTorch 2.9.1 has compatibility issues with Python 3.14's typing.Union implementation
- **Workaround**: Use `convert_clip_simple.py` to create a placeholder model for development

## convert_clip_simple.py

Creates a placeholder model structure when you can't run the full conversion.

### Usage

```bash
python3 scripts/convert_clip_simple.py
```

### What it does

- Creates a placeholder `CLIPVision.mlpackage` structure
- Allows the Xcode project to build
- DOES NOT create a functional model
- Use this for UI development and testing

### Notes

- The app will build and run with the placeholder
- Duplicate detection won't work correctly (returns random embeddings)
- Good for testing UI, navigation, and photo library access
- Replace with real model before production use
