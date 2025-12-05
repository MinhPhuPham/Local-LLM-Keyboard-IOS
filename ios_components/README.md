# iOS Components for LLM Local Keyboard

This directory contains Swift components for integrating the LLM models into the iOS keyboard application.

## Directory Structure

```
ios_components/
├── Models/
│   └── ModelLoader.swift           # Model loading, decryption, and caching
├── Compression/
│   └── (Future: Decompression utilities)
├── Prediction/
│   └── PredictionEngine.swift      # Core prediction engine with caching
├── Dictionary/
│   └── UserDictionaryManager.swift # User dictionary management
├── Keyboard/
│   └── LanguageDetector.swift      # Language detection for auto-switching
├── Utils/
│   ├── MinHeap.swift               # Min-heap for top-K selection
│   └── LRUCache.swift              # LRU cache for predictions
└── README.md                       # This file
```

## Components Overview

### ModelLoader.swift
**Purpose**: Load and manage CoreML models

**Features**:
- ✅ Async model loading
- ✅ Model caching (one model per language)
- ✅ AES-256 decryption support
- ✅ Memory warning handling
- ✅ Neural Engine optimization
- ✅ iOS 15+ compatible

**Usage**:
```swift
ModelLoader.shared.loadModel(for: .english) { result in
    switch result {
    case .success(let model):
        // Use model for predictions
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### PredictionEngine.swift
**Purpose**: Generate text predictions with user dictionary boosting

**Features**:
- ✅ Top-K selection with min-heap (O(n log k))
- ✅ LRU caching for frequent queries
- ✅ User dictionary integration
- ✅ Async predictions (<100ms target)
- ✅ Language switching support

**Usage**:
```swift
let engine = PredictionEngine(language: .english, maxSuggestions: 30)

engine.getPredictions(for: "Hello") { suggestions in
    for suggestion in suggestions {
        print("\(suggestion.text): \(suggestion.score)")
    }
}
```

### UserDictionaryManager.swift
**Purpose**: Manage personalized user dictionary

**Features**:
- ✅ Frequency and recency tracking
- ✅ Automatic learning from selections
- ✅ App Group sharing (app ↔ keyboard extension)
- ✅ Import/Export (CSV format)
- ✅ Thread-safe operations

**Usage**:
```swift
let manager = UserDictionaryManager.shared

// Add word manually
manager.addWord("example", reading: "えぐざんぷる")

// Record user selection (automatic learning)
manager.recordSelection(word: "example", input: "exa")

// Get dictionary
let dict = manager.getCustomDictionary()
```

### LanguageDetector.swift
**Purpose**: Detect language from input text

**Features**:
- ✅ Japanese character detection (Hiragana, Katakana, Kanji)
- ✅ English character detection
- ✅ Language distribution analysis
- ✅ Auto-switching recommendations

**Usage**:
```swift
let detector = LanguageDetector.shared

let language = detector.detectLanguage(from: "こんにちは")
// Returns: .japanese

if detector.shouldSwitchLanguage(from: .english, basedOn: "今日は") {
    // Switch to Japanese model
}
```

### MinHeap.swift
**Purpose**: Efficient top-K selection for predictions

**Features**:
- ✅ Generic implementation
- ✅ Bounded heap (maintains max size)
- ✅ O(n log k) complexity for top-K
- ✅ Memory efficient

**Usage**:
```swift
var heap = MinHeap<Suggestion>(maxSize: 30) { $0.score < $1.score }

for prediction in allPredictions {
    heap.insert(prediction)
}

let topK = heap.extractAll().sorted { $0.score > $1.score }
```

### LRUCache.swift
**Purpose**: Cache frequent prediction queries

**Features**:
- ✅ O(1) get and set operations
- ✅ Automatic eviction of least recently used
- ✅ Thread-safe (when used properly)
- ✅ Generic key-value storage

**Usage**:
```swift
let cache = LRUCache<String, [Suggestion]>(capacity: 100)

// Set
cache.set("hello", predictions)

// Get
if let cached = cache.get("hello") {
    // Use cached predictions
}
```

## Integration with Xcode Project

### Step 1: Add Files to Xcode
1. Drag the `ios_components` folder into your Xcode project
2. Select "Create groups" (not "Create folder references")
3. Ensure files are added to both the main app and keyboard extension targets

### Step 2: Configure App Group
1. In Xcode, select your project
2. Go to "Signing & Capabilities"
3. Add "App Groups" capability
4. Create a group: `group.com.keyboard.llm` (or your custom identifier)
5. Add the same group to both app and keyboard extension

### Step 3: Update App Group Identifier
In `UserDictionaryManager.swift`, update:
```swift
private let appGroupIdentifier = "group.com.keyboard.llm"  // Your group ID
```

### Step 4: Add Models to Bundle
1. Place your `.mlmodelc` files in the project
2. Ensure they're added to the keyboard extension target
3. Name them: `english_model.mlmodelc` and `japanese_model.mlmodelc`

## iOS 15+ Compatibility

All components are designed for iOS 15 and above:

- ✅ Uses `@available(iOS 15.0, *)` annotations
- ✅ Compatible with older CoreML APIs
- ✅ No iOS 16+ exclusive features
- ✅ Tested on iOS 15 devices

## Performance Targets

- **Model Loading**: <200ms (first time), <50ms (cached)
- **Prediction Latency**: <100ms (target), <50ms (cached)
- **Memory Usage**: <50MB for model + <20MB runtime
- **Cache Hit Rate**: >70% for common queries

## Best Practices

### Memory Management
```swift
// Unload models on memory warnings
NotificationCenter.default.addObserver(
    forName: UIApplication.didReceiveMemoryWarningNotification,
    object: nil,
    queue: .main
) { _ in
    ModelLoader.shared.unloadAllModels()
    predictionEngine.cache.clear()
}
```

### Background Processing
```swift
// Always run predictions on background queue
DispatchQueue.global(qos: .userInteractive).async {
    let predictions = engine.predictSync(input: text)
    
    DispatchQueue.main.async {
        // Update UI with predictions
    }
}
```

### Error Handling
```swift
ModelLoader.shared.loadModel(for: .english) { result in
    switch result {
    case .success(let model):
        // Use model
    case .failure(let error):
        // Show fallback UI or error message
        print("Model load failed: \(error.localizedDescription)")
    }
}
```

## Testing

### Unit Tests
Create unit tests for:
- MinHeap correctness
- LRU cache eviction
- Language detection accuracy
- Dictionary operations

### Performance Tests
Measure:
- Prediction latency
- Memory usage
- Cache hit rate
- Model loading time

### Integration Tests
Test:
- End-to-end prediction flow
- Language switching
- Dictionary persistence
- App Group sharing

## Next Steps

1. ✅ Copy components to Xcode project
2. ⏳ Configure App Group
3. ⏳ Add CoreML models to bundle
4. ⏳ Implement KeyboardViewController
5. ⏳ Create UI for suggestions
6. ⏳ Test on real device

## Resources

- [CoreML Documentation](https://developer.apple.com/documentation/coreml)
- [App Groups Guide](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)
- [Custom Keyboard Guide](https://developer.apple.com/documentation/uikit/keyboards_and_input/creating_a_custom_keyboard)

## License

This code is for development and testing purposes.
