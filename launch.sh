#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔨 Building DuplicatePhotos...${NC}"
xcodebuild -project DuplicatePhotos.xcodeproj \
    -scheme DuplicatePhotos \
    -sdk iphonesimulator \
    -configuration Debug \
    build 2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED|error:)" || true

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Build succeeded${NC}"

# Find the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/DuplicatePhotos-*/Build/Products/Debug-iphonesimulator/DuplicatePhotos.app -print -quit 2>/dev/null)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}❌ Could not find built app${NC}"
    exit 1
fi

# Get the fresh simulator ID
SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone 17" | grep "Shutdown\|Booted" | tail -1 | grep -o '[0-9A-F-]\{36\}')

if [ -z "$SIMULATOR_ID" ]; then
    echo -e "${RED}❌ Could not find iPhone 17 simulator${NC}"
    exit 1
fi

echo -e "${BLUE}📱 Booting simulator...${NC}"
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || echo "Simulator already booted"

# Open Simulator.app
open -a Simulator

sleep 2

echo -e "${BLUE}📦 Installing app...${NC}"
xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"

echo -e "${BLUE}🚀 Launching DuplicatePhotos...${NC}"
xcrun simctl launch "$SIMULATOR_ID" com.mosheavni.DuplicatePhotos

echo -e "${GREEN}✓ App launched successfully!${NC}"
echo -e "${BLUE}ℹ️  Look at the Simulator app to use DuplicatePhotos${NC}"
