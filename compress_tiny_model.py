"""
Simple Model Compression for iOS Keyboard

This script compresses tiny models for iOS deployment.
Optimized for keyboard extension use with minimal size.
"""

import torch
from pathlib import Path
import json
import sys

# Add current directory to path to import tiny_model
sys.path.insert(0, str(Path(__file__).parent))
from tiny_model import TinyKeyboardModel, TinyKeyboardConfig


def get_model_size_mb(model):
    """Get model size in MB."""
    param_size = sum(p.nelement() * p.element_size() for p in model.parameters())
    buffer_size = sum(b.nelement() * b.element_size() for b in model.buffers())
    return (param_size + buffer_size) / 1024 / 1024


def compress_tiny_model(language: str):
    """Compress tiny model for iOS."""
    
    print(f"\n{'='*60}")
    print(f"Compressing {language.upper()} tiny model for iOS")
    print(f"{'='*60}\n")
    
    # Check if model exists
    model_path = Path(f"models/{language}/tiny_final")
    if not model_path.exists():
        print(f"❌ Model not found at {model_path}")
        print(f"   Please train first: python train_tiny_model.py --language {language}")
        return None
    
    # Load model
    print("Loading model...")
    model = TinyKeyboardModel.from_pretrained(model_path)
    
    initial_size = get_model_size_mb(model)
    print(f"Initial size: {initial_size:.2f} MB")
    
    # Step 1: Convert to half precision (float16)
    print("\n1️⃣  Converting to half-precision (float16)...")
    model = model.half()
    half_size = get_model_size_mb(model)
    reduction1 = (1 - half_size / initial_size) * 100
    print(f"   Size: {half_size:.2f} MB ({reduction1:.1f}% reduction)")
    
    # Step 2: Save compressed model
    output_dir = Path(f"models/{language}/ios_ready")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"\n2️⃣  Saving iOS-ready model...")
    
    # Save model in half precision
    model.save_pretrained(output_dir)
    
    # Copy tokenizer
    import shutil
    tokenizer_src = model_path / "tokenizer.json"
    tokenizer_dst = output_dir / "tokenizer.json"
    shutil.copy(tokenizer_src, tokenizer_dst)
    
    # Save metadata
    metadata = {
        'language': language,
        'original_size_mb': initial_size,
        'compressed_size_mb': half_size,
        'reduction_percent': reduction1,
        'precision': 'float16',
        'ready_for_ios': True,
    }
    
    with open(output_dir / 'metadata.json', 'w') as f:
        json.dump(metadata, f, indent=2)
    
    print(f"   ✅ Saved to: {output_dir}")
    
    # Summary
    print(f"\n{'='*60}")
    print("COMPRESSION SUMMARY")
    print(f"{'='*60}")
    print(f"Original: {initial_size:.2f} MB")
    print(f"Compressed: {half_size:.2f} MB")
    print(f"Reduction: {reduction1:.1f}%")
    print(f"\n✅ Model ready for iOS CoreML conversion!")
    
    return metadata


def main():
    """Main compression script."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Compress tiny models for iOS')
    parser.add_argument(
        '--language',
        type=str,
        choices=['english', 'japanese', 'both'],
        default='both',
        help='Language to compress (default: both)'
    )
    
    args = parser.parse_args()
    
    languages = ['english', 'japanese'] if args.language == 'both' else [args.language]
    
    results = {}
    for lang in languages:
        result = compress_tiny_model(lang)
        if result:
            results[lang] = result
    
    if results:
        print(f"\n{'='*60}")
        print("ALL COMPRESSION COMPLETE")
        print(f"{'='*60}\n")
        
        for lang, meta in results.items():
            print(f"{lang.upper()}:")
            print(f"  Original: {meta['original_size_mb']:.2f} MB")
            print(f"  Compressed: {meta['compressed_size_mb']:.2f} MB")
            print(f"  Reduction: {meta['reduction_percent']:.1f}%")
            print()
        
        print("Next steps:")
        print("1. Models are ready in models/*/ios_ready/")
        print("2. Convert to CoreML: python convert_to_coreml.py")
        print("3. Add to iOS project")
        print("\n✅ Perfect size for iOS keyboard extension!")


if __name__ == "__main__":
    main()
