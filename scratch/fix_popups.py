import os
import re
import glob

# Games directory
games_dir = "/Users/hasangseon/kids_toybox/lib/games"

files_to_check = glob.glob(os.path.join(games_dir, "*", "*.dart"))

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    modified = False

    # 1. Replace width: 320, (or 300, 350) inside popup containers with BoxConstraints and margin
    # Look for a pattern where width: 320 is used in a Container that has padding or decoration near it.
    # It's safer to just replace width: 320 (or similar) with constraints and margin if it's inside a Center or ScaleTransition
    
    # We will do a generic replacement for the known widths used in popups.
    width_pattern = re.compile(r'(\s+)width:\s*(300|320|350|400),')
    
    # Not all width: 320 are popups, but in this context, most likely they are.
    # To be safer, we can just replace 'child: Column(\n' with 'child: SingleChildScrollView(\nchild: Column(\n' 
    # but only if it's inside a popup (e.g. follows 'decoration: BoxDecoration(' or 'padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),').
    
    # Let's search for "child: Column(\n...mainAxisSize: MainAxisSize.min" which is strongly indicative of a popup
    popup_col_pattern = re.compile(r'(\s+)child: Column\(\s*mainAxisSize: MainAxisSize.min,')
    
    def repl_col(m):
        indent = m.group(1)
        # return indent + 'child: SingleChildScrollView(' + indent + '  child: Column(' + '\n' + indent + '    mainAxisSize: MainAxisSize.min,'
        # We need to be careful with closing brackets. If we add SingleChildScrollView, we need an extra ')' at the end of the Column.
        # This is hard to do with regex alone because we need to find the matching closing bracket.
        return m.group(0) # skip for now, regex isn't smart enough for closing bracket

    # Simpler approach: We know exactly which files and what lines based on our grep.
    # pacman_game.dart, whack_a_mole_game.dart, balloon_pop_game.dart, brick_breaker_game.dart
    
    # Instead of regex magic, let's just do it manually for the files we know have popups that break.
    pass

if __name__ == "__main__":
    for f in files_to_check:
        fix_file(f)
