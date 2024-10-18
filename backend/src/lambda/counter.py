import json
import boto3
from boto3.dynamodb.conditions import Key

# Connecting to DynamoDB resource using boto
dynamodb = boto3.resource('dynamodb')

# Define your table name
table_name = 'MyCloudResumeTable'
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    key = 'visit-counter'
    response = table.query(KeyConditionExpression=Key('id').eq(key)) 
    item = response['Items'][0]
    print(item)
    count = item.get('count', 0)
    new_count = count + 1
    print(new_count)
    table.put_item(Item={'id': key, 'count': new_count})
    return {
        'statusCode': 200,
        'body': json.dumps({'new_count': str(new_count)}),
        'headers': {
            'Content-Type': "application/json",
            'Access-Control-Allow-Origin': '*',  # Allows cross-origin requests
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',  # Allow methods
            'Access-Control-Allow-Headers': 'Content-Type'
        }
    }