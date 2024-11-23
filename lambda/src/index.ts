import {
  AppConfigDataClient,
  StartConfigurationSessionCommand,
  GetLatestConfigurationCommand,
  StartConfigurationSessionCommandInput,
  GetLatestConfigurationCommandInput,
} from "@aws-sdk/client-appconfigdata";
import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";

// Instantiate AppConfig client
const appConfigClient = new AppConfigDataClient({});

// Cache InitialConfigurationToken and the last retrieval time
let initialConfigurationToken: string | null = null;
let lastTokenFetchTime: number | null = null;

const ALLOWED_ORIGINS = {
  local: "http://localhost:5173",
  dev: "https://dev.fourhorizonsed.com",
  staging: "https://staging.fourhorizonsed.com",
  production: "https://app.fourhorizonsed.com",
};

// Get the allowed origin dynamically based on the request
function getAllowedOrigin(requestOrigin: string): string | null {
  return (
    Object.values(ALLOWED_ORIGINS).find((origin) => origin === requestOrigin) ||
    null
  );
}

// Handler function for Lambda
export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  const requestOrigin = event.headers.origin || ""; // Get the request origin from headers
  const { application_id, config_profile_id, environment_id } =
    event.queryStringParameters || {};

  if (!application_id || !config_profile_id || !environment_id) {
    return {
      statusCode: 400,
      body: JSON.stringify({
        error:
          "Missing required query parameters: application_id, config_profile_id, or environment_id.",
      }),
    };
  }

  try {
    // Validate the request origin
    const allowedOrigin = getAllowedOrigin(requestOrigin);
    if (!allowedOrigin) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          error: "Origin not allowed.",
        }),
      };
    }

    // Check if token needs to be refreshed (after 24 hours or if null)
    if (!initialConfigurationToken || isTokenExpired()) {
      initialConfigurationToken = await startConfigurationSession(
        application_id,
        config_profile_id,
        environment_id
      );
      lastTokenFetchTime = Date.now();
    }

    // Get the latest configuration with cached token
    const configData = await getLatestConfiguration(initialConfigurationToken);

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": allowedOrigin,
        "Access-Control-Allow-Methods": "GET,OPTIONS",
        "Access-Control-Allow-Headers":
          "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
      },
      body: JSON.stringify({
        configuration:
          JSON.parse(configData?.Configuration?.transformToString()) || null,
      }),
    };
  } catch (error) {
    // Handle BadRequestException by retrying the session
    if ((error as any).name === "BadRequestException") {
      initialConfigurationToken = await startConfigurationSession(
        application_id,
        config_profile_id,
        environment_id
      );
      lastTokenFetchTime = Date.now();

      // Retry configuration fetch with a refreshed token
      const configData = await getLatestConfiguration(
        initialConfigurationToken
      );

      return {
        statusCode: 200,
        body: JSON.stringify({
          configuration:
            JSON.parse(configData?.Configuration?.transformToString()) || null,
        }),
      };
    }

    // For other errors, respond with failure
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: "Failed to fetch configuration.",
        details: (error as Error).message,
      }),
    };
  }
};

// Function to start a new configuration session
async function startConfigurationSession(
  applicationId: string,
  configProfileId: string,
  environmentId: string
): Promise<string> {
  const startSessionParams: StartConfigurationSessionCommandInput = {
    ApplicationIdentifier: applicationId,
    ConfigurationProfileIdentifier: configProfileId,
    EnvironmentIdentifier: environmentId,
  };
  const startSessionCommand = new StartConfigurationSessionCommand(
    startSessionParams
  );
  const { InitialConfigurationToken } = await appConfigClient.send(
    startSessionCommand
  );

  if (!InitialConfigurationToken) {
    throw new Error("Failed to retrieve initial configuration token.");
  }

  return InitialConfigurationToken;
}

// Function to fetch the latest configuration
async function getLatestConfiguration(token: string): Promise<any> {
  const getConfigParams: GetLatestConfigurationCommandInput = {
    ConfigurationToken: token,
  };

  const getConfigCommand = new GetLatestConfigurationCommand(getConfigParams);
  return appConfigClient.send(getConfigCommand);
}

// Utility function to check if the token is expired
function isTokenExpired(): boolean {
  const TWENTY_FOUR_HOURS_IN_MS = 24 * 60 * 60 * 1000;
  return (
    !lastTokenFetchTime ||
    Date.now() - lastTokenFetchTime > TWENTY_FOUR_HOURS_IN_MS
  );
}
