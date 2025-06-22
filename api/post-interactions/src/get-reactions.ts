import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import {
  DynamoDBClient,
  QueryCommand,
  ScanCommand,
  GetItemCommand,
} from "@aws-sdk/client-dynamodb";

const dynamoDb = new DynamoDBClient({
  region: process.env.AWS_REGION || "us-east-1",
});
const REACTIONS_TABLE = process.env.REACTIONS_TABLE || "post_reactions";
const POSTS_TABLE = process.env.POSTS_TABLE || "posts";

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
  try {
    // Extract user ID from Firebase authorizer
    const userId = event.requestContext.authorizer?.user;
    const { post_id } = event.pathParameters || {};

    if (!post_id) {
      return response(400, {
        error: "Bad Request",
        message: "post_id is required",
      });
    }

    if (!userId) {
      return response(401, {
        error: "Unauthorized",
        message: "Authentication required",
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

    // Don't allow reactions on deleted posts
    if (postResult.Item.is_deleted?.BOOL === true) {
      return response(404, {
        error: "Not Found",
        message: "Post not found",
      });
    }

    // Parse query parameters for pagination
    const queryParams = event.queryStringParameters || {};
    const limit = parseInt(queryParams.limit || "20", 10);
    const lastEvaluatedKey = queryParams.lastEvaluatedKey;

    // Validate pagination parameters
    if (limit < 1 || limit > 100) {
      return response(400, {
        error: "Bad Request",
        message: "Limit must be between 1 and 100",
      });
    }

    // Query reactions for this post
    const queryParams2: any = {
      TableName: REACTIONS_TABLE,
      KeyConditionExpression: "post_id = :postId",
      ExpressionAttributeValues: {
        ":postId": { S: normalizedPostId },
      },
      Limit: limit,
    };

    // Add pagination token if provided
    if (lastEvaluatedKey) {
      try {
        const decodedKey = JSON.parse(decodeURIComponent(lastEvaluatedKey));
        queryParams2.ExclusiveStartKey = decodedKey;
      } catch (error) {
        return response(400, {
          error: "Bad Request",
          message: "Invalid pagination token",
        });
      }
    }

    const result = await dynamoDb.send(new QueryCommand(queryParams2));

    // Transform the results to match expected format
    const reactions = (result.Items || []).map((item) => ({
      user_id: item.user_id?.S,
      reaction: item.reaction?.S,
      timestamp: item.timestamp?.S,
    }));

    // Calculate reaction counts
    const reactionCounts: { [key: string]: number } = {};
    reactions.forEach((reaction) => {
      const reactionType = reaction.reaction;
      if (reactionType) {
        reactionCounts[reactionType] = (reactionCounts[reactionType] || 0) + 1;
      }
    });

    // Prepare response
    const responseBody: any = {
      reactions: reactions,
      counts: reactionCounts,
      total: reactions.length,
    };

    // Add pagination info if there are more results
    if (result.LastEvaluatedKey) {
      responseBody.pagination = {
        lastEvaluatedKey: encodeURIComponent(
          JSON.stringify(result.LastEvaluatedKey)
        ),
        hasMore: true,
      };
    }

    return response(200, responseBody);
  } catch (error) {
    console.error("Error getting reactions for post:", error);
    return response(500, {
      error: "Internal Server Error",
      message: "Failed to get reactions for post",
    });
  }
};
