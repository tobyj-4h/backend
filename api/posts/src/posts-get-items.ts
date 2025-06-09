import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  ScanCommand,
  BatchGetCommand,
} from "@aws-sdk/lib-dynamodb";

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

    // Get unique user IDs from posts
    const userIds = [
      ...new Set(posts.map((post) => post.user_id).filter(Boolean)),
    ];

    // Batch fetch user profiles
    let userProfiles: { [userId: string]: UserProfile } = {};

    if (userIds.length > 0) {
      // DynamoDB BatchGet can handle up to 100 items at once
      const batchSize = 100;
      for (let i = 0; i < userIds.length; i += batchSize) {
        const batch = userIds.slice(i, i + batchSize);

        const batchParams = new BatchGetCommand({
          RequestItems: {
            [USER_PROFILE_TABLE]: {
              Keys: batch.map((userId) => ({
                PK: `USER#${userId}`,
                SK: `PROFILE#${userId}`,
              })),
              ProjectionExpression:
                "user_id, handle, profile_picture_url, first_name, last_name",
            },
          },
        });

        const batchResult = await dynamoDb.send(batchParams);

        if (batchResult.Responses?.[USER_PROFILE_TABLE]) {
          batchResult.Responses[USER_PROFILE_TABLE].forEach((profile: any) => {
            userProfiles[profile.user_id] = {
              handle: profile.handle,
              profile_picture_url: profile.profile_picture_url,
              first_name: profile.first_name,
              last_name: profile.last_name,
            };
          });
        }
      }
    }

    // Enhance posts with user information
    const postsWithUserInfo: PostWithUserInfo[] = posts.map((post) => ({
      ...post,
      user: post.user_id ? userProfiles[post.user_id] : undefined,
    }));

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify(postsWithUserInfo),
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
