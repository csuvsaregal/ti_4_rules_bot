import boto3
import json
import random
import os
import requests
import re

s3 = boto3.client('s3')
WEBHOOK_URL = os.environ['DISCORD_WEBHOOK']
BUCKET_NAME = 'ti4-rules'

def lambda_handler(event, context):
    try:
        # Gel all files from bucket
        objects = s3.list_objects_v2(Bucket=BUCKET_NAME)['Contents']
        
        # Pick a random file
        random_file = random.choice(objects)
        file_key = random_file['Key']
        
        # Read file content
        file_obj = s3.get_object(Bucket=BUCKET_NAME, Key=file_key)
        rule_data = json.loads(file_obj['Body'].read().decode('utf-8'))
        
        # Format to Discord
        message = f"**{rule_data['rule_name']}:**\n{rule_data['rule_text']}\n"
        message = re.sub(r'\.[^.]*$', '.', message)
        message = f"{message}\n\n"

        print(f"Sending rule to Discord: {rule_data['rule_name']}"

        # Send to Discord
        payload = {'content': message}
        response = requests.post(WEBHOOK_URL, json=payload)
        print(response.text)
        
        return {'statusCode': 200, 'body': 'Message sent'}
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return {'statusCode': 500, 'body': 'Message send failed!'}
