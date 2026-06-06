#!/bin/bash
# Sync local changes to master and purify config for GitHub Actions

set -e

# Ensure we are on local branch
current_branch=$(git branch --show-current)
if [ "$current_branch" != "local" ]; then
    echo "Error: Must run from 'local' branch."
    exit 1
fi

# Ensure working directory is clean
if ! git diff-index --quiet HEAD --; then
    echo "Error: You have uncommitted changes on 'local'. Please commit them first."
    exit 1
fi

echo "Switching to master..."
git checkout master

echo "Rebasing master onto local..."
git rebase local

echo "Purifying config.yaml..."
cat << 'PYEOF' > purify_config.py
import re
import sys

def process_config(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Disable AI Analysis
        content = re.sub(r'(\n\s*enabled:\s*)true(\s*#\s*是否启用 AI 分析)', r'\1false\2', content)
        
        # Disable AI Translation
        content = re.sub(r'(\n\s*enabled:\s*)true(\s*#\s*是否启用翻译功能)', r'\1false\2', content)
        
        # Set Filter method to keyword
        content = re.sub(r'(filter:\s*\n\s*method:\s*)"ai"', r'\1"keyword"', content)
        
        # Clear Webhook URL for wework
        content = re.sub(r'(wework:\s*\n\s*webhook_url:\s*)"[^"]+"', r'\1""', content)
        
        # Clear api_base
        content = re.sub(r'(api_base:\s*)"[^"]+"', r'\1""', content)

        # Disable local RSS feeds
        lines = content.split('\n')
        out_lines = []
        i = 0
        while i < len(lines):
            line = lines[i]
            out_lines.append(line)
            if 'url: "http://host.docker.internal:1200' in line:
                if i + 1 < len(lines) and 'enabled:' in lines[i+1]:
                    out_lines.append(re.sub(r'enabled:\s*true', 'enabled: false', lines[i+1]))
                    i += 1
                else:
                    indent = len(line) - len(line.lstrip())
                    out_lines.append(' ' * indent + 'enabled: false')
            i += 1

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write('\n'.join(out_lines))
            
        print("Config purified successfully.")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    process_config('config/config.yaml')
PYEOF

python3 purify_config.py
rm purify_config.py

# Check if there are changes to commit
if ! git diff-index --quiet HEAD --; then
    echo "Committing purified config..."
    git add config/config.yaml
    git commit -m "chore: purify config for remote (disable local AI, proxies, and webhooks)"
else
    echo "No config changes needed."
fi

echo "Pushing master to origin..."
# Uncomment the following line when you are ready to push
# git push origin master

echo "Switching back to local..."
git checkout local

echo "Done!"
