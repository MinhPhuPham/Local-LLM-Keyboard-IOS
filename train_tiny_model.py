"""
Train Tiny Model - Optimized for Keyboard Use

This script trains a custom tiny model (<10M parameters) instead of using
large pre-trained models like distilgpt2 (82M parameters).

Result: Model size <50MB after compression (vs 300MB+ with distilgpt2)
"""

import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
from pathlib import Path
from typing import List
import json
from tqdm import tqdm

from data_loader import TrainingDataLoader
from tiny_model import TinyKeyboardModel, TinyKeyboardConfig, count_parameters, get_model_size_mb


class SimpleTokenizer:
    """Simple character-level tokenizer for tiny model."""
    
    def __init__(self, vocab_size=5000):
        self.vocab_size = vocab_size
        self.char_to_id = {}
        self.id_to_char = {}
        self.pad_token_id = 0
        self.unk_token_id = 1
        
    def build_vocab(self, texts: List[str]):
        """Build vocabulary from texts."""
        # Count character frequencies
        char_freq = {}
        for text in texts:
            for char in text:
                char_freq[char] = char_freq.get(char, 0) + 1
        
        # Sort by frequency and take top vocab_size - 2 (reserve for pad/unk)
        sorted_chars = sorted(char_freq.items(), key=lambda x: x[1], reverse=True)
        top_chars = [char for char, _ in sorted_chars[:self.vocab_size - 2]]
        
        # Build mappings
        self.char_to_id = {'<pad>': 0, '<unk>': 1}
        self.id_to_char = {0: '<pad>', 1: '<unk>'}
        
        for i, char in enumerate(top_chars, start=2):
            self.char_to_id[char] = i
            self.id_to_char[i] = char
        
        print(f"Built vocabulary: {len(self.char_to_id)} characters")
    
    def encode(self, text: str, max_length=64) -> List[int]:
        """Encode text to token IDs."""
        ids = [self.char_to_id.get(char, self.unk_token_id) for char in text]
        
        # Truncate or pad
        if len(ids) > max_length:
            ids = ids[:max_length]
        else:
            ids = ids + [self.pad_token_id] * (max_length - len(ids))
        
        return ids
    
    def decode(self, ids: List[int]) -> str:
        """Decode token IDs to text."""
        chars = [self.id_to_char.get(id, '<unk>') for id in ids]
        return ''.join(chars).replace('<pad>', '').replace('<unk>', '')
    
    def save(self, path: Path):
        """Save tokenizer."""
        data = {
            'char_to_id': self.char_to_id,
            'id_to_char': {str(k): v for k, v in self.id_to_char.items()},
            'vocab_size': self.vocab_size,
        }
        with open(path / 'tokenizer.json', 'w') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
    
    @classmethod
    def load(cls, path: Path):
        """Load tokenizer."""
        with open(path / 'tokenizer.json', 'r') as f:
            data = json.load(f)
        
        tokenizer = cls(vocab_size=data['vocab_size'])
        tokenizer.char_to_id = data['char_to_id']
        tokenizer.id_to_char = {int(k): v for k, v in data['id_to_char'].items()}
        return tokenizer


class TextDataset(Dataset):
    """Dataset for text sequences."""
    
    def __init__(self, texts: List[str], tokenizer: SimpleTokenizer, max_length=64):
        self.tokenizer = tokenizer
        self.max_length = max_length
        self.examples = []
        
        for text in texts:
            ids = tokenizer.encode(text, max_length)
            self.examples.append(torch.tensor(ids, dtype=torch.long))
    
    def __len__(self):
        return len(self.examples)
    
    def __getitem__(self, idx):
        input_ids = self.examples[idx]
        # Labels are shifted input_ids
        labels = input_ids.clone()
        return {'input_ids': input_ids, 'labels': labels}


