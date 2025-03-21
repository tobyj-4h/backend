import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { ulid } from "ulid";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);
const POSTS_TABLE = process.env.POSTS_TABLE || "posts";

interface Post {
  id: string;
  user_id: string;
  username: string;
  avatar_url: string;
  timestamp: string;
  content: string;
  media_items?: Array<{
    url: string;
    type: string;
    alt_text?: string;
  }>;
  interaction_settings?: Array<{
    action: string;
    effect: string;
    value: string;
  }>;
  is_edited: boolean;
  edited_timestamp?: string;
  is_deleted: boolean;
}

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    const requestBody = JSON.parse(event.body || "{}");

    // Extract user information from request context or JWT token
    const userId =
      event.requestContext.authorizer?.claims?.sub || "unknown-user";
    const username =
      event.requestContext.authorizer?.claims?.username || "anonymous";

    // Validate required fields
    if (!requestBody.content) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({ error: "Content is required" }),
      };
    }

    const timestamp = new Date().toISOString();
    const postId = ulid();

    const post: Post = {
      id: postId,
      user_id: userId,
      username: username,
      avatar_url: requestBody.avatar_url || "",
      timestamp: timestamp,
      content: requestBody.content,
      media_items: requestBody.media_items || [],
      interaction_settings: requestBody.interaction_settings || [],
      is_edited: false,
      is_deleted: false,
    };

    const params = new PutCommand({
      TableName: POSTS_TABLE,
      Item: {
        post_id: postId,
        ...post,
      },
    });

    await dynamoDb.send(params);

    return {
      statusCode: 201,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify(post),
    };
  } catch (error) {
    console.error("Error creating post:", error);

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ error: "Failed to create post" }),
    };
  }
};
