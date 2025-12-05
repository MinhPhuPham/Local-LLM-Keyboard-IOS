# LLM Local Keyboard Training - Implementation Plan

## Project Overview

This plan outlines the implementation of a local LLM-powered keyboard for iOS 15+ with support for English and Japanese languages. The goal is to create a highly compressed, performant model that runs entirely on-device with intelligent text prediction.

## Key Requirements

- **Target Size**: <50MB total model size
- **Performance**: <100ms prediction latency
- **Languages**: English and Japanese (separate optimized models)
- **iOS Support**: iOS 15 and above
- **Suggestions**: Top 30-50 predictions with user dictionary integration

---

## Phase 1: Model Training & Compression

### 1.1 Training Data Preparation

#### English Training Data
Create initial dataset with 10-20 diverse examples covering:
- Common phrases and sentences
- Technical terms
- Conversational text
- Formal writing
- Social media style text

**Example Categories**:
- Greetings: "Hello, how are you?", "Good morning!"
- Questions: "What time is it?", "Where are you going?"
- Statements: "I'm working on a project", "The weather is nice today"
- Technical: "Initialize the database connection", "Run the test suite"
- Casual: "lol that's funny", "brb getting coffee"

#### Japanese Training Data
Create initial dataset with 10-20 diverse examples covering:
- Hiragana, Katakana, and Kanji
- Common phrases (挨拶)
- Business Japanese (ビジネス日本語)
- Casual conversation
- Mixed English-Japanese text

**Example Categories**:
- Greetings: "おはようございます", "こんにちは"
- Questions: "何時ですか？", "どこに行きますか？"
- Statements: "今日は天気がいいですね", "仕事をしています"
- Mixed: "メールをチェックします", "プロジェクトを進めています"
- Casual: "ありがとう！", "わかりました"

**File Structure**:
```
training_data/
├── english/
│   ├── common_phrases.txt
│   ├── technical_terms.txt
│   ├── conversational.txt
│   └── formal_writing.txt
├── japanese/
│   ├── common_phrases.txt
│   ├── business_japanese.txt
│   ├── conversational.txt
│   └── mixed_language.txt
└── README.md (data format documentation)
```

### 1.2 Model Architecture

#### English Model Configuration
```python
config = {
    'model_type': 'transformer',
    'layers': 3,
    'hidden_size': 192,
    'attention_heads': 6,
    'vocab_size': 16000,
    'tokenizer': 'bpe',  # Better for English
    'max_sequence_length': 128
}
```

#### Japanese Model Configuration
```python
config = {
    'model_type': 'transformer',
    'layers': 4,
    'hidden_size': 256,
    'attention_heads': 8,
    'vocab_size': 32000,
    'tokenizer': 'unigram',  # Better for Japanese
    'character_coverage': 0.9995,  # High for Kanji
    'max_sequence_length': 128,
    'english_support': True,  # 30% English corpus
}
```

### 1.3 Compression Pipeline

Implement aggressive compression to achieve <50MB target:

1. **Model Distillation** (Optional but recommended)
   - Train smaller student model from larger teacher
   - Target: 50MB → 15MB

2. **4-bit Quantization**
   - Use BitsAndBytes or CoreML quantization
   - Target: 75% size reduction

3. **Weight Pruning**
   - Remove 30% of least important weights
   - Target: Additional 20-30% reduction

4. **Vocabulary Compression (LOUDS Trie)**
   - Compress tokenizer vocabulary using LOUDS structure
   - Target: 1MB → 200KB (5x compression)

5. **Huffman Encoding**
   - Entropy encoding for quantized weights
   - Target: Additional 15-20% reduction

6. **LZMA Compression**
   - Final storage compression
   - Applied at build time

**Expected Final Sizes**:
- English Model: ~25-30MB
- Japanese Model: ~35-40MB
- User loads only one model at a time

### 1.4 Model Encryption

Implement AES-256 encryption for model protection:
- Encrypt model files before bundling
- Obfuscate encryption keys in code
- Decrypt on-device during model loading

---

## Phase 2: iOS Integration

### 2.1 Project Structure

