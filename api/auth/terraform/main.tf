# Use the current AWS region without a variable by using data source
data "aws_region" "current" {}

# Lambda Exec Role
resource "aws_iam_role" "lambda_exec" {
  name = "customer_authorizer_lambda_exec_role"

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

# Custome Authorizer Lambda
resource "aws_lambda_function" "custom_authorizer_lambda" {
  function_name = "CustomAuthorizerFunction"
  handler       = "custom-authorizer.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/custom-authorizer.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/custom-authorizer.zip")

  environment {
    variables = {
      LOG_LEVEL    = "INFO"
      USER_POOL_ID = var.user_pool_id
      REGION       = data.aws_region.current.name
    }
  }
}

resource "aws_cloudwatch_log_group" "custom_authorizer_lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.custom_authorizer_lambda.function_name}"
  retention_in_days = 7
}

resource "aws_iam_policy" "user_preferences_post_lambda_policy" {
  name = "${aws_lambda_function.custom_authorizer_lambda.function_name}Policy"
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
        aws_cloudwatch_log_group.custom_authorizer_lambda_log_group.arn,       # Restrict to specific log group
        "${aws_cloudwatch_log_group.custom_authorizer_lambda_log_group.arn}:*" # Allow access to log streams in the group
      ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "custom_authorizer_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.user_preferences_post_lambda_policy.arn
}
