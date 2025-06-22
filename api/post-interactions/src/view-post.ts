import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import {
  DynamoDBClient,
  PutItemCommand,
  UpdateItemCommand,
} from "@aws-sdk/client-dynamodb";
import { ulid } from "ulid";

const dynamoDb = new DynamoDBClient({
  region: process.env.AWS_REGION || "us-east-1",
});
// const EVENTS_TABLE = process.env.EVENTS_TABLE || "post_events";
const VIEWS_TABLE = process.env.VIEWS_TABLE || "post_views";
const VIEW_COUNTERS_TABLE =
  process.env.VIEW_COUNTERS_TABLE || "post_view_counters";

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

    const timestamp = Date.now();

    // Store raw view event in post_views table
    await dynamoDb.send(
      new PutItemCommand({
        TableName: VIEWS_TABLE,
        Item: {
          post_id: { S: normalizedPostId },
          timestamp: { N: timestamp.toString() },
          user_id: { S: userId },
        },
      })
    );

    // Update view counter atomically
    await dynamoDb.send(
      new UpdateItemCommand({
        TableName: VIEW_COUNTERS_TABLE,
        Key: {
          post_id: { S: normalizedPostId },
        },
        UpdateExpression:
          "SET view_count = if_not_exists(view_count, :zero) + :inc",
        ExpressionAttributeValues: {
          ":inc": { N: "1" },
          ":zero": { N: "0" },
        },
      })
    );

    return response(201, {
      post_id: normalizedPostId,
      user_id: userId,
      timestamp: new Date(timestamp).toISOString(),
    });
  } catch (error) {
    console.error("Error recording view:", error);
    return response(500, { message: "Internal server error" });
  }
};
