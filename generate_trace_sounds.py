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

# 1. trace_start.wav - Cute Magic Spark Start
samples = []
duration = 0.25
for i in range(int(sample_rate * duration)):
    t = i / sample_rate
    # Dual sine wave frequency sweep (glissando up)
    freq = 600 + 400 * (t / duration)
    freq2 = 1200 + 800 * (t / duration)
    env = math.sin(math.pi * (t / duration))
    val = env * 0.4 * (math.sin(2.0 * math.pi * freq * t) + 0.5 * math.sin(2.0 * math.pi * freq2 * t))
    samples.append(val)
generate_wav('assets/audio/trace_start.wav', samples)

# 2. trace_draw.wav - Cute Crayon Squeak
samples = []
duration = 0.15
for i in range(int(sample_rate * duration)):
    t = i / sample_rate
    # Crayon friction sound (some noise + pitch change)
    freq = 800 + 100 * math.sin(t * 100)
    env = math.exp(-t * 20)
    # Add a bit of white-noise style grit for crayon texture
    noise = (math.sin(t * 100000) * 0.1) if (i % 2 == 0) else 0.0
    val = env * 0.5 * (math.sin(2.0 * math.pi * freq * t) + noise)
    samples.append(val)
generate_wav('assets/audio/trace_draw.wav', samples)

# 3. trace_success.wav - Very Cute Happy Melody (Tada!)
samples = []
duration = 1.6
# ascending happy major notes (C5, E5, G5, C6) with short cute envelope
notes = [523.25, 659.25, 783.99, 1046.50, 1318.51] # C, E, G, C, E
for i in range(int(sample_rate * duration)):
    t = i / sample_rate
    val = 0
    for j, f in enumerate(notes):
        start_t = j * 0.12
        if t >= start_t:
            local_t = t - start_t
            env = math.exp(-local_t * 6)
            # soft xylophone sound
            val += env * 0.25 * math.sin(2.0 * math.pi * f * local_t)
            # add warm 2nd harmonic
            val += env * 0.08 * math.sin(2.0 * math.pi * f * 2 * local_t)
    samples.append(val)
generate_wav('assets/audio/trace_success.wav', samples)

print("Generated trace sounds successfully.")
