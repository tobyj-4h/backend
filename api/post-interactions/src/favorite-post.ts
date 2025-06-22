import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";
import { ulid } from "ulid";

const dynamoDb = new DynamoDBClient({ region: "us-east-1" });

const EVENTS_TABLE = process.env.EVENTS_TABLE || "post_events";
const FAVORITES_TABLE = process.env.FAVORITES_TABLE || "post_user_favorites";

const response = (statusCode: number, body?: any): APIGatewayProxyResult => ({
  statusCode,
  headers: {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
    "Access-Control-Allow-Headers":
      "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
  },
  body: JSON.stringify(body),
});

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    // Extract user ID from Firebase authorizer
    const userId = event.requestContext.authorizer?.user;
    const { post_id } = event.pathParameters || {};

    if (!post_id) {
      return response(400, { message: "post_id is required" });
    }

    if (!userId) {
      return response(401, { message: "Unauthorized" });
    }

    // Convert post_id to uppercase for DynamoDB consistency
    const normalizedPostId = post_id.toUpperCase();

    const eventId = ulid();
    const timestamp = new Date().toISOString();

    // Store favorite event in post_events table
    await dynamoDb.send(
      new PutItemCommand({
        TableName: EVENTS_TABLE,
        Item: {
          post_id: { S: normalizedPostId },
          event_id: { S: eventId },
          user_id: { S: userId },
          event_type: { S: "favorite" },
          event_value: { BOOL: true },
          timestamp: { S: timestamp },
        },
      })
    );

    // Add post to post_user_favorites table
    await dynamoDb.send(
      new PutItemCommand({
        TableName: FAVORITES_TABLE,
        Item: {
          user_id: { S: userId },
          post_id: { S: normalizedPostId },
          timestamp: { S: timestamp },
        },
      })
    );

    return response(201, {
      id: eventId,
      post_id: normalizedPostId,
      user_id: userId,
      timestamp: timestamp,
    });
  } catch (error) {
    console.error("Error favoriting post:", error);
    return response(500, { message: "Internal server error" });
  }
};
