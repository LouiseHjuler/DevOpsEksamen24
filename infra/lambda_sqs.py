import base64
import boto3
import json
import random
import logging
import os

# Initialize AWS clients
bedrock_client = boto3.client("bedrock-runtime", region_name="us-east-1")
s3_client = boto3.client("s3")

# Define the model ID and get S3 bucket name from YAML and lambda name
model_id = "amazon.titan-image-generator-v1"
bucket_name = get_s3_bucket_name()

# Set up logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Get correct bucket name from environment variables
def get_s3_bucket_name():
    bucket_name = os.environ.get("CouchExplorerBucket")
    if not bucket_name:
        raise ValueError("Error: Bucket name not found")
    return bucket_name

def lambda_handler(event, context):
    # Log the incoming event for debugging
    logger.info("Received event: %s", json.dumps(event))
    
    try:
        #determine HTTP method
        http_method = event.get("httpMethod")
        
        #handle GET / POST methods
        if http_method == "GET":
            #handle GET request
            logger.info("handeling GET request")
            return{
                "statusCode": 200,
                "body": json.dumps({"message": "Image generation API is working!"}),
                "headers": {
                    "Content-Type": "application/json"
                }
            }
        elif http_method == "POST":
            #handle POST request
            logger.info("handle POST request")
            try:
                # Loop through all SQS records in the event
                for record in event["Records"]:
                    # Extract the prompt from the SQS message body
                    prompt = record["body"]
                    
                    if not prompt:
                        return {
                            "statusCode": 400,
                            "body": json.dumps({"error": "Missing 'prompt' in request body"}),
                            "headers": {
                                "Content-Type": "application/json"
                            }
                        }
                    
                    # Log the prompt for confirmation
                    logger.info("Received prompt: %s", prompt)
        
                    # Generate unique image name with a random seed
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
                        modelId=model_id,
                        body=json.dumps(native_request)
                    )
        
                    model_response = json.loads(response["body"].read())
                    base64_image_data = model_response["images"][0]
                    image_data = base64.b64decode(base64_image_data)
        
                    # Upload the image to S3
                    s3_client.put_object(Bucket=bucket_name, Key=s3_image_path, Body=image_data)
        
                    # Generate a presigned URL for the image
                    gen_uri = s3_client.generate_presigned_url(
                        "get_object",
                        Params={"Bucket": bucket_name, "Key": s3_image_path}
                    )
        
                    return {
                        "statusCode": 200,
                        "body": json.dumps({
                            "image_URI": gen_uri
                        }),
                        "headers": {
                            "Content-Type": "application/json"
                        }
                    }
                else:
                    return {
                        "statusCode": 405,
                        "body": json.dumps({"error": "Method Not Allowed"}),
                        "headers": {
                            "Content-Type": "application/json"
                        }
                    }

    except Exception as e:
        logger.error("error: %s", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)}),
            "headers": {
                "Content-Type": "application/json"
            }
        }