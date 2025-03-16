import json
import os
import boto3
from botocore.exceptions import ClientError
from decimal import Decimal

# Initialize DynamoDB client (adjust as needed for your setup)
dynamodb = boto3.resource('dynamodb')
table_name = os.environ['TABLE_NAME']  # Set this in Lambda's environment variables
table = dynamodb.Table(table_name)

# Custom JSON encoder for handling Decimal objects
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)  # Convert Decimal to float
        return super(DecimalEncoder, self).default(obj)

def get_school_by_id(school_id):
    try:
        # Query DynamoDB for a school by school_id
        response = table.get_item(
            Key={'school_id': school_id}
        )
        return response.get('Item', None)
    except ClientError as e:
        print(f"Error getting school from DynamoDB: {e}")
        return None

def lambda_handler(event, context):
    # Log the incoming event for debugging
    print(f"Received event: {json.dumps(event)}")

    # Define CORS headers
    cors_headers = {
        'Access-Control-Allow-Origin': '*',  # Allow all origins
        'Access-Control-Allow-Methods': 'GET, OPTIONS',  # Allow specific HTTP methods
        'Access-Control-Allow-Headers': 'Content-Type'  # Allow specific headers
    }

    # Get path parameters from the event
    path_params = event.get('pathParameters', {}) or {}  # Default to empty dictionary if not present

    # Check if school_id is in path params
    if 'school_id' in path_params and path_params['school_id']:
        school_id = path_params['school_id']
        school = get_school_by_id(school_id)
        if school:
            return {
                'statusCode': 200,
                'body': json.dumps(school, cls=DecimalEncoder)
            }
        else:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'School not found'}, cls=DecimalEncoder)
            }
    
    # If school_id is not provided
    return {
        'statusCode': 400,
        'body': json.dumps({'error': 'Invalid request. Please provide school_id.'}, cls=DecimalEncoder)
    }
