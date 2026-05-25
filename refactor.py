import re

with open('lib/features/journey_builder/presentation/widgets/canvas_panel.dart', 'r') as f:
    content = f.read()

def repl(match):
    body = match.group(0)
    # find type: "something" or type: 'something'
    type_match = re.search(r'type:\s*[\"\']([^\"\']+)[\"\']', body)
    if type_match:
        t = type_match.group(1)
        if t in ['dropdown', 'api_dropdown', 'radio', 'checkbox', 'switch', 'multi_select']:
            return body.replace('JourneyField(', 'OptionsComponent(', 1)
        elif t in ['section', 'card', 'tabs', 'accordion', 'row', 'column']:
            return body.replace('JourneyField(', 'LayoutComponent(', 1)
        elif t == 'table_grid':
            return body.replace('JourneyField(', 'GridComponent(', 1)
        elif t == 'repeater':
            return body.replace('JourneyField(', 'RepeaterComponent(', 1)
        elif t == 'divider':
            return body.replace('JourneyField(', 'DividerComponent(', 1)
    return body.replace('JourneyField(', 'InputComponent(', 1)

# Matches JourneyField( ... ) possibly spanning multiple lines until the closing parenthesis for that call.
# Actually regex for matching nested parentheses is hard. Let's just find JourneyField( and look ahead.
# We'll iteratively find "JourneyField(" and replace it.

new_content = ""
idx = 0
while True:
    start = content.find("JourneyField(", idx)
    if start == -1:
        new_content += content[idx:]
        break
    
    new_content += content[idx:start]
    
    # find matching parenthesis
    paren_count = 1
    end = start + len("JourneyField(")
    while end < len(content) and paren_count > 0:
        if content[end] == '(':
            paren_count += 1
        elif content[end] == ')':
            paren_count -= 1
        end += 1
    
    body = content[start:end]
    new_body = repl(re.match(r'.*', body, re.DOTALL)) # Just pass an object that has group(0)
    
    class DummyMatch:
        def group(self, n):
            return body
    new_body = repl(DummyMatch())
    new_content += new_body
    idx = end

with open('lib/features/journey_builder/presentation/widgets/canvas_panel.dart', 'w') as f:
    f.write(new_content)
print('Done modifying journey_provider.dart')
