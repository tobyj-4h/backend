import boto3
import json
import argparse
import sys
from boto3.dynamodb.types import TypeSerializer
from decimal import Decimal

def convert_floats_to_decimals(obj):
    """
    Recursively convert all float values in a JSON-like object to Decimal.
    """
    if isinstance(obj, float):
        return Decimal(str(obj))  # Convert float to Decimal
    elif isinstance(obj, dict):
        return {k: convert_floats_to_decimals(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_floats_to_decimals(item) for item in obj]
    else:
        return obj

# Command-line argument parsing
parser = argparse.ArgumentParser(description="Seed a DynamoDB table with data from a JSON file.")
parser.add_argument("--profile", required=True, help="AWS profile to use for credentials.")
parser.add_argument("--region", required=True, help="AWS region where the DynamoDB table is located.")
parser.add_argument("--file", required=True, help="Path to the JSON file containing the data.")
args = parser.parse_args()

# Create a session with the specified profile and region
session = boto3.Session(profile_name=args.profile, region_name=args.region)
dynamodb = session.client('dynamodb')

# Load vanilla JSON file
with open(args.file, 'r') as file:
    data = json.load(file, parse_float=Decimal)  # Optionally convert floats at load time

# Optionally process all data to ensure Decimal conversion
data = convert_floats_to_decimals(data)

# Initialize the TypeSerializer
serializer = TypeSerializer()

# DynamoDB limits: 25 items per batch
BATCH_SIZE = 25
chunks = [data[i:i + BATCH_SIZE] for i in range(0, len(data), BATCH_SIZE)]

# Process each chunk
for i, chunk in enumerate(chunks):
    # Convert each item to DynamoDB JSON format
    request_items = {
        "Schools": [
            {"PutRequest": {"Item": {k: serializer.serialize(v) for k, v in item.items()}}}
            for item in chunk
        ]
    }

    # Batch write the data to DynamoDB
    response = dynamodb.batch_write_item(RequestItems=request_items)
    
    # Overwrite the terminal line
    sys.stdout.write(f"\rUploaded batch {i+1}/{len(chunks)}")
    sys.stdout.flush()

    # Handle unprocessed items (if any)
    while response.get('UnprocessedItems'):
        sys.stdout.write(f"\rRetrying unprocessed items in batch {i+1}      ")
        sys.stdout.flush()
        response = dynamodb.batch_write_item(RequestItems=response['UnprocessedItems'])

print("\nData seeding complete!")
