import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import {
  DynamoDBClient,
  PutItemCommand,
  GetItemCommand,
} from "@aws-sdk/client-dynamodb";
import { ulid } from "ulid";

const dynamoDb = new DynamoDBClient({
  region: process.env.AWS_REGION || "us-east-1",
});
const EVENTS_TABLE = process.env.EVENTS_TABLE || "post_events";
const COMMENTS_TABLE = process.env.COMMENTS_TABLE || "post_comments";
const POSTS_TABLE = process.env.POSTS_TABLE || "posts";
const USER_PROFILE_TABLE = process.env.USER_PROFILE_TABLE || "user_profile";

interface UserProfile {
  user_id: string;
  handle: string;
  display_name: string;
  profile_picture_url?: string;
  is_verified: boolean;
}

interface CommentReply {
  comment_id: string;
  post_id: string;
  user_id: string;
  timestamp: string;
  comment_text: string;
  parent_comment_id: string;
  mentions: string[];
  hashtags: string[];
  is_edited: boolean;
  edited_timestamp: string | null;
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

// Helper function to extract mentions from text (@username)
const extractMentions = (text: string): string[] => {
  const mentionRegex = /@(\w+)/g;
  const mentions: string[] = [];
  let match;

  while ((match = mentionRegex.exec(text)) !== null) {
    mentions.push(match[1]);
  }

  return [...new Set(mentions)]; // Remove duplicates
};

// Helper function to extract hashtags from text (#hashtag)
const extractHashtags = (text: string): string[] => {
  const hashtagRegex = /#(\w+)/g;
  const hashtags: string[] = [];
  let match;

  while ((match = hashtagRegex.exec(text)) !== null) {
    hashtags.push(match[1]);
  }

  return [...new Set(hashtags)]; // Remove duplicates
};

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

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  console.log("=== REPLY TO COMMENT LAMBDA START ===");
  console.log("Event:", JSON.stringify(event, null, 2));

