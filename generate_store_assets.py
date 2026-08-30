import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# Base paths
WORKSPACE_DIR = '/Users/hasangseon/kids_toybox'
CAPTURED_DIR = os.path.join(WORKSPACE_DIR, 'build/captured_screens')
FONT_PATH = os.path.join(WORKSPACE_DIR, 'assets/fonts/Jua-Regular.ttf')
DESKTOP_DIR = '/Users/hasangseon/Desktop/kids_toybox_store_assets'
os.makedirs(DESKTOP_DIR, exist_ok=True)

# Helper function to create gradient background
def create_vertical_gradient(width, height, top_color, bottom_color):
    base = Image.new('RGBA', (width, height), top_color)
    top_r, top_g, top_b = top_color[:3]
    bot_r, bot_g, bot_b = bottom_color[:3]
    
    gradient = Image.new('RGBA', (width, height))
    draw = ImageDraw.Draw(gradient)
    for y in range(height):
        factor = y / float(height)
        r = int(top_r + (bot_r - top_r) * factor)
        g = int(top_g + (bot_g - top_g) * factor)
        b = int(bot_b + (bot_b - top_b) * factor)
        draw.line([(0, y), (width, y)], fill=(r, g, b, 255))
    return gradient

def add_floating_bubbles(image, count=15):
    draw = ImageDraw.Draw(image, 'RGBA')
    w, h = image.size
    import random
    random.seed(42)
    for _ in range(count):
        x = random.randint(30, w - 30)
        y = random.randint(30, h - 30)
        radius = random.randint(20, 80)
        alpha = random.randint(25, 60)
        draw.ellipse([x - radius, y - radius, x + radius, y + radius], fill=(255, 255, 255, alpha))
        # bubble highlight
        draw.ellipse([x - radius * 0.5, y - radius * 0.6, x - radius * 0.1, y - radius * 0.2], fill=(255, 255, 255, alpha + 30))

