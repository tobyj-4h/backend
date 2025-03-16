#!/bin/bash

# Start timer
START_TIME=$(date +%s)

# Define the root directory and dist directory paths
ROOT_DIR="$(pwd)/.."
SRC_DIR="$ROOT_DIR/src"
DIST_DIR="$ROOT_DIR/dist"

# Create the dist directory if it doesn't exist
mkdir -p $DIST_DIR

# Define subdirectories for each Lambda and their corresponding zip names
LAMBDA_DIRS=("get-school-by-id" "get-schools-by-district" "get-schools-nearby")
LAMBDA_ZIPS=("get-school-by-id.zip" "get-schools-by-district.zip" "get-schools-nearby.zip")

# Create a temporary directory for Lambda dependencies
TMP_DIR="$ROOT_DIR/tmp_lambda_dir"

# Remove the temporary directory if it exists
rm -rf $TMP_DIR
mkdir -p $TMP_DIR

# Loop through each Lambda subdirectory
for i in "${!LAMBDA_DIRS[@]}"; do
  LAMBDA_DIR="${LAMBDA_DIRS[$i]}"
  ZIP_FILE="${LAMBDA_ZIPS[$i]}"

  # Check if there's a requirements.txt in the Lambda directory and install dependencies
  if [ -f "$SRC_DIR/$LAMBDA_DIR/requirements.txt" ]; then
    echo "Installing dependencies for $LAMBDA_DIR..."
    pip install -r "$SRC_DIR/$LAMBDA_DIR/requirements.txt" --target="$TMP_DIR"
  fi

  # Copy the Python file from the src directory to the temporary directory
  cp "$SRC_DIR/$LAMBDA_DIR/$LAMBDA_DIR.py" "$TMP_DIR/"

  # Create the zip file in the dist directory
  echo "Creating $ZIP_FILE..."
  cd "$TMP_DIR"
  zip -r "$DIST_DIR/$ZIP_FILE" .
  cd "$ROOT_DIR"

  # Clean up the temporary directory for the next iteration
  rm -rf "$TMP_DIR"
  mkdir -p "$TMP_DIR"
done

# Clean up the temporary directory after all processing is complete
rm -rf "$TMP_DIR"

# End timer and calculate elapsed time
END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))

# Output the build time
echo "Build completed in $BUILD_TIME seconds."
