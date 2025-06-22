import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import {
  DynamoDBClient,
  QueryCommand,
  GetItemCommand,
} from "@aws-sdk/client-dynamodb";

const dynamoDb = new DynamoDBClient({
  region: process.env.AWS_REGION || "us-east-1",
});
const COMMENTS_TABLE = process.env.COMMENTS_TABLE || "post_comments";
const POSTS_TABLE = process.env.POSTS_TABLE || "posts";
const USER_PROFILE_TABLE = process.env.USER_PROFILE_TABLE || "user_profile";
const COMMENT_REACTIONS_TABLE =
  process.env.COMMENT_REACTIONS_TABLE || "comment_reactions";

interface UserProfile {
  user_id: string;
  handle: string;
  display_name: string;
  profile_picture_url?: string;
  is_verified: boolean;
}

interface Comment {
  comment_id: string;
  post_id: string;
  user_id: string;
  timestamp: string;
  comment_text: string;
  parent_comment_id: string | null;
  mentions: string[];
  hashtags: string[];
  is_edited: boolean;
  edited_timestamp: string | null;
  user_reaction: string | null;
  likes: number;
  user: UserProfile;
}

const response = (statusCode: number, body?: any): APIGatewayProxyResult => ({
  statusCode,
  headers: {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
    "Access-Control-Allow-Headers":
      "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
  },
  body: body ? JSON.stringify(body) : "",
});

// Helper function to get user profile
const getUserProfile = async (userId: string): Promise<UserProfile | null> => {
  try {
    const result = await dynamoDb.send(
      new GetItemCommand({
        TableName: USER_PROFILE_TABLE,
        Key: {
          PK: { S: `USER#${userId}` },
          SK: { S: `PROFILE#${userId}` },
        },
        ProjectionExpression:
          "user_id, handle, first_name, last_name, profile_picture_url, is_verified",
      })
    );

    if (result.Item) {
      const firstName = result.Item.first_name?.S || "";
      const lastName = result.Item.last_name?.S || "";
      const displayName = `${firstName} ${lastName}`.trim() || "Unknown User";

      return {
        user_id: result.Item.user_id?.S || userId,
        handle: result.Item.handle?.S || `user_${userId.slice(0, 8)}`,
        display_name: displayName,
        profile_picture_url: result.Item.profile_picture_url?.S,
        is_verified: result.Item.is_verified?.BOOL || false,
      };
    }
    return null;
  } catch (error) {
    console.error("Error fetching user profile:", error);
    return null;
  }
};