def create_phone_mockup(screen_img, target_width=860, target_height=1480, corner_radius=60):
    # Resize screen image keeping aspect ratio
    screen_resized = screen_img.resize((target_width, target_height), Image.Resampling.LANCZOS).convert('RGBA')
    
    # Create mask for rounded corners
    mask = Image.new('L', (target_width, target_height), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, target_width, target_height], radius=corner_radius, fill=255)
    
    # Create device frame (white card with border & shadow)
    padding = 18
    frame_w = target_width + padding * 2
    frame_h = target_height + padding * 2
    
    frame = Image.new('RGBA', (frame_w, frame_h), (0, 0, 0, 0))
    frame_draw = ImageDraw.Draw(frame)
    # White bezel
    frame_draw.rounded_rectangle([0, 0, frame_w, frame_h], radius=corner_radius + padding, fill=(255, 255, 255, 255))
    # Border outline
    frame_draw.rounded_rectangle([0, 0, frame_w, frame_h], radius=corner_radius + padding, outline=(230, 235, 245, 255), width=4)
    
    # Paste screen with mask
    frame.paste(screen_resized, (padding, padding), mask)
    
    # Add shadow
    shadow_margin = 40
    total_w = frame_w + shadow_margin * 2
    total_h = frame_h + shadow_margin * 2
    canvas = Image.new('RGBA', (total_w, total_h), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(canvas)
    shadow_draw.rounded_rectangle([shadow_margin + 5, shadow_margin + 15, shadow_margin + frame_w - 5, shadow_margin + frame_h + 15], 
                                  radius=corner_radius + padding, fill=(0, 0, 0, 45))
    canvas = canvas.filter(ImageFilter.GaussianBlur(16))
    canvas.paste(frame, (shadow_margin, shadow_margin), frame)
    
    return canvas

# -------------------------------------------------------------
# 1. Feature Graphic (그래픽 이미지: 1024 x 500)
# -------------------------------------------------------------
def generate_feature_graphic():
    width, height = 1024, 500
    # Soft warm pastel background
    bg = create_vertical_gradient(width, height, (255, 248, 225), (255, 229, 145))
    add_floating_bubbles(bg, count=20)
    
    logo_path = os.path.join(WORKSPACE_DIR, 'assets/images/app_logo.png')
    draw = ImageDraw.Draw(bg)
    
    font_title = ImageFont.truetype(FONT_PATH, 72)
    font_sub = ImageFont.truetype(FONT_PATH, 36)
    
    # Simple & Bold Title
    title_text = "키즈토이박스"
    # Title shadow
    draw.text((82, 172), title_text, font=font_title, fill=(255, 140, 0, 100))
    draw.text((80, 170), title_text, font=font_title, fill=(45, 52, 54, 255))
    
    # Clean Subtitle
    sub_text = "광고 없는 다양한 안심 놀이터"
    draw.text((80, 270), sub_text, font=font_sub, fill=(235, 77, 75, 255))
    
    # Right side: App Icon / 3D Toy Box
    if os.path.exists(logo_path):
        logo_img = Image.open(logo_path).convert('RGBA')
        logo_img = logo_img.resize((370, 370), Image.Resampling.LANCZOS)
        
        # Rounded mask for logo
        lmask = Image.new('L', (370, 370), 0)
        ldraw = ImageDraw.Draw(lmask)
        ldraw.rounded_rectangle([0, 0, 370, 370], radius=75, fill=255)
        
        # Shadow for logo
        logo_x, logo_y = 570, 65
        bg.paste(logo_img, (logo_x, logo_y), lmask)
        
    out_path = os.path.join(DESKTOP_DIR, '00_feature_graphic_1024x500.png')
    bg.convert('RGB').save(out_path, quality=95)
    print(f"Generated Clean Feature Graphic -> {out_path}")

# -------------------------------------------------------------
# 2. Phone Screenshots (1080 x 1920)
# -------------------------------------------------------------
def generate_screenshot(filename, tag_text, title_text, sub_text, screen_file, bg_top, bg_bot, badge_color):
    w, h = 1080, 1920
    bg = create_vertical_gradient(w, h, bg_top, bg_bot)
    add_floating_bubbles(bg, count=30)
    draw = ImageDraw.Draw(bg)
    
    font_tag = ImageFont.truetype(FONT_PATH, 34)
    font_title = ImageFont.truetype(FONT_PATH, 68)
    font_sub = ImageFont.truetype(FONT_PATH, 42)
    
    # Tag Badge
    tag_w = int(draw.textlength(tag_text, font=font_tag)) + 48
    tag_h = 60
    tag_x = (w - tag_w) // 2
    tag_y = 110
    draw.rounded_rectangle([tag_x, tag_y, tag_x + tag_w, tag_y + tag_h], radius=30, fill=badge_color)
    draw.text((tag_x + 24, tag_y + 10), tag_text, font=font_tag, fill=(255, 255, 255, 255))
    
    # Main Title
    title_w = int(draw.textlength(title_text, font=font_title))
    title_x = (w - title_w) // 2
    title_y = 195
    # Shadow text
    draw.text((title_x + 3, title_y + 3), title_text, font=font_title, fill=(0, 0, 0, 30))
    draw.text((title_x, title_y), title_text, font=font_title, fill=(45, 52, 54, 255))
    
    # Subtitle
    sub_w = int(draw.textlength(sub_text, font=font_sub))
    sub_x = (w - sub_w) // 2
    sub_y = 285
    draw.text((sub_x, sub_y), sub_text, font=font_sub, fill=(99, 110, 114, 255))
    
    # Load screen image and create mockup
    screen_path = os.path.join(CAPTURED_DIR, screen_file)
    if os.path.exists(screen_path):
        screen_raw = Image.open(screen_path).convert('RGBA')
        mockup = create_phone_mockup(screen_raw, target_width=860, target_height=1440, corner_radius=50)
        mockup_x = (w - mockup.size[0]) // 2
        mockup_y = 390
        bg.paste(mockup, (mockup_x, mockup_y), mockup)
        
    out_path = os.path.join(DESKTOP_DIR, filename)
    bg.convert('RGB').save(out_path, quality=95)
    print(f"Generated Screenshot -> {out_path}")

CAPTURED_DIR = os.path.join(WORKSPACE_DIR, 'build/emulator_raw_screens')

# Run Generation
if __name__ == '__main__':
    generate_feature_graphic()
    
    # Screenshot 1: Lobby (All-in-one games)
    generate_screenshot(
        filename='01_screenshot_lobby.png',
        tag_text='🧸 올인원 키즈 놀이터',
        title_text='광고 없이 즐기는 다양한 미니게임!',
        sub_text='세차 · 소방관 · 퍼즐 · 동물병원까지 가득해요',
        screen_file='01_lobby.png',
        bg_top=(255, 245, 230),
        bg_bot=(255, 225, 170),
        badge_color=(255, 107, 107, 255)
    )
    
    # Screenshot 2: Car Wash
    generate_screenshot(
        filename='02_screenshot_car_wash.png',
        tag_text='🚗 신나는 인기 놀이',
        title_text='뽀글뽀글 거품 내어 반짝반짝 세차!',
        sub_text='비누칠하고 물을 뿌려 깨끗하게 닦아보아요',
        screen_file='02_car_wash.png',
        bg_top=(235, 248, 255),
        bg_bot=(195, 230, 255),
        badge_color=(9, 132, 227, 255)
    )
    
    # Screenshot 3: Firefighter
    generate_screenshot(
        filename='03_screenshot_firefighter.png',
        tag_text='🚒 영웅 역할놀이',
        title_text='출동! 삐뽀삐뽀 불을 끄는 소방관',
        sub_text='호스를 조준해 위험에 처한 건물을 구해요!',
        screen_file='03_firefighter.png',
        bg_top=(255, 240, 235),
        bg_bot=(255, 215, 205),
        badge_color=(235, 77, 75, 255)
    )
    
    # Screenshot 4: Feed Animals
    generate_screenshot(
        filename='04_screenshot_feed_animals.png',
        tag_text='🦁 교감 & 인지 놀이',
        title_text='냠냠! 배고픈 동물 친구들 밥 주기',
        sub_text='동물이 좋아하는 맛있는 음식을 골라줘요',
        screen_file='04_feed_animals.png',
        bg_top=(245, 255, 235),
        bg_bot=(215, 245, 200),
        badge_color=(46, 204, 113, 255)
    )
    
    # Screenshot 5: Slide Puzzle & Brain
    generate_screenshot(
        filename='05_screenshot_puzzle.png',
        tag_text='🧩 두뇌 발달 & 집중력',
        title_text='쓱쓱 맞춰보는 신나는 슬라이드 퍼즐',
        sub_text='알록달록 귀여운 그림 조각을 완성해보아요!',
        screen_file='05_slide_puzzle.png',
        bg_top=(255, 248, 230),
        bg_bot=(255, 230, 180),
        badge_color=(243, 156, 18, 255)
    )
    
    # Screenshot 6: Hidden Object / Exploration
    generate_screenshot(
        filename='06_screenshot_hidden_object.png',
        tag_text='🔍 관찰력 쑥쑥 탐험',
        title_text='꼭꼭 숨어라! 숨은그림찾기 놀이',
        sub_text='신비로운 숲과 바닷속에서 숨은 보물을 찾아요',
        screen_file='06_hidden_object.png',
        bg_top=(248, 240, 255),
        bg_bot=(230, 215, 250),
        badge_color=(155, 89, 182, 255)
    )
