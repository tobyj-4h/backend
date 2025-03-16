import { S3Client, DeleteObjectCommand } from "@aws-sdk/client-s3";

const REGION = process.env.AWS_REGION || "us-east-1";
const BUCKET_NAME = process.env.BUCKET_NAME || "yourapp-media-prod";

const s3Client = new S3Client({ region: REGION });

export async function handler(event: any) {
  try {
    const mediaId = event.pathParameters?.mediaId;

    if (!mediaId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "Missing mediaId in request" }),
      };
    }

    const command = new DeleteObjectCommand({
      Bucket: BUCKET_NAME,
      Key: mediaId,
    });

    await s3Client.send(command);

    return {
      statusCode: 200,
      body: JSON.stringify({ message: "File deleted successfully" }),
    };
  } catch (error) {
    console.error("Error deleting media:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: "Failed to delete media" }),
    };
  }
}
