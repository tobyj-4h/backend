import {
  APIGatewayTokenAuthorizerEvent,
  APIGatewayAuthorizerResult,
} from "aws-lambda";
import axios from "axios";
import jwkToPem from "jwk-to-pem";
import jwt, { JwtPayload } from "jsonwebtoken";

// Environment variables
const REGION = process.env.AWS_REGION || "us-east-1";
const USER_POOL_ID = process.env.USER_POOL_ID || "";
const JWKS_URL = `https://cognito-idp.${REGION}.amazonaws.com/${USER_POOL_ID}/.well-known/jwks.json`;

// Cache for public keys
let cachedKeys: { [key: string]: string } = {};

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
    const decodedToken = await verifyToken(token);

    console.log("Decoded token:", decodedToken);

    const policy = generatePolicy(
      decodedToken.sub || "user",
      "Allow",
      event.methodArn,
      {
        sub: decodedToken.sub,
        username: decodedToken["cognito:username"], // or decodedToken.username depending on your token
        email: decodedToken.email,
      }
    );

    console.log("Generated policy:", JSON.stringify(policy));
    return policy;
  } catch (error) {
    if (error instanceof Error) {
      console.error("Authorization error:", error.message);
    } else {
      console.error("An unknown error occured.");
    }
    throw new Error("Unauthorized");
  }
};

/**
 * Verifies and decodes a JWT token.
 * @param token - The JWT token
 * @returns Decoded JWT payload
 */
const verifyToken = async (token: string): Promise<JwtPayload> => {
  const decodedHeader = jwt.decode(token, { complete: true });

  console.log("decodedHeader", decodedHeader);
  console.log("typeof decodedHeader", typeof decodedHeader);

  if (!decodedHeader || typeof decodedHeader === "string") {
    throw new Error("Invalid token: Unable to decode header");
  }

  const { kid } = decodedHeader.header;
  if (!kid) {
    throw new Error("Invalid token: Missing 'kid' in header");
  }

  const publicKey = await getPublicKey(kid);

  try {
    return jwt.verify(token, publicKey, {
      algorithms: ["RS256"],
    }) as JwtPayload;
  } catch (err) {
    throw new Error("Invalid token: Signature verification failed");
  }
};

/**
 * Retrieves a public key for the given key ID (kid).
 * @param kid - Key ID from the token header
 * @returns Public key in PEM format
 */
const getPublicKey = async (kid: string): Promise<string> => {
  if (cachedKeys[kid]) {
    console.log(`Cache hit for kid: ${kid}`);
    return cachedKeys[kid];
  }

  try {
    console.log(`Fetching JWKS from ${JWKS_URL}`);
    const response = await axios.get(JWKS_URL);
    const jwks = response.data.keys;

    console.log(`JWKS fetched successfully: ${JSON.stringify(jwks)}`);

    const key = jwks.find((key: any) => key.kid === kid);
    if (!key) {
      console.error(`Key with kid ${kid} not found in JWKS`);
      throw new Error("Public key not found for the given 'kid'");
    }

    const pem = jwkToPem(key);
    cachedKeys[kid] = pem;

    console.log(`Public key for kid ${kid} converted and cached`);
    return pem;
  } catch (error) {
    if (error instanceof Error) {
      console.error(`Failed to fetch or process JWKS: ${error.message}`);
    } else {
      console.error("Unknown error.");
    }
    throw new Error("Unable to retrieve public keys");
  }
};

/**
 * Generates an IAM policy document.
 * @param principalId - The principal user ID
 * @param effect - "Allow" or "Deny"
 * @param resource - The resource ARN
 * @param claims
 * @returns IAM policy document
 */
const generatePolicy = (
  principalId: string,
  effect: "Allow" | "Deny",
  resource: string,
  claims: Record<string, any> = {}
): APIGatewayAuthorizerResult => {
  // Parse the methodArn to create a more permissive version if needed
  const arnParts = resource.split(":");
  const apiGatewayArnPart = arnParts[5].split("/");
  const restApiId = apiGatewayArnPart[0];
  const stage = apiGatewayArnPart[1];
  const httpVerb = apiGatewayArnPart[2];

  // Allow access to this endpoint for any stage
  const resourceArn = `arn:aws:execute-api:${arnParts[3]}:${arnParts[4]}:${restApiId}/*/${httpVerb}/`;

  // Keep the original resource ARN
  // const resourceArn = resource;

  const policyDocument = {
    Version: "2012-10-17",
    Statement: [
      {
        Action: "execute-api:Invoke",
        Effect: effect,
        Resource: resourceArn,
      },
    ],
  };

  return {
    principalId,
    policyDocument,
    context: {
      user: principalId,
      claims: JSON.stringify(claims),
    },
  };
};
