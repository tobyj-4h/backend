.PHONY: auth build build-custom-authorizer build-user terraform-init terraform-plan terraform-apply terraform-destroy select-profile

# Define default terraform directory
export TF_DIR := terraform
export PROFILE_FILE := .aws_profile

# Check if AWS credentials are valid; log in only if necessary
check-aws-auth:
	@if [ ! -f $(PROFILE_FILE) ]; then \
		echo "AWS profile not selected, please run 'make auth' to select a profile"; \
		exit 1; \
	fi
	@AWS_PROFILE=$$(cat $(PROFILE_FILE)); \
	echo "Using profile: $$AWS_PROFILE"; \
	if ! aws sts get-caller-identity --profile $$AWS_PROFILE > /dev/null 2>&1; then \
		echo "AWS credentials not found or expired. Logging in..."; \
		aws sso login --profile $$AWS_PROFILE; \
		aws configure export-credentials --profile $$AWS_PROFILE > /dev/null 2>&1; \
	fi	

# AWS SSO login and configure credentials, only if necessary
auth: select-profile check-aws-auth

build: build-custom-authorizer build-user

# Navigate to auth/app directory and build the lambda functions
build-custom-authorizer:
	cd api/auth && npm run build

# Navigate to auth/user directory and build the lambda function
build-user:
	cd api/user && npm run build

# Run Terraform init
terraform-init: auth
	@AWS_PROFILE=$$(cat $(PROFILE_FILE)); \
	echo "Initializing Terraform with profile: $$AWS_PROFILE"; \
	cd $(TF_DIR) && AWS_PROFILE=$$AWS_PROFILE terraform init

# Run Terraform plan
terraform-plan: auth
	@AWS_PROFILE=$$(cat $(PROFILE_FILE)); \
	echo "Running Terraform plan with profile: $$AWS_PROFILE"; \
	cd $(TF_DIR) && AWS_PROFILE=$$AWS_PROFILE terraform plan -var-file=../terraform.tfvars

# Run Terraform apply
terraform-apply: auth
	@AWS_PROFILE=$$(cat $(PROFILE_FILE)); \
	echo "Running Terraform apply with profile: $$AWS_PROFILE"; \
	cd $(TF_DIR) && AWS_PROFILE=$$AWS_PROFILE terraform apply -var-file=../terraform.tfvars

# Run Terraform destroy
terraform-destroy: auth
	@AWS_PROFILE=$$(cat $(PROFILE_FILE)); \
	echo "Running Terraform apply with profile: $$AWS_PROFILE"; \
	cd $(TF_DIR) && AWS_PROFILE=$$AWS_PROFILE terraform destroy -var-file=../terraform.tfvars

# Use fzf to allow user to select profile from ~/.aws/config
select-profile:
	@echo "Available AWS profiles:"
	@AWS_PROFILE=$$(grep '\[profile' ~/.aws/config | sed 's/\[profile \(.*\)\]/\1/' | fzf --prompt "Select AWS Profile: "); \
	echo "Selected profile: $$AWS_PROFILE"; \
	echo $$AWS_PROFILE > $(PROFILE_FILE)
