import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  console.log("event", event);

  // Validate that the Authorization header exists
  const authHeader = event.headers.Authorization || event.headers.authorization; // Handle case-insensitivity
  if (!authHeader) {
    console.warn("Missing Authorization header");
    return {
      statusCode: 401,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
        "Access-Control-Allow-Headers":
          "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
      },
      body: JSON.stringify({
        error: "Unauthorized",
        message: "Authorization header is required",
      }),
    };
  }

  // Log the Authorization header (for debugging purposes)
  console.log("Authorization header:", authHeader);

  // Process the request
  return {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
      "Access-Control-Allow-Headers":
        "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
    },
    body: "success!",
  };
};
