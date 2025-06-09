import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);
const PREFERENCES_TABLE = process.env.PREFERENCES_TABLE || "user_preferences";

interface UserPreferences {
  PK: string;
  SK: string;
  user_id: string;
  locations: any[];
  schools: string[];
  districts: string[];
  topics: string[];
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

    // Validate required fields
    if (!Array.isArray(requestBody.locations)) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({
          error: "locations is required and must be an array",
        }),
      };
    }

    if (!Array.isArray(requestBody.schools)) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({
          error: "schools is required and must be an array",
        }),
      };
    }

    if (!Array.isArray(requestBody.districts)) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({
          error: "districts is required and must be an array",
        }),
      };
    }

    if (!Array.isArray(requestBody.topics)) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({
          error: "topics is required and must be an array",
        }),
      };
    }

    const timestamp = new Date().toISOString();

    const userPreferences: UserPreferences = {
      PK: `USER#${userId}`,
      SK: `PREFERENCES#${userId}`,
      user_id: userId,
      locations: requestBody.locations,
      schools: requestBody.schools,
      districts: requestBody.districts,
      topics: requestBody.topics,
      created_at: timestamp,
    };

    const params = new PutCommand({
      TableName: PREFERENCES_TABLE,
      Item: userPreferences,
    });

    await dynamoDb.send(params);

    return {
      statusCode: 201,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify(userPreferences),
    };
  } catch (error) {
    console.error("Error creating user preferences:", error);

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ error: "Failed to create user preferences" }),
    };
  }
};
