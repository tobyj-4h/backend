resource "aws_dynamodb_table" "post_events" {
  name         = "post_events"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "post_id"
    type = "S"
  }

  attribute {
    name = "event_id"
    type = "S"
  }

  hash_key  = "post_id"
  range_key = "event_id"

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }
}

resource "aws_dynamodb_table" "post_reactions" {
  name         = "post_reactions"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "post_id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "reaction"
    type = "S"
  }

  hash_key  = "post_id"
  range_key = "user_id"

  global_secondary_index {
    name            = "user_reaction_index"
    hash_key        = "user_id"
    range_key       = "reaction"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }
}

resource "aws_dynamodb_table" "post_comments" {
  name         = "post_comments"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "post_id"
    type = "S"
  }

  attribute {
    name = "comment_id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  hash_key  = "post_id"
  range_key = "comment_id"

  global_secondary_index {
    name            = "user_comments_index"
    hash_key        = "user_id"
    range_key       = "comment_id"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }
}

resource "aws_dynamodb_table" "post_user_favorites" {
  name         = "post_user_favorites"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "post_id"
    type = "S"
  }

  hash_key  = "user_id"
  range_key = "post_id"

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }
}

resource "aws_dynamodb_table" "post_view_counters" {
  name         = "post_view_counters"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "post_id"
    type = "S"
  }

  hash_key = "post_id"

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }
}

resource "aws_dynamodb_table" "post_views" {
  name         = "post_views"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "post_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  hash_key  = "post_id"
  range_key = "timestamp"

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  global_secondary_index {
    name            = "user_id-index"
    hash_key        = "user_id"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }
}

resource "aws_dynamodb_table" "comment_reactions" {
  name         = "comment_reactions"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "comment_id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "reaction"
    type = "S"
  }

  hash_key  = "comment_id"
  range_key = "user_id"

  global_secondary_index {
    name            = "user_reaction_index"
    hash_key        = "user_id"
    range_key       = "reaction"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }
}


