#!/usr/bin/env python3
import subprocess
import sys
import os

os.chdir('/home/rayu/das-tern')

# Add and commit
result = subprocess.run(['git', 'add', 'nginx/dastern.conf'], capture_output=True, text=True)
print(f"Add: {result.returncode}")

result = subprocess.run(['git', 'commit', '-m', 'fix: nginx http2 directive'], capture_output=True, text=True)
print(f"Commit: {result.returncode}")
print(result.stdout)
print(result.stderr)

# Push
result = subprocess.run(['git', 'push', 'origin', 'main'], capture_output=True, text=True)
print(f"Push: {result.returncode}")
print(result.stdout)
print(result.stderr)

