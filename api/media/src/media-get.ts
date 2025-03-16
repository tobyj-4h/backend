export async function handler(event: any) {
  try {
    const mediaId = event.pathParameters?.mediaId;

    if (!mediaId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "Missing mediaId in request" }),
      };
    }

    // Get CloudFront URL from environment variable
    const CLOUDFRONT_URL = process.env.CLOUDFRONT_URL;
    if (!CLOUDFRONT_URL) {
      throw new Error("CLOUDFRONT_URL is not set in environment variables");
    }

    const cloudFrontUrl = `${CLOUDFRONT_URL}/${mediaId}`;

    return {
      statusCode: 200,
      body: JSON.stringify({ url: cloudFrontUrl }),
    };
  } catch (error) {
    console.error("Error retrieving media:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: "Failed to retrieve media" }),
    };
  }
}
