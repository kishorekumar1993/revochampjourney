import re

file_path = 'lib/features/visual_builder/presentation/widgets/studio_panels.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

classes = []
for i, line in enumerate(lines):
    if line.startswith('class '):
        classes.append((i+1, line.strip()))

for i in range(len(classes)):
    start, name = classes[i]
    end = classes[i+1][0] - 1 if i+1 < len(classes) else len(lines)
    print(f'Line {start} to {end}: {name}')
