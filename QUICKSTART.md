# QUICKSTART - LLM Local Keyboard

## Option A: Automated Setup (Recommended)

```bash
./setup.sh
```

This will:
- Check Python version
- Create virtual environment
- Install all dependencies
- Test data loader
- Create necessary directories

## Option B: Manual Setup

### 1. Setup Python Environment (5 minutes)

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

## 2. Test Training Data (30 seconds)

```bash
python data_loader.py
```

Expected output: Statistics for English (80 examples) and Japanese (80 examples)

## 3. Train Models (10-30 minutes depending on hardware)

**IMPORTANT**: Use the tiny model trainer (not train_model.py)

```bash
# Train tiny models (<10M parameters each)
python train_tiny_model.py --language both --epochs 20

# This creates models ~5-10MB each (vs 300MB+ with distilgpt2)
```

Models saved to: `models/english/tiny_final/` and `models/japanese/tiny_final/`

## 4. Compress Models (1-2 minutes)

```bash
python compress_tiny_model.py --language both
```

Compressed models saved to: `models/*/ios_ready/`

Final size: **~3MB per model** (perfect for iOS!)

## 5. iOS Integration

### What to Copy to Xcode

Copy these files to your Xcode project:

```
models/english/ios_ready/model.safetensors  (3.0 MB)
models/japanese/ios_ready/model.safetensors (3.0 MB)
ios_components/                              (Swift files)
```

### Quick Steps

1. Open `custom-keyboard-ios.xcodeproj` in Xcode
2. Drag model files into keyboard extension target
3. Drag `ios_components/` folder into project
4. Add App Group capability: `group.com.keyboard.llm`
5. Implement keyboard UI in `KeyboardViewController.swift`

**See [XCODE_INTEGRATION.md](XCODE_INTEGRATION.md) for detailed guide**

### Note About CoreML

CoreML conversion doesn't work with our custom transformer architecture. Instead, use:
- **Option A**: PyTorch Mobile (add via CocoaPods)
- **Option B**: Lookup table (no ML framework needed - faster!)

See XCODE_INTEGRATION.md for both approaches.

## Common Issues

**"Module not found"**: Activate venv first: `source venv/bin/activate`

**"accelerate not found"**: Install it: `pip install 'accelerate>=0.26.0'`

**"Out of memory"**: Reduce batch_size in `train_model.py` (line 76)

**"Model too large"**: Current 80 examples create small models. Add more data for production.

## File Locations

- Training data: `training_data/`
- Python scripts: `*.py` files in root
- iOS components: `ios_components/`
- Trained models: `models/`

## Quick Test

```bash
# Verify everything works
source venv/bin/activate
python data_loader.py
```

That's it! For detailed docs, see README files in each directory.
