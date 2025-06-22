import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import {
  DynamoDBClient,
  PutItemCommand,
  GetItemCommand,
  QueryCommand,
} from "@aws-sdk/client-dynamodb";
import { ulid } from "ulid";

const dynamoDb = new DynamoDBClient({
  region: process.env.AWS_REGION || "us-east-1",
});
const COMMENT_REACTIONS_TABLE =
  process.env.COMMENT_REACTIONS_TABLE || "comment_reactions";
const COMMENTS_TABLE = process.env.COMMENTS_TABLE || "post_comments";

// Valid reaction types
const VALID_REACTIONS = ["like", "love", "laugh", "wow", "sad", "angry"];

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

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  console.log("=== COMMENT REACTIONS LAMBDA START ===");
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

    const { reaction, custom_emoji } = requestBody;

    // Validate reaction type
    if (!reaction || !VALID_REACTIONS.includes(reaction)) {
      console.log("ERROR: Invalid reaction type:", reaction);
      return response(400, {
        error: "Bad Request",
        message:
          "Invalid reaction type. Must be one of: " +
          VALID_REACTIONS.join(", "),
      });
    }

    // Extract comment ID from path parameters
    const { comment_id, post_id } = event.pathParameters || {};
    console.log("Comment ID from path parameters:", comment_id);
    console.log("Post ID from path parameters:", post_id);

    if (!comment_id) {
      console.log("ERROR: comment_id is missing from path parameters");
      return response(400, {
        error: "Bad Request",
        message: "comment_id is required",
      });
    }

    if (!post_id) {
      console.log("ERROR: post_id is missing from path parameters");
      return response(400, {
        error: "Bad Request",
        message: "post_id is required",
      });
    }

    // Convert IDs to uppercase for DynamoDB consistency
    const normalizedCommentId = comment_id.toUpperCase();
    const normalizedPostId = post_id.toUpperCase();
    console.log("Normalized comment ID:", normalizedCommentId);
    console.log("Normalized post ID:", normalizedPostId);

    // Check if comment exists using the correct composite key
    console.log(
      "Checking if comment exists with post_id:",
      normalizedPostId,
      "and comment_id:",
      normalizedCommentId
    );
    const commentResult = await dynamoDb.send(
      new GetItemCommand({
        TableName: COMMENTS_TABLE,
        Key: {
          post_id: { S: normalizedPostId },
          comment_id: { S: normalizedCommentId },
        },
      })
    );
    console.log(
      "Comment query result:",
      JSON.stringify(commentResult, null, 2)
    );

    if (!commentResult.Item) {
      console.log("ERROR: Comment not found in DynamoDB");
      return response(404, {
        error: "Not Found",
        message: "Comment not found",
      });
    }

    // Don't allow reactions on deleted comments
    if (commentResult.Item.is_deleted?.BOOL === true) {
      console.log("ERROR: Comment is deleted");
      return response(404, {
        error: "Not Found",
        message: "Comment not found",
      });
    }

    // Check if user already has a reaction on this comment
    console.log("Checking for existing user reaction on comment");
    const existingReactionResult = await dynamoDb.send(
      new QueryCommand({
        TableName: COMMENT_REACTIONS_TABLE,
        KeyConditionExpression: "comment_id = :commentId AND user_id = :userId",
        ExpressionAttributeValues: {
          ":commentId": { S: normalizedCommentId },
          ":userId": { S: userId },
        },
      })
    );
    console.log(
      "Existing reaction query result:",
      JSON.stringify(existingReactionResult, null, 2)
    );

    if (
      existingReactionResult.Items &&
      existingReactionResult.Items.length > 0
    ) {
      console.log("ERROR: User already has a reaction on this comment");
      return response(409, {
        error: "Conflict",
        message: "User already has a reaction on this comment",
      });
    }

    // Generate ULID for the reaction
    const reactionId = ulid();
    console.log("Generated reaction ID:", reactionId);

    // Get current timestamp
    const timestamp = new Date().toISOString();
    console.log("Timestamp:", timestamp);

    // Create the reaction
    const reactionItem: any = {
      id: { S: reactionId },
      comment_id: { S: normalizedCommentId },
      user_id: { S: userId },
      timestamp: { S: timestamp },
      reaction: { S: reaction },
    };

    // Only add custom_emoji if provided
    if (custom_emoji) {
      reactionItem.custom_emoji = { S: custom_emoji };
    }

    console.log(
      "Reaction to be created:",
      JSON.stringify(reactionItem, null, 2)
    );

    // Store the reaction in DynamoDB
    console.log("Storing reaction in DynamoDB...");
    await dynamoDb.send(
      new PutItemCommand({
        TableName: COMMENT_REACTIONS_TABLE,
        Item: reactionItem,
      })
    );
    console.log("Reaction stored successfully in DynamoDB");

    // Prepare response
    const responseData = {
      id: reactionId,
      post_id: normalizedPostId,
      comment_id: normalizedCommentId,
      user_id: userId,
      timestamp: timestamp,
      reaction: reaction,
      custom_emoji: custom_emoji || null,
    };
    console.log("Response data:", JSON.stringify(responseData, null, 2));

    console.log("=== COMMENT REACTIONS LAMBDA SUCCESS ===");
    return response(201, responseData);
  } catch (error) {
    console.error("=== COMMENT REACTIONS LAMBDA ERROR ===");
    console.error("Error details:", error);
    console.error(
      "Error stack:",
      error instanceof Error ? error.stack : "No stack trace"
    );
    return response(500, {
      error: "Internal Server Error",
      message: "Failed to add reaction to comment",
    });
  }
};
