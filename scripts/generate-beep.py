#!/usr/bin/env python3
"""
Generate DOXos 3-Beep Chime (Clean 880Hz A5 Tri-Tone)
"""
import wave
import math
import struct
import os

sample_rate = 44100
beep_duration = 0.08    # 80ms per beep
pause_duration = 0.05   # 50ms pause between beeps
frequency = 880.0       # Crisp A5 tone

frames = []

for b in range(3):
    total_samples = int(sample_rate * beep_duration)
    for s in range(total_samples):
        # Linear fade-in / fade-out to prevent audio pops
        env = min(1.0, s / (0.01 * sample_rate), (total_samples - s) / (0.01 * sample_rate))
        val = int(32767 * 0.45 * env * math.sin(2.0 * math.pi * frequency * (s / sample_rate)))
        frames.append(struct.pack('<h', val))
    
    if b < 2:
        for _ in range(int(sample_rate * pause_duration)):
            frames.append(struct.pack('<h', 0))

output_dir = "/usr/share/sounds/doxos"
os.makedirs(output_dir, exist_ok=True)
output_path = os.path.join(output_dir, "doxos-beep.wav")

with wave.open(output_path, "wb") as wf:
    wf.setnchannels(1)
    wf.setsampwidth(2)
    wf.setframerate(sample_rate)
    wf.writeframes(b"".join(frames))

print(f"Generated DOXos 3-beep sound at: {output_path}")
