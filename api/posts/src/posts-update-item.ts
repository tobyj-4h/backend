import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import {
  DynamoDBClient,
  GetItemCommand,
  UpdateItemCommand,
  ReturnValue,
} from "@aws-sdk/client-dynamodb";
import { marshall, unmarshall } from "@aws-sdk/util-dynamodb";

const dynamoDb = new DynamoDBClient({});
const POSTS_TABLE = process.env.POSTS_TABLE || "posts";

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    const postId = event.pathParameters?.post_id;
    const requestBody = JSON.parse(event.body || "{}");

    // Extract user information from request context or JWT token
    const userId =
      event.requestContext.authorizer?.claims?.sub || "unknown-user";

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

    // Retrieve the existing post to verify ownership
    const getParams = {
      TableName: POSTS_TABLE,
      Key: marshall({
        post_id: postId,
      }),
    };

    const getCommand = new GetItemCommand(getParams);
    const existingPost = await dynamoDb.send(getCommand);

    if (!existingPost.Item) {
      return {
        statusCode: 404,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({ error: "Post not found" }),
      };
    }

    const postItem = unmarshall(existingPost.Item);

    // Check if the user is the owner of the post
    if (postItem.user_id !== userId) {
      return {
        statusCode: 403,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({
          error: "You do not have permission to update this post",
        }),
      };
    }

    // Create update expression and attribute values
    const updateExpressionParts = [];
    const expressionAttributeNames: Record<string, string> = {};
    const expressionAttributeValues: Record<string, any> = {};

    // Only allow updating specific fields
    const allowedFields = ["content", "media_items", "interaction_settings"];

    allowedFields.forEach((field) => {
      if (requestBody[field] !== undefined) {
        updateExpressionParts.push(`#${field} = :${field}`);
        expressionAttributeNames[`#${field}`] = field;
        expressionAttributeValues[`:${field}`] = requestBody[field];
      }
    });

    // Always mark as edited and update timestamp
    const timestamp = new Date().toISOString();
    updateExpressionParts.push("#is_edited = :is_edited");
    updateExpressionParts.push("#edited_timestamp = :edited_timestamp");
    expressionAttributeNames["#is_edited"] = "is_edited";
    expressionAttributeNames["#edited_timestamp"] = "edited_timestamp";
    expressionAttributeValues[":is_edited"] = true;
    expressionAttributeValues[":edited_timestamp"] = timestamp;

    const updateExpression = `SET ${updateExpressionParts.join(", ")}`;

    const updateParams = {
      TableName: POSTS_TABLE,
      Key: marshall({
        post_id: postId,
      }),
      UpdateExpression: updateExpression,
      ExpressionAttributeNames: expressionAttributeNames,
      ExpressionAttributeValues: expressionAttributeValues,
      ReturnValues: ReturnValue.ALL_NEW, // Use the correct enum
    };

    const updateCommand = new UpdateItemCommand(updateParams);
    const result = await dynamoDb.send(updateCommand);

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({
        message: "Post updated successfully",
        updatedItem: result.Attributes ? unmarshall(result.Attributes) : null, // Handle undefined
      }),
    };
  } catch (error) {
    console.error("Error updating post:", error);
    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({
        error: "An error occurred while updating the post",
      }),
    };
  }
};
