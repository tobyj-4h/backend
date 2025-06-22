import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";
import { ulid } from "ulid";

const dynamoDb = new DynamoDBClient({
  region: process.env.AWS_REGION || "us-east-1",
});
const EVENTS_TABLE = process.env.EVENTS_TABLE || "post_events";
const COMMENTS_TABLE = process.env.COMMENTS_TABLE || "post_comments";

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

    const body = JSON.parse(event.body || "{}");
    const { comment_text } = body;
    if (!comment_text) {
      return response(400, { message: "comment_text is required" });
    }

    const commentId = ulid();
    const timestamp = new Date().toISOString();
    const eventId = ulid();

    // Store comment event in post_events table
    await dynamoDb.send(
      new PutItemCommand({
        TableName: EVENTS_TABLE,
        Item: {
          post_id: { S: normalizedPostId },
          event_id: { S: eventId },
          user_id: { S: userId },
          event_type: { S: "comment" },
          event_value: { S: commentId },
          timestamp: { S: timestamp },
        },
      })
    );

    // Store comment in post_comments table
    await dynamoDb.send(
      new PutItemCommand({
        TableName: COMMENTS_TABLE,
        Item: {
          post_id: { S: normalizedPostId },
          comment_id: { S: commentId },
          user_id: { S: userId },
          comment_text: { S: comment_text },
          timestamp: { S: timestamp },
        },
      })
    );

    return response(201, {
      id: eventId,
      post_id: normalizedPostId,
      user_id: userId,
      comment_id: commentId,
      comment_text: comment_text,
      timestamp: timestamp,
    });
  } catch (error) {
    console.error("Error adding comment:", error);
    return response(500, { message: "Internal server error" });
  }
};
