import wave
import math
import struct

def generate_wav(filename, samples, sample_rate=44100):
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        for s in samples:
            s = max(-1.0, min(1.0, s))
            v = int(s * 32767.0)
            wav_file.writeframes(struct.pack('<h', v))

sample_rate = 44100

# 1. jigsaw_pickup.wav - Cute soft pop
samples = []
duration = 0.1
for i in range(int(sample_rate * duration)):
    t = i / sample_rate
    # fast frequency sweep 400 to 900
    freq = 400 + 500 * (t / duration)
    env = math.sin(math.pi * (t / duration))
    val = env * 0.4 * math.sin(2.0 * math.pi * freq * t)
    samples.append(val)
generate_wav('assets/audio/jigsaw_pickup.wav', samples)

# 2. jigsaw_snap_correct.wav - Solid wooden block click
samples = []
duration = 0.15
for i in range(int(sample_rate * duration)):
    t = i / sample_rate
    # exponential decay
    env = math.exp(-t * 35)
    # fundamental 250Hz + strong harmonics for wooden character
    val = env * 0.6 * (math.sin(2.0 * math.pi * 250 * t) + 
                       0.5 * math.sin(2.0 * math.pi * 500 * t) + 
                       0.25 * math.sin(2.0 * math.pi * 750 * t))
    samples.append(val)
generate_wav('assets/audio/jigsaw_snap_correct.wav', samples)

# 3. jigsaw_snap_incorrect.wav - Funny spring/boing
samples = []
duration = 0.3
for i in range(int(sample_rate * duration)):
    t = i / sample_rate
    # descending pitch + vibrato
    freq = 300 - 150 * (t / duration) + 20 * math.sin(t * 80)
    env = math.sin(math.pi * (t / duration))
    val = env * 0.4 * math.sin(2.0 * math.pi * freq * t)
    samples.append(val)
generate_wav('assets/audio/jigsaw_snap_incorrect.wav', samples)

# 4. jigsaw_success.wav - Sweet Glockenspiel Fanfare
samples = []
duration = 1.8
# Cute progression of notes (C5, G5, C6) with sparkle
notes = [523.25, 783.99, 1046.50]
for i in range(int(sample_rate * duration)):
    t = i / sample_rate
    val = 0
    for j, f in enumerate(notes):
        start_t = j * 0.15
        if t >= start_t:
            local_t = t - start_t
            env = math.exp(-local_t * 5)
            val += env * 0.3 * math.sin(2.0 * math.pi * f * local_t)
            val += env * 0.15 * math.sin(2.0 * math.pi * f * 1.5 * local_t) # perfect fifth harmonic
    samples.append(val)
generate_wav('assets/audio/jigsaw_success.wav', samples)

print("Generated jigsaw sounds successfully.")
