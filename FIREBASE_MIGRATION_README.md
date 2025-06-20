# Firebase Migration Guide

## Overview

This project has been migrated from AWS Cognito to Firebase Authentication for custom authorizers.

## Changes Made

### 1. Updated Custom Authorizers

The following custom authorizers have been updated to use Firebase instead of Cognito:

- `api/locations/src/locations-authorizer.ts`
- `api/media/src/media-authorizer.ts`
- `api/posts/src/posts-authorizer.ts`
- `api/user/src/user-authorizer.ts`
- `api/post-interactions/src/post-interactions-authorizer.ts` (newly created)

### 2. Dependencies Added

Added `firebase-admin: ^12.0.0` to the following package.json files:

- `api/locations/package.json`
- `api/media/package.json`
- `api/posts/package.json`
- `api/user/package.json`
- `api/post-interactions/package.json`

## Key Differences from Cognito

| Aspect       | Cognito (Old)         | Firebase (New)          |
| ------------ | --------------------- | ----------------------- |
| Token Source | AWS Cognito User Pool | Firebase Authentication |
| Token Type   | Cognito ID Token      | Firebase ID Token       |
| User ID      | `sub` claim           | `uid` claim             |
| Username     | `cognito:username`    | `name` claim            |
| Email        | `email` claim         | `email` claim           |

## Firebase Setup Requirements

### 1. Environment Variables

Each Lambda function needs Firebase credentials. You can set these up in several ways:

#### Option A: Service Account Key (Recommended for production)

1. Download your Firebase service account key from Firebase Console
2. Store it securely (AWS Secrets Manager, environment variables, etc.)
3. Update the authorizer code to use:

```typescript
firebaseApp = admin.initializeApp({
  credential: admin.credential.cert(serviceAccountKey),
});
```

#### Option B: Application Default Credentials (Good for development)

1. Set up Google Cloud credentials
2. The authorizer will automatically use application default credentials

### 2. Lambda Environment Variables

Add these to your Lambda functions:

- `GOOGLE_APPLICATION_CREDENTIALS` (if using service account file)
- Or set up IAM roles with appropriate permissions

### 3. Firebase Project Configuration

Ensure your Firebase project is properly configured with:

- Authentication enabled
- Appropriate sign-in methods
- Custom claims if needed

## Installation Steps

1. Install dependencies in each API project:

```bash
cd api/locations && npm install
cd api/media && npm install
cd api/posts && npm install
cd api/user && npm install
cd api/post-interactions && npm install
```

2. Build each project:

```bash
cd api/locations && npm run build
cd api/media && npm run build
cd api/posts && npm run build
cd api/user && npm run build
cd api/post-interactions && npm run build
```

## Client Changes Required

Your client application should now send Firebase ID tokens instead of Cognito tokens:

```javascript
// Old Cognito approach
const token = cognitoUser.getSignInUserSession().getIdToken().getJwtToken();

// New Firebase approach
const token = await firebase.auth().currentUser.getIdToken();
```

## Testing

To test the authorizers:

1. Get a valid Firebase ID token from your client
2. Send requests with header: `Authorization: Bearer <firebase_id_token>`
3. Check CloudWatch logs for authorization results

## Troubleshooting

### Common Issues:

1. **"Invalid Firebase token"** - Ensure the token is a valid Firebase ID token
2. **"Firebase not initialized"** - Check Firebase credentials setup
3. **"Unauthorized"** - Verify the token hasn't expired and is properly formatted

### Debug Steps:

1. Check CloudWatch logs for detailed error messages
2. Verify Firebase project configuration
3. Ensure Lambda has proper IAM permissions
4. Test token verification locally if needed

## Security Considerations

1. **Token Expiration**: Firebase ID tokens expire after 1 hour by default
2. **Token Refresh**: Implement token refresh logic in your client
3. **Custom Claims**: Use Firebase custom claims for role-based access control
4. **Environment Isolation**: Use different Firebase projects for dev/staging/prod

## Migration Checklist

- [ ] Install Firebase Admin SDK in all API projects
- [ ] Set up Firebase credentials for Lambda functions
- [ ] Update client to send Firebase ID tokens
- [ ] Test all authorizers with Firebase tokens
- [ ] Update any hardcoded Cognito references
- [ ] Remove Cognito dependencies if no longer needed
- [ ] Update documentation and deployment scripts
