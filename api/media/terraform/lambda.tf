resource "aws_iam_role" "lambda_exec" {
  name = "media_api_lambda_exec_role"

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

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

##################################################
# LAMBDA: Media Upload
##################################################
resource "aws_lambda_function" "media_upload_lambda" {
  function_name = "MediaUploadFunction"
  handler       = "media-upload.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/media-upload.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/media-upload.zip")

  environment {
    variables = {
      BUCKET_NAME    = aws_s3_bucket.media_bucket.id
      CLOUDFRONT_URL = "https://${aws_cloudfront_distribution.media_cdn.domain_name}"
    }
  }
}

##################################################
# LAMBDA: Media Upload Permission
##################################################
resource "aws_lambda_permission" "api_gateway_media_upload_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.media_upload_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.media_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Media Upload Log Group
##################################################
resource "aws_cloudwatch_log_group" "media_upload_log_group" {
  name              = "/aws/lambda/MediaUploadFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Media Upload Policy
##################################################
resource "aws_iam_policy" "media_upload_lambda_policy" {
  name = "MediaUploadPolicy"
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
        aws_cloudwatch_log_group.media_upload_log_group.arn,       # Restrict to specific log group
        "${aws_cloudwatch_log_group.media_upload_log_group.arn}:*" # Allow access to log streams in the group
      ]
    }]
  })
}

##################################################
# LAMBDA: Media Upload Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "media_upload_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.media_upload_lambda_policy.arn
}

##################################################
# LAMBDA: Media Get
##################################################
resource "aws_lambda_function" "media_get_lambda" {
  function_name = "MediaGetFunction"
  handler       = "media-get.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/media-get.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/media-get.zip")

  environment {
    variables = {
      CLOUDFRONT_URL = "https://${aws_cloudfront_distribution.media_cdn.domain_name}"
    }
  }
}

##################################################
# LAMBDA: Media Get Permission
##################################################
resource "aws_lambda_permission" "api_gateway_media_get_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.media_get_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.media_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Media Get Log Group
##################################################
resource "aws_cloudwatch_log_group" "media_get_log_group" {
  name              = "/aws/lambda/MediaGetFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Media Get Policy
##################################################
resource "aws_iam_policy" "media_get_lambda_policy" {
  name = "MediaGetPolicy"
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
        aws_cloudwatch_log_group.media_get_log_group.arn,       # Restrict to specific log group
        "${aws_cloudwatch_log_group.media_get_log_group.arn}:*" # Allow access to log streams in the group
      ]
    }]
  })
}

##################################################
# LAMBDA: Media Get Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "media_get_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.media_get_lambda_policy.arn
}

##################################################
# LAMBDA: Media Delete
##################################################
resource "aws_lambda_function" "media_delete_lambda" {
  function_name = "MediaDeleteFunction"
  handler       = "media-delete.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/media-delete.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/media-delete.zip")

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.media_bucket.id
    }
  }
}

##################################################
# LAMBDA: Media Delete Permission
##################################################
resource "aws_lambda_permission" "api_gateway_media_delete_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.media_delete_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.media_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Media Delete Log Group
##################################################
resource "aws_cloudwatch_log_group" "media_delete_log_group" {
  name              = "/aws/lambda/MediaDeleteFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Media Delete Policy
##################################################
resource "aws_iam_policy" "media_delete_lambda_policy" {
  name = "MediaDeletePolicy"
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
        aws_cloudwatch_log_group.media_delete_log_group.arn,       # Restrict to specific log group
        "${aws_cloudwatch_log_group.media_delete_log_group.arn}:*" # Allow access to log streams in the group
      ]
    }]
  })
}

##################################################
# LAMBDA: Media Delete Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "media_delete_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.media_delete_lambda_policy.arn
}



##################################################
# API Gateway: Media Resource (`/media`)
##################################################
# resource "aws_api_gateway_resource" "media_resource" {
#   rest_api_id = aws_api_gateway_rest_api.media_api.id
#   parent_id   = aws_api_gateway_rest_api.media_api.root_resource_id
#   path_part   = "media"
# }

