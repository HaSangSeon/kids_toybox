import wave
import math
import struct
import random

def write_wav(filename, samples, sample_rate=44100):
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        for s in samples:
            wav_file.writeframes(struct.pack('<h', int(max(-32768, min(32767, s * 32767)))))

def make_pop():
    sr = 44100
    duration = 0.05
    samples = []
    for i in range(int(sr * duration)):
        t = i / sr
        freq = 400 + (400 * (t / duration)) # sweep 400 to 800
        val = 0.5 * math.sin(2 * math.pi * freq * t)
        env = math.exp(-t * 80)
        samples.append(val * env)
    write_wav("assets/audio/maze_move.wav", samples)

def make_bump():
    sr = 44100
    duration = 0.1
    samples = []
    for i in range(int(sr * duration)):
        t = i / sr
        freq = 150 - (100 * (t / duration)) # sweep 150 down to 50
        val = 0.8 * math.sin(2 * math.pi * freq * t)
        noise = random.uniform(-0.2, 0.2)
        val += noise
        env = math.exp(-t * 40)
        samples.append(val * env)
    write_wav("assets/audio/maze_bump.wav", samples)

def make_clear():
    sr = 44100
    notes = [523.25, 659.25, 783.99, 1046.50]
    durations = [0.1, 0.1, 0.1, 0.4]
    samples = []
    for note, dur in zip(notes, durations):
        for i in range(int(sr * dur)):
            t = i / sr
            val = 0.5 * math.sin(2 * math.pi * note * t)
            env = math.exp(-t * 10)
            samples.append(val * env)
    write_wav("assets/audio/maze_clear.wav", samples)

make_pop()
make_bump()
make_clear()
print("Maze sounds created.")
