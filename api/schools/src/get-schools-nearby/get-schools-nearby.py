import os
import boto3
import json
from botocore.exceptions import BotoCoreError, ClientError
from decimal import Decimal

# Initialize SageMaker Runtime client
sagemaker_runtime = boto3.client('sagemaker-runtime')

# Initialize the database client
dynamodb = boto3.resource('dynamodb')

# Environment variables
SAGEMAKER_ENDPOINT_NAME = os.getenv('SAGEMAKER_ENDPOINT_NAME')
TABLE_NAME = os.getenv('TABLE_NAME')

if not SAGEMAKER_ENDPOINT_NAME or not TABLE_NAME:
    raise ValueError("Environment variables SAGEMAKER_ENDPOINT_NAME and TABLE_NAME must be set")

ALLOWED_ORIGINS = [
    "http://localhost:5173",
    "https://dev.fourhorizonsed.com",
    "https://staging.fourhorizonsed.com",
    "https://app.fourhorizonsed.com",
]

# Custom JSON encoder for handling Decimal objects
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)  # Convert Decimal to float
        return super(DecimalEncoder, self).default(obj)

def validate_origin(origin):
    """Validates if the request origin is allowed."""
    if origin in ALLOWED_ORIGINS:
        return origin
    raise ValueError("Origin not allowed.")

def lambda_handler(event, context):
    # Log the incoming event for debugging
    print(f"Received event: {json.dumps(event)}")

    try:
        # Validate origin
        origin = event.get('headers', {}).get('origin')
        if not origin:
            print('Origin header is missing.')
            return {
                'statusCode': 400,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
                },
                'body': json.dumps({'error': 'Origin header is missing.'})
            }

        try:
            allowed_origin = validate_origin(origin)
        except ValueError as e:
            print(json.dumps({'error': str(e)}))
            return {
                'statusCode': 403,
                'headers': {
                    'Access-Control-Allow-Origin': origin,
                    'Access-Control-Allow-Methods': 'GET, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
                },
                'body': json.dumps({'error': str(e)})
            }

        # Handle CORS preflight request
        if event['httpMethod'] == 'OPTIONS':
            print('Handle CORS preflight request')
            return {
                'statusCode': 200,
                'headers': {
                    'Access-Control-Allow-Origin': allowed_origin,
                    'Access-Control-Allow-Methods': 'GET, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
                },
                'body': ''
            }

        # Extract lat and lng from query parameters
        query_params = event.get('queryStringParameters', {})
        lat = query_params.get('lat')
        lng = query_params.get('lng')

        if not lat or not lng:
            print(json.dumps({'error': 'Missing query parameters: lat and lng are required'}))
            return {
                'statusCode': 400,
                'headers': {
                    'Access-Control-Allow-Origin': allowed_origin,
                    'Access-Control-Allow-Methods': 'GET, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
                },
                'body': json.dumps({'error': 'Missing query parameters: lat and lng are required'})
            }

        # Convert lat and lng to float
        lat = float(lat)
        lng = float(lng)

        # Call the SageMaker endpoint
        payload = {'lat': lat, 'lng': lng}
        response = sagemaker_runtime.invoke_endpoint(
            EndpointName=SAGEMAKER_ENDPOINT_NAME,
            ContentType='application/json',
            Body=json.dumps(payload)
        )
        # Parse SageMaker response
        result = json.loads(response['Body'].read().decode('utf-8'))

        # Extract GEOID
        geoid = result.get('GEOID')
        if not geoid:
            print(json.dumps({'error': 'No matching district found'}))
            return {
                'statusCode': 404,
                'headers': {
                    'Access-Control-Allow-Origin': allowed_origin,
                    'Access-Control-Allow-Methods': 'GET, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
                },
                'body': json.dumps({'error': 'No matching district found'})
            }

        # Query documents using GEOID
        table = dynamodb.Table(TABLE_NAME)
        db_response = table.query(
            IndexName='DistrictIndex',  # Adjust to your index name if applicable
            KeyConditionExpression=boto3.dynamodb.conditions.Key('district_id').eq(geoid)
        )

        documents = db_response.get('Items', [])
        print(json.dumps({
                'district': result,
                'documents': documents
            }, cls=DecimalEncoder))

        return {
            'statusCode': 200,
            'headers': {
                    'Access-Control-Allow-Origin': allowed_origin,
                    'Access-Control-Allow-Methods': 'GET, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
                },
            'body': json.dumps({
                'district': result,
                'documents': documents
            }, cls=DecimalEncoder)
        }

    except (BotoCoreError, ClientError) as e:
        print(json.dumps({'error': f"Error calling SageMaker endpoint: {str(e)}"}))
        return {
            'statusCode': 500,
            'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
                },
            'body': json.dumps({'error': f"Error calling SageMaker endpoint: {str(e)}"})
        }
    except Exception as e:
        print(json.dumps({'error': str(e)}))
        return {
            'statusCode': 500,
            'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
                },
            'body': json.dumps({'error': str(e)})
        }
