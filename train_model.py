"""
Model Training Script for LLM Keyboard

This script trains lightweight transformer models for English and Japanese
text prediction, optimized for iOS deployment.

Note: This is a starter implementation. For production, you'll need:
1. Larger training datasets (thousands of examples)
2. More sophisticated model architectures
3. Longer training times
4. GPU acceleration
"""

import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
from transformers import (
    AutoTokenizer,
    AutoModelForCausalLM,
    TrainingArguments,
    Trainer,
    DataCollatorForLanguageModeling,
)
from pathlib import Path
from typing import List, Dict
import json

from data_loader import TrainingDataLoader


class TextDataset(Dataset):
    """Simple dataset for text sequences."""
    
    def __init__(self, texts: List[str], tokenizer, max_length: int = 128):
        self.encodings = tokenizer(
            texts,
            truncation=True,
            padding='max_length',
            max_length=max_length,
            return_tensors='pt'
        )
    
    def __len__(self):
        return len(self.encodings.input_ids)
    
    def __getitem__(self, idx):
        return {
            'input_ids': self.encodings.input_ids[idx],
            'attention_mask': self.encodings.attention_mask[idx],
        }


class ModelTrainer:
    """Train language models for keyboard prediction."""
    
    def __init__(self, language: str, output_dir: str = "models"):
        """
        Initialize the trainer.
        
        Args:
            language: 'english' or 'japanese'
            output_dir: Directory to save trained models
        """
        self.language = language
        self.output_dir = Path(output_dir) / language
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Model configuration based on language
        self.config = self._get_model_config()
        
    def _get_model_config(self) -> Dict:
        """Get model configuration for the language."""
        if self.language == 'english':
            return {
                'model_name': 'distilgpt2',  # Small base model
                'vocab_size': 16000,
                'max_length': 128,
                'num_train_epochs': 10,
                'batch_size': 4,
                'learning_rate': 5e-5,
            }
        elif self.language == 'japanese':
            return {
                'model_name': 'rinna/japanese-gpt2-small',  # Japanese base model
                'vocab_size': 32000,
                'max_length': 128,
                'num_train_epochs': 10,
                'batch_size': 4,
                'learning_rate': 5e-5,
            }
        else:
            raise ValueError(f"Unsupported language: {self.language}")
    
    def train(self):
        """Train the model."""
        print(f"\n{'='*60}")
        print(f"Training {self.language.upper()} model")
        print(f"{'='*60}\n")
        
        # Load data
        print("Loading training data...")
        loader = TrainingDataLoader()
        train_texts, val_texts = loader.get_train_val_split(self.language)
        
        if len(train_texts) < 10:
            print(f"⚠️  Warning: Only {len(train_texts)} training examples.")
            print("   For production, you need thousands of examples!")
            print("   This model will have limited accuracy.\n")
        
        # Load tokenizer and model
        print(f"Loading base model: {self.config['model_name']}...")
        try:
            tokenizer = AutoTokenizer.from_pretrained(self.config['model_name'])
            model = AutoModelForCausalLM.from_pretrained(self.config['model_name'])
        except Exception as e:
            print(f"Error loading model: {e}")
            print("Using GPT2 as fallback...")
            tokenizer = AutoTokenizer.from_pretrained('gpt2')
            model = AutoModelForCausalLM.from_pretrained('gpt2')
        
        # Set pad token if not exists
        if tokenizer.pad_token is None:
            tokenizer.pad_token = tokenizer.eos_token
        
        # Create datasets
        print("Preparing datasets...")
        train_dataset = TextDataset(
            train_texts, 
            tokenizer, 
            max_length=self.config['max_length']
        )
        val_dataset = TextDataset(
            val_texts, 
            tokenizer, 
            max_length=self.config['max_length']
        )
        
        # Training arguments
        training_args = TrainingArguments(
            output_dir=str(self.output_dir),
            num_train_epochs=self.config['num_train_epochs'],
            per_device_train_batch_size=self.config['batch_size'],
            per_device_eval_batch_size=self.config['batch_size'],
            learning_rate=self.config['learning_rate'],
            warmup_steps=100,
            weight_decay=0.01,
            logging_dir=str(self.output_dir / 'logs'),
            logging_steps=10,
            eval_strategy="epoch",
            save_strategy="epoch",
            load_best_model_at_end=True,
            push_to_hub=False,
        )
        
        # Data collator
        data_collator = DataCollatorForLanguageModeling(
            tokenizer=tokenizer,
            mlm=False,  # Causal LM, not masked LM
        )
        
        # Initialize trainer
        trainer = Trainer(
            model=model,
            args=training_args,
            train_dataset=train_dataset,
            eval_dataset=val_dataset,
            data_collator=data_collator,
        )
        
        # Train
        print("\nStarting training...")
        print("(This may take a while depending on your hardware)\n")
        trainer.train()
        
        # Save final model
        print("\nSaving model...")
        final_model_path = self.output_dir / 'final'
        trainer.save_model(str(final_model_path))
        tokenizer.save_pretrained(str(final_model_path))
        
        # Save config
        config_path = self.output_dir / 'config.json'
        with open(config_path, 'w') as f:
            json.dump(self.config, f, indent=2)
        
        print(f"\n✅ Training complete!")
        print(f"   Model saved to: {final_model_path}")
        
        return trainer, tokenizer
    
    def test_predictions(self, tokenizer, model=None):
        """Test the trained model with sample predictions."""
        if model is None:
            model_path = self.output_dir / 'final'
            model = AutoModelForCausalLM.from_pretrained(str(model_path))
        
        print(f"\n{'='*60}")
        print(f"Testing {self.language.upper()} model predictions")
        print(f"{'='*60}\n")
        
        # Sample prompts
        if self.language == 'english':
            prompts = [
                "Hello, how",
                "Thank you",
                "I am",
            ]
        else:  # japanese
            prompts = [
                "おはよう",
                "ありがとう",
                "今日は",
            ]
        
        model.eval()
        with torch.no_grad():
            for prompt in prompts:
                inputs = tokenizer(prompt, return_tensors='pt')
                outputs = model.generate(
                    **inputs,
                    max_length=20,
                    num_return_sequences=3,
                    temperature=0.8,
                    do_sample=True,
                    pad_token_id=tokenizer.eos_token_id,
                )
                
                print(f"Prompt: '{prompt}'")
                for i, output in enumerate(outputs):
                    text = tokenizer.decode(output, skip_special_tokens=True)
                    print(f"  {i+1}. {text}")
                print()


def main():
    """Main training script."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Train LLM keyboard models')
    parser.add_argument(
        '--language',
        type=str,
        choices=['english', 'japanese', 'both'],
        default='both',
        help='Language to train (default: both)'
    )
    parser.add_argument(
        '--test',
        action='store_true',
        help='Test predictions after training'
    )
    
    args = parser.parse_args()
    
    languages = ['english', 'japanese'] if args.language == 'both' else [args.language]
    
    for lang in languages:
        trainer = ModelTrainer(lang)
        trained_model, tokenizer = trainer.train()
        
        if args.test:
            trainer.test_predictions(tokenizer, trained_model.model)
    
    print("\n" + "="*60)
    print("ALL TRAINING COMPLETE!")
    print("="*60)
    print("\nNext steps:")
    print("1. Run compression pipeline: python compress_model.py")
    print("2. Convert to CoreML: python convert_to_coreml.py")
    print("3. Integrate with iOS app")


if __name__ == "__main__":
    main()
