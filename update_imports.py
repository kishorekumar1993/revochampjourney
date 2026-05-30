import os
import glob
import re

dir_path = 'lib/features/visual_builder/presentation/widgets/studio_panels'
for file_path in glob.glob(os.path.join(dir_path, '*.dart')):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    def add_dot_dot(match):
        return match.group(1) + '../' + match.group(2)
        
    new_content = re.sub(r"(import\s+['\"])\.\./(.*?['\"];)", add_dot_dot, content)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
