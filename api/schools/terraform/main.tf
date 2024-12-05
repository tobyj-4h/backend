resource "aws_iam_role" "lambda_exec" {
  name = "schools_api_lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

##################################################
# Lambda: Schools Get 
##################################################
resource "aws_cloudwatch_log_group" "schools_get_lambda_log_group" {
  name              = "/aws/lambda/SchoolsGetFunction"
  retention_in_days = 7
}

resource "aws_iam_policy" "schools_get_lambda_policy" {
  name = "SchoolsGetLambdaPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Effect = "Allow"
      Resource = [
        aws_cloudwatch_log_group.schools_get_lambda_log_group.arn,       # Restrict to specific log group
        "${aws_cloudwatch_log_group.schools_get_lambda_log_group.arn}:*" # Allow access to log streams in the group
      ]
      }, {
      Effect = "Allow",
      Action = [
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      Resource = "${aws_dynamodb_table.schools.arn}"
    }]
  })
}

resource "aws_lambda_function" "schools_get_lambda" {
  function_name = "SchoolsGetFunction"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.schools_api_get_lambda_repo.repository_url}:v5_3"

  memory_size = 3008
  timeout     = 60

  # IAM Role for Lambda
  role = aws_iam_role.lambda_exec.arn

  # Optionally add environment variables if needed
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.schools.name
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "user_profile_get_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.schools_get_lambda_policy.arn
}



