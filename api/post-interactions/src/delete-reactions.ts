import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import {
  DynamoDBClient,
  PutItemCommand,
  GetItemCommand,
  DeleteItemCommand,
} from "@aws-sdk/client-dynamodb";
import { ulid } from "ulid";

const dynamoDb = new DynamoDBClient({
  region: process.env.AWS_REGION || "us-east-1",
});
const EVENTS_TABLE = process.env.EVENTS_TABLE || "post_events";
const REACTIONS_TABLE = process.env.REACTIONS_TABLE || "post_reactions";
const POSTS_TABLE = process.env.POSTS_TABLE || "posts";

const response = (statusCode: number, body?: any): APIGatewayProxyResult => ({
  statusCode,
  headers: {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
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

    // Check if post exists
    const postResult = await dynamoDb.send(
      new GetItemCommand({
        TableName: POSTS_TABLE,
        Key: {
          post_id: { S: normalizedPostId },
        },
      })
    );

    if (!postResult.Item) {
      return response(404, {
        error: "Not Found",
        message: "Post not found",
      });
    }

    // Don't allow reactions on deleted posts
    if (postResult.Item.is_deleted?.BOOL === true) {
      return response(404, {
        error: "Not Found",
        message: "Post not found",
      });
    }

    // Check if user has a reaction for this post
    const existingReaction = await dynamoDb.send(
      new GetItemCommand({
        TableName: REACTIONS_TABLE,
        Key: {
          post_id: { S: normalizedPostId },
          user_id: { S: userId },
        },
      })
    );

    if (!existingReaction.Item) {
      return response(404, {
        error: "Not Found",
        message: "No reaction found for this user and post",
      });
    }

    const eventId = ulid();
    const timestamp = new Date().toISOString();
    const removedReaction = existingReaction.Item.reaction?.S;

    // Store reaction removal event in post_events table
    await dynamoDb.send(
      new PutItemCommand({
        TableName: EVENTS_TABLE,
        Item: {
          post_id: { S: normalizedPostId },
          event_id: { S: eventId },
          user_id: { S: userId },
          event_type: { S: "reaction_removed" },
          event_value: { S: removedReaction || "" },
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
    console.error("Error removing reaction from post:", error);
    return response(500, {
      error: "Internal Server Error",
      message: "Failed to remove reaction from post",
    });
  }
};
