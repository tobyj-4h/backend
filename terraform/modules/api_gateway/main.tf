# Use the current AWS region without a variable by using data source
data "aws_region" "current" {}

# Set up a custom domain name
resource "aws_api_gateway_domain_name" "custom_domain" {
  domain_name     = var.domain_name
  certificate_arn = var.certificate_arn
}

# Create IAM role for API Gateway to push logs to CloudWatch
resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name = "APIGatewayCloudWatchLogsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the managed policy to the IAM role
resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_logs" {
  role       = aws_iam_role.api_gateway_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

