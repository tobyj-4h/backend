#!/bin/bash

# Navigate to the root of the project (parent of bin)
cd "$(dirname "$0")/.." || exit 1

# Path to the profile file
PROFILE_FILE="../../.aws_profile"

# Read the profile from the file or use default
AWS_PROFILE=$(cat "$PROFILE_FILE" 2>/dev/null || echo "default")

# AWS region
AWS_REGION="us-east-1"

# Get the account number
AWS_ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text --profile "$AWS_PROFILE")

echo "Using profile: $AWS_PROFILE"
echo "Account ID: $AWS_ACCOUNT"
echo "Region: $AWS_REGION"

if [ -z "$AWS_ACCOUNT" ]; then
  echo "Failed to retrieve AWS account ID. Check your AWS profile and credentials."
  exit 1
fi

# Docker image name
IMAGE_NAME="school-district-query"

# Version file in the project root
VERSION_FILE=".version"
if [ ! -f "$VERSION_FILE" ]; then
  echo "v1.0.0" > "$VERSION_FILE"
fi

# Read and increment the version
VERSION=$(cat "$VERSION_FILE")
IFS='.' read -r major minor patch <<< "${VERSION//v/}"
patch=$((patch + 1))
NEW_VERSION="v$major.$minor.$patch"
echo "$NEW_VERSION" > "$VERSION_FILE"

# ECR repository
ECR_REPO="$AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE_NAME:$NEW_VERSION"

# Build, tag, and push the Docker image
echo "Building Docker image..."
docker build -t "$IMAGE_NAME" .

echo "Tagging Docker image..."
docker tag "$IMAGE_NAME:latest" "$ECR_REPO"

echo "Pushing Docker image..."
docker push "$ECR_REPO"

# Output the result
echo "Docker image pushed to $ECR_REPO"
