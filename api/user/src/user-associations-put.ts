import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  PutCommand,
  GetCommand,
} from "@aws-sdk/lib-dynamodb";

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

interface CreateAssociationRequest {
  association_type: "following" | "group_member";
  target_user_id?: string;
  group_id?: string;
  role?: string;
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

    // Parse request body
    const requestBody: CreateAssociationRequest = JSON.parse(
      event.body || "{}"
    );
    const { association_type, target_user_id, group_id, role } = requestBody;

    // Validate request
    if (!association_type) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
          "Access-Control-Allow-Headers":
            "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
        },
        body: JSON.stringify({
          error: "Bad Request",
          message: "association_type is required",
        }),
      };
    }

    if (association_type === "following" && !target_user_id) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
          "Access-Control-Allow-Headers":
            "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
        },
        body: JSON.stringify({
          error: "Bad Request",
          message: "target_user_id is required for following associations",
        }),
      };
    }

    if (association_type === "group_member" && !group_id) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
          "Access-Control-Allow-Headers":
            "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
        },
        body: JSON.stringify({
          error: "Bad Request",
          message: "group_id is required for group member associations",
        }),
      };
    }

    // Prevent self-following
    if (association_type === "following" && target_user_id === userId) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
          "Access-Control-Allow-Headers":
            "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
        },
        body: JSON.stringify({
          error: "Bad Request",
          message: "Cannot follow yourself",
        }),
      };
    }

    // Determine SK based on association type
    let sk: string;
    if (association_type === "following") {
      sk = `FOLLOWING#${target_user_id}`;
    } else {
      sk = `GROUP#${group_id}`;
    }

    const timestamp = new Date().toISOString();

    // Check if association already exists
    const existingParams = new GetCommand({
      TableName: ASSOCIATIONS_TABLE,
      Key: {
        PK: `USER#${userId}`,
        SK: sk,
      },
    });

    const existingResult = await dynamoDb.send(existingParams);
    if (existingResult.Item) {
      return {
        statusCode: 409,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
          "Access-Control-Allow-Headers":
            "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
        },
        body: JSON.stringify({
          error: "Conflict",
          message: "Association already exists",
        }),
      };
    }

    // Create the association
    const association: UserAssociation = {
      PK: `USER#${userId}`,
      SK: sk,
      association_type,
      created_at: timestamp,
      role: role || "member",
      joined_at: timestamp,
      target_user_id,
      group_id,
    };

    const putParams = new PutCommand({
      TableName: ASSOCIATIONS_TABLE,
      Item: association,
    });

    await dynamoDb.send(putParams);

    console.log("Created association:", association);

    return {
      statusCode: 201,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
        "Access-Control-Allow-Headers":
          "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
      },
      body: JSON.stringify(association),
    };
  } catch (error) {
    console.error("Error creating user association:", error);

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
        error: "Failed to create user association",
        message: error instanceof Error ? error.message : "Unknown error",
      }),
    };
  }
};
