##################################################
# API Gateway: Posts Resource (`/{post_id}`)
##################################################
resource "aws_api_gateway_resource" "post_resource" {
  rest_api_id = aws_api_gateway_rest_api.interactions_api.id
  parent_id   = aws_api_gateway_rest_api.interactions_api.root_resource_id
  path_part   = "{post_id}"
}

##################################################
# API Gateway: Post Reactions Resource (`/{post_id}/reactions`)
##################################################
resource "aws_api_gateway_resource" "post_reactions_resource" {
  rest_api_id = aws_api_gateway_rest_api.interactions_api.id
  parent_id   = aws_api_gateway_resource.post_resource.id
  path_part   = "reactions"
}

##################################################
# API Gateway: Reaction a Post (POST /{post_id}/reactions)
##################################################
resource "aws_api_gateway_method" "reaction_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.post_reactions_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "reaction_post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.post_reactions_resource.id
  http_method             = aws_api_gateway_method.reaction_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.reaction_post_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: Remove Reaction from a Post (DELETE /{post_id}/reactions)
##################################################
resource "aws_api_gateway_method" "remove_reaction_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.post_reactions_resource.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "remove_reaction_post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.post_reactions_resource.id
  http_method             = aws_api_gateway_method.remove_reaction_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.remove_reaction_post_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: Post Comments Resource (`/{post_id}/comments`)
##################################################
resource "aws_api_gateway_resource" "post_comments_resource" {
  rest_api_id = aws_api_gateway_rest_api.interactions_api.id
  parent_id   = aws_api_gateway_resource.post_resource.id
  path_part   = "comments"
}

##################################################
# API Gateway: Comment on a Post (POST /{post_id}/comments)
##################################################
resource "aws_api_gateway_method" "comment_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.post_comments_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "comment_post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.post_comments_resource.id
  http_method             = aws_api_gateway_method.comment_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.comment_post_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: Post Favorites Resource (`/{post_id}/favorites`)
##################################################
resource "aws_api_gateway_resource" "post_favorites_resource" {
  rest_api_id = aws_api_gateway_rest_api.interactions_api.id
  parent_id   = aws_api_gateway_resource.post_resource.id
  path_part   = "favorites"
}

##################################################
# API Gateway: Favorite a Post (POST /{post_id}/favorites)
##################################################
resource "aws_api_gateway_method" "favorite_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.post_favorites_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "favorite_post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.post_favorites_resource.id
  http_method             = aws_api_gateway_method.favorite_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.favorite_post_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: Unfavorite a Post (DELETE /{post_id}/favorites)
##################################################
resource "aws_api_gateway_method" "unfavorite_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.post_favorites_resource.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "unfavorite_post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.post_favorites_resource.id
  http_method             = aws_api_gateway_method.unfavorite_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.unfavorite_post_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: Post Views Resource (`/{post_id}/views`)
##################################################
resource "aws_api_gateway_resource" "post_views_resource" {
  rest_api_id = aws_api_gateway_rest_api.interactions_api.id
  parent_id   = aws_api_gateway_resource.post_resource.id
  path_part   = "views"
}

##################################################
# API Gateway: View a Post (POST /{post_id}/views)
##################################################
# resource "aws_api_gateway_method" "view_post_method" {
#   rest_api_id   = aws_api_gateway_rest_api


resource "aws_api_gateway_method" "view_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.post_views_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "view_post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.post_views_resource.id
  http_method             = aws_api_gateway_method.view_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.view_post_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}
