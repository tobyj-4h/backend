import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  PutCommand,
  GetCommand,
} from "@aws-sdk/lib-dynamodb";
import { ulid } from "ulid";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);
const POSTS_TABLE = process.env.POSTS_TABLE || "posts";
const USER_PROFILE_TABLE = process.env.USER_PROFILE_TABLE || "user_profile";
const REQUIRED_SCOPE = process.env.REQUIRED_SCOPE;

interface UserProfile {
  handle: string;
  profile_picture_url?: string;
  first_name: string;
  last_name: string;
}

interface Post {
  id: string;
  user_id: string;
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

interface PostWithUserInfo extends Post {
  user?: UserProfile;
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

    // if (
    //   REQUIRED_SCOPE &&
    //   !scopes.includes(REQUIRED_SCOPE) &&
    //   !scopes.includes("https://api.dev.fourhorizonsed.com/beehive.post.admin")
    // ) {
    //   return {
    //     statusCode: 403,
    //     body: JSON.stringify({ message: "Insufficient permissions" }),
    //   };
    // }

    const requestBody = JSON.parse(event.body || "{}");

    if (!requestBody.content) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
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

    // Fetch user profile information
    let postWithUserInfo: PostWithUserInfo = { ...post };

    try {
      const userProfileParams = new GetCommand({
        TableName: USER_PROFILE_TABLE,
        Key: {
          PK: `USER#${userId}`,
          SK: `PROFILE#${userId}`,
        },
        ProjectionExpression:
          "user_id, handle, profile_picture_url, first_name, last_name",
      });

      const userProfileResult = await dynamoDb.send(userProfileParams);

      if (userProfileResult.Item) {
        postWithUserInfo.user = {
          handle: userProfileResult.Item.handle,
          profile_picture_url: userProfileResult.Item.profile_picture_url,
          first_name: userProfileResult.Item.first_name,
          last_name: userProfileResult.Item.last_name,
        };
      }
    } catch (userError) {
      console.error("Error fetching user profile:", userError);
      // Continue without user info rather than failing the entire request
    }

    return {
      statusCode: 201,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify(postWithUserInfo),
    };
  } catch (error) {
    console.error("Error creating post:", error);

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ error: "Failed to create post" }),
    };
  }
};
