##################################################
# API Gateway: Location Item Resource (`/{location_id}`)
##################################################
resource "aws_api_gateway_resource" "location_item_resource" {
  rest_api_id = aws_api_gateway_rest_api.locations_api.id
  parent_id   = aws_api_gateway_rest_api.locations_api.root_resource_id
  path_part   = "{location_id}"
}

##################################################
# API Gateway: Get Location Item (GET /{location_id})
##################################################
resource "aws_api_gateway_method" "get_location_item_method" {
  rest_api_id   = aws_api_gateway_rest_api.locations_api.id
  resource_id   = aws_api_gateway_resource.location_item_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.locations_authorizer.id

  request_parameters = {
    "method.request.path.location_id" = true
  }
}

resource "aws_api_gateway_integration" "get_location_item_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.locations_api.id
  resource_id             = aws_api_gateway_resource.location_item_resource.id
  http_method             = aws_api_gateway_method.get_location_item_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.locations_get_item_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.location_id" = "method.request.path.location_id"
  }
}

##################################################
# API Gateway: Districts Resource (`/districts`)
##################################################
resource "aws_api_gateway_resource" "districts_resource" {
  rest_api_id = aws_api_gateway_rest_api.locations_api.id
  parent_id   = aws_api_gateway_rest_api.locations_api.root_resource_id
  path_part   = "districts"
}

##################################################
# API Gateway: Get Districts (GET /)
##################################################
resource "aws_api_gateway_method" "get_districts_method" {
  rest_api_id   = aws_api_gateway_rest_api.locations_api.id
  resource_id   = aws_api_gateway_resource.districts_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.locations_authorizer.id

  request_parameters = {
    "method.request.querystring.lat"         = false
    "method.request.querystring.lng"         = false
    "method.request.querystring.postal_code" = false
  }
}

resource "aws_api_gateway_integration" "get_districts_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.locations_api.id
  resource_id             = aws_api_gateway_resource.districts_resource.id
  http_method             = aws_api_gateway_method.get_districts_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.locations_get_districts_lambda.invoke_arn

  request_parameters = {
    "integration.request.querystring.lat"         = "method.request.querystring.lat"
    "integration.request.querystring.lng"         = "method.request.querystring.lng"
    "integration.request.querystring.postal_code" = "method.request.querystring.postal_code"
  }
}

##################################################
# API Gateway: Schools Resource (`/schools`)
##################################################
resource "aws_api_gateway_resource" "schools_resource" {
  rest_api_id = aws_api_gateway_rest_api.locations_api.id
  parent_id   = aws_api_gateway_rest_api.locations_api.root_resource_id
  path_part   = "schools"
}

##################################################
# API Gateway: Get Schools (GET /)
##################################################
resource "aws_api_gateway_method" "get_schools_method" {
  rest_api_id   = aws_api_gateway_rest_api.locations_api.id
  resource_id   = aws_api_gateway_resource.schools_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.locations_authorizer.id

  request_parameters = {
    "method.request.querystring.lat"         = false
    "method.request.querystring.lng"         = false
    "method.request.querystring.postal_code" = false
    "method.request.querystring.district_id" = false
  }
}

resource "aws_api_gateway_integration" "get_schools_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.locations_api.id
  resource_id             = aws_api_gateway_resource.schools_resource.id
  http_method             = aws_api_gateway_method.get_schools_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.locations_get_schools_lambda.invoke_arn

  request_parameters = {
    "integration.request.querystring.lat"         = "method.request.querystring.lat"
    "integration.request.querystring.lng"         = "method.request.querystring.lng"
    "integration.request.querystring.postal_code" = "method.request.querystring.postal_code"
    "integration.request.querystring.district_id" = "method.request.querystring.district_id"
  }
}

##################################################
# API Gateway: Geocode Resource (`/geocode`)
##################################################
resource "aws_api_gateway_resource" "geocode_resource" {
  rest_api_id = aws_api_gateway_rest_api.locations_api.id
  parent_id   = aws_api_gateway_rest_api.locations_api.root_resource_id
  path_part   = "geocode"
}

##################################################
# API Gateway: Get Schools (GET /)
##################################################
resource "aws_api_gateway_method" "get_geocode_method" {
  rest_api_id   = aws_api_gateway_rest_api.locations_api.id
  resource_id   = aws_api_gateway_resource.geocode_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.locations_authorizer.id

  request_parameters = {
    "method.request.querystring.postal_code" = true
  }
}

resource "aws_api_gateway_integration" "get_geocode_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.locations_api.id
  resource_id             = aws_api_gateway_resource.geocode_resource.id
  http_method             = aws_api_gateway_method.get_geocode_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.locations_get_geocode_lambda.invoke_arn

  request_parameters = {
    "integration.request.querystring.postal_code" = "method.request.querystring.postal_code"
  }
}

##################################################
# API Gateway: Suggestions Resource (`/suggestions`)
##################################################
resource "aws_api_gateway_resource" "suggestions_resource" {
  rest_api_id = aws_api_gateway_rest_api.locations_api.id
  parent_id   = aws_api_gateway_rest_api.locations_api.root_resource_id
  path_part   = "suggestions"
}

##################################################
# API Gateway: Get Schools (GET /)
##################################################
resource "aws_api_gateway_method" "get_suggestions_method" {
  rest_api_id   = aws_api_gateway_rest_api.locations_api.id
  resource_id   = aws_api_gateway_resource.suggestions_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.locations_authorizer.id

  request_parameters = {
    "method.request.querystring.query" = true
    "method.request.querystring.limit" = true
    "method.request.querystring.types" = true
  }
}

resource "aws_api_gateway_integration" "get_suggestions_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.locations_api.id
  resource_id             = aws_api_gateway_resource.suggestions_resource.id
  http_method             = aws_api_gateway_method.get_suggestions_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.locations_get_suggestions_lambda.invoke_arn

  request_parameters = {
    "integration.request.querystring.query" = "method.request.querystring.query"
    "integration.request.querystring.limit" = "method.request.querystring.limit"
    "integration.request.querystring.types" = "method.request.querystring.types"
  }
}
