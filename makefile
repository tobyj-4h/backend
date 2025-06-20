.PHONY: auth build build-custom-authorizer build-user terraform-init terraform-plan terraform-apply terraform-destroy select-profile refresh-sso

# Define default terraform directory
export TF_DIR := terraform
export PROFILE_FILE := .aws_profile

# Refresh SSO session specifically
refresh-sso:
	@if [ ! -f $(PROFILE_FILE) ]; then \
		echo "AWS profile not selected, please run 'make auth' to select a profile"; \
		exit 1; \
	fi
	@AWS_PROFILE=$$(cat $(PROFILE_FILE)); \
	echo "Refreshing SSO session for profile: $$AWS_PROFILE"; \
	if aws sso login --profile $$AWS_PROFILE; then \
		echo "✅ SSO session refreshed successfully."; \
		echo "Exporting credentials..."; \
		if aws configure export-credentials --profile $$AWS_PROFILE > /dev/null 2>&1; then \
			echo "✅ Credentials exported successfully."; \
		else \
			echo "❌ Failed to export credentials. Please try 'make auth' again."; \
			exit 1; \
		fi; \
	else \
		echo "❌ Failed to refresh SSO session. Please check your SSO configuration."; \
		exit 1; \
	fi

# Check if AWS credentials are valid; log in only if necessary
check-aws-auth:
	@if [ ! -f $(PROFILE_FILE) ]; then \
		echo "AWS profile not selected, please run 'make auth' to select a profile"; \
		exit 1; \
	fi
	@AWS_PROFILE=$$(cat $(PROFILE_FILE)); \
	echo "Using profile: $$AWS_PROFILE"; \
	echo "Checking AWS credentials..."; \
	if ! aws sts get-caller-identity --profile $$AWS_PROFILE > /dev/null 2>&1; then \
		echo "❌ AWS credentials not found or expired."; \
		echo "Attempting to refresh SSO session..."; \
		if aws sso login --profile $$AWS_PROFILE; then \
			echo "✅ SSO session refreshed successfully."; \
			echo "Exporting credentials..."; \
			if aws configure export-credentials --profile $$AWS_PROFILE > /dev/null 2>&1; then \
				echo "✅ Credentials exported successfully."; \
			else \
				echo "❌ Failed to export credentials. Please try 'make auth' again."; \
				exit 1; \
			fi; \
		else \
			echo "❌ Failed to refresh SSO session. Please run 'make auth' to re-authenticate."; \
			exit 1; \
		fi; \
	else \
		echo "✅ AWS credentials are valid."; \
	fi

# Enhanced AWS SSO login with better error handling
auth: select-profile check-aws-auth

build: build-custom-authorizer build-user

# Navigate to auth/app directory and build the lambda functions
build-custom-authorizer:
	cd api/auth && npm run build

# Navigate to auth/user directory and build the lambda function
build-user:
	cd api/user && npm run build

# Run Terraform init with enhanced error handling
terraform-init: auth
	@AWS_PROFILE=$$(cat $(PROFILE_FILE)); \
	echo "Initializing Terraform with profile: $$AWS_PROFILE"; \
	cd $(TF_DIR) && AWS_PROFILE=$$AWS_PROFILE terraform init

# Run Terraform plan with enhanced error handling
terraform-plan: auth
	@AWS_PROFILE=$$(cat $(PROFILE_FILE)); \
	echo "Running Terraform plan with profile: $$AWS_PROFILE"; \
	cd $(TF_DIR) && AWS_PROFILE=$$AWS_PROFILE terraform plan -var-file=../terraform.tfvars || { \
		echo "❌ Terraform plan failed. This might be due to:"; \
		echo "   - Expired AWS SSO session"; \
		echo "   - Missing or invalid credentials"; \
		echo "   - Terraform configuration errors"; \
		echo ""; \
		echo "To resolve SSO issues, try: make refresh-sso"; \
		exit 1; \
	}

# Run Terraform apply with enhanced error handling
terraform-apply: auth
	@AWS_PROFILE=$$(cat $(PROFILE_FILE)); \
	echo "Running Terraform apply with profile: $$AWS_PROFILE"; \
	cd $(TF_DIR) && AWS_PROFILE=$$AWS_PROFILE terraform apply -var-file=../terraform.tfvars || { \
		echo "❌ Terraform apply failed. This might be due to:"; \
		echo "   - Expired AWS SSO session"; \
		echo "   - Missing or invalid credentials"; \
		echo "   - Terraform configuration errors"; \
		echo ""; \
		echo "To resolve SSO issues, try: make refresh-sso"; \
		exit 1; \
	}

# Run Terraform destroy with enhanced error handling
terraform-destroy: auth
	@AWS_PROFILE=$$(cat $(PROFILE_FILE)); \
	echo "Running Terraform destroy with profile: $$AWS_PROFILE"; \
	cd $(TF_DIR) && AWS_PROFILE=$$AWS_PROFILE terraform destroy -var-file=../terraform.tfvars || { \
		echo "❌ Terraform destroy failed. This might be due to:"; \
		echo "   - Expired AWS SSO session"; \
		echo "   - Missing or invalid credentials"; \
		echo "   - Terraform configuration errors"; \
		echo ""; \
		echo "To resolve SSO issues, try: make refresh-sso"; \
		exit 1; \
	}

# Use fzf to allow user to select profile from ~/.aws/config
select-profile:
	@echo "Available AWS profiles:"
	@AWS_PROFILE=$$(grep '\[profile' ~/.aws/config | sed 's/\[profile \(.*\)\]/\1/' | fzf --prompt "Select AWS Profile: "); \
	echo "Selected profile: $$AWS_PROFILE"; \
	echo $$AWS_PROFILE > $(PROFILE_FILE)
