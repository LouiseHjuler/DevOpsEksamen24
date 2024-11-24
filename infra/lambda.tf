variable "prefix" {
    type        = string
    description = "Prefix for all resource names"
}

resource "aws_s3_bucket" "targetBucket" {
    bucket  = "pgr301-couch-explorer-bucket"
    
    tags    = {
        Name        = "TargetBucket"
        Environment = "Production"
    }
}

#IAM role
resource "aws_iam_role" "lambda_tf_role"{
    assume_role_policy = jsonencode({
        "Version": "2012-10-17"
        "Statement": [
        {
            "Action":"sts:AssumeRole",
            "Effect": "Allow",
            "Principal":{
                "Service": "lambda.amazonaws.com"
            }
        }]
    })
    
    name = "${var.prefix}_lambda_tf_role"
}

#add same accesses as OG py-lambda role
resource "aws_iam_role_policy" "lambda_image_gen_policy" {
    name    = "${var.prefix}_LambdaImageGenPolicy"
    role    = aws_iam_role.lambda_tf_role.id
    
    policy  = jsonencode({
        "Version": "2012-10-17"
        "Statement": [
            {
            "Effect":"Allow",
            "Action":["s3:PutObject",
                     "s3:GetObject",
                     "s3:ListBucket",
                     "bedrock:InvokeModel",
                     "logs:CreateLogGroup",
                     "logs:CreateLogStream",
                     "logs:PutLogEvents",
                     "logs:DescribeLogStreams",
                     "iam:UpdateFunctionConfiguration",
                     "sqs:ReceiveMessage",
                     "sqs:DeleteMessage",
                     "sqs:GetQueueAttributes",
                     "sqs:SendMessage"]
            "Resource": ["arn:aws:s3:::pgr301-couch-explorers/*",
                        "arn:aws:bedrock:us-east-1::model/amazon.titan-image-generator-v1",
                        "*"]
                        #obvi the * is redundant here in the end but but. 
            }
        ]
    })
}

#lambda to be used 
resource "aws_lambda_function" "image_gen_lambda" {
    function_name   = "${var.prefix}_image_gen_lambda"
    runtime         = "python3.8"
    handler         = "lambda_sqs.lambda_handler"
    role            = aws_iam_role.lambda_tf_role.arn
    filename        = "lambda_function_payload.zip"
    timeout         = 30
    
    environment{
        variables = {
            LOG_LEVEL   = "DEBUG"
            #Destination bucket!
            BUCKET_NAME = aws_s3_bucket.targetBucket.bucket
        }
    }
}

#lambda fun url resource 
resource "aws_lambda_function_url" "image_gen_lambda_url"{
    function_name       = aws_lambda_function.image_gen_lambda.function_name
    authorization_type  = "NONE"
}

#invoke function ok
resource "aws_lambda_permission" "allow_lambda_url"{
    statement_id            = "AllowLambdaURLInvoke"
    action                  = "lambda:InvokeFunctionUrl"
    function_name           = aws_lambda_function.image_gen_lambda.arn
    principal               = "*"
    function_url_auth_type  = aws_lambda_function_url.image_gen_lambda_url.authorization_type
}

#create zip from code
data "archive_file" "lambda_zip"{
    type        = "zip"
    source_file = "${path.module}/lambda_sqs.py"
    output_path = "${path.module}/lambda_function_payload.zip"
}

#cloudwatch log group for lambda
resource "aws_cloudwatch_log_group" "image_gen_log_group"{
    name                = "/aws/lambda/${var.prefix}_image_gen_lambda"
    retention_in_days   = 7
}

output "lambda_url" {
    value = aws_lambda_function_url.image_gen_lambda_url.function_url
}