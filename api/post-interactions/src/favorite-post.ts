import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";
import { ulid } from "ulid";

const dynamoDb = new DynamoDBClient({ region: "us-east-1" });

const EVENTS_TABLE = process.env.EVENTS_TABLE || "post_events";
const FAVORITES_TABLE = process.env.COMMENTS_TABLE || "post_user_favorites";

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

    const eventId = `evt_${ulid()}`;
    const timestamp = new Date().toISOString();

    // Store favorite event in post_events table
    await dynamoDb.send(
      new PutItemCommand({
        TableName: EVENTS_TABLE,
        Item: {
          post_id: { S: post_id },
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
          post_id: { S: post_id },
          timestamp: { S: timestamp },
        },
      })
    );

    return response(201, { message: "Post favorited successfully" });
  } catch (error) {
    console.error("Error favoriting post:", error);
    return response(500, { message: "Internal server error" });
  }
};
