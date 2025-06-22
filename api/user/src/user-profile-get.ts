import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);
const PROFILE_TABLE = process.env.PROFILE_TABLE || "user_profile";

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

    const params = new GetCommand({
      TableName: PROFILE_TABLE,
      Key: {
        PK: `USER#${userId}`,
        SK: `PROFILE#${userId}`,
      },
    });

    const result = await dynamoDb.send(params);

    if (!result.Item) {
      return {
        statusCode: 404,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({ error: "Profile not found" }),
      };
    }

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify(result.Item),
    };
  } catch (error) {
    console.error("Error getting user profile:", error);

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
