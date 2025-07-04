#!/bin/bash

# English Study Flutter App Setup Script

echo "🎓 English Study Flutter App Setup"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    echo "Please install Flutter first: https://flutter.dev/docs/get-started/insp
    tall"
    exit 1
fi

echo -e "${GREEN}✅ Flutter found${NC}"

# Check Flutter version
flutter --version

# Get Flutter dependencies
echo -e "${YELLOW}📦 Installing Flutter dependencies...${NC}"
flutter pub get

# Check for common issues
echo -e "${YELLOW}🔍 Checking project configuration...${NC}"

# Check if pubspec.yaml exists
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ pubspec.yaml not found${NC}"
    exit 1
fi

# Check Android configuration
if [ ! -f "android/app/src/main/AndroidManifest.xml" ]; then
    echo -e "${RED}❌ Android configuration missing${NC}"
    exit 1
fi

# Check iOS configuration
if [ ! -f "ios/Runner/Info.plist" ]; then
    echo -e "${RED}❌ iOS configuration missing${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Project structure looks good${NC}"

# Check for API keys
echo -e "${YELLOW}🔑 Checking API configuration...${NC}"

if grep -q "YOUR_YOUTUBE_API_KEY" lib/services/transcript_service.dart; then
    echo -e "${YELLOW}⚠️  Please replace YOUR_YOUTUBE_API_KEY in lib/services/transcript_service.dart${NC}"
fi

if [ ! -f "android/app/google-services.json" ]; then
    echo -e "${YELLOW}⚠️  Android google-services.json not found${NC}"
    echo "   Download from Firebase Console and place in android/app/"
fi

if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${YELLOW}⚠️  iOS GoogleService-Info.plist not found${NC}"
    echo "   Download from Firebase Console and place in ios/Runner/"
fi

# Run Flutter doctor
echo -e "${YELLOW}🏥 Running Flutter doctor...${NC}"
flutter doctor

# Check for devices
echo -e "${YELLOW}📱 Checking connected devices...${NC}"
flutter devices

echo ""
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Configure your API keys (YouTube Data API)"
echo "2. Add Google Services configuration files"
echo "3. Connect a device or start an emulator"
echo "4. Run: flutter run"
echo ""
echo "For more information, see README.md"