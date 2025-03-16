##################################################
# Define OPTIONS method for Root ("/")
##################################################
resource "aws_api_gateway_method" "root_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.schools_api.id
  resource_id   = aws_api_gateway_rest_api.schools_api.root_resource_id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.schools_api.id
  resource_id = aws_api_gateway_rest_api.schools_api.root_resource_id
  http_method = aws_api_gateway_method.root_options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "root_options_response" {
  rest_api_id = aws_api_gateway_rest_api.schools_api.id
  resource_id = aws_api_gateway_rest_api.schools_api.root_resource_id
  http_method = aws_api_gateway_method.root_options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

##################################################
# API Gateway: GET Schools By District Method (Root "/")
##################################################
resource "aws_api_gateway_method" "get_schools_by_district_method" {
  rest_api_id   = aws_api_gateway_rest_api.schools_api.id
  resource_id   = aws_api_gateway_rest_api.schools_api.root_resource_id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.querystring.district_id" = true
  }

  api_key_required = false
}

resource "aws_api_gateway_integration" "get_schools_by_district_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.schools_api.id
  resource_id             = aws_api_gateway_rest_api.schools_api.root_resource_id
  http_method             = aws_api_gateway_method.get_schools_by_district_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.get_schools_by_district_lambda.arn}/invocations"

  request_parameters = {
    "integration.request.querystring.district_id" = "method.request.querystring.district_id"
  }
}


##################################################
# API Gateway: GET School By ID Method (Root "/{school_id}")
##################################################
resource "aws_api_gateway_resource" "school_id_resource" {
  rest_api_id = aws_api_gateway_rest_api.schools_api.id
  parent_id   = aws_api_gateway_rest_api.schools_api.root_resource_id
  path_part   = "{school_id}"
}

resource "aws_api_gateway_method" "get_school_by_id_method" {
  rest_api_id   = aws_api_gateway_rest_api.schools_api.id
  resource_id   = aws_api_gateway_resource.school_id_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.school_id" = true
  }

  api_key_required = false
}

resource "aws_api_gateway_integration" "get_school_by_id_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.schools_api.id
  resource_id             = aws_api_gateway_resource.school_id_resource.id
  http_method             = aws_api_gateway_method.get_school_by_id_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.get_school_by_id_lambda.arn}/invocations"
}

##################################################
# API Gateway: OPTIONS School ID Method (Root "/{school_id}")
##################################################
resource "aws_api_gateway_method" "school_id_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.schools_api.id
  resource_id   = aws_api_gateway_resource.school_id_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "school_id_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.schools_api.id
  resource_id = aws_api_gateway_resource.school_id_resource.id
  http_method = aws_api_gateway_method.school_id_options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "school_id_options_response" {
  rest_api_id = aws_api_gateway_rest_api.schools_api.id
  resource_id = aws_api_gateway_resource.school_id_resource.id
  http_method = aws_api_gateway_method.school_id_options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

##################################################
# API Gateway: GET School Nearby Method (Root "/nearby")
##################################################
resource "aws_api_gateway_resource" "nearby_resource" {
  rest_api_id = aws_api_gateway_rest_api.schools_api.id
  parent_id   = aws_api_gateway_rest_api.schools_api.root_resource_id
  path_part   = "nearby"
}

resource "aws_api_gateway_method" "get_schools_nearby_method" {
  rest_api_id   = aws_api_gateway_rest_api.schools_api.id
  resource_id   = aws_api_gateway_resource.nearby_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.querystring.lat" = true
    "method.request.querystring.lng" = true
  }

  api_key_required = false
}

resource "aws_api_gateway_integration" "get_schools_nearby_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.schools_api.id
  resource_id             = aws_api_gateway_resource.nearby_resource.id
  http_method             = aws_api_gateway_method.get_schools_nearby_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.get_schools_nearby_lambda.arn}/invocations"

  request_parameters = {
    "integration.request.querystring.lat" = "method.request.querystring.lat"
    "integration.request.querystring.lng" = "method.request.querystring.lng"
  }
}

##################################################
# API Gateway: OPTIONS Schools Nearby Method (Root "/nearby")
##################################################
resource "aws_api_gateway_method" "nearby_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.schools_api.id
  resource_id   = aws_api_gateway_resource.nearby_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "nearby_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.schools_api.id
  resource_id = aws_api_gateway_resource.nearby_resource.id
  http_method = aws_api_gateway_method.nearby_options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# resource "aws_api_gateway_method_response" "nearby_options_response" {
#   rest_api_id = aws_api_gateway_rest_api.schools_api.id
#   resource_id = aws_api_gateway_resource.nearby_resource.id
#   http_method = aws_api_gateway_method.nearby_options_method.http_method
#   status_code = "200"

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Origin"  = true
#     "method.response.header.Access-Control-Allow-Methods" = true
#     "method.response.header.Access-Control-Allow-Headers" = true
#   }
# }

# resource "aws_api_gateway_integration_response" "nearby_options_response" {
#   rest_api_id = aws_api_gateway_rest_api.schools_api.id
#   resource_id = aws_api_gateway_resource.nearby_resource.id
#   http_method = "OPTIONS"
#   status_code = "200"

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Origin"  = "'*'"
#     "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
#     "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
#   }

#   selection_pattern = ""
# }

