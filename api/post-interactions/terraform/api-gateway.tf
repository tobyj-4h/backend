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
# API Gateway: New POST /{post_id}/reactions (Add New Reaction)
##################################################
resource "aws_api_gateway_method" "post_reactions_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.post_reactions_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "post_reactions_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.post_reactions_resource.id
  http_method             = aws_api_gateway_method.post_reactions_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.post_interactions_add_reaction_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: New PUT /{post_id}/reactions (Update Existing Reaction)
##################################################
resource "aws_api_gateway_method" "put_reactions_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.post_reactions_resource.id
  http_method   = "PUT"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "put_reactions_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.post_reactions_resource.id
  http_method             = aws_api_gateway_method.put_reactions_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.post_interactions_update_reaction_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: New DELETE /{post_id}/reactions (Remove Reaction)
##################################################
resource "aws_api_gateway_method" "delete_reactions_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.post_reactions_resource.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "delete_reactions_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.post_reactions_resource.id
  http_method             = aws_api_gateway_method.delete_reactions_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.post_interactions_delete_reaction_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: New GET /{post_id}/reactions (Get Reactions for Post)
##################################################
resource "aws_api_gateway_method" "get_reactions_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.post_reactions_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "get_reactions_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.post_reactions_resource.id
  http_method             = aws_api_gateway_method.get_reactions_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.post_interactions_get_reaction_lambda.invoke_arn

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
  uri                     = aws_lambda_function.post_interactions_comment_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: Get Comments for a Post (GET /{post_id}/comments)
##################################################
resource "aws_api_gateway_method" "get_comments_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.post_comments_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "get_comments_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.post_comments_resource.id
  http_method             = aws_api_gateway_method.get_comments_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.post_interactions_get_comments_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: Individual Comment Resource (`/{post_id}/comments/{comment_id}`)
##################################################
resource "aws_api_gateway_resource" "individual_comment_resource" {
  rest_api_id = aws_api_gateway_rest_api.interactions_api.id
  parent_id   = aws_api_gateway_resource.post_comments_resource.id
  path_part   = "{comment_id}"
}

##################################################
# API Gateway: Comment Replies Resource (`/{post_id}/comments/{comment_id}/replies`)
##################################################
resource "aws_api_gateway_resource" "comment_replies_resource" {
  rest_api_id = aws_api_gateway_rest_api.interactions_api.id
  parent_id   = aws_api_gateway_resource.individual_comment_resource.id
  path_part   = "replies"
}

##################################################
# API Gateway: Reply to Comment (POST /{post_id}/comments/{comment_id}/replies)
##################################################
resource "aws_api_gateway_method" "reply_to_comment_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.comment_replies_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id"    = true
    "method.request.path.comment_id" = true
  }
}

resource "aws_api_gateway_integration" "reply_to_comment_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.comment_replies_resource.id
  http_method             = aws_api_gateway_method.reply_to_comment_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.post_interactions_reply_comment_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id"    = "method.request.path.post_id"
    "integration.request.path.comment_id" = "method.request.path.comment_id"
  }
}

##################################################
# API Gateway: Comment Reactions Resource (`/{post_id}/comments/{comment_id}/reactions`)
##################################################
resource "aws_api_gateway_resource" "comment_reactions_resource" {
  rest_api_id = aws_api_gateway_rest_api.interactions_api.id
  parent_id   = aws_api_gateway_resource.individual_comment_resource.id
  path_part   = "reactions"
}

##################################################
# API Gateway: Add Comment Reaction (POST /{post_id}/comments/{comment_id}/reactions)
##################################################
resource "aws_api_gateway_method" "comment_reactions_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.comment_reactions_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id"    = true
    "method.request.path.comment_id" = true
  }
}

resource "aws_api_gateway_integration" "comment_reactions_post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.comment_reactions_resource.id
  http_method             = aws_api_gateway_method.comment_reactions_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.post_interactions_add_comment_reaction_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id"    = "method.request.path.post_id"
    "integration.request.path.comment_id" = "method.request.path.comment_id"
  }
}

##################################################
# API Gateway: Update Comment Reaction (PUT /{post_id}/comments/{comment_id}/reactions)
##################################################
resource "aws_api_gateway_method" "comment_reactions_put_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.comment_reactions_resource.id
  http_method   = "PUT"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id"    = true
    "method.request.path.comment_id" = true
  }
}

resource "aws_api_gateway_integration" "comment_reactions_put_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.comment_reactions_resource.id
  http_method             = aws_api_gateway_method.comment_reactions_put_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.post_interactions_update_comment_reaction_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id"    = "method.request.path.post_id"
    "integration.request.path.comment_id" = "method.request.path.comment_id"
  }
}

##################################################
# API Gateway: Delete Comment Reaction (DELETE /{post_id}/comments/{comment_id}/reactions)
##################################################
resource "aws_api_gateway_method" "comment_reactions_delete_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.comment_reactions_resource.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id"    = true
    "method.request.path.comment_id" = true
  }
}

resource "aws_api_gateway_integration" "comment_reactions_delete_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.comment_reactions_resource.id
  http_method             = aws_api_gateway_method.comment_reactions_delete_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.post_interactions_delete_comment_reaction_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id"    = "method.request.path.post_id"
    "integration.request.path.comment_id" = "method.request.path.comment_id"
  }
}

##################################################
# API Gateway: Get Comment Reactions (GET /{post_id}/comments/{comment_id}/reactions)
##################################################
resource "aws_api_gateway_method" "comment_reactions_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.comment_reactions_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id"    = true
    "method.request.path.comment_id" = true
  }
}

resource "aws_api_gateway_integration" "comment_reactions_get_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.comment_reactions_resource.id
  http_method             = aws_api_gateway_method.comment_reactions_get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.post_interactions_get_comment_reaction_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id"    = "method.request.path.post_id"
    "integration.request.path.comment_id" = "method.request.path.comment_id"
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
# API Gateway: Favorite Post (POST /{post_id}/favorites)
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
  uri                     = aws_lambda_function.post_interactions_favorite_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: Unfavorite Post (DELETE /{post_id}/favorites)
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
  uri                     = aws_lambda_function.post_interactions_unfavorite_lambda.invoke_arn

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
# API Gateway: View Post (POST /{post_id}/views)
##################################################
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
  uri                     = aws_lambda_function.post_interactions_view_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}
