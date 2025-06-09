import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { Client } from "@opensearch-project/opensearch";
import { AwsSigv4Signer } from "@opensearch-project/opensearch/aws";
import { defaultProvider } from "@aws-sdk/credential-provider-node";

const REQUIRED_SCOPE = process.env.REQUIRED_SCOPE;
const OPENSEARCH_DOMAIN = process.env.OPENSEARCH_DOMAIN!;
const INDEX_NAME = process.env.SCHOOLS_INDEX!;
const REGION = process.env.AWS_REGION || "us-east-1";

const createSignedClient = async () => {
  const signerConfig = {
    region: REGION,
    service: "es" as const, // use 'aoss' for OpenSearch Serverless
    getCredentials: () => defaultProvider()(),
  };

  return new Client({
    ...AwsSigv4Signer(signerConfig),
    node: OPENSEARCH_DOMAIN,
  });
};

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    console.log("Received event:", JSON.stringify(event));

    const token = event.headers["Authorization"]?.split(" ")[1];
    if (!token) {
      console.error("Unauthorized: Missing token");
      return {
        statusCode: 401,
        body: JSON.stringify({ message: "Unauthorized" }),
      };
    }

    const scopes = (event.requestContext.authorizer?.scope || "").split(" ");
    const userId = event.requestContext.authorizer?.user;
    console.log("Scopes:", scopes);
    console.log("User ID:", userId);

    const queryParams = event.queryStringParameters || {};
    const lat = parseFloat(queryParams.lat || "");
    const lon = parseFloat(queryParams.lon || "");
    const radius = queryParams.radius || "25mi";

    if (isNaN(lat) || isNaN(lon)) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: "Invalid or missing lat/lon" }),
      };
    }

    const client = await createSignedClient();

    const response = await client.search({
      index: INDEX_NAME,
      size: 50,
      body: {
        _source: { excludes: ["geometry"] },
        sort: [
          {
            _geo_distance: {
              location: {
                lat: lat,
                lon: lon,
              },
              order: "asc",
              unit: "mi",
            },
          },
        ],
        query: {
          bool: {
            must: [{ match_all: {} }],
            filter: {
              geo_distance: {
                distance: radius,
                location: { lat, lon },
              },
            },
          },
        },
      },
    });

    const hits = response.body.hits.hits.map((hit: any) => hit._source);
    console.log("Hits:", hits);

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify(hits),
    };
  } catch (error) {
    console.error("Error fetching locations:", error);

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ error: "Failed to retrieve locations" }),
    };
  }
};
