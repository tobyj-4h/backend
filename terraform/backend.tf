terraform {
  backend "s3" {
    bucket  = "parenthub-tf-state-bucket-dev"             # The name of your state bucket
    key     = "terraform/backend/state/terraform.tfstate" # The path to the state file in S3
    region  = "us-east-1"                                 # Replace with your desired default region
    encrypt = true
  }
}
