import os
import re

file_path = 'lib/features/visual_builder/presentation/widgets/studio_panels.dart'
dir_path = 'lib/features/visual_builder/presentation/widgets/studio_panels'
os.makedirs(dir_path, exist_ok=True)

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find boundaries
boundaries = []
for i, line in enumerate(lines):
    if line.startswith('// 1.'): boundaries.append(('pages_panel', i))
    elif line.startswith('// 2.'): boundaries.append(('theme_panel', i))
    elif line.startswith('// 3.'): boundaries.append(('api_panel', i))
    elif line.startswith('// 4.'): boundaries.append(('database_panel', i))
    elif line.startswith('// 5.'): boundaries.append(('variable_panel', i))
    elif line.startswith('// 6.'): boundaries.append(('action_flow_panel', i))
    elif line.startswith('// 7.'): boundaries.append(('assets_panel', i))
    elif line.startswith('// 8.'): boundaries.append(('responsive_panel', i))
    elif line.startswith('// 9.'): boundaries.append(('settings_panel', i))

# Also find where wrapper ends (before // 1.)
wrapper_start = -1
for i, line in enumerate(lines):
    if line.startswith('class RevoStudioPanelWrapper'):
        wrapper_start = i
        break

# Also find RevoGeneratedCodePanel
generated_panel_start = -1
for i, line in enumerate(lines):
    if line.startswith('// 10.') or line.startswith('class RevoGeneratedCodePanel'):
        if generated_panel_start == -1:
            generated_panel_start = i

boundaries.append(('generated_code_panel', generated_panel_start))

# Collect imports
imports = []
for line in lines[:wrapper_start]:
    imports.append(line)

imports_str = "".join(imports)

# We should make sure imports are correct for each file.
# We will just put all imports in each file, plus the wrapper import.
# Wait, they might need to import each other? No, they don't seem to.
# We'll put import 'studio_panel_wrapper.dart'; in all.

wrapper_code = imports_str + "".join(lines[wrapper_start:boundaries[0][1]])
with open(os.path.join(dir_path, 'studio_panel_wrapper.dart'), 'w', encoding='utf-8') as f:
    f.write(wrapper_code)

common_imports = imports_str + "import 'studio_panel_wrapper.dart';\n"

for i in range(len(boundaries)):
    name, start = boundaries[i]
    end = boundaries[i+1][1] if i + 1 < len(boundaries) else len(lines)
    
    content = common_imports + "\n" + "".join(lines[start:end])
    
    with open(os.path.join(dir_path, f'{name}.dart'), 'w', encoding='utf-8') as f:
        f.write(content)

# Now rewrite studio_panels.dart to just export all of them
exports = [
    "export 'studio_panels/studio_panel_wrapper.dart';",
    "export 'studio_panels/pages_panel.dart';",
    "export 'studio_panels/theme_panel.dart';",
    "export 'studio_panels/api_panel.dart';",
    "export 'studio_panels/database_panel.dart';",
    "export 'studio_panels/variable_panel.dart';",
    "export 'studio_panels/action_flow_panel.dart';",
    "export 'studio_panels/assets_panel.dart';",
    "export 'studio_panels/responsive_panel.dart';",
    "export 'studio_panels/settings_panel.dart';",
    "export 'studio_panels/generated_code_panel.dart';"
]
with open(file_path, 'w', encoding='utf-8') as f:
    f.write('\\n'.join(exports) + '\\n')

print('Done splitting!')
