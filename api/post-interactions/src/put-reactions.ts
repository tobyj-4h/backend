import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import {
  DynamoDBClient,
  PutItemCommand,
  GetItemCommand,
  UpdateItemCommand,
} from "@aws-sdk/client-dynamodb";
import { ulid } from "ulid";

const dynamoDb = new DynamoDBClient({
  region: process.env.AWS_REGION || "us-east-1",
});
const EVENTS_TABLE = process.env.EVENTS_TABLE || "post_events";
const REACTIONS_TABLE = process.env.REACTIONS_TABLE || "post_reactions";
const POSTS_TABLE = process.env.POSTS_TABLE || "posts";

// Valid reaction types
const VALID_REACTIONS = ["like", "love", "laugh", "wow", "sad", "angry"];

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

    // Check if user already has a reaction for this post
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
        message:
          "No existing reaction found for this user and post. Use POST to create a new reaction.",
      });
    }

    const eventId = ulid();
    const timestamp = new Date().toISOString();
    const oldReaction = existingReaction.Item.reaction?.S;

    // Store reaction update event in post_events table
    await dynamoDb.send(
      new PutItemCommand({
        TableName: EVENTS_TABLE,
        Item: {
          post_id: { S: normalizedPostId },
          event_id: { S: eventId },
          user_id: { S: userId },
          event_type: { S: "reaction_update" },
          event_value: {
            S: JSON.stringify({ old: oldReaction, new: reaction }),
          },
          timestamp: { S: timestamp },
        },
      })
    );

    // Update reaction in post_reactions table
    await dynamoDb.send(
      new UpdateItemCommand({
        TableName: REACTIONS_TABLE,
        Key: {
          post_id: { S: normalizedPostId },
          user_id: { S: userId },
        },
        UpdateExpression: "SET reaction = :reaction, timestamp = :timestamp",
        ExpressionAttributeValues: {
          ":reaction": { S: reaction },
          ":timestamp": { S: timestamp },
        },
      })
    );

    return response(200, {
      id: eventId,
      post_id: normalizedPostId,
      user_id: userId,
      reaction: reaction,
      timestamp: timestamp,
    });
  } catch (error) {
    console.error("Error updating reaction on post:", error);
    return response(500, {
      error: "Internal Server Error",
      message: "Failed to update reaction on post",
    });
  }
};
