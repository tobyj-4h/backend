resource "aws_sagemaker_model" "school_district_model_v1_0_9" {
  name = "${var.sagemaker_endpoint_name}-model-v1-0-9"

  primary_container {
    image = var.ecr_image_uri
    environment = {
      S3_BUCKET = aws_s3_bucket.schools_data_bucket.bucket
      S3_KEY    = aws_s3_object.school_districts_parquet_file.key
    }
  }

  execution_role_arn = aws_iam_role.sagemaker_execution_role.arn
}
