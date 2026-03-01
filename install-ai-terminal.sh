#!/bin/bash
# Quick AI Terminal Installer for Current System
# Installs llama.cpp + NanoPi 1.5B + terminal sounds

set -e

echo "🧠 Installing MoltOS AI Terminal on your current system..."

# 1. Install dependencies
echo "Installing dependencies..."
sudo apt update
sudo apt install -y git build-essential cmake curl wget jq

# 2. Clone and build llama.cpp
if [ ! -d "/opt/llama.cpp" ]; then
    echo "Building llama.cpp with CMake..."
    cd /opt
    sudo git clone https://github.com/ggerganov/llama.cpp.git
    cd llama.cpp
    sudo mkdir -p build
    cd build
    sudo cmake .. -DGGML_CUDA=OFF
    sudo cmake --build . --config Release -j$(nproc)
    sudo cp bin/llama-cli /usr/local/bin/llama-cli
    sudo cp bin/llama-server /usr/local/bin/llama-server
else
    echo "✓ llama.cpp already installed"
fi

# 3. Download NanoPi 1.5B (quantized)
sudo mkdir -p /opt/moltos/models
cd /opt/moltos/models

if [ ! -f "qwen2.5-1.5b-instruct-q4_k_m.gguf" ]; then
    echo "Downloading NanoPi 1.5B model (~900MB)..."
    sudo wget -q --show-progress \
        https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf
else
    echo "✓ NanoPi model already downloaded"
fi

# 4. Create systemd service
echo "Creating AI server service..."
sudo tee /etc/systemd/system/moltos-ai.service > /dev/null <<'EOF'
[Unit]
Description=MoltOS AI Server
After=network.target

[Service]
Type=simple
User=cube
ExecStart=/usr/local/bin/llama-server \
    --model /opt/moltos/models/qwen2.5-1.5b-instruct-q4_k_m.gguf \
    --host 127.0.0.1 \
    --port 8765 \
    --ctx-size 2048 \
    --threads 4
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable moltos-ai
sudo systemctl start moltos-ai

echo "✓ AI server started"

# 5. Create nanopi terminal command
sudo tee /usr/local/bin/nanopi > /dev/null <<'NANOCMD'
#!/bin/bash
# NanoPi - Photonic Intelligence

PROMPT="$*"
if [ -z "$PROMPT" ]; then
    echo "Usage: nanopi '<your question>'"
    exit 1
fi

curl -s -X POST http://localhost:8765/completion \
    -H "Content-Type: application/json" \
    -d "{
        \"prompt\": \"<|im_start|>system\nYou are NanoPi, a helpful AI assistant integrated into MoltOS. You provide concise, accurate answers to help users with their Linux and development tasks.<|im_end|>\n<|im_start|>user\n$PROMPT<|im_end|>\n<|im_start|>assistant\",
        \"temperature\": 0.7,
        \"max_tokens\": 300,
        \"stop\": [\"<|im_end|>\"]
    }" | jq -r '.content'
NANOCMD

sudo chmod +x /usr/local/bin/nanopi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Try it: nanopi 'how do I check disk space?'"