```
custom-keyboard-ios/
├── Models/
│   ├── english_model.mlmodelc (encrypted)
│   ├── japanese_model.mlmodelc (encrypted)
│   └── ModelLoader.swift
├── Compression/
│   ├── ModelEncryption.swift
│   ├── HuffmanDecoder.swift
│   └── LZMADecompressor.swift
├── Prediction/
│   ├── PredictionEngine.swift
│   ├── TopKSelector.swift
│   └── SuggestionCache.swift
├── Dictionary/
│   ├── UserDictionaryManager.swift
│   ├── WordInfo.swift
│   └── DictionaryBooster.swift
├── Keyboard/
│   ├── KeyboardViewController.swift
│   ├── LanguageDetector.swift
│   └── SuggestionView.swift
└── Utils/
    ├── MinHeap.swift
    ├── LRUCache.swift
    └── Debouncer.swift
```

### 2.2 Core Components

#### ModelLoader.swift
- Load and decrypt compressed models
- Support lazy loading for memory efficiency
- Handle model switching between languages
- Utilize Neural Engine when available

#### PredictionEngine.swift
- Interface with CoreML models
- Implement top-K selection with min-heap
- Apply user dictionary boosting
- Cache frequent predictions (LRU cache)
- Debounce rapid input changes

#### UserDictionaryManager.swift
- Read iOS system dictionary (where possible)
- Manage custom app dictionary
- Track word frequency and recency
- Learn from user selections
- Support dictionary import/export

#### LanguageDetector.swift
- Auto-detect Japanese vs English input
- Switch models dynamically
- Handle mixed-language text

### 2.3 Performance Optimizations

1. **Caching Strategy**
   - LRU cache for top 100 frequent queries
   - Cache invalidation on dictionary updates
   - Memory-efficient cache size limits

2. **Async Processing**
   - Run predictions on background queue (QoS: userInteractive)
   - Return results on main thread
   - Timeout protection (<50ms)

3. **Early Stopping**
   - Stop model inference if confidence drops
   - Limit candidate generation to 2x max suggestions
   - Use score thresholds for filtering

4. **Memory Management**
   - Unload inactive language model
   - Clear caches on memory warnings
   - Use autoreleasepool for batch operations

### 2.4 iOS 15+ Compatibility

Ensure compatibility with iOS 15 and above:
- Use `@available` annotations for newer APIs
- Fallback implementations for iOS 15
- Test on minimum supported version
- Avoid iOS 16+ exclusive features unless conditionally available

---

## Phase 3: User Dictionary Integration

### 3.1 Dictionary Architecture

**Two-Layer System**:
1. **Base Model Layer**: Frozen pre-trained predictions
2. **User Dictionary Layer**: Dynamic boosting and learning

### 3.2 Dictionary Features

- **Word Tracking**: Frequency and recency scoring
- **Boosting Algorithm**: 
  - Frequency boost: `log(frequency + 1) * 0.3`
  - Recency boost: `max(0, 1.0 - days_since_used/30) * 0.2`
  - Prefix match boost: `+0.1`

- **Learning System**:
  - Auto-add selected words not in dictionary
  - Increment frequency on repeated selections
  - Update last-used timestamp

- **Import/Export**:
  - CSV format support
  - Share between app and keyboard extension
  - App Group container for data sharing

### 3.3 Data Persistence

Use App Group for sharing between main app and keyboard extension:
```swift
let groupURL = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourapp.keyboard")
```

Store dictionary as JSON with structure:
```json
{
  "word": {
    "word": "example",
    "reading": "えぐざんぷる",
    "frequency": 5,
    "lastUsed": "2025-12-05T10:30:00Z",
    "source": "userAdded"
  }
}
```

---

## Phase 4: Testing & Validation

### 4.1 Unit Tests

- Model loading and decryption
- Compression/decompression accuracy
- Top-K selection correctness
- Dictionary boosting logic
- Cache behavior and invalidation
- Language detection accuracy

### 4.2 Performance Tests

- Prediction latency (<100ms target)
- Memory usage (<50MB for model + runtime)
- Cache hit rate (>70% for common queries)
- Model switching time (<200ms)

### 4.3 Integration Tests

- End-to-end prediction flow
- Dictionary learning and persistence
- Multi-language switching
- App Group data sharing
- iOS 15 compatibility

### 4.4 Manual Testing

