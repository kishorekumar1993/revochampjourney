import os
import re
import shutil

src_file = r'd:\SoftwareWork\Project\RevoChamp\RevochampChecker\revojourneytryone\lib\features\journey_builder\presentation\widgets\canvas_panel.dart'
dest_dir = r'd:\SoftwareWork\Project\RevoChamp\RevochampChecker\revojourneytryone\lib\features\journey_builder\presentation\widgets\canvas_panel'

if not os.path.exists(dest_dir):
    os.makedirs(dest_dir)

with open(src_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

def get_class_lines(start_line_idx):
    brace_count = 0
    started = False
    for i in range(start_line_idx, len(lines)):
        line = lines[i]
        for char in line:
            if char == '{':
                started = True
                brace_count += 1
            elif char == '}':
                brace_count -= 1
        if started and brace_count == 0:
            return i
    return start_line_idx

classes = {}
for i, line in enumerate(lines):
    if line.startswith('class '):
        class_name = line.split(' ')[1]
        classes[class_name] = (i, get_class_lines(i))

imports = "".join(lines[0:9])

# Toolbox file
toolbox_content = imports + "\n"
toolbox_content += "".join(lines[classes['_CanvasToolbox'][0] : classes['_CanvasToolbox'][1]+1]).replace('_CanvasToolbox', 'CanvasToolbox') + "\n\n"
toolbox_content += "".join(lines[classes['_CanvasBottomStats'][0] : classes['_CanvasBottomStats'][1]+1]).replace('_CanvasBottomStats', 'CanvasBottomStats') + "\n"

with open(os.path.join(dest_dir, 'canvas_toolbox.dart'), 'w', encoding='utf-8') as f:
    f.write(toolbox_content)

# Fields file
fields_content = imports + "\n"
fields_content += "".join(lines[classes['_CanvasDropdownField'][0] : classes['_CanvasDropdownField'][1]+1]).replace('_CanvasDropdownField', 'CanvasDropdownField') + "\n\n"
text_field_code = "".join(lines[classes['_CanvasTextField'][0] : classes['_CanvasTextField'][1]+1])
text_field_state_code = "".join(lines[classes['_CanvasTextFieldState'][0] : classes['_CanvasTextFieldState'][1]+1])
text_field_code = text_field_code.replace('_CanvasTextField', 'CanvasTextField')
text_field_state_code = text_field_state_code.replace('_CanvasTextField', 'CanvasTextField')
fields_content += text_field_code + "\n\n" + text_field_state_code + "\n"

with open(os.path.join(dest_dir, 'canvas_fields.dart'), 'w', encoding='utf-8') as f:
    f.write(fields_content)

# Main file
main_content = imports
main_content += "import 'canvas_toolbox.dart';\n"
main_content += "import 'canvas_fields.dart';\n\n"
main_code = "".join(lines[classes['RevoCanvasPanel'][0] : classes['_RevoCanvasPanelState'][1]+1])
main_code = main_code.replace('_CanvasToolbox', 'CanvasToolbox')
main_code = main_code.replace('_CanvasBottomStats', 'CanvasBottomStats')
main_code = main_code.replace('_CanvasDropdownField', 'CanvasDropdownField')
main_code = main_code.replace('_CanvasTextField', 'CanvasTextField')

main_content += main_code + "\n"

with open(os.path.join(dest_dir, 'canvas_panel_main.dart'), 'w', encoding='utf-8') as f:
    f.write(main_content)

# After successful generation, we can delete the old one or rename it
os.remove(src_file)
print("Canvas panel split successfully.")
