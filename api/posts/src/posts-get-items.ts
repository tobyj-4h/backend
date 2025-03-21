import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, ScanCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);
const POSTS_TABLE = process.env.POSTS_TABLE || "posts";

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    const queryParams = event.queryStringParameters || {};

    // Placeholder for future filtering logic
    console.log("Received query parameters:", queryParams);

    const params = new ScanCommand({
      TableName: POSTS_TABLE,
    });

    const result = await dynamoDb.send(params);

    // Filter out deleted posts
    const posts = result.Items?.filter((post) => !post.is_deleted) || [];

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify(posts),
    };
  } catch (error) {
    console.error("Error retrieving posts:", error);

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ error: "Failed to retrieve posts" }),
    };
  }
};
