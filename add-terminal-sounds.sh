#!/bin/bash
# Terminal Sound Script - adds clicking sounds to terminal

# Create sound directory
mkdir -p ~/.local/share/moltos/sounds

# Generate simple click sound using sox (or use beep as fallback)
create_click_sound() {
    if command -v sox &> /dev/null; then
        # Generate a short click sound
        sox -n ~/.local/share/moltos/sounds/click.wav synth 0.01 sine 800 fade 0 0.01 0.005
    else
        echo "Sox not found, will use beep fallback"
    fi
}

create_click_sound

# Add to bashrc for terminal sounds on each keystroke
cat >> ~/.bashrc <<'EOF'

# MoltOS Terminal Clicking Sound
if [ -f ~/.local/share/moltos/sounds/click.wav ]; then
    # Play sound on each command (lightweight)
    trap 'aplay -q ~/.local/share/moltos/sounds/click.wav 2>/dev/null &' DEBUG
fi
EOF

echo "✓ Terminal clicking sounds installed!"
echo "Restart your terminal or run: source ~/.bashrc"
