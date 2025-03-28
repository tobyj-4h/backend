import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);
const POSTS_TABLE = process.env.POSTS_TABLE || "posts";
const REQUIRED_SCOPE = process.env.REQUIRED_SCOPE;

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    console.log(
      "authorizer",
      JSON.stringify(event.requestContext.authorizer, null, 2)
    );

    // Extract scopes and user info from authorizer context
    const scopes = (event.requestContext.authorizer?.scopes || "").split(" ");
    const userId = event.requestContext.authorizer?.user;
    const claims = JSON.parse(event.requestContext.authorizer?.claims);
    const username = claims?.username;

    console.log("scopes", scopes);
    console.log("userId", userId);
    console.log("claims", claims);
    console.log("username", username);

    if (
      REQUIRED_SCOPE &&
      !scopes.includes(REQUIRED_SCOPE) &&
      !scopes.includes("admin")
    ) {
      return {
        statusCode: 403,
        body: JSON.stringify({ message: "Insufficient permissions" }),
      };
    }

    const postId = event.pathParameters?.post_id;

    if (!postId) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({ error: "Post ID is required" }),
      };
    }

    const params = new GetCommand({
      TableName: POSTS_TABLE,
      Key: {
        post_id: postId,
      },
    });

    const result = await dynamoDb.send(params);

    if (!result.Item) {
      return {
        statusCode: 404,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({ error: "Post not found" }),
      };
    }

    // Don't return posts marked as deleted
    if (result.Item.is_deleted) {
      return {
        statusCode: 404,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({ error: "Post not found" }),
      };
    }

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify(result.Item),
    };
  } catch (error) {
    console.error("Error retrieving post:", error);

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ error: "Failed to retrieve post" }),
    };
  }
};
