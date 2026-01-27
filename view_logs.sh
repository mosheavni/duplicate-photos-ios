#!/bin/bash
# View DuplicatePhotos app logs from simulator

echo "📱 Streaming DuplicatePhotos logs..."
echo "Run the app with ./launch.sh and start scanning"
echo "Press Ctrl+C to stop"
echo ""

xcrun simctl spawn booted log stream --predicate 'process == "DuplicatePhotos"' --level debug --style compact