- Real device testing (iPhone with iOS 15+)
- Typing speed and responsiveness
- Suggestion quality and relevance
- Memory pressure scenarios
- Battery impact assessment

---

## Phase 5: Documentation & Deployment

### 5.1 Code Documentation

- Inline comments for complex algorithms
- API documentation for public interfaces
- Architecture decision records (ADRs)
- Performance optimization notes

### 5.2 User Documentation

- Setup instructions
- Dictionary import guide
- Language switching instructions
- Privacy and data handling explanation

### 5.3 Training Documentation

- Model training scripts and instructions
- Compression pipeline usage
- Adding new training data
- Re-training and updating models

---

## Implementation Checklist

### Phase 1: Training & Compression
- [ ] Create English training data (10-20 examples)
- [ ] Create Japanese training data (10-20 examples)
- [ ] Set up Python training environment
- [ ] Implement model training scripts
- [ ] Implement compression pipeline
- [ ] Test compression ratios
- [ ] Implement model encryption
- [ ] Convert to CoreML format
- [ ] Validate model accuracy after compression

### Phase 2: iOS Integration
- [ ] Set up Xcode project structure
- [ ] Implement ModelLoader with decryption
- [ ] Implement PredictionEngine
- [ ] Implement TopKSelector with MinHeap
- [ ] Implement LRU Cache
- [ ] Implement Debouncer
- [ ] Create KeyboardViewController
- [ ] Implement LanguageDetector
- [ ] Create SuggestionView UI
- [ ] Test on iOS 15 device

### Phase 3: Dictionary Integration
- [ ] Implement UserDictionaryManager
- [ ] Implement WordInfo model
- [ ] Implement dictionary boosting algorithm
- [ ] Implement learning system
- [ ] Set up App Group container
- [ ] Implement dictionary persistence
- [ ] Create import/export functionality
- [ ] Test dictionary synchronization

### Phase 4: Testing
- [ ] Write unit tests for core components
- [ ] Write performance tests
- [ ] Write integration tests
- [ ] Conduct manual testing on real devices
- [ ] Test iOS 15 compatibility
- [ ] Profile memory usage
- [ ] Profile battery impact
- [ ] Optimize based on profiling results

### Phase 5: Documentation
- [ ] Document code with comments
- [ ] Create API documentation
- [ ] Write user guide
- [ ] Write training guide
- [ ] Create README with setup instructions

---

## Success Criteria

✅ **Model Size**: Each model <50MB compressed  
✅ **Performance**: Predictions <100ms latency  
✅ **Accuracy**: Relevant suggestions in top 5 for common inputs  
✅ **Memory**: Total runtime memory <100MB  
✅ **Compatibility**: Works on iOS 15+  
✅ **User Experience**: Smooth typing with no lag  
✅ **Learning**: Dictionary improves with usage  

---

## Risk Mitigation

### Risk: Model too large
**Mitigation**: Aggressive compression pipeline, consider smaller base model

### Risk: Predictions too slow
**Mitigation**: Caching, early stopping, async processing, model optimization

### Risk: Poor accuracy after compression
**Mitigation**: Validate at each compression step, adjust compression ratios

### Risk: iOS 15 compatibility issues
**Mitigation**: Test early on iOS 15 devices, use compatibility checks

### Risk: Memory pressure on older devices
**Mitigation**: Lazy loading, aggressive cache limits, memory warning handlers

---

## Timeline Estimate

- **Phase 1**: 1-2 weeks (training data + compression)
- **Phase 2**: 2-3 weeks (iOS integration)
- **Phase 3**: 1 week (dictionary integration)
- **Phase 4**: 1-2 weeks (testing & optimization)
- **Phase 5**: 3-5 days (documentation)

**Total**: 6-9 weeks for complete implementation

---

## Next Steps

1. **Immediate**: Create training data files (10-20 examples each for EN/JP)
2. **Short-term**: Set up Python training environment
3. **Medium-term**: Implement compression pipeline
4. **Long-term**: Full iOS integration and testing

---

## Notes

- Training data will be expanded later (starting with 10-20 examples as requested)
- Focus on code quality and performance from the start
- Prioritize iOS 15 compatibility throughout development
- Document all compression trade-offs and decisions
- Keep user privacy as top priority (all processing on-device)
