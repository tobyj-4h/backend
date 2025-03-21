##################################################
# API Gateway: Get Posts (GET /)
##################################################
resource "aws_api_gateway_method" "posts_get_items_method" {
  rest_api_id   = aws_api_gateway_rest_api.posts_api.id
  resource_id   = aws_api_gateway_rest_api.posts_api.root_resource_id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id
}

resource "aws_api_gateway_integration" "posts_get_items_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.posts_api.id
  resource_id             = aws_api_gateway_rest_api.posts_api.root_resource_id
  http_method             = aws_api_gateway_method.posts_get_items_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.posts_get_items_lambda.invoke_arn
}


##################################################
# API Gateway: Create Post (POST /)
##################################################
resource "aws_api_gateway_method" "posts_create_item_method" {
  rest_api_id   = aws_api_gateway_rest_api.posts_api.id
  resource_id   = aws_api_gateway_rest_api.posts_api.root_resource_id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id
}

resource "aws_api_gateway_integration" "posts_create_post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.posts_api.id
  resource_id             = aws_api_gateway_rest_api.posts_api.root_resource_id
  http_method             = aws_api_gateway_method.posts_create_item_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.posts_create_item_lambda.invoke_arn
}

##################################################
# API Gateway: Post Item Resource (`/{post_id}`)
##################################################
resource "aws_api_gateway_resource" "posts_item_resource" {
  rest_api_id = aws_api_gateway_rest_api.posts_api.id
  parent_id   = aws_api_gateway_rest_api.posts_api.root_resource_id
  path_part   = "{post_id}"
}

##################################################
# API Gateway: Get Post (GET /{post_id})
##################################################
resource "aws_api_gateway_method" "posts_get_item_method" {
  rest_api_id   = aws_api_gateway_rest_api.posts_api.id
  resource_id   = aws_api_gateway_resource.posts_item_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "posts_get_item_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.posts_api.id
  resource_id             = aws_api_gateway_resource.posts_item_resource.id
  http_method             = aws_api_gateway_method.posts_get_item_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.posts_get_item_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: Update Post (PUT /{post_id})
##################################################
resource "aws_api_gateway_method" "posts_item_put_method" {
  rest_api_id   = aws_api_gateway_rest_api.posts_api.id
  resource_id   = aws_api_gateway_resource.posts_item_resource.id
  http_method   = "PUT"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "posts_item_put_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.posts_api.id
  resource_id             = aws_api_gateway_resource.posts_item_resource.id
  http_method             = aws_api_gateway_method.posts_item_put_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.posts_update_item_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: Delete Post (DELETE /{post_id})
##################################################
resource "aws_api_gateway_method" "posts_item_delete_method" {
  rest_api_id   = aws_api_gateway_rest_api.posts_api.id
  resource_id   = aws_api_gateway_resource.posts_item_resource.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "posts_item_delete_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.posts_api.id
  resource_id             = aws_api_gateway_resource.posts_item_resource.id
  http_method             = aws_api_gateway_method.posts_item_delete_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.posts_delete_item_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}
