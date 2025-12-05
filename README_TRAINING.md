# LLM Local Keyboard - Python Training Scripts

This directory contains Python scripts for training and compressing language models for the iOS keyboard.

## Prerequisites

- Python 3.8 or higher
- pip (Python package manager)
- (Optional) CUDA-capable GPU for faster training

## Installation

1. **Create a virtual environment** (recommended):
```bash
python -m venv venv
source venv/bin/activate  # On macOS/Linux
# or
venv\Scripts\activate  # On Windows
```

2. **Install dependencies**:
```bash
pip install -r requirements.txt
```

## Usage

### 1. Verify Training Data

First, check that your training data is loaded correctly:

```bash
python data_loader.py
```

This will display statistics about your English and Japanese training data.

### 2. Train Models

Train both English and Japanese models:

```bash
python train_model.py --language both
```

Or train a specific language:

```bash
python train_model.py --language english
python train_model.py --language japanese
```

Add `--test` flag to test predictions after training:

```bash
python train_model.py --language both --test
```

**Note**: With only 80 examples per language, the models will have limited accuracy. For production use, you need thousands of examples.

### 3. Compress Models

After training, compress the models for iOS deployment:

```bash
python compress_model.py --language both
```

This will apply:
- Quantization (8-bit, upgradeable to 4-bit)
- Weight pruning (30%)
- Vocabulary compression
- LZMA compression

Target: Reduce model size by 70-80%

### 4. Convert to CoreML (Coming Soon)

```bash
python convert_to_coreml.py --language both
```

This will convert the compressed models to CoreML format for iOS.

## File Structure

```
.
├── requirements.txt          # Python dependencies
├── data_loader.py           # Training data loader
├── train_model.py           # Model training script
├── compress_model.py        # Model compression pipeline
├── convert_to_coreml.py     # CoreML conversion (TODO)
├── training_data/           # Training data directory
│   ├── english/
│   └── japanese/
└── models/                  # Output directory (created during training)
    ├── english/
    │   ├── final/          # Trained model
    │   └── compressed/     # Compressed model
    └── japanese/
        ├── final/
        └── compressed/
```

## Training Tips

### Improving Model Accuracy

1. **Add more training data**: The current 80 examples per language is just a starter. Aim for:
   - Minimum: 1,000 examples per language
   - Recommended: 10,000+ examples per language
   - Production: 100,000+ examples per language

2. **Diversify your data**: Include various:
   - Writing styles (formal, casual, technical)
   - Topics (daily life, work, hobbies)
   - Sentence lengths (short and long)
   - Common typos and corrections

3. **Balance categories**: Ensure similar amounts of data across all categories

4. **Use quality data**: Natural, grammatically correct, commonly-used phrases

### Training Parameters

Edit `train_model.py` to adjust:

```python
'num_train_epochs': 10,      # More epochs for larger datasets
'batch_size': 4,             # Increase if you have more GPU memory
'learning_rate': 5e-5,       # Tune based on validation loss
```

### Compression Trade-offs

In `compress_model.py`, you can adjust:

```python
amount=0.3  # Pruning amount (0.3 = 30% of weights removed)
```

Higher pruning = smaller model but potentially lower accuracy.

## GPU Acceleration

If you have a CUDA-capable GPU:

```bash
# Check if PyTorch detects your GPU
python -c "import torch; print(torch.cuda.is_available())"
```

Training will automatically use GPU if available.

## Troubleshooting

### Issue: "Model not found"
**Solution**: Train the model first with `python train_model.py`

### Issue: "Out of memory"
**Solution**: Reduce batch size in `train_model.py`

### Issue: "Poor prediction quality"
**Solution**: Add more training data (current 80 examples is too small)

### Issue: "Slow training"
**Solution**: 
- Use GPU if available
- Reduce number of epochs
- Use smaller base model

## Performance Benchmarks

With current setup (80 examples):
- Training time: ~5-10 minutes per language (CPU)
- Model size before compression: ~100-150 MB
- Model size after compression: ~30-50 MB
- Prediction accuracy: Limited (need more data)

With production setup (10,000+ examples):
- Training time: ~1-2 hours per language (GPU)
- Model size before compression: ~200-300 MB
- Model size after compression: ~40-60 MB
- Prediction accuracy: Good

## Next Steps

1. ✅ Train initial models with starter data
2. ✅ Compress models to <50MB
3. ⏳ Convert to CoreML format
4. ⏳ Implement model encryption
5. ⏳ Integrate with iOS keyboard app
6. ⏳ Expand training dataset
7. ⏳ Fine-tune compression parameters

## Resources

- [Hugging Face Transformers](https://huggingface.co/docs/transformers)
- [PyTorch Quantization](https://pytorch.org/docs/stable/quantization.html)
- [CoreML Tools](https://coremltools.readme.io/)
- [Model Compression Techniques](https://arxiv.org/abs/2106.08295)

## License

This project is for development and testing purposes.
