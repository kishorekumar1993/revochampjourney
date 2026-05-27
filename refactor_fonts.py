import os
import re

target_dir = r'd:\SoftwareWork\Project\RevoChamp\RevochampChecker\revojourneytryone\lib\features\journey_builder'

def process_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'GoogleFonts.' not in content:
        return False
        
    # Replacements for GoogleFonts without arguments
    new_content = re.sub(r"GoogleFonts\.inter\(\s*\)", r"TextStyle(fontFamily: 'Inter')", content)
    new_content = re.sub(r"GoogleFonts\.outfit\(\s*\)", r"TextStyle(fontFamily: 'Outfit')", new_content)
    new_content = re.sub(r"GoogleFonts\.sourceCodePro\(\s*\)", r"TextStyle(fontFamily: 'Source Code Pro')", new_content)

    # Replacements for GoogleFonts with arguments
    new_content = re.sub(r"GoogleFonts\.inter\(", r"TextStyle(fontFamily: 'Inter', ", new_content)
    new_content = re.sub(r"GoogleFonts\.outfit\(", r"TextStyle(fontFamily: 'Outfit', ", new_content)
    new_content = re.sub(r"GoogleFonts\.sourceCodePro\(", r"TextStyle(fontFamily: 'Source Code Pro', ", new_content)
    
    # Remove import
    new_content = re.sub(r"import\s+'package:google_fonts/google_fonts\.dart';\n", '', new_content)

    if new_content != content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

modified_files = []
for root, dirs, files in os.walk(target_dir):
    for f in files:
        if f.endswith('.dart'):
            filepath = os.path.join(root, f)
            if process_file(filepath):
                modified_files.append(f)

print('Modified files:', modified_files)
