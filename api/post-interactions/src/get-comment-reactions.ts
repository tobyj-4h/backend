import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import {
  DynamoDBClient,
  QueryCommand,
  GetItemCommand,
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
  console.log("=== GET COMMENT REACTIONS LAMBDA START ===");
  console.log("Event:", JSON.stringify(event, null, 2));

  try {
    // Extract user ID from Firebase authorizer (optional for GET)
    const userId = event.requestContext.authorizer?.user;
    const { comment_id, post_id } = event.pathParameters || {};

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

    // Query reactions for this comment
    const queryParams2: any = {
      TableName: COMMENT_REACTIONS_TABLE,
      KeyConditionExpression: "comment_id = :commentId",
      ExpressionAttributeValues: {
        ":commentId": { S: normalizedCommentId },
      },
      ScanIndexForward: false, // Get newest reactions first
    };

    // If we have an offset, we need to scan and skip
    if (offset > 0) {
      // For offset-based pagination, we need to scan and skip
      // This is not ideal for large datasets, but works for the current use case
      const scanParams = {
        TableName: COMMENT_REACTIONS_TABLE,
        FilterExpression: "comment_id = :commentId",
        ExpressionAttributeValues: {
          ":commentId": { S: normalizedCommentId },
        },
        ScanIndexForward: false,
      };

      const scanResult = await dynamoDb.send(new QueryCommand(scanParams));
      const allReactions = scanResult.Items || [];

      // Apply pagination manually
      const paginatedReactions = allReactions.slice(offset, offset + pageSize);

      // Transform the results
      const reactions = paginatedReactions.map((item) => ({
        id: item.id?.S || "",
        post_id: normalizedPostId,
        comment_id: item.comment_id?.S || "",
        user_id: item.user_id?.S || "",
        timestamp: item.timestamp?.S || "",
        reaction: item.reaction?.S || "",
        custom_emoji: item.custom_emoji?.S || null,
      }));

      console.log("Response data:", JSON.stringify({ reactions }, null, 2));
      return response(200, { reactions });
    } else {
      // No offset, use regular query with limit
      queryParams2.Limit = pageSize;

      const result = await dynamoDb.send(new QueryCommand(queryParams2));

      // Transform the results
      const reactions = (result.Items || []).map((item) => ({
        id: item.id?.S || "",
        post_id: normalizedPostId,
        comment_id: item.comment_id?.S || "",
        user_id: item.user_id?.S || "",
        timestamp: item.timestamp?.S || "",
        reaction: item.reaction?.S || "",
        custom_emoji: item.custom_emoji?.S || null,
      }));

      console.log("Response data:", JSON.stringify({ reactions }, null, 2));
      return response(200, { reactions });
    }
  } catch (error) {
    console.error("=== GET COMMENT REACTIONS LAMBDA ERROR ===");
    console.error("Error details:", error);
    console.error(
      "Error stack:",
      error instanceof Error ? error.stack : "No stack trace"
    );
    return response(500, {
      error: "Internal Server Error",
      message: "Failed to get reactions for comment",
    });
  }
};
