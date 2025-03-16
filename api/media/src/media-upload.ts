import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const REGION = process.env.AWS_REGION || "";
const BUCKET_NAME = process.env.BUCKET_NAME || "";
const CLOUDFRONT_URL = process.env.CLOUDFRONT_URL || ""; // ✅ Ensure this is set

const s3Client = new S3Client({ region: REGION });

export async function handler(event: any) {
  try {
    const { fileName, fileType, userId, postId } = JSON.parse(event.body);

    // Get current date in ISO format (UTC)
    const now = new Date().toISOString(); // Example: "2025-03-14T12:34:56.789Z"
    const [year, month, day] = now.split("T")[0].split("-"); // Extract YYYY, MM, DD
    const timestamp = now.replace(/[-T:.Z]/g, ""); // Compact timestamp: 20250314T123456789

    // Construct S3 file path
    const filePath = `posts/${year}/${month}/${day}/${postId}/${userId}-${timestamp}-${fileName}`;

    const command = new PutObjectCommand({
      Bucket: BUCKET_NAME,
      Key: filePath,
      ContentType: fileType,
      ACL: "private",
    });

    const presignedUrl = await getSignedUrl(s3Client, command, {
      expiresIn: 600,
    }); // 10-minute expiry

    const cdnUrl = `${CLOUDFRONT_URL}/${filePath}`; // ✅ Construct CloudFront URL

    return {
      statusCode: 200,
      body: JSON.stringify({ url: presignedUrl, filePath, cdnUrl }), // ✅ Return cdnUrl
    };
  } catch (error) {
    console.error("Error generating pre-signed URL:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: "Failed to generate pre-signed URL" }),
    };
  }
}
