# iOS Xcode Integration Guide

## 📱 What to Copy to Xcode

You need to copy **2 model files** to your Xcode project:

```
models/english/ios_ready/model.safetensors  (3.0 MB)
models/japanese/ios_ready/model.safetensors (3.0 MB)
```

**Total size: ~6 MB** - Perfect for keyboard extension!

## 🚀 Step-by-Step Xcode Integration

### Step 1: Add Models to Xcode Project

1. Open your Xcode project: `custom-keyboard-ios.xcodeproj`

2. In Xcode, right-click on your project navigator → **Add Files to "custom-keyboard-ios"**

3. Navigate to and select:
   - `models/english/ios_ready/model.safetensors`
   - `models/japanese/ios_ready/model.safetensors`

4. **Important**: In the dialog, check:
   - ✅ **Copy items if needed**
   - ✅ **Add to targets**: Select your **keyboard extension target** (NOT the main app)

5. Rename the files in Xcode for clarity:
   - `model.safetensors` → `english_model.safetensors`
   - `model.safetensors` → `japanese_model.safetensors`

### Step 2: Add iOS Components

1. Drag the entire `ios_components/` folder into your Xcode project

2. Select:
   - ✅ **Create groups**
   - ✅ **Add to targets**: Both main app AND keyboard extension

3. Your project structure should look like:
   ```
   custom-keyboard-ios/
   ├── Custom Keyboard/
   │   ├── english_model.safetensors
   │   ├── japanese_model.safetensors
   │   └── KeyboardViewController.swift
   ├── ios_components/
   │   ├── Models/
   │   │   └── ModelLoader.swift
   │   ├── Prediction/
   │   │   └── PredictionEngine.swift
   │   ├── Dictionary/
   │   │   └── UserDictionaryManager.swift
   │   ├── Keyboard/
   │   │   └── LanguageDetector.swift
   │   └── Utils/
   │       ├── MinHeap.swift
   │       └── LRUCache.swift
   ```

### Step 3: Configure App Groups

1. Select your project in Xcode
2. Go to **Signing & Capabilities**
3. Click **+ Capability** → **App Groups**
4. Add a new group: `group.com.keyboard.llm` (or your custom identifier)
5. **Repeat for both**:
   - Main app target
   - Keyboard extension target

### Step 4: Update Model Loading

Since CoreML conversion doesn't work with our custom architecture, we'll use the compressed models directly.

**Option A: Use Compressed PyTorch Models (Recommended)**

The models in `ios_ready/` are already compressed to 2.96MB each and ready to use. You'll need to add PyTorch Mobile to your project:

1. Add to your `Podfile`:
```ruby
pod 'LibTorch-Lite', '~> 2.0.0'
```

2. Run: `pod install`

3. Use `ModelLoader.swift` to load the models

**Option B: Create Simple Lookup Table (No ML Framework Needed)**

For a keyboard, you can use a simpler approach without ML frameworks:

1. Pre-compute predictions for common inputs
2. Store in a dictionary/trie structure
3. Use `UserDictionaryManager` for personalization
4. Much faster and smaller than running ML models

### Step 5: Implement Keyboard UI

1. Open `Custom Keyboard/KeyboardViewController.swift`

2. Add prediction engine:
```swift
import UIKit

class KeyboardViewController: UIInputViewController {
    
    var predictionEngine: PredictionEngine!
    var dictionaryManager: UserDictionaryManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize components
        dictionaryManager = UserDictionaryManager.shared
        predictionEngine = PredictionEngine(
            language: .english,
            maxSuggestions: 30
        )
        
        // Setup UI
        setupKeyboardUI()
    }
    
    func setupKeyboardUI() {
        // Add your keyboard layout here
        // Add suggestion bar at top
    }
    
    func textDidChange(_ textInput: UITextInput?) {
        guard let proxy = textDocumentProxy as? UITextDocumentProxy else { return }
        guard let text = proxy.documentContextBeforeInput else { return }
        
        // Get predictions
        predictionEngine.getPredictions(for: text) { suggestions in
            // Update suggestion bar
            self.updateSuggestions(suggestions)
        }
    }
}
```

## 📊 Model Information

| File | Size | Purpose |
|------|------|---------|
| `english_model.safetensors` | 3.0 MB | English predictions |
| `japanese_model.safetensors` | 3.0 MB | Japanese predictions |

**Format**: SafeTensors (PyTorch format)
**Precision**: float16 (half-precision)
**Parameters**: 1.55M per model
**iOS Version**: 15.0+

## ⚠️ Why Not CoreML?

CoreML doesn't support our custom transformer architecture (multi-head attention). Instead:

1. **Use compressed PyTorch models** (2.96MB each) - Recommended
2. **Or use lookup tables** - Simpler, no ML framework needed
3. **Or simplify the model** - Remove attention, use simpler architecture

## 🎯 Recommended Approach

For a keyboard extension, I recommend **Option B: Lookup Table**:

### Why?
- ✅ No ML framework needed (smaller app size)
- ✅ Instant predictions (<1ms)
- ✅ Works offline perfectly
- ✅ Easy to update
- ✅ Lower battery usage

### How?
1. Pre-generate predictions for common prefixes
2. Store in efficient trie structure
3. Use `UserDictionaryManager` for learning
4. Fallback to basic suggestions

Would you like me to create a lookup table generator instead of using the ML models?

## 📝 Next Steps

1. Choose your approach (PyTorch Mobile or Lookup Table)
2. Add models/data to Xcode
3. Configure App Groups
4. Implement keyboard UI
5. Test on device

Let me know which approach you prefer and I'll create the complete implementation!
