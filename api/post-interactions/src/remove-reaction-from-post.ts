import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import {
  DynamoDBClient,
  PutItemCommand,
  DeleteItemCommand,
} from "@aws-sdk/client-dynamodb";
import { ulid } from "ulid";

const dynamoDb = new DynamoDBClient({
  region: process.env.AWS_REGION || "us-east-1",
});
const EVENTS_TABLE = process.env.EVENTS_TABLE || "post_events";
const REACTIONS_TABLE = process.env.REACTIONS_TABLE || "post_reactions";

// Valid reaction types
const VALID_REACTIONS = [
  "like",
  "love",
  "laugh",
  "wow",
  "sad",
  "angry",
  "👍",
  "❤️",
  "🔄",
  "💬",
];

const response = (statusCode: number, body?: any): APIGatewayProxyResult => ({
  statusCode,
  headers: {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS,DELETE",
    "Access-Control-Allow-Headers":
      "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
  },
  body: body ? JSON.stringify(body) : "",
});

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    // Extract user ID from Firebase authorizer
    const userId = event.requestContext.authorizer?.user;
    const { post_id } = event.pathParameters || {};

    if (!post_id) {
      return response(400, {
        error: "Bad Request",
        message: "post_id is required",
      });
    }

    if (!userId) {
      return response(401, {
        error: "Unauthorized",
        message: "Authentication required",
      });
    }

    // Convert post_id to uppercase for DynamoDB consistency
    const normalizedPostId = post_id.toUpperCase();

    const body = JSON.parse(event.body || "{}");
    const { reaction } = body;
    if (!reaction) {
      return response(400, {
        error: "Bad Request",
        message: "reaction is required",
      });
    }

    if (!VALID_REACTIONS.includes(reaction)) {
      return response(400, {
        error: "Bad Request",
        message: `Invalid reaction type. Must be one of: ${VALID_REACTIONS.join(
          ", "
        )}`,
      });
    }

    const eventId = ulid();
    const timestamp = new Date().toISOString();

    // Store remove reaction event in post_events table
    await dynamoDb.send(
      new PutItemCommand({
        TableName: EVENTS_TABLE,
        Item: {
          post_id: { S: normalizedPostId },
          event_id: { S: eventId },
          user_id: { S: userId },
          event_type: { S: "unreaction" },
          event_value: { S: reaction },
          timestamp: { S: timestamp },
        },
      })
    );

    // Remove reaction from post_reactions table
    await dynamoDb.send(
      new DeleteItemCommand({
        TableName: REACTIONS_TABLE,
        Key: {
          post_id: { S: normalizedPostId },
          user_id: { S: userId },
        },
      })
    );

    return response(204);
  } catch (error) {
    console.error("Error removing reaction:", error);
    return response(500, {
      error: "Internal Server Error",
      message: "Failed to remove reaction from post",
    });
  }
};
