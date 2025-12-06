#!/bin/bash

# Setup script for LLM Local Keyboard project
# Run this first to set up your environment

set -e  # Exit on error

echo "🚀 Setting up LLM Local Keyboard project..."
echo ""

# Check Python version
echo "1️⃣  Checking Python version..."
python3 --version || { echo "❌ Python 3 not found. Please install Python 3.8+"; exit 1; }
echo "✅ Python found"
echo ""

# Create virtual environment
echo "2️⃣  Creating virtual environment..."
if [ -d "venv" ]; then
    echo "⚠️  venv already exists, skipping..."
else
    python3 -m venv venv
    echo "✅ Virtual environment created"
fi
echo ""

# Activate virtual environment
echo "3️⃣  Activating virtual environment..."
source venv/bin/activate
echo "✅ Virtual environment activated"
echo ""

# Install dependencies
echo "4️⃣  Installing Python dependencies..."
echo "   (This may take a few minutes...)"
pip install --upgrade pip > /dev/null 2>&1
pip install -r requirements.txt
echo "✅ Dependencies installed"
echo ""

# Test data loader
echo "5️⃣  Testing data loader..."
python data_loader.py > /dev/null 2>&1
echo "✅ Data loader works"
echo ""

# Create models directory
echo "6️⃣  Creating models directory..."
mkdir -p models
echo "✅ Models directory ready"
echo ""

echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Activate venv: source venv/bin/activate"
echo "  2. Train tiny models: python train_tiny_model.py --language both --epochs 20"
echo "  3. Compress models: python compress_model.py --language both"
echo ""
echo "See QUICKSTART.md for more details."
