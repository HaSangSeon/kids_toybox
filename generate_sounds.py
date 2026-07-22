import wave
import math
import struct
import random
import os

SAMPLE_RATE = 44100
MAX_AMP = 32767.0

def save_wav(filename, samples):
    with wave.open(filename, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SAMPLE_RATE)
        for s in samples:
            # Clamp
            s = max(-1.0, min(1.0, s))
            data = struct.pack('<h', int(s * MAX_AMP))
            f.writeframesraw(data)

def generate_jump():
    samples = []
    duration = 0.2
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        freq = 400 + (t / duration) * 800
        val = math.sin(2 * math.pi * freq * t)
        env = 1.0 - (t / duration)
        samples.append(val * env * 0.5)
    return samples

def generate_engine():
    samples = []
    duration = 1.0
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        freq = 100 + math.sin(2 * math.pi * 5 * t) * 10
        val = math.sin(2 * math.pi * freq * t) + (random.random() * 0.2 - 0.1)
        samples.append(val * 0.4)
    return samples

def generate_thud():
    samples = []
    duration = 0.15
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        freq = 150 - (t / duration) * 100
        val = math.sin(2 * math.pi * freq * t)
        env = (1.0 - (t / duration)) ** 3
        samples.append(val * env * 0.8)
    return samples

def generate_crash():
    samples = []
    duration = 0.5
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        val = random.random() * 2.0 - 1.0
        env = (1.0 - (t / duration)) ** 4
        samples.append(val * env * 0.6)
    return samples

def generate_splash():
    samples = []
    duration = 0.3
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        val = random.random() * 2.0 - 1.0
        env = (1.0 - (t / duration)) ** 2
        # mix with sine
        freq = 300 - (t / duration) * 100
        val2 = math.sin(2 * math.pi * freq * t)
        samples.append((val * 0.6 + val2 * 0.4) * env * 0.6)
    return samples

def generate_reel():
    samples = []
    duration = 0.5
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        # clicking
        click = 1.0 if (i % 2000) < 100 else 0.0
        samples.append(click * 0.3)
    return samples

def generate_scribble():
    samples = []
    duration = 0.4
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        val = (random.random() * 2.0 - 1.0) * math.sin(2 * math.pi * 10 * t)
        samples.append(val * 0.3)
    return samples

def generate_snap():
    samples = []
    duration = 0.05
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        freq = 800
        val = math.sin(2 * math.pi * freq * t)
        env = 1.0 - (t / duration)
        samples.append(val * env * 0.7)
    return samples

def generate_squeak():
    samples = []
    duration = 0.1
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        freq = 1500 + (t / duration) * 500
        val = math.sin(2 * math.pi * freq * t)
        env = 1.0 - (t / duration)
        samples.append(val * env * 0.5)
    return samples

def generate_munch():
    samples = []
    duration = 0.15
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        # amplitude modulation
        amp = abs(math.sin(2 * math.pi * 20 * t))
        val = (random.random() * 2.0 - 1.0) * amp
        env = 1.0 - (t / duration)
        samples.append(val * env * 0.4)
    return samples

def generate_boing():
    samples = []
    duration = 0.3
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        freq = 300 + math.sin(2 * math.pi * 5 * t) * 200
        val = math.sin(2 * math.pi * freq * t)
        env = 1.0 - (t / duration)
        samples.append(val * env * 0.6)
    return samples

def generate_chime():
    samples = []
    duration = 0.5
    for i in range(int(SAMPLE_RATE * duration)):
        t = i / SAMPLE_RATE
        val1 = math.sin(2 * math.pi * 800 * t)
        val2 = math.sin(2 * math.pi * 1200 * t)
        env = math.exp(-t * 5)
        samples.append((val1 + val2) * 0.5 * env * 0.5)
    return samples

if __name__ == '__main__':
    out_dir = '/Users/hasangseon/kids_toybox/assets/audio'
    os.makedirs(out_dir, exist_ok=True)
    
    save_wav(os.path.join(out_dir, 'jump.wav'), generate_jump())
    save_wav(os.path.join(out_dir, 'engine.wav'), generate_engine())
    save_wav(os.path.join(out_dir, 'thud.wav'), generate_thud())
    save_wav(os.path.join(out_dir, 'crash.wav'), generate_crash())
    save_wav(os.path.join(out_dir, 'splash.wav'), generate_splash())
    save_wav(os.path.join(out_dir, 'reel.wav'), generate_reel())
    save_wav(os.path.join(out_dir, 'scribble.wav'), generate_scribble())
    save_wav(os.path.join(out_dir, 'snap.wav'), generate_snap())
    save_wav(os.path.join(out_dir, 'squeak.wav'), generate_squeak())
    save_wav(os.path.join(out_dir, 'munch.wav'), generate_munch())
    save_wav(os.path.join(out_dir, 'boing.wav'), generate_boing())
    save_wav(os.path.join(out_dir, 'chime.wav'), generate_chime())
    
    print("Generated all audio files.")
