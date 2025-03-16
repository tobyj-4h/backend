import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import {
  DynamoDBClient,
  UpdateItemCommand,
  ScanCommand,
} from "@aws-sdk/client-dynamodb";

const dynamoDb = new DynamoDBClient({
  region: process.env.AWS_REGION || "us-east-1",
});
const VIEWS_TABLE = process.env.VIEWS_TABLE || "post_views";
const VIEW_COUNTERS_TABLE =
  process.env.VIEW_COUNTERS_TABLE || "post_view_counters";

export const handler = async (): Promise<void> => {
  try {
    const scanResult = await dynamoDb.send(
      new ScanCommand({ TableName: VIEWS_TABLE })
    );
    const viewsByPost: Record<string, number> = {};

    if (scanResult.Items) {
      for (const item of scanResult.Items) {
        const postId = item.post_id.S;
        if (postId) {
          viewsByPost[postId] = (viewsByPost[postId] || 0) + 1;
        }
      }
    }

    for (const [postId, viewCount] of Object.entries(viewsByPost)) {
      await dynamoDb.send(
        new UpdateItemCommand({
          TableName: VIEW_COUNTERS_TABLE,
          Key: { post_id: { S: postId } },
          UpdateExpression: "ADD view_count :inc",
          ExpressionAttributeValues: { ":inc": { N: viewCount.toString() } },
        })
      );
    }

    console.log("View counts flushed successfully");
  } catch (error) {
    console.error("Error flushing view counts:", error);
  }
};
