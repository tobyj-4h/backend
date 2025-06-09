import { LocationClient, GetPlaceCommand } from "@aws-sdk/client-location";

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
    // Extract the locationId from the path parameters
    const locationId = event.pathParameters?.locationId;

    if (!locationId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "Missing locationId parameter" }),
      };
    }

    // AWS Location Service Place Index Name
    const placeIndexName = process.env.PLACE_INDEX_NAME || "YourPlaceIndexName";

    const command = new GetPlaceCommand({
      IndexName: placeIndexName,
      PlaceId: locationId,
    });

    const response = await client.send(command);

    if (!response.Place) {
      return {
        statusCode: 404,
        body: JSON.stringify({ error: "Location not found" }),
      };
    }

    const place = response.Place;

    // Transform the AWS response to a more user-friendly format
    const locationDetails = {
      id: locationId,
      name: place.Label || "",
      address: place.AddressNumber
        ? `${place.AddressNumber} ${place.Street || ""}`
        : place.Street || "",
      city: place.Municipality || "",
      state: place.Region || "",
      postalCode: place.PostalCode || "",
      country: place.Country || "",
      coordinates: place.Geometry?.Point
        ? {
            lat: place.Geometry.Point[1],
            lng: place.Geometry.Point[0],
          }
        : null,
      categories: place.Categories || [],
      timeZone: place.TimeZone || "",
      // Additional metadata if available
      metadata: {
        isAddressComplete:
          !!place.AddressNumber && !!place.Street && !!place.Municipality,
        type: place.SubRegion ? "city" : place.Region ? "state" : "country",
        formattedAddress: place.Label || "",
      },
    };

    return {
      statusCode: 200,
      body: JSON.stringify(locationDetails),
    };
  } catch (error) {
    console.error("Error fetching location details:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: "Internal server error" }),
    };
  }
};
