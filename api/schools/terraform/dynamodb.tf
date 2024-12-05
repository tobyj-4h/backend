resource "aws_dynamodb_table" "schools" {
  name         = "Schools"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "school_id" # Primary Key

  attribute {
    name = "school_id"
    type = "S"
  }

  attribute {
    name = "district_id"
    type = "S"
  }

  # Global Secondary Index for querying by district_id
  global_secondary_index {
    name            = "DistrictIndex"
    hash_key        = "district_id"
    projection_type = "ALL"
  }

  tags = {
    Environment = "production"
    Name        = "SchoolsTable"
  }
}
