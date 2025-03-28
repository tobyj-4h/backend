import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, QueryCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.DYNAMODB_TABLE || "";

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    console.log("Event:", event);

    // const allowedOrigin = validateOrigin(event.headers.origin || "");
    // const tokenPayload = decodeToken(event.headers.authorization || "");

    // const userId = tokenPayload.sub;

    // const params = {
    //   TableName: TABLE_NAME,
    //   KeyConditionExpression: "PK = :pk",
    //   ExpressionAttributeValues: {
    //     ":pk": `USER#${userId}`,
    //   },
    // };

    // console.log("Querying DynamoDB with params:", params);
    // const result = await ddbDocClient.send(new QueryCommand(params));

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET",
      },
      body: JSON.stringify({
        // preferences: result.Items || [],
      }),
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
