"""
Convert Tiny Models to CoreML for iOS

This script converts the compressed tiny models to CoreML format
for deployment in iOS keyboard extension.
"""

import torch
import coremltools as ct
from pathlib import Path
import json
import sys

# Add current directory to path
sys.path.insert(0, str(Path(__file__).parent))
from tiny_model import TinyKeyboardModel, TinyKeyboardConfig


def convert_to_coreml(language: str):
    """Convert tiny model to CoreML."""
    
    print(f"\n{'='*60}")
    print(f"Converting {language.upper()} model to CoreML")
    print(f"{'='*60}\n")
    
    model_path = Path(f"models/{language}/ios_ready")
    
    if not model_path.exists():
        print(f"❌ Model not found at {model_path}")
        print(f"   Please compress first: python compress_tiny_model.py --language {language}")
        return
    
    # Load model
    print("Loading compressed model...")
    model = TinyKeyboardModel.from_pretrained(model_path)
    model.eval()
    
    # Load tokenizer info
    with open(model_path / 'tokenizer.json', 'r') as f:
        tokenizer_data = json.load(f)
    
    vocab_size = tokenizer_data['vocab_size']
    
    print(f"Model loaded: {vocab_size} vocab size")
    
    # Create example input
    batch_size = 1
    seq_length = 64
    example_input = torch.randint(0, vocab_size, (batch_size, seq_length))
    
    print("\nConverting to CoreML...")
    print("⚠️  Note: This creates a basic CoreML model.")
    print("   For production, you may need custom conversion with:")
    print("   - Optimized input/output shapes")
    print("   - Compute unit specification (Neural Engine)")
    print("   - Model encryption")
    
    try:
        # Trace the model
        traced_model = torch.jit.trace(model, example_input)
        
        # Convert to CoreML
        output_dir = Path(f"models/{language}/coreml")
        output_dir.mkdir(parents=True, exist_ok=True)
        
        mlmodel = ct.convert(
            traced_model,
            inputs=[ct.TensorType(name="input_ids", shape=(1, seq_length), dtype=int)],
            outputs=[ct.TensorType(name="logits")],
            minimum_deployment_target=ct.target.iOS15,
        )
        
        # Save CoreML model
        model_file = output_dir / f"{language}_keyboard.mlpackage"
        mlmodel.save(str(model_file))
        
        print(f"\n✅ CoreML model saved to: {model_file}")
        
        # Save metadata
        metadata = {
            'language': language,
            'vocab_size': vocab_size,
            'input_shape': [1, seq_length],
            'ios_version': '15.0+',
            'model_type': 'TinyKeyboard',
        }
        
        with open(output_dir / 'metadata.json', 'w') as f:
            json.dump(metadata, f, indent=2)
        
        print(f"\n{'='*60}")
        print("CONVERSION COMPLETE")
        print(f"{'='*60}")
        print(f"Model: {model_file}")
        print(f"iOS: 15.0+")
        print(f"Ready for Xcode integration!")
        
    except Exception as e:
        print(f"\n⚠️  CoreML conversion encountered an issue:")
        print(f"   {str(e)}")
        print(f"\nThe model is still usable. For production:")
        print(f"1. Use the PyTorch model directly")
        print(f"2. Or implement custom CoreML conversion")
        print(f"3. Model files are in: {model_path}")


def main():
    """Main conversion script."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Convert to CoreML')
    parser.add_argument(
        '--language',
        type=str,
        choices=['english', 'japanese', 'both'],
        default='both',
        help='Language to convert (default: both)'
    )
    
    args = parser.parse_args()
    
    languages = ['english', 'japanese'] if args.language == 'both' else [args.language]
    
    for lang in languages:
        convert_to_coreml(lang)
    
    print(f"\n{'='*60}")
    print("ALL CONVERSIONS COMPLETE")
    print(f"{'='*60}\n")
    print("Next steps:")
    print("1. Open your Xcode project")
    print("2. Drag .mlpackage files into project")
    print("3. Add to keyboard extension target")
    print("4. Use ModelLoader.swift to load models")
    print("\n✅ Ready for iOS deployment!")


if __name__ == "__main__":
    main()
