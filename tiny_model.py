"""
Tiny Model Architecture for Keyboard Prediction

This creates a custom tiny transformer model specifically for keyboard use.
Target: <10M parameters, <50MB final size

Key differences from standard models:
- Much smaller vocabulary (5000 vs 50000)
- Fewer layers (2 vs 6-12)
- Smaller hidden size (128 vs 768)
- Optimized for next-word prediction only
"""

import torch
import torch.nn as nn
from transformers import PreTrainedModel, PretrainedConfig
from typing import Optional, Tuple
import json
from pathlib import Path


class TinyKeyboardConfig(PretrainedConfig):
    """Configuration for tiny keyboard model."""
    
    model_type = "tiny_keyboard"
    
    def __init__(
        self,
        vocab_size=5000,
        hidden_size=128,
        num_hidden_layers=2,
        num_attention_heads=4,
        intermediate_size=256,
        max_position_embeddings=64,
        **kwargs
    ):
        super().__init__(**kwargs)
        self.vocab_size = vocab_size
        self.hidden_size = hidden_size
        self.num_hidden_layers = num_hidden_layers
        self.num_attention_heads = num_attention_heads
        self.intermediate_size = intermediate_size
        self.max_position_embeddings = max_position_embeddings


class TinyTransformerBlock(nn.Module):
    """Lightweight transformer block."""
    
    def __init__(self, config):
        super().__init__()
        self.attention = nn.MultiheadAttention(
            config.hidden_size,
            config.num_attention_heads,
            batch_first=True
        )
        self.norm1 = nn.LayerNorm(config.hidden_size)
        self.norm2 = nn.LayerNorm(config.hidden_size)
        
        self.ffn = nn.Sequential(
            nn.Linear(config.hidden_size, config.intermediate_size),
            nn.GELU(),
            nn.Linear(config.intermediate_size, config.hidden_size),
        )
    
    def forward(self, x):
        # Self-attention with residual
        attn_out, _ = self.attention(x, x, x, need_weights=False)
        x = self.norm1(x + attn_out)
        
        # FFN with residual
        ffn_out = self.ffn(x)
        x = self.norm2(x + ffn_out)
        
        return x


class TinyKeyboardModel(PreTrainedModel):
    """Tiny model for keyboard prediction."""
    
    config_class = TinyKeyboardConfig
    
    def __init__(self, config):
        super().__init__(config)
        self.config = config
        
        # Embeddings
        self.token_embedding = nn.Embedding(config.vocab_size, config.hidden_size)
        self.position_embedding = nn.Embedding(config.max_position_embeddings, config.hidden_size)
        
        # Transformer blocks
        self.blocks = nn.ModuleList([
            TinyTransformerBlock(config)
            for _ in range(config.num_hidden_layers)
        ])
        
        # Output
        self.norm = nn.LayerNorm(config.hidden_size)
        self.lm_head = nn.Linear(config.hidden_size, config.vocab_size, bias=False)
        
        # Initialize weights
        self.apply(self._init_weights)
    
    def _init_weights(self, module):
        if isinstance(module, nn.Linear):
            torch.nn.init.normal_(module.weight, mean=0.0, std=0.02)
            if module.bias is not None:
                torch.nn.init.zeros_(module.bias)
        elif isinstance(module, nn.Embedding):
            torch.nn.init.normal_(module.weight, mean=0.0, std=0.02)
    
    def forward(self, input_ids, labels=None):
        batch_size, seq_len = input_ids.shape
        
        # Get embeddings
        token_emb = self.token_embedding(input_ids)
        positions = torch.arange(seq_len, device=input_ids.device).unsqueeze(0)
        pos_emb = self.position_embedding(positions)
        
        x = token_emb + pos_emb
        
        # Apply transformer blocks
        for block in self.blocks:
            x = block(x)
        
        x = self.norm(x)
        logits = self.lm_head(x)
        
        # Calculate loss if labels provided
        loss = None
        if labels is not None:
            loss_fct = nn.CrossEntropyLoss()
            loss = loss_fct(logits.view(-1, self.config.vocab_size), labels.view(-1))
        
        return {"loss": loss, "logits": logits}
    
    def generate(self, input_ids, max_length=20, temperature=1.0, top_k=50):
        """Simple generation for testing."""
        self.eval()
        
        with torch.no_grad():
            for _ in range(max_length - input_ids.shape[1]):
                outputs = self.forward(input_ids)
                logits = outputs["logits"][:, -1, :] / temperature
                
                # Top-k sampling
                top_k_logits, top_k_indices = torch.topk(logits, top_k)
                probs = torch.softmax(top_k_logits, dim=-1)
                next_token = top_k_indices.gather(-1, torch.multinomial(probs, 1))
                
                input_ids = torch.cat([input_ids, next_token], dim=1)
        
        return input_ids


def count_parameters(model):
    """Count model parameters."""
    return sum(p.numel() for p in model.parameters() if p.requires_grad)


def get_model_size_mb(model):
    """Get model size in MB."""
    param_size = sum(p.nelement() * p.element_size() for p in model.parameters())
    buffer_size = sum(b.nelement() * b.element_size() for b in model.buffers())
    return (param_size + buffer_size) / 1024 / 1024


if __name__ == "__main__":
    # Test the model
    print("Creating tiny keyboard model...")
    
    config = TinyKeyboardConfig(
        vocab_size=5000,
        hidden_size=128,
        num_hidden_layers=2,
        num_attention_heads=4,
        intermediate_size=256,
        max_position_embeddings=64,
    )
    
    model = TinyKeyboardModel(config)
    
    params = count_parameters(model)
    size_mb = get_model_size_mb(model)
    
    print(f"\n✅ Model created!")
    print(f"   Parameters: {params:,} ({params/1e6:.2f}M)")
    print(f"   Size: {size_mb:.2f} MB")
    print(f"   Target after compression: ~{size_mb * 0.5:.2f} MB (50% reduction)")
    
    # Test forward pass
    batch_size = 2
    seq_len = 10
    input_ids = torch.randint(0, config.vocab_size, (batch_size, seq_len))
    labels = torch.randint(0, config.vocab_size, (batch_size, seq_len))
    
    outputs = model(input_ids, labels=labels)
    print(f"\n✅ Forward pass successful!")
    print(f"   Loss: {outputs['loss'].item():.4f}")
    print(f"   Logits shape: {outputs['logits'].shape}")
    
    # Save model
    output_dir = Path("models/tiny_test")
    output_dir.mkdir(parents=True, exist_ok=True)
    model.save_pretrained(output_dir)
    config.save_pretrained(output_dir)
    
    print(f"\n✅ Model saved to: {output_dir}")
