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
    const postalCode = event.queryStringParameters?.postal_code;
    if (!postalCode) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "Missing postal_code parameter" }),
      };
    }

    // AWS Location Service Place Index Name
    const placeIndexName = process.env.PLACE_INDEX_NAME || "YourPlaceIndexName";

    const command = new SearchPlaceIndexForTextCommand({
      IndexName: placeIndexName,
      Text: postalCode,
      MaxResults: 1,
    });

    const response = await client.send(command);
    const results = response.Results;

    if (!results || results.length === 0 || !results[0].Place) {
      return {
        statusCode: 404,
        body: JSON.stringify({ error: "No results found for postal code" }),
      };
    }

    // Ensure Place and Geometry are defined before accessing them
    const place = results[0].Place;
    if (!place.Geometry?.Point) {
      return {
        statusCode: 500,
        body: JSON.stringify({
          error: "Invalid response from AWS Location Service",
        }),
      };
    }

    return {
      statusCode: 200,
      body: JSON.stringify({
        lat: place.Geometry.Point[1], // AWS returns [longitude, latitude]
        lng: place.Geometry.Point[0],
      }),
    };
  } catch (error) {
    console.error("Error fetching geocode:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: "Internal server error" }),
    };
  }
};
