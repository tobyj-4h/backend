resource "aws_ecr_repository" "schools_api_get_lambda_repo" {
  name                 = "schools-api-get-lambda"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository" "school_district_query_repo" {
  name                 = "school-district-query"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
