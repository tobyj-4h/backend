import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  GetCommand,
  QueryCommand,
  ScanCommand,
} from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);
const POSTS_TABLE = process.env.POSTS_TABLE || "posts";
const USER_PROFILE_TABLE = process.env.USER_PROFILE_TABLE || "user_profile";
const REQUIRED_SCOPE = process.env.REQUIRED_SCOPE;

// Interaction table names
const VIEW_COUNTERS_TABLE =
  process.env.VIEW_COUNTERS_TABLE || "post_view_counters";
const REACTIONS_TABLE = process.env.REACTIONS_TABLE || "post_reactions";
const COMMENTS_TABLE = process.env.COMMENTS_TABLE || "post_comments";
const FAVORITES_TABLE = process.env.FAVORITES_TABLE || "post_user_favorites";

interface UserProfile {
  id: string;
  handle: string;
  profile_picture_url?: string;
  first_name: string;
  last_name: string;
}

interface PostWithUserInfo {
  [key: string]: any;
  user?: UserProfile;
}

// Helper function to get interaction counts for a single post
const getInteractionCounts = async (
  postId: string
): Promise<{
  comments: number;
  likes: number;
  reposts: number;
  quotes: number;
  views: number;
  reactions: {
    like: number;
    love: number;
    laugh: number;
    wow: number;
    sad: number;
    angry: number;
  };
}> => {
  const counts = {
    comments: 0,
    likes: 0,
    reposts: 0,
    quotes: 0,
    views: 0,
    reactions: {
      like: 0,
      love: 0,
      laugh: 0,
      wow: 0,
      sad: 0,
      angry: 0,
    },
  };

  try {
    // Get view count
    const viewResult = await dynamoDb.send(
      new GetCommand({
        TableName: VIEW_COUNTERS_TABLE,
        Key: { post_id: postId },
      })
    );
    if (viewResult.Item?.view_count) {
      counts.views = parseInt(viewResult.Item.view_count.N || "0", 10);
    }

    // Get reactions for this post
    const reactionsResult = await dynamoDb.send(
      new ScanCommand({
        TableName: REACTIONS_TABLE,
        FilterExpression: "post_id = :postId",
        ExpressionAttributeValues: {
          ":postId": postId,
        },
      })
    );

    if (reactionsResult.Items) {
      const reactionCounts: { [key: string]: number } = {};
      reactionsResult.Items.forEach((item) => {
        const reaction = item.reaction;
        reactionCounts[reaction] = (reactionCounts[reaction] || 0) + 1;
      });

      // Set detailed reaction counts
      counts.reactions.like = reactionCounts["like"] || 0;
      counts.reactions.love = reactionCounts["love"] || 0;
      counts.reactions.laugh = reactionCounts["laugh"] || 0;
      counts.reactions.wow = reactionCounts["wow"] || 0;
      counts.reactions.sad = reactionCounts["sad"] || 0;
      counts.reactions.angry = reactionCounts["angry"] || 0;

      // Map specific reactions to expected fields (legacy support)
      // New reaction types: like, love, laugh, wow, sad, angry
      counts.likes =
        reactionCounts["like"] ||
        reactionCounts["love"] ||
        reactionCounts["👍"] ||
        reactionCounts["❤️"] ||
        0;
      counts.reposts = reactionCounts["🔄"] || reactionCounts["repost"] || 0;
      counts.quotes = reactionCounts["💬"] || reactionCounts["quote"] || 0;
    }

    // Get comment count
    const commentsResult = await dynamoDb.send(
      new ScanCommand({
        TableName: COMMENTS_TABLE,
        FilterExpression: "post_id = :postId",
        ExpressionAttributeValues: {
          ":postId": postId,
        },
        Select: "COUNT",
      })
    );
    counts.comments = commentsResult.Count || 0;

    // Get favorite count and add it to likes
    const favoritesResult = await dynamoDb.send(
      new ScanCommand({
        TableName: FAVORITES_TABLE,
        FilterExpression: "post_id = :postId",
        ExpressionAttributeValues: {
          ":postId": postId,
        },
        Select: "COUNT",
      })
    );
    counts.likes += favoritesResult.Count || 0;
  } catch (error) {
    console.error("Error getting interaction counts:", error);
  }

  return counts;
};

// Helper function to check if user has favorited the post
const checkUserFavorite = async (
  postId: string,
  userId: string
): Promise<boolean> => {
  try {
    const result = await dynamoDb.send(
      new GetCommand({
        TableName: FAVORITES_TABLE,
        Key: {
          user_id: userId,
          post_id: postId,
        },
      })
    );
    return !!result.Item;
  } catch (error) {
    console.error("Error checking user favorite:", error);
    return false;
  }
};

// Helper function to get user's reaction for the post
const getUserReaction = async (
  postId: string,
  userId: string
): Promise<string | null> => {
  try {
    const result = await dynamoDb.send(
      new GetCommand({
        TableName: REACTIONS_TABLE,
        Key: {
          post_id: postId,
          user_id: userId,
        },
      })
    );
    return result.Item?.reaction?.S || null;
  } catch (error) {
    console.error("Error checking user reaction:", error);
    return null;
  }
};

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

    // if (
    //   REQUIRED_SCOPE &&
    //   !scopes.includes(REQUIRED_SCOPE) &&
    //   !scopes.includes("admin")
    // ) {
    //   return {
    //     statusCode: 403,
    //     body: JSON.stringify({ message: "Insufficient permissions" }),
    //   };
    // }

    const postId = event.pathParameters?.post_id;

    if (!postId) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({ error: "Post ID is required" }),
      };
    }

    // Convert postId to uppercase for DynamoDB consistency
    const normalizedPostId = postId.toUpperCase();

    const params = new GetCommand({
      TableName: POSTS_TABLE,
      Key: {
        post_id: normalizedPostId,
      },
    });

    const result = await dynamoDb.send(params);

    if (!result.Item) {
      return {
        statusCode: 404,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
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
          "Content-Type": "application/json; charset=utf-8",
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
            id: userProfileResult.Item.user_id,
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

    // Get interaction counts and user interaction states
    const [interactionCounts, isFavorite, userReaction] = await Promise.all([
      getInteractionCounts(normalizedPostId),
      userId
        ? checkUserFavorite(normalizedPostId, userId)
        : Promise.resolve(false),
      userId
        ? getUserReaction(normalizedPostId, userId)
        : Promise.resolve(null),
    ]);

    // Add interaction metrics to the response
    postWithUserInfo = {
      ...postWithUserInfo,
      ...interactionCounts,
      is_favorite: isFavorite,
      user_reaction: userReaction,
    };

    console.log("postWithUserInfo", postWithUserInfo);

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify(postWithUserInfo),
    };
  } catch (error) {
    console.error("Error retrieving post:", error);

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ error: "Failed to retrieve post" }),
    };
  }
};
