import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { validateOrigin, decodeToken } from "../../utils/auth";

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.TABLE_NAME || "";

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    console.log("Event:", event);

    const allowedOrigin = validateOrigin(event.headers.origin || "");
    const tokenPayload = decodeToken(event.headers.authorization || "");

    const userId = tokenPayload.sub;

    // Parse the request body
    const requestBody = JSON.parse(event.body || "{}");
    const { preferences } = requestBody;

    if (!preferences || !Array.isArray(preferences)) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          error: "Bad Request",
          message: "The preferences array is required in the request body.",
        }),
      };
    }

    // Prepare the data for DynamoDB
    const items = preferences.map((pref: any) => ({
      PK: `USER#${userId}`,
      SK: pref.$type, // Assuming each preference has a unique $type
      ...pref, // Spread the remaining fields into the item
      created_at: new Date().toISOString(),
    }));

    // Batch insert the preferences into the DynamoDB table
    const putPromises = items.map((item) =>
      ddbDocClient.send(
        new PutCommand({
          TableName: TABLE_NAME,
          Item: item,
        })
      )
    );
    await Promise.all(putPromises);

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": allowedOrigin,
      },
      body: JSON.stringify({ message: "Preferences updated successfully." }),
    };
  } catch (error) {
    // Explicitly narrow the type of error
    if (error instanceof Error) {
      console.error("Error:", error.message);
      return {
        statusCode: 500,
        body: JSON.stringify({ error: error.message }),
      };
    } else {
      console.error("Unknown error:", error);
      return {
        statusCode: 500,
        body: JSON.stringify({ error: "An unknown error occurred" }),
      };
    }
  }
};
