import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { ulid } from "ulid";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);
const POSTS_TABLE = process.env.POSTS_TABLE || "posts";
const REQUIRED_SCOPE = process.env.REQUIRED_SCOPE;

interface Post {
  id: string;
  user_id: string;
  username: string;
  avatar_url: string;
  timestamp: string;
  content: string;
  content_json?: any;
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
    console.log("Received event:", JSON.stringify(event));

    const token = event.headers["Authorization"]?.split(" ")[1];

    if (!token) {
      console.error("Unauthorized: Missing token");
      throw new Error("Unauthorized");
    }

    const scopes = (event.requestContext.authorizer?.scope || "").split(" ");
    const userId = event.requestContext.authorizer?.user;

    console.log("scopes", scopes);
    console.log("userId", userId);

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

    const requestBody = JSON.parse(event.body || "{}");

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
      username: requestBody.username || "", // Default to empty string if not provided
      avatar_url: requestBody.avatar_url || "",
      timestamp: timestamp,
      content: requestBody.content,
      content_json: requestBody.content_json || null,
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
