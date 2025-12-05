"""
Convert to CoreML for iOS Deployment

This script converts compressed PyTorch models to CoreML format for iOS.
Supports iOS 15+ deployment.
"""

import torch
import coremltools as ct
from transformers import AutoModelForCausalLM, AutoTokenizer
from pathlib import Path
import json


class CoreMLConverter:
    """Convert models to CoreML format."""
    
    def __init__(self, language: str):
        self.language = language
        self.model_path = Path(f"models/{language}/final")
        self.output_path = Path(f"models/{language}/coreml")
        self.output_path.mkdir(parents=True, exist_ok=True)
    
    def convert(self):
        """Convert model to CoreML."""
        print(f"\n{'='*60}")
        print(f"Converting {self.language.upper()} model to CoreML")
        print(f"{'='*60}\n")
        
        if not self.model_path.exists():
            print(f"❌ Model not found at {self.model_path}")
            print(f"   Please train the model first:")
            print(f"   python train_model.py --language {self.language}")
            return
        
        print("Loading PyTorch model...")
        model = AutoModelForCausalLM.from_pretrained(str(self.model_path))
        tokenizer = AutoTokenizer.from_pretrained(str(self.model_path))
        
        print("Converting to CoreML...")
        print("⚠️  Note: This is a simplified conversion.")
        print("   For production, you need custom conversion logic")
        print("   based on your specific model architecture.\n")
        
        # For now, save model info for manual conversion
        model_info = {
            'language': self.language,
            'vocab_size': len(tokenizer.get_vocab()),
            'model_type': model.config.model_type,
            'hidden_size': model.config.hidden_size,
            'num_layers': model.config.num_hidden_layers,
            'status': 'ready_for_conversion',
            'notes': 'Use coremltools.convert() with proper input/output specs'
        }
        
        info_path = self.output_path / 'model_info.json'
        with open(info_path, 'w') as f:
            json.dump(model_info, f, indent=2)
        
        print(f"✅ Model info saved to: {info_path}")
        print(f"\nNext steps:")
        print(f"1. Define input/output specs for your model")
        print(f"2. Use coremltools.convert() with proper configuration")
        print(f"3. Test CoreML model on iOS device")
        print(f"4. Encrypt model before bundling")
        
        return model_info


def main():
    """Main conversion script."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Convert models to CoreML')
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
        converter = CoreMLConverter(lang)
        converter.convert()
    
    print(f"\n{'='*60}")
    print("CONVERSION INFO GENERATED")
    print(f"{'='*60}")
    print("\nFor actual CoreML conversion, you'll need to:")
    print("1. Define model input/output shapes")
    print("2. Create conversion script with coremltools")
    print("3. Test on iOS device")
    print("\nSee Apple's CoreML documentation for details.")


if __name__ == "__main__":
    main()