  try {
    // Extract user ID from Firebase authorizer
    const userId = event.requestContext.authorizer?.user;
    console.log("User ID from authorizer:", userId);

    if (!userId) {
      console.log("ERROR: No user ID found in authorizer");
      return response(401, {
        error: "Unauthorized",
        message: "User not authenticated",
      });
    }

    // Parse request body
    const requestBody = event.body ? JSON.parse(event.body) : {};
    console.log("Request body:", JSON.stringify(requestBody, null, 2));

    // Handle both 'content' and 'comment_text' field names
    const comment_text = requestBody.comment_text || requestBody.content;

    if (!comment_text || typeof comment_text !== "string") {
      console.log("ERROR: Invalid comment_text/content in request body");
      return response(400, {
        error: "Bad Request",
        message: "comment_text or content is required and must be a string",
      });
    }

    // Extract path parameters
    const { post_id, comment_id } = event.pathParameters || {};
    console.log(
      "Path parameters - post_id:",
      post_id,
      "comment_id:",
      comment_id
    );

    if (!post_id) {
      console.log("ERROR: post_id is missing from path parameters");
      return response(400, {
        error: "Bad Request",
        message: "post_id is required",
      });
    }

    if (!comment_id) {
      console.log("ERROR: comment_id is missing from path parameters");
      return response(400, {
        error: "Bad Request",
        message: "comment_id is required",
      });
    }

    // Convert post_id and comment_id to uppercase for DynamoDB consistency
    const normalizedPostId = post_id.toUpperCase();
    const normalizedCommentId = comment_id.toUpperCase();
    console.log(
      "Normalized IDs - post_id:",
      normalizedPostId,
      "comment_id:",
      normalizedCommentId
    );

    // Check if post exists
    console.log("Checking if post exists with ID:", normalizedPostId);
    const postResult = await dynamoDb.send(
      new GetItemCommand({
        TableName: POSTS_TABLE,
        Key: {
          post_id: { S: normalizedPostId },
        },
      })
    );
    console.log("Post query result:", JSON.stringify(postResult, null, 2));

    if (!postResult.Item) {
      console.log("ERROR: Post not found in DynamoDB");
      return response(404, {
        error: "Not Found",
        message: "Post not found",
      });
    }

    // Don't allow replies on deleted posts
    if (postResult.Item.is_deleted?.BOOL === true) {
      console.log("ERROR: Post is deleted");
      return response(404, {
        error: "Not Found",
        message: "Post not found",
      });
    }

    // Check if parent comment exists
    console.log(
      "Checking if parent comment exists with ID:",
      normalizedCommentId
    );

    let parentCommentResult = await dynamoDb.send(
      new GetItemCommand({
        TableName: COMMENTS_TABLE,
        Key: {
          post_id: { S: normalizedPostId },
          comment_id: { S: normalizedCommentId },
        },
      })
    );

    console.log(
      "Parent comment query result:",
      JSON.stringify(parentCommentResult, null, 2)
    );

    if (!parentCommentResult.Item) {
      console.log("ERROR: Parent comment not found in DynamoDB");
      return response(404, {
        error: "Not Found",
        message: "Parent comment not found",
      });
    }

    // Get the actual comment_id from the found item for consistency
    const actualParentCommentId =
      parentCommentResult.Item.comment_id?.S || normalizedCommentId;
    console.log("Actual parent comment ID from DB:", actualParentCommentId);

    // Don't allow replies on deleted comments
    if (parentCommentResult.Item.is_deleted?.BOOL === true) {
      console.log("ERROR: Parent comment is deleted");
      return response(404, {
        error: "Not Found",
        message: "Parent comment not found",
      });
    }

    // Extract mentions and hashtags
    const mentions = extractMentions(comment_text);
    const hashtags = extractHashtags(comment_text);
    console.log("Extracted mentions:", mentions);
    console.log("Extracted hashtags:", hashtags);

    // Generate ULID for the reply
    const replyId = ulid();
    console.log("Generated reply ID:", replyId);

    // Get current timestamp
    const timestamp = new Date().toISOString();
    console.log("Timestamp:", timestamp);

    // Get user profile for the reply
    console.log("Fetching user profile for user ID:", userId);
    const userProfile = await getUserProfile(userId);
    console.log("User profile result:", JSON.stringify(userProfile, null, 2));

    // Create the reply comment
    const replyComment: any = {
      post_id: { S: normalizedPostId },
      comment_id: { S: replyId },
      user_id: { S: userId },
      timestamp: { S: timestamp },
      comment_text: { S: comment_text },
      parent_comment_id: { S: actualParentCommentId },
      is_edited: { BOOL: false },
      edited_timestamp: { NULL: true },
    };

    // Only add mentions if there are any
    if (mentions.length > 0) {
      replyComment.mentions = { SS: mentions };
    }

    // Only add hashtags if there are any
    if (hashtags.length > 0) {
      replyComment.hashtags = { SS: hashtags };
    }

    console.log(
      "Reply comment to be created:",
      JSON.stringify(replyComment, null, 2)
    );

    // Store the reply in DynamoDB
    console.log("Storing reply in DynamoDB...");
    await dynamoDb.send(
      new PutItemCommand({
        TableName: COMMENTS_TABLE,
        Item: replyComment,
      })
    );
    console.log("Reply stored successfully in DynamoDB");

    // Create event for the reply
    const replyEvent: any = {
      event_id: { S: ulid() },
      event_type: { S: "COMMENT_REPLY" },
      timestamp: { S: timestamp },
      post_id: { S: normalizedPostId },
      user_id: { S: userId },
      data: {
        M: {
          comment_id: { S: replyId },
          parent_comment_id: { S: actualParentCommentId },
          comment_text: { S: comment_text },
        },
      },
    };

    // Only add mentions if there are any
    if (mentions.length > 0) {
      replyEvent.data.M.mentions = { SS: mentions };
    }

    // Only add hashtags if there are any
    if (hashtags.length > 0) {
      replyEvent.data.M.hashtags = { SS: hashtags };
    }

    console.log(
      "Reply event to be created:",
      JSON.stringify(replyEvent, null, 2)
    );

    // Store the event in DynamoDB
    console.log("Storing reply event in DynamoDB...");
    await dynamoDb.send(
      new PutItemCommand({
        TableName: EVENTS_TABLE,
        Item: replyEvent,
      })
    );
    console.log("Reply event stored successfully in DynamoDB");

    // Prepare response
    const responseData = {
      comment_id: replyId,
      post_id: normalizedPostId,
      user_id: userId,
      timestamp: timestamp,
      comment_text: comment_text,
      parent_comment_id: actualParentCommentId,
      mentions: mentions,
      hashtags: hashtags,
      is_edited: false,
      edited_timestamp: null,
      user: userProfile || {
        user_id: userId,
        handle: `user_${userId.slice(0, 8)}`,
        display_name: "Unknown User",
        profile_picture_url: undefined,
        is_verified: false,
      },
    };
    console.log("Response data:", JSON.stringify(responseData, null, 2));

    console.log("=== REPLY TO COMMENT LAMBDA SUCCESS ===");
    return response(201, responseData);
  } catch (error) {
    console.error("=== REPLY TO COMMENT LAMBDA ERROR ===");
    console.error("Error details:", error);
    console.error(
      "Error stack:",
      error instanceof Error ? error.stack : "No stack trace"
    );
    return response(500, {
      error: "Internal Server Error",
      message: "Failed to create reply to comment",
    });
  }
};
