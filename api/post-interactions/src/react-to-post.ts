import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";
import { ulid } from "ulid";

const dynamoDb = new DynamoDBClient({
  region: process.env.AWS_REGION || "us-east-1",
});
const EVENTS_TABLE = process.env.EVENTS_TABLE || "post_events";
const REACTIONS_TABLE = process.env.REACTIONS_TABLE || "post_reactions";

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
    const { reaction } = body;
    if (!reaction) {
      return response(400, { message: "reaction is required" });
    }

    const eventId = `evt_${ulid()}`;
    const timestamp = new Date().toISOString();

    // Store reaction event in post_events table
    await dynamoDb.send(
      new PutItemCommand({
        TableName: EVENTS_TABLE,
        Item: {
          post_id: { S: post_id },
          event_id: { S: eventId },
          user_id: { S: userId },
          event_type: { S: "reaction" },
          event_value: { S: reaction },
          timestamp: { S: timestamp },
        },
      })
    );

    // Store reaction in post_reactions table
    await dynamoDb.send(
      new PutItemCommand({
        TableName: REACTIONS_TABLE,
        Item: {
          post_id: { S: post_id },
          reaction: { S: reaction },
          user_id: { S: userId },
          timestamp: { S: timestamp },
        },
      })
    );

    return response(201, { message: "Reaction added successfully" });
  } catch (error) {
    console.error("Error reacting to post:", error);
    return response(500, { message: "Internal server error" });
  }
};
