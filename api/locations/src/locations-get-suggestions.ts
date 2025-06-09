import {
  LocationClient,
  SearchPlaceIndexForTextCommand,
} from "@aws-sdk/client-location";

const client = new LocationClient({ region: "us-east-1" });

export const handler = async (event: any) => {
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

  try {
    const query = event.queryStringParameters?.query;
    const limit = parseInt(event.queryStringParameters?.limit || "5");
    const types = event.queryStringParameters?.types || "city,state,postalCode";

    if (!query) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "Missing query parameter" }),
      };
    }

    // AWS Location Service Place Index Name
    const placeIndexName = process.env.PLACE_INDEX_NAME || "YourPlaceIndexName";

    const command = new SearchPlaceIndexForTextCommand({
      IndexName: placeIndexName,
      Text: query,
      MaxResults: limit,
      FilterCountries: ["USA", "CAN"],
    });

    const response = await client.send(command);
    const results = response.Results;

    if (!results || results.length === 0) {
      return {
        statusCode: 404,
        body: JSON.stringify({ error: "No results found for query" }),
      };
    }

    console.log("Search results:", JSON.stringify(results));

    // Transform the results to match client expectations
    const districts = results
      .filter((result) => result.Place) // Filter out null/undefined Place
      .map((result) => {
        const place = result.Place!;

        return {
          label: place.Label || "",
          neighborhood: place.Neighborhood || null,
          subMunicipality: place.SubMunicipality || null,
          municipality: place.Municipality || null,
          region: place.Region || "",
          subRegion: place.SubRegion || "",
          country: place.Country || "",
          latitude: place.Geometry?.Point?.[1] ?? null,
          longitude: place.Geometry?.Point?.[0] ?? null,
          relevance: result.Relevance ?? 0.0,
          categories: place.Categories ?? [],
          interpolated: place.Interpolated ?? false,
        };
      });

    return {
      statusCode: 200,
      body: JSON.stringify(districts),
    };
  } catch (error) {
    console.error("Error fetching districts:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: "Internal server error" }),
    };
  }
};
