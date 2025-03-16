import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";
import { ulid } from "ulid";

const dynamoDb = new DynamoDBClient({
  region: process.env.AWS_REGION || "us-east-1",
});
// const EVENTS_TABLE = process.env.EVENTS_TABLE || "post_events";
const VIEWS_TABLE = process.env.VIEWS_TABLE || "post_views";

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
    const timestamp = Date.now();

    // Store raw view event in post_views table
    await dynamoDb.send(
      new PutItemCommand({
        TableName: VIEWS_TABLE,
        Item: {
          post_id: { S: post_id },
          timestamp: { N: timestamp.toString() },
          user_id: { S: userId },
        },
      })
    );

    // // Store view event in post_events table
    // await dynamoDb.send(
    //   new PutItemCommand({
    //     TableName: EVENTS_TABLE,
    //     Item: {
    //       post_id: { S: post_id },
    //       event_id: { S: eventId },
    //       user_id: { S: userId },
    //       event_type: { S: "view" },
    //       event_value: { NULL: true },
    //       timestamp: { S: new Date(timestamp).toISOString() },
    //     },
    //   })
    // );

    return response(201, { message: "View recorded successfully" });
  } catch (error) {
    console.error("Error recording view:", error);
    return response(500, { message: "Internal server error" });
  }
};