// Helper function to get reaction data for a comment
const getCommentReactionData = async (
  commentId: string,
  userId?: string
): Promise<{ user_reaction: string | null; likes: number }> => {
  try {
    // Get total reaction count
    const countResult = await dynamoDb.send(
      new QueryCommand({
        TableName: COMMENT_REACTIONS_TABLE,
        KeyConditionExpression: "comment_id = :commentId",
        ExpressionAttributeValues: {
          ":commentId": { S: commentId },
        },
        Select: "COUNT",
      })
    );

    const likes = countResult.Count || 0;

    // Get user's reaction if userId is provided
    let user_reaction: string | null = null;
    if (userId) {
      const userReactionResult = await dynamoDb.send(
        new QueryCommand({
          TableName: COMMENT_REACTIONS_TABLE,
          KeyConditionExpression:
            "comment_id = :commentId AND user_id = :userId",
          ExpressionAttributeValues: {
            ":commentId": { S: commentId },
            ":userId": { S: userId },
          },
        })
      );

      if (userReactionResult.Items && userReactionResult.Items.length > 0) {
        user_reaction = userReactionResult.Items[0].reaction?.S || null;
      }
    }

    return { user_reaction, likes };
  } catch (error) {
    console.error("Error fetching comment reaction data:", error);
    return { user_reaction: null, likes: 0 };
  }
};

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    // Extract user ID from Firebase authorizer (optional for GET)
    const userId = event.requestContext.authorizer?.user;
    const { post_id } = event.pathParameters || {};

    if (!post_id) {
      return response(400, {
        error: "Bad Request",
        message: "post_id is required",
      });
    }

    // Convert post_id to uppercase for DynamoDB consistency
    const normalizedPostId = post_id.toUpperCase();

    // Check if post exists
    const postResult = await dynamoDb.send(
      new GetItemCommand({
        TableName: POSTS_TABLE,
        Key: {
          post_id: { S: normalizedPostId },
        },
      })
    );

    if (!postResult.Item) {
      return response(404, {
        error: "Not Found",
        message: "Post not found",
      });
    }

    // Don't allow comments on deleted posts
    if (postResult.Item.is_deleted?.BOOL === true) {
      return response(404, {
        error: "Not Found",
        message: "Post not found",
      });
    }

    // Parse query parameters for pagination
    const queryParams = event.queryStringParameters || {};
    const page = parseInt(queryParams.page || "0", 10);
    const pageSize = parseInt(queryParams.pageSize || "20", 10);

    // Validate pagination parameters
    if (page < 0) {
      return response(400, {
        error: "Bad Request",
        message: "Page must be 0 or greater",
      });
    }

    if (pageSize < 1 || pageSize > 100) {
      return response(400, {
        error: "Bad Request",
        message: "Page size must be between 1 and 100",
      });
    }

    // Calculate offset for pagination
    const offset = page * pageSize;

    // Query comments for this post
    const queryParams2: any = {
      TableName: COMMENTS_TABLE,
      KeyConditionExpression: "post_id = :postId",
      ExpressionAttributeValues: {
        ":postId": { S: normalizedPostId },
      },
      ScanIndexForward: false, // Get newest comments first
    };

    // If we have an offset, we need to scan and skip
    if (offset > 0) {
      // For offset-based pagination, we need to scan and skip
      // This is not ideal for large datasets, but works for the current use case
      const scanParams = {
        TableName: COMMENTS_TABLE,
        FilterExpression: "post_id = :postId",
        ExpressionAttributeValues: {
          ":postId": { S: normalizedPostId },
        },
        ScanIndexForward: false,
      };

      const scanResult = await dynamoDb.send(new QueryCommand(scanParams));
      const allComments = scanResult.Items || [];

      // Apply pagination manually
      const paginatedComments = allComments.slice(offset, offset + pageSize);

      // Get unique user IDs from comments
      const userIds = [
        ...new Set(
          paginatedComments
            .map((item) => item.user_id?.S)
            .filter((id): id is string => Boolean(id))
        ),
      ];

      // Fetch user profiles in parallel
      const userProfiles = await Promise.all(
        userIds.map(async (uid) => {
          const profile = await getUserProfile(uid);
          return { userId: uid, profile };
        })
      );

      // Create a map of user profiles for quick lookup
      const userProfileMap = new Map(
        userProfiles.map(({ userId, profile }) => [userId, profile])
      );

      // Transform the results
      const comments: Comment[] = await Promise.all(
        paginatedComments.map(async (item) => {
          const userProfile = userProfileMap.get(item.user_id?.S || "") || {
            user_id: item.user_id?.S || "",
            handle: `user_${(item.user_id?.S || "").slice(0, 8)}`,
            display_name: "Unknown User",
            profile_picture_url: undefined,
            is_verified: false,
          };

          // Get reaction data for this comment
          const reactionData = await getCommentReactionData(
            item.comment_id?.S || "",
            userId
          );

          return {
            comment_id: item.comment_id?.S || "",
            post_id: item.post_id?.S || "",
            user_id: item.user_id?.S || "",
            timestamp: item.timestamp?.S || "",
            comment_text: item.comment_text?.S || "",
            parent_comment_id: item.parent_comment_id?.S || null,
            mentions: item.mentions?.SS || [],
            hashtags: item.hashtags?.SS || [],
            is_edited: item.is_edited?.BOOL || false,
            edited_timestamp: item.edited_timestamp?.S || null,
            user_reaction: reactionData.user_reaction,
            likes: reactionData.likes,
            user: userProfile,
          };
        })
      );

      if (comments.length === 0) {
        return response(204);
      }

      return response(200, {
        comments: comments,
      });
    } else {
      // No offset, use regular query with limit
      queryParams2.Limit = pageSize;

      const result = await dynamoDb.send(new QueryCommand(queryParams2));

      // Get unique user IDs from comments
      const userIds = [
        ...new Set(
          (result.Items || [])
            .map((item) => item.user_id?.S)
            .filter((id): id is string => Boolean(id))
        ),
      ];

      // Fetch user profiles in parallel
      const userProfiles = await Promise.all(
        userIds.map(async (uid) => {
          const profile = await getUserProfile(uid);
          return { userId: uid, profile };
        })
      );

      // Create a map of user profiles for quick lookup
      const userProfileMap = new Map(
        userProfiles.map(({ userId, profile }) => [userId, profile])
      );

      // Transform the results
      const comments: Comment[] = await Promise.all(
        (result.Items || []).map(async (item) => {
          const userProfile = userProfileMap.get(item.user_id?.S || "") || {
            user_id: item.user_id?.S || "",
            handle: `user_${(item.user_id?.S || "").slice(0, 8)}`,
            display_name: "Unknown User",
            profile_picture_url: undefined,
            is_verified: false,
          };

          // Get reaction data for this comment
          const reactionData = await getCommentReactionData(
            item.comment_id?.S || "",
            userId
          );

          return {
            comment_id: item.comment_id?.S || "",
            post_id: item.post_id?.S || "",
            user_id: item.user_id?.S || "",
            timestamp: item.timestamp?.S || "",
            comment_text: item.comment_text?.S || "",
            parent_comment_id: item.parent_comment_id?.S || null,
            mentions: item.mentions?.SS || [],
            hashtags: item.hashtags?.SS || [],
            is_edited: item.is_edited?.BOOL || false,
            edited_timestamp: item.edited_timestamp?.S || null,
            user_reaction: reactionData.user_reaction,
            likes: reactionData.likes,
            user: userProfile,
          };
        })
      );

      if (comments.length === 0) {
        return response(204);
      }

      return response(200, {
        comments: comments,
      });
    }
  } catch (error) {
    console.error("Error getting comments for post:", error);
    return response(500, {
      error: "Internal Server Error",
      message: "Failed to get comments for post",
    });
  }
};
