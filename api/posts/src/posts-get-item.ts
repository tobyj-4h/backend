import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand } from "@aws-sdk/lib-dynamodb";

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

interface PostWithUserInfo {
  [key: string]: any;
  user?: UserProfile;
}

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

    const post = result.Item;
    let postWithUserInfo: PostWithUserInfo = { ...post };

    // Fetch user profile if post has a user_id
    if (post.user_id) {
      try {
        const userProfileParams = new GetCommand({
          TableName: USER_PROFILE_TABLE,
          Key: {
            PK: `USER#${post.user_id}`,
            SK: `PROFILE#${post.user_id}`,
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
    }

    console.log("postWithUserInfo", postWithUserInfo);

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify(postWithUserInfo),
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
