import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);
const TABLE_NAME = process.env.TABLE_NAME || "user_profile";

interface UserProfile {
  user_id: string;
  first_name: string;
  last_name: string;
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

    if (!requestBody.content) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({ error: "Content is required" }),
      };
    }

    const timestamp = new Date().toISOString();

    const userProfile: UserProfile = {
      user_id: userId,
      first_name: requestBody.first_name,
      last_name: requestBody.last_name,
      created_at: timestamp,
    };

    const params = new PutCommand({
      TableName: TABLE_NAME,
      Item: userProfile,
    });

    await dynamoDb.send(params);

    return {
      statusCode: 201,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify(userProfile),
    };
  } catch (error) {
    console.error("Error creating user profile:", error);

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ error: "Failed to create user profile" }),
    };
  }
};
