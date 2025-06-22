import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, QueryCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);
const TABLE_NAME = process.env.TABLE_NAME || "user_profile";
const HANDLE_INDEX = "HandleIndex"; // The name of the GSI

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    console.log("Received event:", JSON.stringify(event));

    // Extract the handle from the path parameters
    const handle = event.pathParameters?.handle;
    if (!handle) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({ error: "Handle is required" }),
      };
    }

    // Query the GSI for the given handle
    const params = new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: HANDLE_INDEX,
      KeyConditionExpression: "handle = :handle",
      ExpressionAttributeValues: {
        ":handle": handle,
      },
      Limit: 1, // We only need to check if one exists
    });

    const result = await dynamoDb.send(params);

    // If any item exists, the handle is already taken
    if (result.Items && result.Items.length > 0) {
      console.info(`Handle: ${handle} is already taken.`);
      return {
        statusCode: 200, // Handle exists
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({ available: false }),
      };
    }

    console.info(`Handle: ${handle} does not exist.`);
    return {
      statusCode: 404, // Handle does not exist (available)
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ available: true }),
    };
  } catch (error) {
    console.error("Error checking handle uniqueness:", error);

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ error: "Failed to check handle uniqueness" }),
    };
  }
};
