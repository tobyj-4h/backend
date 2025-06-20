# Firebase Service Account Key Security Guide

## 🔐 **Recommended Approach: AWS Secrets Manager (Production)**

### Step 1: Store Service Account Key in AWS Secrets Manager

```bash
# Store the service account key in AWS Secrets Manager
aws secretsmanager create-secret \
    --name "firebase/service-account-key" \
    --description "Firebase service account key for Lambda authorizers" \
    --secret-string file://firebase-service-account.json
```

### Step 2: Update Lambda IAM Roles

Add this policy to each authorizer Lambda's IAM role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue"],
      "Resource": "arn:aws:secretsmanager:*:*:secret:firebase/service-account-key*"
    }
  ]
}
```

### Step 3: Update Authorizer Code

Update each authorizer to fetch the service account key from Secrets Manager:

```typescript
import * as admin from "firebase-admin";
import { SecretsManager } from "@aws-sdk/client-secrets-manager";

// Initialize Firebase Admin SDK with Secrets Manager
const initializeFirebase = async (): Promise<admin.app.App> => {
  if (!firebaseApp) {
    try {
      firebaseApp = admin.app();
    } catch (error) {
      // Fetch service account key from Secrets Manager
      const secretsManager = new SecretsManager({
        region: process.env.AWS_REGION,
      });
      const secretResponse = await secretsManager.getSecretValue({
        SecretId: "firebase/service-account-key",
      });

      const serviceAccountKey = JSON.parse(secretResponse.SecretString || "{}");

      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccountKey),
      });
    }
  }
  return firebaseApp;
};
```

## 🚀 **Alternative Approach: Environment Variables (Development)**

### Step 1: Base64 Encode the Service Account Key

```bash
# Encode the service account key
base64 -i firebase-service-account.json | tr -d '\n'
```

### Step 2: Add to Lambda Environment Variables

Update Terraform to include the encoded key:

```hcl
environment {
  variables = {
    LOG_LEVEL = "INFO"
    FIREBASE_SERVICE_ACCOUNT_BASE64 = "BASE64_ENCODED_SERVICE_ACCOUNT_KEY"
  }
}
```

### Step 3: Update Authorizer Code

```typescript
const initializeFirebase = (): admin.app.App => {
  if (!firebaseApp) {
    try {
      firebaseApp = admin.app();
    } catch (error) {
      const serviceAccountKeyBase64 =
        process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
      if (!serviceAccountKeyBase64) {
        throw new Error(
          "FIREBASE_SERVICE_ACCOUNT_BASE64 environment variable not set"
        );
      }

      const serviceAccountKey = JSON.parse(
        Buffer.from(serviceAccountKeyBase64, "base64").toString("utf-8")
      );

      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccountKey),
      });
    }
  }
  return firebaseApp;
};
```

## 🔧 **Terraform Implementation**

### Option A: Secrets Manager Integration

```hcl
# Add to each authorizer Lambda's IAM policy
resource "aws_iam_policy" "firebase_secrets_policy" {
  name = "${aws_lambda_function.locations_authorizer_lambda.function_name}FirebaseSecretsPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Effect = "Allow"
      Resource = [
        "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:firebase/service-account-key*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "firebase_secrets_attachment" {
  role       = aws_iam_role.locations_authorizer_lambda_exec.name
  policy_arn = aws_iam_policy.firebase_secrets_policy.arn
}
```

### Option B: Environment Variables

```hcl
# Add to each authorizer Lambda's environment variables
environment {
  variables = {
    LOG_LEVEL = "INFO"
    FIREBASE_SERVICE_ACCOUNT_BASE64 = var.firebase_service_account_base64
  }
}
```

## 📋 **Step-by-Step Implementation**

### 1. Download Service Account Key

```bash
# From Firebase Console or using gcloud
gcloud iam service-accounts keys create firebase-service-account.json \
    --iam-account=YOUR_SERVICE_ACCOUNT_EMAIL@YOUR_PROJECT.iam.gserviceaccount.com
```

### 2. Store in Secrets Manager (Recommended)

```bash
# Create the secret
aws secretsmanager create-secret \
    --name "firebase/service-account-key" \
    --description "Firebase service account key" \
    --secret-string file://firebase-service-account.json

# Get the secret ARN for Terraform
aws secretsmanager describe-secret --secret-id "firebase/service-account-key"
```

### 3. Update Terraform Variables

Add to `variables.tf`:

```hcl
variable "firebase_service_account_base64" {
  description = "Base64 encoded Firebase service account key"
  type        = string
  sensitive   = true
}
```

### 4. Update Authorizer Code

Choose one of the approaches above and update all authorizer files.

## 🔒 **Security Best Practices**

1. **Never commit service account keys to version control**
2. **Use AWS Secrets Manager for production environments**
3. **Rotate service account keys regularly**
4. **Use least privilege IAM policies**
5. **Enable CloudTrail for audit logging**
6. **Use different service accounts for different environments**

## 🧪 **Testing**

### Test Secrets Manager Access

```bash
# Test if Lambda can access the secret
aws lambda invoke \
    --function-name LocationsAuthorizerFunction \
    --payload '{"test": "secrets"}' \
    response.json
```

### Test Firebase Authentication

```bash
# Test with a valid Firebase ID token
curl -H "Authorization: Bearer YOUR_FIREBASE_ID_TOKEN" \
     https://your-api-gateway-url/locations/districts
```

## 🚨 **Troubleshooting**

### Common Issues:

1. **"Permission denied"** - Check IAM policies
2. **"Invalid service account"** - Verify key format
3. **"Token verification failed"** - Check Firebase project configuration

### Debug Commands:

```bash
# Check Lambda logs
aws logs tail /aws/lambda/LocationsAuthorizerFunction --follow

# Verify secret exists
aws secretsmanager describe-secret --secret-id "firebase/service-account-key"

# Test service account key locally
node -e "
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');
admin.initializeApp({credential: admin.credential.cert(serviceAccount)});
console.log('Firebase initialized successfully');
"
```
