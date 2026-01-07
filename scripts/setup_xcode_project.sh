#!/bin/bash

# Setup Xcode Project for DuplicatePhotos
# This script creates the Xcode project with all necessary files

set -e

echo "🏗️  Setting up DuplicatePhotos Xcode Project..."

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "📁 Project directory: $PROJECT_DIR"

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode is not installed or xcodebuild is not in PATH"
    exit 1
fi

echo "✅ Xcode found: $(xcodebuild -version | head -n 1)"

# Create Xcode project structure
echo "📦 Creating Xcode project structure..."

# The project needs to be created in Xcode GUI for proper setup
echo ""
echo "⚠️  Manual Step Required:"
echo ""
echo "To create the Xcode project, please follow these steps:"
echo ""
echo "1. Open Xcode"
echo "2. Select 'Create New Project'"
echo "3. Choose 'iOS' → 'App'"
echo "4. Configure the project:"
echo "   - Product Name: DuplicatePhotos"
echo "   - Team: Your Apple Developer Account"
echo "   - Organization Identifier: com.yourname (or your preferred identifier)"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo "   - Use Core Data: NO"
echo "   - Include Tests: YES"
echo "5. Save location: $PROJECT_DIR"
echo "6. IMPORTANT: Select 'DuplicatePhotos' as the folder (Xcode will merge with existing structure)"
echo ""
echo "After creating the project in Xcode:"
echo ""
echo "7. In Xcode, add all existing Swift files to the project:"
echo "   - Right-click on DuplicatePhotos folder in Project Navigator"
echo "   - Select 'Add Files to DuplicatePhotos...'"
echo "   - Select all .swift files in the following folders:"
echo "     - DuplicatePhotos/App/"
echo "     - DuplicatePhotos/Models/"
echo "     - DuplicatePhotos/Views/"
echo "     - DuplicatePhotos/ViewModels/"
echo "     - DuplicatePhotos/Services/"
echo "   - Make sure 'Copy items if needed' is UNCHECKED"
echo "   - Make sure 'Create groups' is selected"
echo "   - Click 'Add'"
echo ""
echo "8. Replace the default Info.plist with the one in DuplicatePhotos/Info.plist"
echo ""
echo "9. Set deployment target to iOS 17.0:"
echo "   - Select project in Project Navigator"
echo "   - Select 'DuplicatePhotos' target"
echo "   - In 'General' tab, set 'Minimum Deployments' to iOS 17.0"
echo ""
echo "10. Build and run (⌘R) to test"
echo ""
echo "📝 Once the project is created, you can run:"
echo "   python3 scripts/convert_clip_to_coreml.py"
echo "   to convert the CLIP model to CoreML"
echo ""