##################################################
# API Gateway: Upload Media (POST /)
##################################################
resource "aws_api_gateway_method" "media_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.media_api.id
  resource_id   = aws_api_gateway_rest_api.media_api.root_resource_id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.media_authorizer.id
}

resource "aws_api_gateway_integration" "media_post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.media_api.id
  resource_id             = aws_api_gateway_rest_api.media_api.root_resource_id
  http_method             = aws_api_gateway_method.media_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.media_upload_lambda.invoke_arn
}

##################################################
# API Gateway: Media Item Resource (`/{mediaId}`)
##################################################
resource "aws_api_gateway_resource" "media_item_resource" {
  rest_api_id = aws_api_gateway_rest_api.media_api.id
  parent_id   = aws_api_gateway_rest_api.media_api.root_resource_id
  path_part   = "{mediaId}"
}

##################################################
# API Gateway: Retrieve Media (GET /{mediaId})
##################################################
resource "aws_api_gateway_method" "media_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.media_api.id
  resource_id   = aws_api_gateway_resource.media_item_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.media_authorizer.id

  request_parameters = {
    "method.request.path.mediaId" = true
  }
}

resource "aws_api_gateway_integration" "media_get_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.media_api.id
  resource_id             = aws_api_gateway_resource.media_item_resource.id
  http_method             = aws_api_gateway_method.media_get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.media_get_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.mediaId" = "method.request.path.mediaId"
  }
}

##################################################
# API Gateway: Delete Media (DELETE /{mediaId})
##################################################
resource "aws_api_gateway_method" "media_delete_method" {
  rest_api_id   = aws_api_gateway_rest_api.media_api.id
  resource_id   = aws_api_gateway_resource.media_item_resource.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.media_authorizer.id

  request_parameters = {
    "method.request.path.mediaId" = true
  }
}

resource "aws_api_gateway_integration" "media_delete_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.media_api.id
  resource_id             = aws_api_gateway_resource.media_item_resource.id
  http_method             = aws_api_gateway_method.media_delete_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.media_delete_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.mediaId" = "method.request.path.mediaId"
  }
}

##################################################
# LAMBDA: Media Authorizer Lambda Exec Role
##################################################
resource "aws_iam_role" "media_authorizer_lambda_exec" {
  name = "media_authorizer_lambda_exec_role"

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
# LAMBDA: Media Authorizer Lambda
##################################################
resource "aws_lambda_function" "media_authorizer_lambda" {
  function_name = "MediaAuthorizerFunction"
  handler       = "media-authorizer.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.media_authorizer_lambda_exec.arn

  filename         = "${path.module}/../dist/media-authorizer.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/media-authorizer.zip")

  environment {
    variables = {
      LOG_LEVEL    = "INFO"
      USER_POOL_ID = var.user_pool_id
      REGION       = data.aws_region.current.name
    }
  }
}

##################################################
# LAMBDA: Media Authorizer Lambda Log Group
##################################################
resource "aws_cloudwatch_log_group" "media_authorizer_lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.media_authorizer_lambda.function_name}"
  retention_in_days = 7
}

##################################################
# LAMBDA: Media Authorizer Lambda Policy
##################################################
resource "aws_iam_policy" "media_authorizer_lambda_policy" {
  name = "${aws_lambda_function.media_authorizer_lambda.function_name}Policy"
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
        aws_cloudwatch_log_group.media_authorizer_lambda_log_group.arn,       # Restrict to specific log group
        "${aws_cloudwatch_log_group.media_authorizer_lambda_log_group.arn}:*" # Allow access to log streams in the group
      ]
      }
    ]
  })
}

##################################################
# LAMBDA: Media Authorizer Lambda Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "media_authorizer_lambda_attach_policy" {
  role       = aws_iam_role.media_authorizer_lambda_exec.name
  policy_arn = aws_iam_policy.media_authorizer_lambda_policy.arn
}
