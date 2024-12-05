import boto3
import json

# Specify your AWS profile and region
aws_profile = "Dev-Environment-AWSAdministratorAccess"  # Replace with your profile name
aws_region = "us-east-1"  # Replace with your desired AWS region (e.g., "us-east-1")

# Create a session using the specified profile
session = boto3.Session(profile_name=aws_profile, region_name=aws_region)

# Set up the SageMaker runtime client using the session
sagemaker_runtime = session.client('sagemaker-runtime')

# Define the endpoint name (replace with your actual endpoint name)
endpoint_name = 'school-district-query-endpoint-v1-0-9'

# Define the payload (input data) for your request
payload = {
    "lat": 40.6009721,  # Example latitude (replace with actual data)
    "lng": -74.4366886  # Example longitude (replace with actual data)
}

# Convert the payload to JSON format
payload_json = json.dumps(payload)

# Call the SageMaker endpoint
response = sagemaker_runtime.invoke_endpoint(
    EndpointName=endpoint_name,
    ContentType='application/json',  # Set the content type to JSON
    Accept='application/json',  # Accept JSON response
    Body=payload_json  # The input data as the request body
)

# Get the result from the response
result = json.loads(response['Body'].read().decode())

# Print the result
print("Response from SageMaker endpoint:", result)
