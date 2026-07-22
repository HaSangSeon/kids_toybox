import random
import re

def generate_maze(rows, cols):
    # Create empty grid (1 = wall, 0 = path)
    maze = [[1] * cols for _ in range(rows)]
    
    # DFS to carve paths
    def carve(r, c):
        maze[r][c] = 0
        directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]
        random.shuffle(directions)
        
        for dr, dc in directions:
            nr, nc = r + dr*2, c + dc*2
            if 0 <= nr < rows and 0 <= nc < cols and maze[nr][nc] == 1:
                maze[r + dr][c + dc] = 0
                carve(nr, nc)
    
    # Force start at 0,0 and end at bottom-right
    carve(0, 0)
    
    # Ensure start and end are 0
    maze[0][0] = 0
    maze[rows-1][cols-1] = 0
    
    # Connect end if it's isolated (because dimensions might be even)
    if maze[rows-1][cols-1] == 0:
        # Check neighbors
        if (rows-2 >= 0 and maze[rows-2][cols-1] == 1) and (cols-2 >= 0 and maze[rows-1][cols-2] == 1):
            maze[rows-2][cols-1] = 0
            
    # Randomly remove some walls to make it easier for kids
    for _ in range((rows * cols) // 10):
        rr = random.randint(1, rows-2)
        cc = random.randint(1, cols-2)
        maze[rr][cc] = 0
        
    # Formatting
    lines = []
    for row in maze:
        lines.append("        [" + ", ".join(map(str, row)) + "],")
    return "\n".join(lines)

themes_data = [
    {"title": '동물 농장 🐭', "r": 5, "c": 5, "p": '🐭', "g": '🧀', "w": '🧱', "bg1": '0xFFFFF3E0', "bg2": '0xFFFFE0B2', "bge": '☁️', "bpc": '0xFFFFE0B2'},
    {"title": '바다 탐험 🐠', "r": 6, "c": 6, "p": '🐠', "g": '🐚', "w": '🪸', "bg1": '0xFFE0F7FA', "bg2": '0xFFB2EBF2', "bge": '🫧', "bpc": '0xFFB2EBF2'},
    {"title": '꽃밭 나들이 🐝', "r": 7, "c": 7, "p": '🐝', "g": '🌻', "w": '🌿', "bg1": '0xFFE8F5E9', "bg2": '0xFFC8E6C9', "bge": '✨', "bpc": '0xFFC8E6C9'},
    {"title": '우주 비행 🚀', "r": 8, "c": 8, "p": '🚀', "g": '🌎', "w": '☄️', "bg1": '0xFF1A237E', "bg2": '0xFF311B92', "bge": '⭐', "bpc": '0xFF5E35B1'},
    {"title": '공룡 시대 🦕', "r": 7, "c": 7, "p": '🦕', "g": '🍖', "w": '🌋', "bg1": '0xFFF1F8E9', "bg2": '0xFFDCEDC8', "bge": '🌴', "bpc": '0xFFDCEDC8'},
    {"title": '사막 탐험 🐪', "r": 8, "c": 8, "p": '🐪', "g": '🌵', "w": '🏜️', "bg1": '0xFFFFF8E1', "bg2": '0xFFFFECB3', "bge": '☀️', "bpc": '0xFFFFECB3'},
    {"title": '하늘 구름 🦅', "r": 8, "c": 8, "p": '🦅', "g": '🌈', "w": '☁️', "bg1": '0xFFE3F2FD', "bg2": '0xFFBBDEFB', "bge": '🌤️', "bpc": '0xFFBBDEFB'},
    {"title": '겨울 왕국 🐧', "r": 9, "c": 9, "p": '🐧', "g": '🧊', "w": '⛄', "bg1": '0xFFE0F2F1', "bg2": '0xFFB2DFDB', "bge": '❄️', "bpc": '0xFFB2DFDB'},
    {"title": '도시 질주 🚓', "r": 9, "c": 9, "p": '🚓', "g": '🍩', "w": '🏢', "bg1": '0xFFECEFF1', "bg2": '0xFFCFD8DC', "bge": '🚥', "bpc": '0xFFCFD8DC'},
    {"title": '마법의 성 🦄', "r": 10, "c": 10, "p": '🦄', "g": '🏰', "w": '🔮', "bg1": '0xFFF3E5F5', "bg2": '0xFFE1BEE7', "bge": '🌟', "bpc": '0xFFE1BEE7'},
]

output_str = "  final List<MazeTheme> _themes = [\n"
for idx, t in enumerate(themes_data):
    maze_str = generate_maze(t["r"], t["c"])
    output_str += f"""    MazeTheme(
      title: '{t["title"]}',
      rows: {t["r"]}, cols: {t["c"]},
      playerEmoji: '{t["p"]}', goalEmoji: '{t["g"]}', wallEmoji: '{t["w"]}',
      backgroundGradient: [Color({t["bg1"]}), Color({t["bg2"]})],
      bgEmoji: '{t["bge"]}', boardPatternColor: Color({t["bpc"]}).withValues(alpha: 0.4),
      maze: [
{maze_str}
      ],
    ),
"""
output_str += "  ];"

with open('lib/games/maze_escape/maze_escape_game.dart', 'r') as f:
    text = f.read()

# Replace the existing _themes list using regex
pattern = re.compile(r'  final List<MazeTheme> _themes = \[.*?  \];', re.DOTALL)
new_text = pattern.sub(output_str, text)

with open('lib/games/maze_escape/maze_escape_game.dart', 'w') as f:
    f.write(new_text)

print("Updated 10 stages!")
