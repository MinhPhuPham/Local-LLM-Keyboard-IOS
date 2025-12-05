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

```bash
# Train both languages with testing
python train_model.py --language both --test

# OR train individually
python train_model.py --language english
python train_model.py --language japanese
```

Models saved to: `models/english/final/` and `models/japanese/final/`

## 4. Compress Models (5-10 minutes)

```bash
python compress_model.py --language both
```

Compressed models saved to: `models/*/compressed/`

## 5. iOS Integration

1. Open `custom-keyboard-ios.xcodeproj` in Xcode
2. Drag `ios_components/` folder into project
3. Add App Group capability: `group.com.keyboard.llm`
4. Copy compressed models to project bundle
5. Build and run on device (iOS 15+)

## Common Issues

**"Module not found"**: Activate venv first: `source venv/bin/activate`

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
