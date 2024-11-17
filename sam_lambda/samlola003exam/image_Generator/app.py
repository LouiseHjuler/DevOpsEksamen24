import base64
import boto3
import json
import random
import logging

logger= logging.getLogger()
logger.setLevel(logging.INFO)

# import requests


def lambda_handler(event, context):
    """Sample pure Lambda function

    Parameters
    ----------
    event: dict, required
        API Gateway Lambda Proxy Input Format

        Event doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format

    context: object, required
        Lambda Context runtime methods and attributes

        Context doc: https://docs.aws.amazon.com/lambda/latest/dg/python-context-object.html

    Returns
    ------
    API Gateway Lambda Proxy Output Format: dict

        Return doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html
    """

    # try:
    #     ip = requests.get("http://checkip.amazonaws.com/")
    # except requests.RequestException as e:
    #     # Send some context about this error to Lambda Logs
    #     print(e)

    #     raise e

    #return {
    #    "statusCode": 200,
    #    "body": json.dumps({
    #        "message": "hello world",
    #        # "location": ip.text.replace("\n", "")
    #    }),
    #}
    
    print(event)
    # Extract the 'prompt' from the POST request body
    try:
        # Log the incoming event for debugging
        logger.info("Received event: %s", json.dumps(event))

        # Parse the body of the event (it's typically a string)
        body = event.get("body", "{}")
        body = json.loads(body)  # Convert the body string into a dictionary

        # Extract the 'prompt' from the parsed body
        prompt = body.get("prompt", None)
        #prompt = event.get("prompt", None)
        
        # Check if the 'prompt' is provided in the body
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
                
        # Set up the AWS clients
        
        bedrock_client = boto3.client("bedrock-runtime", region_name="us-east-1")
        s3_client = boto3.client("s3")
        
        # Define the model ID and S3 bucket name (replace with your actual bucket name)
        model_id = "amazon.titan-image-generator-v1"
        bucket_name = "pgr301-couch-explorers"
        
        # Frank; Important; Change this prompt to something else before the presentation with the investors!
        #prompt = "Investors, with circus hats, giving money to developers with large smiles"
        
        seed = random.randint(0, 2147483647)
        s3_image_path = f"24/titan_{seed}.png"
        
        native_request = {
            "taskType": "TEXT_IMAGE",
            "textToImageParams": {"text": prompt},
            "imageGenerationConfig": {
                "numberOfImages": 1,
                "quality": "standard",
                "cfgScale": 8.0,
                "height": 1024,
                "width": 1024,
                "seed": seed,
            }
        }
        
        response = bedrock_client.invoke_model(modelId=model_id, body=json.dumps(native_request))
        model_response = json.loads(response["body"].read())
        
        # Extract and decode the Base64 image data
        base64_image_data = model_response["images"][0]
        image_data = base64.b64decode(base64_image_data)
        
        # Upload the decoded image data to S3
        s3_client.put_object(Bucket=bucket_name, Key=s3_image_path, Body=image_data)
        
        gen_uri = s3_client.generate_presigned_url(
            "get_object",
            Params={"Bucket" : bucket_name, "Key" : s3_image_path})
        
        return {
            "statusCode" : 200,
            "body" : json.dumps({
                "image_URI" : gen_uri 
            }),
            "headers" : {
                "Content-Type": "application/json"
            }
        }
        
    except Exception as e:
        logger.error("error: %s", str(e))
        return {
            "statusCode" : 500,
            "body": json.dumps({"error": str(e)}),
            "headers" : {
                "Content-Type": "application/json"
            }
        }