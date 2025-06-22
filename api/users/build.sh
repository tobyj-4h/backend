#!/bin/bash

# Exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
SRC_DIR="src"
DIST_DIR="dist"
BUILD_OUT_DIR="build.out"

# Create directories if they don't exist
mkdir -p "$DIST_DIR" "$BUILD_OUT_DIR"

echo -e "${BLUE}🔍 Checking for changes in Lambda functions...${NC}"

# Function to check if a file needs rebuilding
needs_rebuild() {
    local src_file="$1"
    local dist_file="$2"
    
    # If dist file doesn't exist, needs rebuild
    if [[ ! -f "$dist_file" ]]; then
        return 0
    fi
    
    # If src file is newer than dist file, needs rebuild
    if [[ "$src_file" -nt "$dist_file" ]]; then
        return 0
    fi
    
    # Check if package.json has changed (dependencies)
    if [[ -f "package.json" && "package.json" -nt "$dist_file" ]]; then
        return 0
    fi
    
    # Check if package-lock.json has changed
    if [[ -f "package-lock.json" && "package-lock.json" -nt "$dist_file" ]]; then
        return 0
    fi
    
    # Check if tsconfig.json has changed
    if [[ -f "tsconfig.json" && "tsconfig.json" -nt "$dist_file" ]]; then
        return 0
    fi
    
    return 1
}

# Function to build a single Lambda
build_lambda() {
    local src_file="$1"
    local filename=$(basename "$src_file" .ts)
    local dist_file="$DIST_DIR/${filename}.zip"
    local build_file="$BUILD_OUT_DIR/${filename}.js"
    
    echo -e "${YELLOW}📦 Building $filename...${NC}"
    
    # Build the file
    esbuild "$src_file" \
        --bundle \
        --platform=node \
        --target=node20 \
        --outfile="$build_file"
    
    # Zip the built file
    zip -j "$dist_file" "$build_file" > /dev/null
    
    echo -e "${GREEN}✅ Built $filename${NC}"
}

# Counter for rebuilt functions
rebuilt_count=0
total_count=0

# Iterate through each TypeScript file in the src directory
for file in "$SRC_DIR"/*.ts; do
    if [[ ! -f "$file" ]]; then
        continue
    fi
    
    filename=$(basename "$file" .ts)
    dist_file="$DIST_DIR/${filename}.zip"
    total_count=$((total_count + 1))
    
    if needs_rebuild "$file" "$dist_file"; then
        build_lambda "$file"
        rebuilt_count=$((rebuilt_count + 1))
    else
        echo -e "${BLUE}⏭️  Skipping $filename (no changes)${NC}"
    fi
done

echo -e "${GREEN}🎉 Build complete!${NC}"
echo -e "${BLUE}📊 Rebuilt $rebuilt_count of $total_count functions${NC}"

# Clean up build.out directory
rm -rf "$BUILD_OUT_DIR"

echo -e "${GREEN}✨ Build artifacts cleaned up${NC}"
