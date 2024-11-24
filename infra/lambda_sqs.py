import base64
import boto3
import json
import random
import os

# Frank; This is probalby be closer to what we need in production. Let's get funding first!

bedrock_client = boto3.client("bedrock-runtime", region_name="us-east-1")
s3_client = boto3.client("s3")

MODEL_ID = "amazon.titan-image-generator-v1"
BUCKET_NAME =  os.environ["BUCKET_NAME"]

def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}")
    
    #array for printing our uri's after each record event
    uri_array = []
    
    if "Records" not in event:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Event does not contain 'Records'"})
        }
        
    # Loop through all SQS records in the event
    for record in event["Records"]:
        # Extract the SQS message body
        prompt = record["body"]
        seed = random.randint(0, 2147483647)
        s3_image_path = f"24/titan_{seed}.png"
        # Prepare the request for image generation
        native_request = {
            "taskType": "TEXT_IMAGE",
            "textToImageParams": {"text": prompt},
            "imageGenerationConfig": {
                "numberOfImages": 1,
                "quality": "standard",
                "cfgScale": 8.0,
                "height": 512,
                "width": 512,
                "seed": seed,
            },
        }

        # Invoke the model
        response = bedrock_client.invoke_model(
            modelId=MODEL_ID,
            body=json.dumps(native_request)
        )

        model_response = json.loads(response["body"].read())
        base64_image_data = model_response["images"][0]
        image_data = base64.b64decode(base64_image_data)

        # Upload the image to S3
        s3_client.put_object(Bucket=BUCKET_NAME, Key=s3_image_path, Body=image_data)

        gen_uri = s3_client.generate_presigned_url(
            "get_object",
            Params={"Bucket" : BUCKET_NAME, "Key" : s3_image_path}
        )
        uri_array.append(gen_uri)
        
    return {
        "statusCode" : 200,
        "body" : json.dumps({
            "image_URIs" : uri_array 
        }),
        "headers" : {
            "Content-Type": "application/json"
        }
    }