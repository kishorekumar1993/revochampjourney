import os
import glob

dir_path = 'lib/features/visual_builder/presentation/widgets/studio_panels'
for file_path in glob.glob(os.path.join(dir_path, '*.dart')):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # We want to replace `import '../` with `import '../../`
    new_content = content.replace("import '../", "import '../../")
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
