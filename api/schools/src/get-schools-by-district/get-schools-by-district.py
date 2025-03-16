import json
import os
import boto3
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key
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

def get_schools_by_district(district_id):
    try:
        # Query the DistrictIndex to get schools by district_id
        response = table.query(
            IndexName='DistrictIndex',  # Specify the GSI name
            KeyConditionExpression=Key('district_id').eq(district_id)
        )
        return response.get('Items', [])  # Return the list of schools
    except ClientError as e:
        print(f"Error querying DynamoDB: {e}")
        return None

def lambda_handler(event, context):
    # Log the incoming event for debugging
    print(f"Received event: {json.dumps(event)}")

    # Get query parameters from the event
    query_params = event.get('queryStringParameters', {}) or {}  # Default to empty dictionary if not present

    # Check if district_id is in query params
    if 'district_id' in query_params and query_params['district_id']:
        district_id = query_params['district_id']
        schools = get_schools_by_district(district_id)
        if schools:
            return {
                'statusCode': 200,
                'body': json.dumps(schools, cls=DecimalEncoder)
            }
        else:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'District not found or no schools in district'}, cls=DecimalEncoder)
            }
    
    # If district_id is not provided
    return {
        'statusCode': 400,
        'body': json.dumps({'error': 'Invalid request. Please provide district_id.'}, cls=DecimalEncoder)
    }
