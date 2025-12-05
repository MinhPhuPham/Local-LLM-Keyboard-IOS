"""
Data Loader for LLM Keyboard Training

This module handles loading and preprocessing training data for both
English and Japanese language models.
"""

import os
from typing import List, Tuple, Dict
from pathlib import Path


class TrainingDataLoader:
    """Load and preprocess training data from text files."""
    
    def __init__(self, data_dir: str = "training_data"):
        """
        Initialize the data loader.
        
        Args:
            data_dir: Path to the training data directory
        """
        self.data_dir = Path(data_dir)
        self.english_dir = self.data_dir / "english"
        self.japanese_dir = self.data_dir / "japanese"
        
    def load_file(self, filepath: Path) -> List[str]:
        """
        Load a single training data file.
        
        Args:
            filepath: Path to the text file
            
        Returns:
            List of sentences/phrases
        """
        sentences = []
        
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                for line in f:
                    # Skip comments and empty lines
                    line = line.strip()
                    if line and not line.startswith('#'):
                        sentences.append(line)
        except FileNotFoundError:
            print(f"Warning: File not found: {filepath}")
        except Exception as e:
            print(f"Error loading {filepath}: {e}")
            
        return sentences
    
    def load_english_data(self) -> Dict[str, List[str]]:
        """
        Load all English training data.
        
        Returns:
            Dictionary mapping category to list of sentences
        """
        categories = {
            'common_phrases': self.english_dir / 'common_phrases.txt',
            'technical_terms': self.english_dir / 'technical_terms.txt',
            'conversational': self.english_dir / 'conversational.txt',
            'formal_writing': self.english_dir / 'formal_writing.txt',
        }
        
        data = {}
        for category, filepath in categories.items():
            data[category] = self.load_file(filepath)
            print(f"Loaded {len(data[category])} examples from {category}")
            
        return data
    
    def load_japanese_data(self) -> Dict[str, List[str]]:
        """
        Load all Japanese training data.
        
        Returns:
            Dictionary mapping category to list of sentences
        """
        categories = {
            'common_phrases': self.japanese_dir / 'common_phrases.txt',
            'business_japanese': self.japanese_dir / 'business_japanese.txt',
            'conversational': self.japanese_dir / 'conversational.txt',
            'mixed_language': self.japanese_dir / 'mixed_language.txt',
        }
        
        data = {}
        for category, filepath in categories.items():
            data[category] = self.load_file(filepath)
            print(f"Loaded {len(data[category])} examples from {category}")
            
        return data
    
    def get_all_sentences(self, language: str) -> List[str]:
        """
        Get all sentences for a specific language.
        
        Args:
            language: 'english' or 'japanese'
            
        Returns:
            List of all sentences combined
        """
        if language == 'english':
            data = self.load_english_data()
        elif language == 'japanese':
            data = self.load_japanese_data()
        else:
            raise ValueError(f"Unsupported language: {language}")
        
        # Combine all categories
        all_sentences = []
        for category_sentences in data.values():
            all_sentences.extend(category_sentences)
            
        return all_sentences
    
    def get_train_val_split(
        self, 
        language: str, 
        val_ratio: float = 0.1
    ) -> Tuple[List[str], List[str]]:
        """
        Split data into training and validation sets.
        
        Args:
            language: 'english' or 'japanese'
            val_ratio: Ratio of validation data (default: 0.1 = 10%)
            
        Returns:
            Tuple of (train_sentences, val_sentences)
        """
        import random
        
        sentences = self.get_all_sentences(language)
        
        # Shuffle for random split
        random.seed(42)  # For reproducibility
        random.shuffle(sentences)
        
        # Calculate split point
        val_size = int(len(sentences) * val_ratio)
        
        val_sentences = sentences[:val_size]
        train_sentences = sentences[val_size:]
        
        print(f"\n{language.capitalize()} data split:")
        print(f"  Training: {len(train_sentences)} examples")
        print(f"  Validation: {len(val_sentences)} examples")
        
        return train_sentences, val_sentences
    
    def get_statistics(self, language: str) -> Dict[str, any]:
        """
        Get statistics about the training data.
        
        Args:
            language: 'english' or 'japanese'
            
        Returns:
            Dictionary with statistics
        """
        sentences = self.get_all_sentences(language)
        
        total_chars = sum(len(s) for s in sentences)
        total_words = sum(len(s.split()) for s in sentences)
        
        stats = {
            'total_sentences': len(sentences),
            'total_characters': total_chars,
            'total_words': total_words,
            'avg_sentence_length': total_chars / len(sentences) if sentences else 0,
            'avg_words_per_sentence': total_words / len(sentences) if sentences else 0,
        }
        
        return stats


def main():
    """Demo usage of the data loader."""
    loader = TrainingDataLoader()
    
    print("=" * 60)
    print("ENGLISH DATA")
    print("=" * 60)
    english_data = loader.load_english_data()
    english_stats = loader.get_statistics('english')
    print(f"\nStatistics:")
    for key, value in english_stats.items():
        print(f"  {key}: {value:.2f}" if isinstance(value, float) else f"  {key}: {value}")
    
    print("\n" + "=" * 60)
    print("JAPANESE DATA")
    print("=" * 60)
    japanese_data = loader.load_japanese_data()
    japanese_stats = loader.get_statistics('japanese')
    print(f"\nStatistics:")
    for key, value in japanese_stats.items():
        print(f"  {key}: {value:.2f}" if isinstance(value, float) else f"  {key}: {value}")
    
    print("\n" + "=" * 60)
    print("TRAIN/VAL SPLIT")
    print("=" * 60)
    en_train, en_val = loader.get_train_val_split('english')
    jp_train, jp_val = loader.get_train_val_split('japanese')


if __name__ == "__main__":
    main()
