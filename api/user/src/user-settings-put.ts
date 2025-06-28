import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  PutCommand,
  GetCommand,
} from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);
const TABLE_NAME = process.env.TABLE_NAME || "user_settings";

// Default settings as specified in the API spec
const DEFAULT_SETTINGS = {
  isDarkMode: false,
  themeColor: "black",
  fontSize: 14,
  biometricEnabled: false,
};

// Valid theme colors
const VALID_THEME_COLORS = [
  "red",
  "green",
  "blue",
  "yellow",
  "orange",
  "purple",
  "pink",
  "black",
  "white",
];

// Valid hex color pattern
const HEX_COLOR_PATTERN = /^#[0-9A-Fa-f]{6}$/;

const response = (statusCode: number, body?: any): APIGatewayProxyResult => ({
  statusCode,
  headers: {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,PUT,OPTIONS",
    "Access-Control-Allow-Headers":
      "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
  },
  body: body ? JSON.stringify(body) : "",
});

// Validation function for settings
const validateSettings = (
  settings: any
): { isValid: boolean; errors: string[] } => {
  const errors: string[] = [];

  // Validate isDarkMode
  if (
    settings.isDarkMode !== undefined &&
    typeof settings.isDarkMode !== "boolean"
  ) {
    errors.push("isDarkMode must be a boolean");
  }

  // Validate themeColor
  if (settings.themeColor !== undefined) {
    if (typeof settings.themeColor !== "string") {
      errors.push("themeColor must be a string");
    } else if (
      !VALID_THEME_COLORS.includes(settings.themeColor) &&
      !HEX_COLOR_PATTERN.test(settings.themeColor)
    ) {
      errors.push(
        "themeColor must be one of: red, green, blue, yellow, orange, purple, pink, black, white, or a valid hex color (e.g., #FF0000)"
      );
    }
  }

  // Validate fontSize
  if (settings.fontSize !== undefined) {
    if (!Number.isInteger(settings.fontSize)) {
      errors.push("fontSize must be an integer");
    } else if (settings.fontSize < 10 || settings.fontSize > 30) {
      errors.push("fontSize must be between 10 and 30");
    }
  }

  // Validate biometricEnabled
  if (
    settings.biometricEnabled !== undefined &&
    typeof settings.biometricEnabled !== "boolean"
  ) {
    errors.push("biometricEnabled must be a boolean");
  }

  return {
    isValid: errors.length === 0,
    errors,
  };
};

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    console.log("Received event:", JSON.stringify(event));

    const userId = event.requestContext.authorizer?.user;
    if (!userId) {
      return {
        statusCode: 401,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({
          error: "Unauthorized",
          message: "User ID not found in request context",
        }),
      };
    }

    let requestBody: any;
    try {
      requestBody = JSON.parse(event.body || "{}");
    } catch (parseError) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({
          error: "Bad Request",
          message: "Invalid JSON in request body",
        }),
      };
    }

    // Validate required fields and types
    const errors: string[] = [];
    if (
      requestBody.isDarkMode !== undefined &&
      typeof requestBody.isDarkMode !== "boolean"
    ) {
      errors.push("isDarkMode must be a boolean");
    }
    if (
      requestBody.themeColor !== undefined &&
      typeof requestBody.themeColor !== "string"
    ) {
      errors.push("themeColor must be a string");
    }
    if (
      requestBody.fontSize !== undefined &&
      (!Number.isInteger(requestBody.fontSize) ||
        requestBody.fontSize < 10 ||
        requestBody.fontSize > 30)
    ) {
      errors.push("fontSize must be an integer between 10 and 30");
    }
    if (
      requestBody.biometricEnabled !== undefined &&
      typeof requestBody.biometricEnabled !== "boolean"
    ) {
      errors.push("biometricEnabled must be a boolean");
    }
    if (errors.length > 0) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({ error: "Invalid data", details: errors }),
      };
    }

    // Compose item
    const timestamp = new Date().toISOString();
    const item = {
      PK: `USER#${userId}`,
      SK: "SETTINGS",
      user_id: userId,
      isDarkMode: requestBody.isDarkMode,
      themeColor: requestBody.themeColor,
      fontSize: requestBody.fontSize,
      biometricEnabled: requestBody.biometricEnabled,
      updated_at: timestamp,
    };

    const putParams = new PutCommand({
      TableName: TABLE_NAME,
      Item: item,
    });

    await dynamoDb.send(putParams);

    return {
      statusCode: 201,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify(item),
    };
  } catch (error) {
    console.error("Error saving user settings:", error);
    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ error: "Failed to save user settings" }),
    };
  }
};
