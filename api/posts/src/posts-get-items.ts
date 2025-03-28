import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, ScanCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);
const POSTS_TABLE = process.env.POSTS_TABLE || "posts";
const REQUIRED_SCOPE = process.env.REQUIRED_SCOPE;

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    console.log("Received event:", JSON.stringify(event));

    const token = event.headers["Authorization"]?.split(" ")[1];

    if (!token) {
      console.error("Unauthorized: Missing token");
      throw new Error("Unauthorized");
    }

    // Extract scopes and user info from authorizer context
    const scopes = (event.requestContext.authorizer?.scope || "").split(" ");
    const userId = event.requestContext.authorizer?.user;
    // const claims = JSON.parse(event.requestContext.authorizer?.claims);
    // const username = claims?.username;

    console.log("scopes", scopes);
    console.log("userId", userId);
    // console.log("claims", claims);
    // console.log("username", username);

    if (
      REQUIRED_SCOPE &&
      !scopes.includes(REQUIRED_SCOPE) &&
      !scopes.includes("https://api.dev.fourhorizonsed.com/beehive.post.admin")
    ) {
      return {
        statusCode: 403,
        body: JSON.stringify({ message: "Insufficient permissions" }),
      };
    }

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
