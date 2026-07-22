import wave
import math
import struct
import random

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

def create_dog():
    # Dog bark: woof woof (two short bursts of low-mid pitch sweep)
    samples = []
    for burst in range(2):
        duration = 0.12
        for i in range(int(sample_rate * duration)):
            t = i / sample_rate
            freq = 150 + 200 * math.exp(-t * 20)
            env = math.sin(math.pi * (t / duration))
            # noise addition for growl texture
            noise = random.uniform(-0.15, 0.15)
            val = env * 0.6 * (math.sin(2.0 * math.pi * freq * t) + noise)
            samples.append(val)
        # silent gap
        samples.extend([0] * int(sample_rate * 0.05))
    return samples

def create_cat():
    # Cat meow: sliding frequency up and down
    samples = []
    duration = 0.4
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        # meow shape: start high, dip down, go back up
        if t < 0.15:
            freq = 600 + (t / 0.15) * 200
        else:
            freq = 800 - ((t - 0.15) / 0.25) * 300
        env = math.sin(math.pi * (t / duration))
        val = env * 0.5 * (math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(2.0 * math.pi * freq * 2 * t))
        samples.append(val)
    return samples

def create_rabbit():
    # Rabbit squeak: short high-pitched chirp
    samples = []
    duration = 0.08
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        freq = 1200 + 400 * math.sin(t * 50)
        env = math.sin(math.pi * (t / duration))
        val = env * 0.4 * math.sin(2.0 * math.pi * freq * t)
        samples.append(val)
    return samples

def create_bear():
    # Bear growl: low pitch noise rumble
    samples = []
    duration = 0.5
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        env = math.sin(math.pi * (t / duration))
        # low pass filter approximation for growl noise
        val = env * 0.6 * (random.uniform(-0.4, 0.4) + 0.3 * math.sin(2.0 * math.pi * 80 * t))
        samples.append(val)
    return samples

def create_whale():
    # Whale: echoing whistle
    samples = []
    duration = 0.8
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        freq = 300 + 100 * math.sin(t * 5)
        env = math.sin(math.pi * (t / duration))
        val = env * 0.5 * (math.sin(2.0 * math.pi * freq * t) + 0.1 * math.sin(2.0 * math.pi * freq * 1.5 * t))
        samples.append(val)
    return samples

def create_octopus():
    # Octopus: Bloop bloop
    samples = []
    for b in range(2):
        duration = 0.15
        for i in range(int(sample_rate * duration)):
            t = i / sample_rate
            # sine wave sweeping upwards fast
            freq = 200 + 600 * (t / duration)
            env = math.exp(-t * 15)
            val = env * 0.6 * math.sin(2.0 * math.pi * freq * t)
            samples.append(val)
        samples.extend([0] * int(sample_rate * 0.06))
    return samples

def create_crab():
    # Crab: click click
    samples = []
    for c in range(3):
        duration = 0.03
        for i in range(int(sample_rate * duration)):
            t = i / sample_rate
            env = math.exp(-t * 100)
            val = env * 0.7 * random.uniform(-0.8, 0.8)
            samples.append(val)
        samples.extend([0] * int(sample_rate * 0.04))
    return samples

def create_turtle():
    # Turtle: soft splash
    samples = []
    duration = 0.25
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        env = math.sin(math.pi * (t / duration))
        # noise for splash
        val = env * 0.4 * random.uniform(-0.5, 0.5)
        samples.append(val)
    return samples

def create_apple():
    # Apple: crunch!
    samples = []
    duration = 0.2
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        env = math.exp(-t * 20)
        # crunch sound is sharp noise burst
        val = env * 0.7 * random.uniform(-0.9, 0.9)
        samples.append(val)
    return samples

def create_banana():
    # Banana: peel (zipper sound)
    samples = []
    duration = 0.3
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        env = math.sin(math.pi * (t / duration))
        freq = 800 - 600 * (t / duration)
        val = env * 0.4 * math.sin(2.0 * math.pi * freq * t)
        samples.append(val)
    return samples

def create_grape():
    # Grape: pop!
    samples = []
    duration = 0.08
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        freq = 300 + 400 * (t / duration)
        env = math.sin(math.pi * (t / duration))
        val = env * 0.6 * math.sin(2.0 * math.pi * freq * t)
        samples.append(val)
    return samples

def create_strawberry():
    # Strawberry: munch
    samples = []
    duration = 0.15
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        env = math.exp(-t * 25)
        val = env * 0.6 * random.uniform(-0.7, 0.7)
        samples.append(val)
    return samples

def create_car():
    # Car: honk honk!
    samples = []
    for h in range(2):
        duration = 0.15
        for i in range(int(sample_rate * duration)):
            t = i / sample_rate
            # Honk is dual frequency sine wave around 440Hz + 550Hz
            val = 0.3 * (math.sin(2.0 * math.pi * 440 * t) + math.sin(2.0 * math.pi * 554.37 * t))
            env = math.sin(math.pi * (t / duration))
            samples.append(val * env)
        samples.extend([0] * int(sample_rate * 0.05))
    return samples

def create_plane():
    # Plane: jet swoosh
    samples = []
    duration = 0.6
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        env = math.sin(math.pi * (t / duration))
        # jet swoosh is white noise filtered
        val = env * 0.5 * random.uniform(-0.6, 0.6)
        samples.append(val)
    return samples

def create_ship():
    # Ship: deep foghorn
    samples = []
    duration = 0.7
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        env = math.sin(math.pi * (t / duration))
        # foghorn: 100Hz + 150Hz
        val = env * 0.6 * (math.sin(2.0 * math.pi * 100 * t) + 0.5 * math.sin(2.0 * math.pi * 150 * t))
        samples.append(val)
    return samples

def create_train():
    # Train: choo choo!
    samples = []
    for c in range(2):
        duration = 0.2
        for i in range(int(sample_rate * duration)):
            t = i / sample_rate
            # steam whistle: 800Hz + 1200Hz
            val = 0.35 * (math.sin(2.0 * math.pi * 880 * t) + math.sin(2.0 * math.pi * 1200 * t))
            env = math.sin(math.pi * (t / duration))
            samples.append(val * env)
        samples.extend([0] * int(sample_rate * 0.08))
    return samples

# Generate all
generate_wav('assets/audio/jigsaw_sound_dog.wav', create_dog())
generate_wav('assets/audio/jigsaw_sound_cat.wav', create_cat())
generate_wav('assets/audio/jigsaw_sound_rabbit.wav', create_rabbit())
generate_wav('assets/audio/jigsaw_sound_bear.wav', create_bear())
generate_wav('assets/audio/jigsaw_sound_whale.wav', create_whale())
generate_wav('assets/audio/jigsaw_sound_octopus.wav', create_octopus())
generate_wav('assets/audio/jigsaw_sound_crab.wav', create_crab())
generate_wav('assets/audio/jigsaw_sound_turtle.wav', create_turtle())
generate_wav('assets/audio/jigsaw_sound_apple.wav', create_apple())
generate_wav('assets/audio/jigsaw_sound_banana.wav', create_banana())
generate_wav('assets/audio/jigsaw_sound_grape.wav', create_grape())
generate_wav('assets/audio/jigsaw_sound_strawberry.wav', create_strawberry())
generate_wav('assets/audio/jigsaw_sound_car.wav', create_car())
generate_wav('assets/audio/jigsaw_sound_plane.wav', create_plane())
generate_wav('assets/audio/jigsaw_sound_ship.wav', create_ship())
generate_wav('assets/audio/jigsaw_sound_train.wav', create_train())

print("Generated all 16 emoji sounds.")
