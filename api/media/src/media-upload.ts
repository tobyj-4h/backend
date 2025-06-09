import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const REGION = process.env.AWS_REGION || "";
const BUCKET_NAME = process.env.BUCKET_NAME || "";
const CLOUDFRONT_URL = process.env.CLOUDFRONT_URL || "";

const s3Client = new S3Client({ region: REGION });

interface MediaUploadRequest {
  fileName: string;
  fileType: string;
  userId: string;
  uploadType: "profile_picture" | "post_image";
  postId?: string;
}

interface MediaUploadResponse {
  url: string;
  filePath: string;
  cdnUrl: string;
}

export async function handler(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    console.log("Received event:", JSON.stringify(event));

    const requestBody: MediaUploadRequest = JSON.parse(event.body || "{}");
    const { fileName, fileType, userId, uploadType, postId } = requestBody;

    // Validate required fields
    if (!fileName || !fileType || !userId || !uploadType) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({
          error: "fileName, fileType, userId, and uploadType are required",
        }),
      };
    }

    // Validate uploadType-specific requirements
    if (uploadType === "post_image" && !postId) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({
          error: "postId is required for post_image uploads",
        }),
      };
    }

    // Get current date and timestamp
    const now = new Date().toISOString();
    const [year, month, day] = now.split("T")[0].split("-");
    const timestamp = now.replace(/[-T:.Z]/g, "");

    // Generate file path based on upload type
    let filePath: string;

    switch (uploadType) {
      case "profile_picture":
        filePath = `users/${userId}/profile/${timestamp}-${fileName}`;
        break;
      case "post_image":
        filePath = `posts/${year}/${month}/${day}/${postId}/${userId}-${timestamp}-${fileName}`;
        break;
      default:
        return {
          statusCode: 400,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
          body: JSON.stringify({ error: "Invalid upload type" }),
        };
    }

    const command = new PutObjectCommand({
      Bucket: BUCKET_NAME,
      Key: filePath,
      ContentType: fileType,
      ACL: "private",
      Metadata: {
        userId: userId,
        uploadType: uploadType,
        originalFileName: fileName,
        ...(postId && { postId: postId }),
      },
    });

    const presignedUrl = await getSignedUrl(s3Client, command, {
      expiresIn: 600, // 10-minute expiry
    });

    const cdnUrl = `${CLOUDFRONT_URL}/${filePath}`;

    const response: MediaUploadResponse = {
      url: presignedUrl,
      filePath,
      cdnUrl,
    };

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify(response),
    };
  } catch (error) {
    console.error("Error generating pre-signed URL:", error);
    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ error: "Failed to generate pre-signed URL" }),
    };
  }
}
