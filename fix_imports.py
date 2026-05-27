import os
import re

directories = [
    r'd:\SoftwareWork\Project\RevoChamp\RevochampChecker\revojourneytryone\lib\features\journey_builder\presentation\widgets\canvas_panel',
    r'd:\SoftwareWork\Project\RevoChamp\RevochampChecker\revojourneytryone\lib\features\journey_builder\presentation\widgets\properties_panel'
]

for d in directories:
    for filename in os.listdir(d):
        if not filename.endswith('.dart'):
            continue
        filepath = os.path.join(d, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        def repl(match):
            return "import '../" + match.group(0)[8:]
            
        new_content = re.sub(r"import '(\.\./)+([^']+)';", repl, content)
        
        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
