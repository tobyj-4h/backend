rm -rf dist build.out && mkdir -p dist build.out

# Iterate through each TypeScript file in the src directory
for file in src/*.ts; do
  filename=$(basename "$file" .ts)
  
  # Build the file
  esbuild "$file" --bundle --platform=node --external:jsonwebtoken --target=node20 --outfile="build.out/${filename}.js"
  
  # Zip the built file
  zip -j "dist/${filename}.zip" "build.out/${filename}.js"
done
