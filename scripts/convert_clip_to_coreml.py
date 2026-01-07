#!/usr/bin/env python3
"""
Convert CLIP Vision Model to CoreML format

This script converts the OpenAI CLIP vision transformer to CoreML format
for on-device inference on iOS.

Requirements:
- coremltools
- transformers
- torch
"""

import coremltools as ct
import torch
import torch.nn as nn
from transformers import CLIPVisionModel, CLIPProcessor
import os


class CLIPVisionWrapper(nn.Module):
    """Wrapper to extract pooler_output from CLIP vision model"""
    def __init__(self, clip_model):
        super().__init__()
        self.model = clip_model

    def forward(self, pixel_values):
        outputs = self.model(pixel_values)
        # Extract just the pooler_output (512-dim embedding)
        return outputs.pooler_output


def convert_clip_vision_to_coreml(output_path="./DuplicatePhotos/Resources"):
    """
    Convert CLIP vision model to CoreML format

    Args:
        output_path: Directory to save the .mlmodel file
    """
    print("🚀 Starting CLIP to CoreML conversion...")

    # 1. Load pretrained CLIP vision model
    print("📥 Loading CLIP vision model...")
    model_name = "openai/clip-vit-base-patch32"
    clip_model = CLIPVisionModel.from_pretrained(model_name)
    processor = CLIPProcessor.from_pretrained(model_name)

    # Wrap the model to extract just the pooler_output
    model = CLIPVisionWrapper(clip_model)

    # Set model to evaluation mode
    model.eval()

    print(f"✅ Loaded {model_name}")

    # 2. Create example input (224x224x3 image)
    print("🎨 Creating example input...")
    example_input = torch.randn(1, 3, 224, 224)

    # 3. Trace the model
    print("🔍 Tracing model...")
    with torch.no_grad():
        traced_model = torch.jit.trace(model, example_input)

    print("✅ Model traced successfully")

    # 4. Convert to CoreML
    print("⚙️  Converting to CoreML...")

    mlmodel = ct.convert(
        traced_model,
        inputs=[
            ct.ImageType(
                name="image",
                shape=example_input.shape,
                scale=1.0 / 255.0,  # Normalize pixel values to [0, 1]
                bias=[0, 0, 0],
            )
        ],
        outputs=[ct.TensorType(name="embedding")],
        convert_to="mlprogram",  # Use ML Program format for iOS 17+
        minimum_deployment_target=ct.target.iOS17,
    )

    # 5. Add metadata
    mlmodel.author = "OpenAI (converted by Claude Code)"
    mlmodel.short_description = "CLIP Vision Transformer for image embeddings"
    mlmodel.version = "1.0"

    # Set feature descriptions
    mlmodel.input_description["image"] = "Input image (224x224 RGB)"
    mlmodel.output_description["embedding"] = "512-dimensional image embedding vector"

    print("✅ CoreML conversion successful")

    # 6. Save the model
    os.makedirs(output_path, exist_ok=True)
    output_file = os.path.join(output_path, "CLIPVision.mlpackage")

    print(f"💾 Saving model to {output_file}...")
    mlmodel.save(output_file)

    # Get file size
    file_size_mb = sum(
        os.path.getsize(os.path.join(dirpath, filename))
        for dirpath, dirnames, filenames in os.walk(output_file)
        for filename in filenames
    ) / (1024 * 1024)

    print(f"✅ Model saved successfully!")
    print(f"📊 Model size: {file_size_mb:.2f} MB")
    print(f"📍 Location: {output_file}")

    print("\n🎉 Conversion complete!")
    print("\n📝 Next steps:")
    print("1. Open DuplicatePhotos.xcodeproj in Xcode")
    print("2. Add the .mlpackage file to the project if not already included")
    print("3. Build and run the app")

    return output_file


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Convert CLIP model to CoreML")
    parser.add_argument(
        "--output",
        type=str,
        default="./DuplicatePhotos/Resources",
        help="Output directory for .mlmodel file",
    )

    args = parser.parse_args()

    try:
        convert_clip_vision_to_coreml(args.output)
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback

        traceback.print_exc()
        exit(1)
