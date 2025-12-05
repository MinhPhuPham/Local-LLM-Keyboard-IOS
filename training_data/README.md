# Training Data for LLM Local Keyboard

This directory contains training data for the English and Japanese language models used in the iOS keyboard application.

## Directory Structure

```
training_data/
├── english/
│   ├── common_phrases.txt      # Everyday greetings and expressions
│   ├── technical_terms.txt     # Programming and technical vocabulary
│   ├── conversational.txt      # Casual conversation examples
│   └── formal_writing.txt      # Business and formal communication
├── japanese/
│   ├── common_phrases.txt      # Everyday Japanese expressions
│   ├── business_japanese.txt   # Professional Japanese communication
│   ├── conversational.txt      # Casual Japanese dialogue
│   └── mixed_language.txt      # Japanese with English loanwords
└── README.md                   # This file
```

## Data Format

- **Format**: Plain text files with one phrase/sentence per line
- **Encoding**: UTF-8 (required for Japanese characters)
- **Comments**: Lines starting with `#` are treated as comments
- **Empty lines**: Ignored during processing

## Current Dataset Size

### English
- **common_phrases.txt**: 20 examples
- **technical_terms.txt**: 20 examples
- **conversational.txt**: 20 examples
- **formal_writing.txt**: 20 examples
- **Total**: 80 examples

### Japanese
- **common_phrases.txt**: 20 examples
- **business_japanese.txt**: 20 examples
- **conversational.txt**: 20 examples
- **mixed_language.txt**: 20 examples
- **Total**: 80 examples

## Expanding the Dataset

This is a starter dataset with 10-20 examples per category. To improve model accuracy, you should:

1. **Add more examples**: Aim for thousands of examples per category
2. **Diversify content**: Include various writing styles, topics, and contexts
3. **Balance categories**: Ensure similar amounts of data across categories
4. **Quality over quantity**: Focus on natural, commonly-used phrases

### Recommended Sources for Expansion

#### English
- Common Crawl corpus
- Wikipedia articles
- Social media posts (Twitter, Reddit)
- News articles
- Technical documentation
- Books and literature

#### Japanese
- Japanese Wikipedia
- Twitter (Japanese users)
- Japanese news sites (NHK, Asahi, etc.)
- Technical blogs in Japanese
- Japanese literature
- Anime/drama subtitles

## Data Processing Pipeline

When ready to train models, the data will be processed as follows:

1. **Tokenization**: Text split into tokens using language-specific tokenizers
   - English: BPE (Byte Pair Encoding)
   - Japanese: Unigram with high character coverage for Kanji

2. **Cleaning**: Remove duplicates, normalize whitespace, filter invalid characters

3. **Augmentation**: (Optional) Generate variations using techniques like:
   - Back-translation
   - Synonym replacement
   - Random insertion/deletion

4. **Train/Validation Split**: 90% training, 10% validation

## Model Training Configuration

### English Model
```python
{
    'vocab_size': 16000,
    'tokenizer': 'bpe',
    'layers': 3,
    'hidden_size': 192,
    'attention_heads': 6
}
```

### Japanese Model
```python
{
    'vocab_size': 32000,
    'tokenizer': 'unigram',
    'character_coverage': 0.9995,
    'layers': 4,
    'hidden_size': 256,
    'attention_heads': 8,
    'english_support': True  # 30% English corpus
}
```

## Adding New Data

To add new training data:

1. Choose the appropriate category file
2. Add one phrase per line
3. Ensure UTF-8 encoding
4. Verify no duplicate entries
5. Keep natural language patterns

Example:
```bash
echo "Your new phrase here" >> training_data/english/common_phrases.txt
```

## Data Quality Guidelines

✅ **Good Examples**:
- Natural, commonly-used phrases
- Grammatically correct
- Contextually appropriate
- Diverse vocabulary

❌ **Avoid**:
- Gibberish or nonsensical text
- Overly repetitive patterns
- Offensive or inappropriate content
- Machine-generated spam

## Privacy and Ethics

- Do not include personal information (names, addresses, phone numbers)
- Avoid biased or discriminatory language
- Respect copyright when sourcing data
- Follow data usage terms and licenses

## Next Steps

1. **Expand dataset**: Add more examples to each category (target: 1000+ per file)
2. **Create training scripts**: Python scripts to process and train models
3. **Implement compression**: Apply compression pipeline to reduce model size
4. **Convert to CoreML**: Export models for iOS integration

## License

This training data is for development and testing purposes. Ensure compliance with applicable licenses when expanding the dataset.
