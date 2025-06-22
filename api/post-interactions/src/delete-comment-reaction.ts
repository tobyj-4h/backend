import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import {
  DynamoDBClient,
  DeleteItemCommand,
  GetItemCommand,
  QueryCommand,
} from "@aws-sdk/client-dynamodb";

const dynamoDb = new DynamoDBClient({
  region: process.env.AWS_REGION || "us-east-1",
});
const COMMENT_REACTIONS_TABLE =
  process.env.COMMENT_REACTIONS_TABLE || "comment_reactions";
const COMMENTS_TABLE = process.env.COMMENTS_TABLE || "post_comments";

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
  console.log("=== DELETE COMMENT REACTION LAMBDA START ===");
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

    // Check if user has an existing reaction on this comment
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
      !existingReactionResult.Items ||
      existingReactionResult.Items.length === 0
    ) {
      console.log("ERROR: User has no reaction on this comment");
      return response(404, {
        error: "Not Found",
        message: "User has no reaction on this comment",
      });
    }

    // Delete the reaction from DynamoDB
    console.log("Deleting reaction from DynamoDB...");
    await dynamoDb.send(
      new DeleteItemCommand({
        TableName: COMMENT_REACTIONS_TABLE,
        Key: {
          comment_id: { S: normalizedCommentId },
          user_id: { S: userId },
        },
      })
    );
    console.log("Reaction deleted successfully from DynamoDB");

    console.log("=== DELETE COMMENT REACTION LAMBDA SUCCESS ===");
    return response(204); // No content response for successful delete
  } catch (error) {
    console.error("=== DELETE COMMENT REACTION LAMBDA ERROR ===");
    console.error("Error details:", error);
    console.error(
      "Error stack:",
      error instanceof Error ? error.stack : "No stack trace"
    );
    return response(500, {
      error: "Internal Server Error",
      message: "Failed to delete reaction from comment",
    });
  }
};
