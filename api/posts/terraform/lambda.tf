resource "aws_iam_role" "posts_lambda_exec" {
  name = "posts_api_lambda_exec_role"

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

resource "aws_iam_role_policy_attachment" "posts_lambda_logs" {
  role       = aws_iam_role.posts_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamoDB access policy for the Lambda functions
resource "aws_iam_policy" "posts_dynamodb_access" {
  name = "PostsDynamoDBAccessPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ]
      Effect   = "Allow"
      Resource = aws_dynamodb_table.posts.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "posts_dynamodb_policy_attachment" {
  role       = aws_iam_role.posts_lambda_exec.name
  policy_arn = aws_iam_policy.posts_dynamodb_access.arn
}

##################################################
# LAMBDA: Posts Create
##################################################
resource "aws_lambda_function" "posts_create_lambda" {
  function_name = "PostsCreateFunction"
  handler       = "posts-create.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.posts_lambda_exec.arn

  filename         = "${path.module}/../dist/posts-create.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/posts-create.zip")

  environment {
    variables = {
      POSTS_TABLE = aws_dynamodb_table.posts.id
    }
  }
}

##################################################
# LAMBDA: Posts Create Permission
##################################################
resource "aws_lambda_permission" "api_gateway_posts_create_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.posts_create_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.posts_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Posts Create Log Group
##################################################
resource "aws_cloudwatch_log_group" "posts_create_log_group" {
  name              = "/aws/lambda/PostsCreateFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Posts Create Policy
##################################################
resource "aws_iam_policy" "posts_create_lambda_policy" {
  name = "PostsCreatePolicy"
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
        aws_cloudwatch_log_group.posts_create_log_group.arn,
        "${aws_cloudwatch_log_group.posts_create_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Posts Create Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "posts_create_lambda_attach_policy" {
  role       = aws_iam_role.posts_lambda_exec.name
  policy_arn = aws_iam_policy.posts_create_lambda_policy.arn
}

##################################################
# LAMBDA: Posts Get
##################################################
resource "aws_lambda_function" "posts_get_lambda" {
  function_name = "PostsGetFunction"
  handler       = "posts-get.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.posts_lambda_exec.arn

  filename         = "${path.module}/../dist/posts-get.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/posts-get.zip")

  environment {
    variables = {
      POSTS_TABLE = aws_dynamodb_table.posts.id
    }
  }
}

##################################################
# LAMBDA: Posts Get Permission
##################################################
resource "aws_lambda_permission" "api_gateway_posts_get_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.posts_get_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.posts_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Posts Get Log Group
##################################################
resource "aws_cloudwatch_log_group" "posts_get_log_group" {
  name              = "/aws/lambda/PostsGetFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Posts Get Policy
##################################################
resource "aws_iam_policy" "posts_get_lambda_policy" {
  name = "PostsGetPolicy"
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
        aws_cloudwatch_log_group.posts_get_log_group.arn,
        "${aws_cloudwatch_log_group.posts_get_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Posts Get Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "posts_get_lambda_attach_policy" {
  role       = aws_iam_role.posts_lambda_exec.name
  policy_arn = aws_iam_policy.posts_get_lambda_policy.arn
}

##################################################
# LAMBDA: Posts Update
##################################################
resource "aws_lambda_function" "posts_update_lambda" {
  function_name = "PostsUpdateFunction"
  handler       = "posts-patch.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.posts_lambda_exec.arn

  filename         = "${path.module}/../dist/posts-patch.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/posts-patch.zip")

  environment {
    variables = {
      POSTS_TABLE = aws_dynamodb_table.posts.id
    }
  }
}

##################################################
# LAMBDA: Posts Update Permission
##################################################
resource "aws_lambda_permission" "api_gateway_posts_update_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.posts_update_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.posts_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Posts Update Log Group
##################################################
resource "aws_cloudwatch_log_group" "posts_update_log_group" {
  name              = "/aws/lambda/PostsUpdateFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Posts Update Policy
##################################################
resource "aws_iam_policy" "posts_update_lambda_policy" {
  name = "PostsUpdatePolicy"
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
        aws_cloudwatch_log_group.posts_update_log_group.arn,
        "${aws_cloudwatch_log_group.posts_update_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Posts Update Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "posts_update_lambda_attach_policy" {
  role       = aws_iam_role.posts_lambda_exec.name
  policy_arn = aws_iam_policy.posts_update_lambda_policy.arn
}

##################################################
# LAMBDA: Posts Delete
##################################################
resource "aws_lambda_function" "posts_delete_lambda" {
  function_name = "PostsDeleteFunction"
  handler       = "posts-delete.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.posts_lambda_exec.arn

  filename         = "${path.module}/../dist/posts-delete.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/posts-delete.zip")

  environment {
    variables = {
      POSTS_TABLE = aws_dynamodb_table.posts.id
    }
  }
}

##################################################
# LAMBDA: Posts Delete Permission
##################################################
resource "aws_lambda_permission" "api_gateway_posts_delete_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.posts_delete_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.posts_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Posts Delete Log Group
##################################################
resource "aws_cloudwatch_log_group" "posts_delete_log_group" {
  name              = "/aws/lambda/PostsDeleteFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Posts Delete Policy
##################################################
resource "aws_iam_policy" "posts_delete_lambda_policy" {
  name = "PostsDeletePolicy"
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
        aws_cloudwatch_log_group.posts_delete_log_group.arn,
        "${aws_cloudwatch_log_group.posts_delete_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Posts Delete Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "posts_delete_lambda_attach_policy" {
  role       = aws_iam_role.posts_lambda_exec.name
  policy_arn = aws_iam_policy.posts_delete_lambda_policy.arn
}

##################################################
# API Gateway: Posts Resource (`/`)
##################################################
resource "aws_api_gateway_resource" "posts_resource" {
  rest_api_id = aws_api_gateway_rest_api.posts_api.id
  parent_id   = aws_api_gateway_rest_api.posts_api.root_resource_id
  path_part   = "posts"
}

##################################################
# API Gateway: Create Post (POST /)
##################################################
resource "aws_api_gateway_method" "posts_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.posts_api.id
  resource_id   = aws_api_gateway_resource.posts_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id
}

resource "aws_api_gateway_integration" "posts_post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.posts_api.id
  resource_id             = aws_api_gateway_resource.posts_resource.id
  http_method             = aws_api_gateway_method.posts_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.posts_create_lambda.invoke_arn
}

##################################################
# API Gateway: Post Item Resource (`/{post_id}`)
##################################################
resource "aws_api_gateway_resource" "posts_item_resource" {
  rest_api_id = aws_api_gateway_rest_api.posts_api.id
  parent_id   = aws_api_gateway_resource.posts_resource.id
  path_part   = "{post_id}"
}

##################################################
# API Gateway: Get Post (GET /{post_id})
##################################################
resource "aws_api_gateway_method" "posts_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.posts_api.id
  resource_id   = aws_api_gateway_resource.posts_item_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "posts_get_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.posts_api.id
  resource_id             = aws_api_gateway_resource.posts_item_resource.id
  http_method             = aws_api_gateway_method.posts_get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.posts_get_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: Update Post (PUT /{post_id})
##################################################
resource "aws_api_gateway_method" "posts_put_method" {
  rest_api_id   = aws_api_gateway_rest_api.posts_api.id
  resource_id   = aws_api_gateway_resource.posts_item_resource.id
  http_method   = "PUT"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "posts_put_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.posts_api.id
  resource_id             = aws_api_gateway_resource.posts_item_resource.id
  http_method             = aws_api_gateway_method.posts_put_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.posts_update_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: Delete Post (DELETE /{post_id})
##################################################
resource "aws_api_gateway_method" "posts_delete_method" {
  rest_api_id   = aws_api_gateway_rest_api.posts_api.id
  resource_id   = aws_api_gateway_resource.posts_item_resource.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "posts_delete_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.posts_api.id
  resource_id             = aws_api_gateway_resource.posts_item_resource.id
  http_method             = aws_api_gateway_method.posts_delete_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.posts_delete_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}
