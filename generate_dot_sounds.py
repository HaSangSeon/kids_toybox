import wave
import math
import struct

def generate_wav(filename, samples, sample_rate=44100):
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        for s in samples:
            # clip to [-1, 1]
            s = max(-1.0, min(1.0, s))
            # convert to 16-bit integer
            v = int(s * 32767.0)
            wav_file.writeframes(struct.pack('<h', v))

sample_rate = 44100

# 1. dot_start.wav - Cute Bubble Plop
samples = []
duration = 0.15
for i in range(int(sample_rate * duration)):
    t = i / sample_rate
    # frequency sweeps from 300 to 900
    freq = 300 + 600 * (t / duration)
    # amplitude envelope
    env = math.sin(math.pi * (t / duration))
    val = env * 0.8 * math.sin(2.0 * math.pi * freq * t)
    samples.append(val)
generate_wav('assets/audio/dot_start.wav', samples)

# 2. dot_connect.wav - Marimba / Glockenspiel note (C5 - 523.25 Hz)
samples = []
duration = 0.5
freq = 523.25
for i in range(int(sample_rate * duration)):
    t = i / sample_rate
    # exponential decay
    env = math.exp(-t * 10)
    # fundamental + slight harmonic
    val = env * 0.6 * (math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(2.0 * math.pi * freq * 2 * t))
    samples.append(val)
generate_wav('assets/audio/dot_connect.wav', samples)

# 3. dot_success.wav - Magical Arpeggio (C5, E5, G5, C6)
samples = []
duration = 1.5
notes = [523.25, 659.25, 783.99, 1046.50]
for i in range(int(sample_rate * duration)):
    t = i / sample_rate
    val = 0
    for j, f in enumerate(notes):
        start_t = j * 0.1
        if t >= start_t:
            local_t = t - start_t
            env = math.exp(-local_t * 5)
            val += env * 0.3 * math.sin(2.0 * math.pi * f * local_t)
    samples.append(val)
generate_wav('assets/audio/dot_success.wav', samples)

print("Generated dot_start.wav, dot_connect.wav, dot_success.wav")
