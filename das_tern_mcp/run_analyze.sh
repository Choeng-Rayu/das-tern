#!/bin/bash
cd /home/rayu/das-tern/das_tern_mcp
flutter analyze 2>&1 > /tmp/flutter_analyze_output.txt
echo "DONE"
