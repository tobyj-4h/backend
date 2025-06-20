#!/bin/bash

# Firebase Authentication Setup Script
# This script helps you set up Firebase service account keys for your Lambda authorizers

set -e

echo "🔥 Firebase Authentication Setup"
echo "================================"

# Check if service account key exists
if [ ! -f "firebase-service-account.json" ]; then
    echo "❌ firebase-service-account.json not found!"
    echo ""
    echo "📥 Download your service account key:"
    echo "gcloud iam service-accounts keys create firebase-service-account.json \\"
    echo "    --iam-account=firebase-adminsdk-fbsvc@beehive-parent.iam.gserviceaccount.com"
    echo ""
    echo "Or download it from the Firebase Console:"
    echo "1. Go to Firebase Console > Project Settings > Service Accounts"
    echo "2. Click 'Generate new private key'"
    echo "3. Save as 'firebase-service-account.json' in this directory"
    echo ""
    exit 1
fi

echo "✅ Found firebase-service-account.json"

# Base64 encode the service account key
echo "🔐 Encoding service account key..."
FIREBASE_KEY_BASE64=$(base64 -i firebase-service-account.json | tr -d '\n')

echo "✅ Service account key encoded successfully"
echo ""

echo "📋 Next Steps:"
echo "=============="
echo ""
echo "1. Add this base64 string to your Terraform variables:"
echo "   firebase_service_account_base64 = \"$FIREBASE_KEY_BASE64\""
echo ""
echo "2. Or set it as an environment variable:"
echo "   export TF_VAR_firebase_service_account_base64=\"$FIREBASE_KEY_BASE64\""
echo ""
echo "3. Install dependencies in each API project:"
echo "   cd api/locations && npm install"
echo "   cd api/media && npm install"
echo "   cd api/posts && npm install"
echo "   cd api/user && npm install"
echo "   cd api/post-interactions && npm install"
echo ""
echo "4. Build each project:"
echo "   cd api/locations && npm run build"
echo "   cd api/media && npm run build"
echo "   cd api/posts && npm run build"
echo "   cd api/user && npm run build"
echo "   cd api/post-interactions && npm run build"
echo ""
echo "5. Deploy with Terraform:"
echo "   terraform plan"
echo "   terraform apply"
echo ""
echo "🔒 Security Note:"
echo "The firebase-service-account.json file is now in .gitignore"
echo "Never commit this file to version control!"
echo ""
echo "📚 For production, consider using AWS Secrets Manager instead."
echo "See FIREBASE_SECURITY_GUIDE.md for details." 