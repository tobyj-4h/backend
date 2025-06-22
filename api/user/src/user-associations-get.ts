import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, QueryCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);
const ASSOCIATIONS_TABLE = process.env.TABLE_NAME || "user_associations";

interface UserAssociation {
  PK: string;
  SK: string;
  association_type: string;
  created_at: string;
  role?: string;
  joined_at?: string;
  target_user_id?: string;
  group_id?: string;
}

interface AssociationsResponse {
  following: string[];
  groups: string[];
  associations: UserAssociation[];
}

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    console.log("Received event:", JSON.stringify(event));

    // Extract user ID from authorizer context
    const userId = event.requestContext.authorizer?.user;

    if (!userId) {
      console.error("Unauthorized: Missing user ID");
      return {
        statusCode: 401,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
          "Access-Control-Allow-Headers":
            "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
        },
        body: JSON.stringify({
          error: "Unauthorized",
          message: "User ID is required",
        }),
      };
    }

    console.log("Getting associations for user:", userId);

    // Get all associations for the user
    const queryParams = new QueryCommand({
      TableName: ASSOCIATIONS_TABLE,
      KeyConditionExpression: "PK = :pk",
      ExpressionAttributeValues: {
        ":pk": `USER#${userId}`,
      },
    });

    const result = await dynamoDb.send(queryParams);
    const associations = (result.Items || []) as UserAssociation[];

    console.log("Found associations:", associations);

    // Separate following and group associations
    const following: string[] = [];
    const groups: string[] = [];

    associations.forEach((association: UserAssociation) => {
      if (association.SK.startsWith("FOLLOWING#")) {
        const followedUserId = association.SK.replace("FOLLOWING#", "");
        following.push(followedUserId);
      } else if (association.SK.startsWith("GROUP#")) {
        const groupId = association.SK.replace("GROUP#", "");
        groups.push(groupId);
      }
    });

    const response: AssociationsResponse = {
      following,
      groups,
      associations,
    };

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
        "Access-Control-Allow-Headers":
          "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
      },
      body: JSON.stringify(response),
    };
  } catch (error) {
    console.error("Error retrieving user associations:", error);

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
        "Access-Control-Allow-Headers":
          "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
      },
      body: JSON.stringify({
        error: "Failed to retrieve user associations",
        message: error instanceof Error ? error.message : "Unknown error",
      }),
    };
  }
};
