#!/bin/bash

set -e

# Configuration
PROJECT_NAME="APGI-Explorer"
SCHEME="APGI-Explorer"
WORKSPACE="APGI-Explorer.xcworkspace"
PROJECT="APGI-Explorer.xcodeproj"
BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/$PROJECT_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/Export"
APP_NAME="$PROJECT_NAME.app"
DMG_NAME="$PROJECT_NAME-1.0.dmg"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are available
check_requirements() {
    print_status "Checking requirements..."
    
    if ! command -v xcodebuild &> /dev/null; then
        print_error "xcodebuild is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v xcrun &> /dev/null; then
        print_error "xcrun is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v create-dmg &> /dev/null; then
        print_warning "create-dmg is not installed. DMG creation will use hdiutil instead."
    fi
    
    print_status "Requirements check passed."
}

# Clean previous builds
clean_build() {
    print_status "Cleaning previous builds..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
}

# Build the app
build_app() {
    print_status "Building $PROJECT_NAME for distribution..."
    
    xcodebuild -project "$PROJECT" \
               -scheme "$SCHEME" \
               -configuration Release \
               -derivedDataPath "$BUILD_DIR/DerivedData" \
               -archivePath "$ARCHIVE_PATH" \
               archive
    
    if [ $? -eq 0 ]; then
        print_status "Build completed successfully."
    else
        print_error "Build failed."
        exit 1
    fi
}

# Export the app
export_app() {
    print_status "Exporting app for distribution..."
    
    xcodebuild -exportArchive \
               -archivePath "$ARCHIVE_PATH" \
               -exportPath "$EXPORT_PATH" \
               -exportOptionsPlist exportOptions.plist
    
    if [ $? -eq 0 ]; then
        print_status "Export completed successfully."
    else
        print_error "Export failed."
        exit 1
    fi
}

# Create export options plist if it doesn't exist
create_export_options() {
    if [ ! -f "exportOptions.plist" ]; then
        print_status "Creating export options plist..."
        cat > exportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>destination</key>
    <string>export</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.lesoto.APGI-Explorer</key>
        <string>APGI_Explorer_Mac_App_Store</string>
    </dict>
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    <key>entitlements</key>
    <string>APGI-Explorer/APGI-Explorer.entitlements</string>
</dict>
</plist>
EOF
        print_warning "Please update YOUR_TEAM_ID in exportOptions.plist"
    fi
}

# Create DMG
create_dmg() {
    print_status "Creating DMG..."
    
    APP_PATH="$EXPORT_PATH/$APP_NAME"
    
    if [ ! -d "$APP_PATH" ]; then
        print_error "App not found at $APP_PATH"
        exit 1
    fi
    
    if command -v create-dmg &> /dev/null; then
        create-dmg \
            --volname "$PROJECT_NAME" \
            --volicon "$APP_PATH/Contents/Resources/AppIcon.icns" \
            --window-pos 200 120 \
            --window-size 600 300 \
            --icon-size 100 \
            --icon "$APP_NAME" 175 120 \
            --hide-extension "$APP_NAME" \
            --app-drop-link 425 120 \
            "$DMG_NAME" \
            "$APP_PATH"
    else
        # Fallback to hdiutil
        DMG_TEMP_DIR="$BUILD_DIR/dmg_temp"
        mkdir -p "$DMG_TEMP_DIR"
        cp -R "$APP_PATH" "$DMG_TEMP_DIR/"
        
        # Create Applications symlink
        ln -s /Applications "$DMG_TEMP_DIR/Applications"
        
        hdiutil create -volname "$PROJECT_NAME" \
                     -srcfolder "$DMG_TEMP_DIR" \
                     -ov -format UDZO \
                     "$DMG_NAME"
        
        rm -rf "$DMG_TEMP_DIR"
    fi
    
    if [ $? -eq 0 ]; then
        print_status "DMG created successfully: $DMG_NAME"
    else
        print_error "DMG creation failed."
        exit 1
    fi
}

# Notarize the app
notarize_app() {
    print_status "Starting notarization process..."
    
    if [ -z "$APPLE_ID" ] || [ -z "$APPLE_ID_PASSWORD" ] || [ -z "$TEAM_ID" ]; then
        print_warning "Apple ID credentials not set. Skipping notarization."
        print_warning "Set APPLE_ID, APPLE_ID_PASSWORD, and TEAM_ID environment variables."
        return
    fi
    
    # Upload for notarization
    print_status "Uploading to Apple's notarization service..."
    NOTARIZATION_RESULT=$(xcrun notarytool submit \
        --apple-id "$APPLE_ID" \
        --password "$APPLE_ID_PASSWORD" \
        --team-id "$TEAM_ID" \
        --file "$DMG_NAME" \
        --wait)
    
    if echo "$NOTARIZATION_RESULT" | grep -q "Accepted"; then
        print_status "Notarization successful!"
    else
        print_error "Notarization failed."
        echo "$NOTARIZATION_RESULT"
        exit 1
    fi
    
    # Staple the notarization
    print_status "Stapling notarization to DMG..."
    xcrun stapler staple "$DMG_NAME"
    
    if [ $? -eq 0 ]; then
        print_status "Notarization stapling completed successfully."
    else
        print_error "Stapling failed."
        exit 1
    fi
}

# Verify the build
verify_build() {
    print_status "Verifying build..."
    
    if [ ! -f "$DMG_NAME" ]; then
        print_error "DMG not found."
        exit 1
    fi
    
    # Check if app is code signed
    codesign -dv "$EXPORT_PATH/$APP_NAME" 2>&1 | grep "Authority=" || {
        print_error "App is not properly code signed."
        exit 1
    }
    
    # Check if DMG is notarized (if notarization was performed)
    if [ -n "$APPLE_ID" ]; then
        xcrun stapler validate "$DMG_NAME" || {
            print_error "DMG is not properly notarized."
            exit 1
        }
    fi
    
    print_status "Build verification completed successfully."
}

# Run tests before building
run_tests() {
    print_status "Running automated tests..."
    
    # Run unit tests
    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination 'platform=macOS' \
        -derivedDataPath "$BUILD_DIR/DerivedData" \
        ONLY_ACTIVE_ARCH=NO
    
    if [ $? -eq 0 ]; then
        print_status "Unit tests passed."
    else
        print_warning "Unit tests failed. Continuing with build..."
    fi
    
    # Run UI tests
    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination 'platform=macOS' \
        -derivedDataPath "$BUILD_DIR/DerivedData" \
        -only-testing:APGI_ExplorerUITests \
        ONLY_ACTIVE_ARCH=NO
    
    if [ $? -eq 0 ]; then
        print_status "UI tests passed."
    else
        print_warning "UI tests failed. Continuing with build..."
    fi
}

# Main execution
main() {
    print_status "Starting APGI Explorer build and distribution process..."
    
    check_requirements
    create_export_options
    run_tests
    clean_build
    build_app
    export_app
    create_dmg
    notarize_app
    verify_build
    
    print_status "Build and distribution process completed successfully!"
    print_status "Output: $DMG_NAME"
    
    if [ -n "$APPLE_ID" ]; then
        print_status "The DMG is ready for distribution on the Mac App Store or direct download."
    else
        print_status "The DMG is ready for local testing. Set Apple ID credentials for notarization."
    fi
}

# Run main function
main "$@"
