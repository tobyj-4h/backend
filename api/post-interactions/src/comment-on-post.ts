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
  body: JSON.stringify(body),
});

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    const userId =
      event.requestContext.authorizer?.claims?.sub || "unknown-user";
    const { post_id } = event.pathParameters || {};
    if (!post_id) {
      return response(400, { message: "post_id is required" });
    }

    const body = JSON.parse(event.body || "{}");
    const { comment_text } = body;
    if (!comment_text) {
      return response(400, { message: "comment_text is required" });
    }

    const commentId = `cmt_${ulid()}`;
    const timestamp = new Date().toISOString();
    const eventId = `evt_${ulid()}`;

    // Store comment event in post_events table
    await dynamoDb.send(
      new PutItemCommand({
        TableName: EVENTS_TABLE,
        Item: {
          post_id: { S: post_id },
          event_id: { S: eventId },
          user_id: { S: userId },
          event_type: { S: "comment" },
          event_value: { S: commentId },
          timestamp: { S: timestamp },
          metadata: { M: {} },
        },
      })
    );

    // Store comment in post_comments table
    await dynamoDb.send(
      new PutItemCommand({
        TableName: COMMENTS_TABLE,
        Item: {
          post_id: { S: post_id },
          comment_id: { S: commentId },
          user_id: { S: userId },
          comment_text: { S: comment_text },
          timestamp: { S: timestamp },
        },
      })
    );

    return response(201, { comment_id: commentId, timestamp });
  } catch (error) {
    console.error("Error adding comment:", error);
    return response(500, { message: "Internal server error" });
  }
};
