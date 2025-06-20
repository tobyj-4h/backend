import {
  APIGatewayTokenAuthorizerEvent,
  APIGatewayAuthorizerResult,
} from "aws-lambda";
import * as admin from "firebase-admin";
import { SecretsManager } from "@aws-sdk/client-secrets-manager";

// Initialize Firebase Admin SDK
let firebaseApp: admin.app.App;

/**
 * Initialize Firebase Admin SDK
 */
const initializeFirebase = async (): Promise<admin.app.App> => {
  if (!firebaseApp) {
    // Check if Firebase is already initialized
    try {
      firebaseApp = admin.app();
    } catch (error) {
      // Fetch service account key from Secrets Manager
      const secretsManager = new SecretsManager({
        region: process.env.AWS_REGION || "us-east-1",
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

/**
 * Lambda function handler
 */
export const handler = async (
  event: APIGatewayTokenAuthorizerEvent
): Promise<APIGatewayAuthorizerResult> => {
  console.log("Received event:", JSON.stringify(event));

  const token = event.authorizationToken?.split(" ")[1];

  if (!token) {
    console.error("Unauthorized: Missing token");
    throw new Error("Unauthorized");
  }

  try {
    // Verify Firebase ID token
    const decodedToken = await verifyFirebaseToken(token);
    console.log("Decoded Firebase token:", decodedToken);

    // Parse the ARN to create a policy that covers all endpoints
    const arnParts = event.methodArn.split(":");
    const apiGatewayArnPart = arnParts[5].split("/");
    const restApiId = apiGatewayArnPart[0];
    const stage = apiGatewayArnPart[1];
    const region = arnParts[3];
    const account = arnParts[4];

    const allowedResources = [
      `arn:aws:execute-api:${region}:${account}:${restApiId}/${stage}/*/comment`,
      `arn:aws:execute-api:${region}:${account}:${restApiId}/${stage}/*/favorite`,
      `arn:aws:execute-api:${region}:${account}:${restApiId}/${stage}/*/unfavorite`,
      `arn:aws:execute-api:${region}:${account}:${restApiId}/${stage}/*/react`,
      `arn:aws:execute-api:${region}:${account}:${restApiId}/${stage}/*/remove-reaction`,
      `arn:aws:execute-api:${region}:${account}:${restApiId}/${stage}/*/view`,
      `arn:aws:execute-api:${region}:${account}:${restApiId}/${stage}/*/flush-view-counts`,
    ];

    // Get the principalId from Firebase UID
    const principalId = decodedToken.uid || "user";

    // Generate a policy with the permissive resource pattern
    const policy = generatePolicy(
      principalId,
      "Allow",
      allowedResources,
      decodedToken.email || "",
      decodedToken.name || "",
      decodedToken.email || ""
    );

    console.log("Generated policy:", JSON.stringify(policy));
    return policy;
  } catch (error) {
    if (error instanceof Error) {
      console.error("Authorization error:", error.message);
    } else {
      console.error("An unknown error occurred.");
    }
    throw new Error("Unauthorized");
  }
};

/**
 * Verifies and decodes a Firebase ID token.
 * @param idToken - The Firebase ID token
 * @returns Decoded Firebase token claims
 */
const verifyFirebaseToken = async (
  idToken: string
): Promise<admin.auth.DecodedIdToken> => {
  try {
    const app = await initializeFirebase();
    const auth = app.auth();

    const decodedToken = await auth.verifyIdToken(idToken);
    return decodedToken;
  } catch (error) {
    console.error("Firebase token verification failed:", error);
    throw new Error("Invalid Firebase token");
  }
};

/**
 * Generates an IAM policy document.
 * @param principalId - The principal user ID (Firebase UID)
 * @param effect - "Allow" or "Deny"
 * @param resources - The resource ARNs
 * @param email - User email
 * @param name - User name
 * @param userEmail - User email (duplicate for compatibility)
 * @returns IAM policy document
 */
const generatePolicy = (
  principalId: string,
  effect: "Allow" | "Deny",
  resources: string[],
  email: string,
  name: string,
  userEmail: string
): APIGatewayAuthorizerResult => {
  const policyDocument = {
    Version: "2012-10-17",
    Statement: [
      {
        Action: "execute-api:Invoke",
        Effect: effect,
        Resource: resources,
      },
    ],
  };

  const policy = {
    principalId: principalId,
    policyDocument,
    context: {
      user: principalId,
      username: name,
      email: email,
      uid: principalId,
    },
  };

  return policy;
};
