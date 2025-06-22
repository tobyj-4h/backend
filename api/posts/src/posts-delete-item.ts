import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient, DeleteItemCommand } from "@aws-sdk/client-dynamodb";

const dynamoDbClient = new DynamoDBClient({ region: "us-east-1" }); // Specify your region
const POSTS_TABLE = process.env.POSTS_TABLE || "posts"; // Assuming the table name is passed as an environment variable
const REQUIRED_SCOPE = process.env.REQUIRED_SCOPE;

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
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

  // Check if the postId is provided
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

  try {
    // Delete the post from DynamoDB
    const deleteParams = {
      TableName: POSTS_TABLE,
      Key: {
        post_id: { S: postId },
      },
    };

    const deleteCommand = new DeleteItemCommand(deleteParams);

    const result = await dynamoDbClient.send(deleteCommand);

    // If no item is returned, it means the post doesn't exist
    if (result.Attributes === undefined) {
      return {
        statusCode: 404,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({ error: "Post not found" }),
      };
    }

    // Return a successful response
    return {
      statusCode: 204, // No content response for successful delete
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ message: "Post deleted successfully" }),
    };
  } catch (error) {
    // Return an error response if something goes wrong
    console.error("Error deleting post:", error);
    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({
        error: "An error occurred while deleting the post",
      }),
    };
  }
};
