import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  PutCommand,
  UpdateCommand,
  QueryCommand,
} from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);
const PROFILE_TABLE = process.env.PROFILE_TABLE || "user_profile";

interface UserProfile {
  PK: string;
  SK: string;
  user_id: string;
  first_name: string;
  last_name: string;
  handle: string;
  profile_picture_url?: string;
  onboarding_complete?: boolean;
  onboarding_complete_at?: string;
  created_at: string;
}

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    console.log("Received event:", JSON.stringify(event));

    const token = event.headers["Authorization"]?.split(" ")[1];

    if (!token) {
      console.error("Unauthorized: Missing token");
      throw new Error("Unauthorized");
    }

    const userId = event.requestContext.authorizer?.user;
    console.log("userId", userId);

    const requestBody = JSON.parse(event.body || "{}");
    const timestamp = new Date().toISOString();

    const userProfile: UserProfile = {
      PK: `USER#${userId}`,
      SK: `PROFILE#${userId}`,
      user_id: userId,
      first_name: requestBody.firstName,
      last_name: requestBody.lastName,
      handle: requestBody.handle,
      profile_picture_url: requestBody.profilePictureUrl,
      onboarding_complete: requestBody.onboardingComplete,
      onboarding_complete_at: timestamp,
      created_at: timestamp,
    };

    const params = new PutCommand({
      TableName: PROFILE_TABLE,
      Item: userProfile,
    });

    await dynamoDb.send(params);

    return {
      statusCode: 201,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify(userProfile),
    };
  } catch (error) {
    console.error("Error creating user profile:", error);

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ error: "Failed to create user profile" }),
    };
  }
};
