resource "aws_api_gateway_resource" "districts_resource" {
  rest_api_id = aws_api_gateway_rest_api.location_api.id
  parent_id   = aws_api_gateway_rest_api.location_api.root_resource_id
  path_part   = "districts"
}

resource "aws_api_gateway_method" "get_districts_method" {
  rest_api_id   = aws_api_gateway_rest_api.location_api.id
  resource_id   = aws_api_gateway_resource.districts_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.location_authorizer.id

  request_parameters = {
    "method.request.querystring.lat"         = false
    "method.request.querystring.lng"         = false
    "method.request.querystring.postal_code" = false
  }
}

resource "aws_api_gateway_integration" "get_districts_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.location_api.id
  resource_id             = aws_api_gateway_resource.districts_resource.id
  http_method             = aws_api_gateway_method.get_districts_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.location_get_districts_lambda.invoke_arn

  request_parameters = {
    "integration.request.querystring.lat"         = "method.request.querystring.lat"
    "integration.request.querystring.lng"         = "method.request.querystring.lng"
    "integration.request.querystring.postal_code" = "method.request.querystring.postal_code"
  }
}

resource "aws_api_gateway_resource" "schools_resource" {
  rest_api_id = aws_api_gateway_rest_api.location_api.id
  parent_id   = aws_api_gateway_rest_api.location_api.root_resource_id
  path_part   = "schools"
}

resource "aws_api_gateway_method" "get_schools_method" {
  rest_api_id   = aws_api_gateway_rest_api.location_api.id
  resource_id   = aws_api_gateway_resource.schools_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.location_authorizer.id

  request_parameters = {
    "method.request.querystring.lat"         = false
    "method.request.querystring.lng"         = false
    "method.request.querystring.postal_code" = false
    "method.request.querystring.district_id" = false
  }
}

resource "aws_api_gateway_integration" "get_schools_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.location_api.id
  resource_id             = aws_api_gateway_resource.schools_resource.id
  http_method             = aws_api_gateway_method.get_schools_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.location_get_schools_lambda.invoke_arn

  request_parameters = {
    "integration.request.querystring.lat"         = "method.request.querystring.lat"
    "integration.request.querystring.lng"         = "method.request.querystring.lng"
    "integration.request.querystring.postal_code" = "method.request.querystring.postal_code"
    "integration.request.querystring.district_id" = "method.request.querystring.district_id"
  }
}

resource "aws_api_gateway_resource" "geocode_resource" {
  rest_api_id = aws_api_gateway_rest_api.location_api.id
  parent_id   = aws_api_gateway_rest_api.location_api.root_resource_id
  path_part   = "geocode"
}

resource "aws_api_gateway_method" "get_geocode_method" {
  rest_api_id   = aws_api_gateway_rest_api.location_api.id
  resource_id   = aws_api_gateway_resource.geocode_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.location_authorizer.id

  request_parameters = {
    "method.request.querystring.postal_code" = true
  }
}

resource "aws_api_gateway_integration" "get_geocode_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.location_api.id
  resource_id             = aws_api_gateway_resource.geocode_resource.id
  http_method             = aws_api_gateway_method.get_geocode_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.location_get_geocode_lambda.invoke_arn

  request_parameters = {
    "integration.request.querystring.postal_code" = "method.request.querystring.postal_code"
  }
}

# Root /districts
# resource "aws_api_gateway_resource" "location_districts_resource" {
#   rest_api_id = aws_api_gateway_rest_api.location_api.id
#   parent_id   = aws_api_gateway_rest_api.location_api.root_resource_id
#   path_part   = "districts"
# }

# resource "aws_api_gateway_method" "location_get_districts_method" {
#   rest_api_id   = aws_api_gateway_rest_api.location_api.id
#   resource_id   = aws_api_gateway_resource.location_districts_resource.id
#   http_method   = "GET"
#   authorization = "CUSTOM"
#   authorizer_id = aws_api_gateway_authorizer.location_authorizer.id
# }

# resource "aws_api_gateway_integration" "location_get_districts_lambda_integration" {
#   rest_api_id             = aws_api_gateway_rest_api.location_api.id
#   resource_id             = aws_api_gateway_resource.location_districts_resource.id
#   http_method             = aws_api_gateway_method.location_get_districts_method.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.location_get_districts_lambda.invoke_arn
# }

# /districts/{district_id}/schools
# resource "aws_api_gateway_resource" "location_schools_resource" {
#   rest_api_id = aws_api_gateway_rest_api.location_api.id
#   parent_id   = aws_api_gateway_resource.location_districts_resource.id
#   path_part   = "{district_id}"
# }

# resource "aws_api_gateway_resource" "location_district_schools_resource" {
#   rest_api_id = aws_api_gateway_rest_api.location_api.id
#   parent_id   = aws_api_gateway_resource.location_schools_resource.id
#   path_part   = "schools"
# }

# resource "aws_api_gateway_method" "location_get_schools_method" {
#   rest_api_id   = aws_api_gateway_rest_api.location_api.id
#   resource_id   = aws_api_gateway_resource.location_district_schools_resource.id
#   http_method   = "GET"
#   authorization = "CUSTOM"
#   authorizer_id = aws_api_gateway_authorizer.location_authorizer.id

#   request_parameters = {
#     "method.request.path.district_id" = true
#   }
# }

# resource "aws_api_gateway_integration" "location_get_schools_lambda_integration" {
#   rest_api_id             = aws_api_gateway_rest_api.location_api.id
#   resource_id             = aws_api_gateway_resource.location_district_schools_resource.id
#   http_method             = aws_api_gateway_method.location_get_schools_method.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.location_get_schools_lambda.invoke_arn

#   request_parameters = {
#     "integration.request.path.district_id" = "method.request.path.district_id"
#   }
# }