def train_tiny_model(language: str, num_epochs=20):
    """Train tiny model for specified language."""
    
    print(f"\n{'='*60}")
    print(f"Training TINY {language.upper()} model")
    print(f"{'='*60}\n")
    
    # Load data
    loader = TrainingDataLoader()
    train_texts, val_texts = loader.get_train_val_split(language)
    
    print(f"Training examples: {len(train_texts)}")
    print(f"Validation examples: {len(val_texts)}\n")
    
    # Build tokenizer
    print("Building tokenizer...")
    tokenizer = SimpleTokenizer(vocab_size=5000)
    tokenizer.build_vocab(train_texts + val_texts)
    
    # Create model
    print("\nCreating model...")
    config = TinyKeyboardConfig(
        vocab_size=tokenizer.vocab_size,
        hidden_size=128,
        num_hidden_layers=2,
        num_attention_heads=4,
        intermediate_size=256,
        max_position_embeddings=64,
    )
    
    model = TinyKeyboardModel(config)
    device = torch.device('mps' if torch.backends.mps.is_available() else 'cpu')
    model = model.to(device)
    
    params = count_parameters(model)
    size_mb = get_model_size_mb(model)
    
    print(f"✅ Model created!")
    print(f"   Parameters: {params:,} ({params/1e6:.2f}M)")
    print(f"   Size: {size_mb:.2f} MB")
    print(f"   Device: {device}\n")
    
    # Create datasets
    train_dataset = TextDataset(train_texts, tokenizer, max_length=64)
    val_dataset = TextDataset(val_texts, tokenizer, max_length=64)
    
    train_loader = DataLoader(train_dataset, batch_size=8, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=8)
    
    # Optimizer
    optimizer = torch.optim.AdamW(model.parameters(), lr=1e-3)
    
    # Training loop
    print("Starting training...\n")
    best_val_loss = float('inf')
    
    for epoch in range(num_epochs):
        # Train
        model.train()
        train_loss = 0
        
        for batch in tqdm(train_loader, desc=f"Epoch {epoch+1}/{num_epochs}"):
            input_ids = batch['input_ids'].to(device)
            labels = batch['labels'].to(device)
            
            optimizer.zero_grad()
            outputs = model(input_ids, labels=labels)
            loss = outputs['loss']
            loss.backward()
            optimizer.step()
            
            train_loss += loss.item()
        
        train_loss /= len(train_loader)
        
        # Validate
        model.eval()
        val_loss = 0
        
        with torch.no_grad():
            for batch in val_loader:
                input_ids = batch['input_ids'].to(device)
                labels = batch['labels'].to(device)
                
                outputs = model(input_ids, labels=labels)
                val_loss += outputs['loss'].item()
        
        val_loss /= len(val_loader)
        
        print(f"Epoch {epoch+1}: train_loss={train_loss:.4f}, val_loss={val_loss:.4f}")
        
        # Save best model
        if val_loss < best_val_loss:
            best_val_loss = val_loss
            output_dir = Path(f"models/{language}/tiny_final")
            output_dir.mkdir(parents=True, exist_ok=True)
            model.save_pretrained(output_dir)
            tokenizer.save(output_dir)
            print(f"   ✅ Saved best model (val_loss={val_loss:.4f})")
    
    print(f"\n✅ Training complete!")
    print(f"   Best validation loss: {best_val_loss:.4f}")
    print(f"   Model saved to: models/{language}/tiny_final")
    
    return model, tokenizer


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser()
    parser.add_argument('--language', choices=['english', 'japanese', 'both'], default='both')
    parser.add_argument('--epochs', type=int, default=20)
    args = parser.parse_args()
    
    languages = ['english', 'japanese'] if args.language == 'both' else [args.language]
    
    for lang in languages:
        train_tiny_model(lang, num_epochs=args.epochs)
    
    print("\n" + "="*60)
    print("ALL TRAINING COMPLETE!")
    print("="*60)
    print("\nNext steps:")
    print("1. Run compression: python compress_model.py --language both")
    print("2. Expected final size: <25MB per model")
