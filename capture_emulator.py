import os
import time
import subprocess
from PIL import Image

ADB_PATH = '/Users/hasangseon/Library/Android/sdk/platform-tools/adb'
OUTPUT_DIR = '/Users/hasangseon/kids_toybox/build/emulator_raw_screens'
os.makedirs(OUTPUT_DIR, exist_ok=True)

screens = [
    ('01_lobby', 4),
    ('02_car_wash', 6),
    ('03_firefighter', 6),
    ('04_feed_animals', 6),
    ('05_slide_puzzle', 6),
    ('06_hidden_object', 6),
    ('07_pet_hospital', 6),
]

print("Starting screen capture from real Android Emulator...")

for name, wait_sec in screens:
    time.sleep(wait_sec)
    out_file = os.path.join(OUTPUT_DIR, f"{name}.png")
    cmd = f"{ADB_PATH} exec-out screencap -p > {out_file}"
    subprocess.run(cmd, shell=True)
    if os.path.exists(out_file):
        im = Image.open(out_file)
        print(f"Captured {name}: {im.size} ({os.path.getsize(out_file)} bytes)")

print("All real emulator screens captured!")
