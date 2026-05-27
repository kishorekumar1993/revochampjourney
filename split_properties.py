import os

src_file = r'd:\SoftwareWork\Project\RevoChamp\RevochampChecker\revojourneytryone\lib\features\journey_builder\presentation\widgets\properties_panel.dart'
dest_dir = r'd:\SoftwareWork\Project\RevoChamp\RevochampChecker\revojourneytryone\lib\features\journey_builder\presentation\widgets\properties_panel'

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

imports = "".join(lines[0:10])

# Fields file
fields_content = imports + "\n"
text_field_code = "".join(lines[classes['_PropertyTextField'][0] : classes['_PropertyTextField'][1]+1])
text_field_state_code = "".join(lines[classes['_PropertyTextFieldState'][0] : classes['_PropertyTextFieldState'][1]+1])
dropdown_code = "".join(lines[classes['_PropertyDropdownField'][0] : classes['_PropertyDropdownField'][1]+1])

text_field_code = text_field_code.replace('_PropertyTextField', 'PropertyTextField')
text_field_state_code = text_field_state_code.replace('_PropertyTextField', 'PropertyTextField')
dropdown_code = dropdown_code.replace('_PropertyDropdownField', 'PropertyDropdownField')

fields_content += text_field_code + "\n\n" + text_field_state_code + "\n\n" + dropdown_code + "\n"

with open(os.path.join(dest_dir, 'property_fields.dart'), 'w', encoding='utf-8') as f:
    f.write(fields_content)

# Main file
main_content = imports
main_content += "import 'property_fields.dart';\n\n"
main_code = "".join(lines[classes['RevoPropertiesPanel'][0] : classes['_RevoPropertiesPanelState'][1]+1])
main_code = main_code.replace('_PropertyTextField', 'PropertyTextField')
main_code = main_code.replace('_PropertyDropdownField', 'PropertyDropdownField')

main_content += main_code + "\n"

with open(os.path.join(dest_dir, 'properties_panel_main.dart'), 'w', encoding='utf-8') as f:
    f.write(main_content)

os.remove(src_file)
print("Properties panel split successfully.")
