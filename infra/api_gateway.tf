# API Gateway REST API
resource "aws_api_gateway_rest_api" "image_gen_api" {
    name        = "${var.prefix}_image_gen_api"
    description = "API Gateway for Lambda function"
}

# Create the '/imageGen' resource
resource "aws_api_gateway_resource" "image_gen_resource" {
    rest_api_id = aws_api_gateway_rest_api.image_gen_api.id
    parent_id   = aws_api_gateway_rest_api.image_gen_api.root_resource_id
    path_part   = "imageGen"
}

# Create GET method for the resource
resource "aws_api_gateway_method" "get_image_gen" {
    rest_api_id   = aws_api_gateway_rest_api.image_gen_api.id
    resource_id   = aws_api_gateway_resource.image_gen_resource.id
    http_method   = "GET"
    authorization = "NONE"
}

# Create POST method for the resource
resource "aws_api_gateway_method" "post_image_gen" {
    rest_api_id   = aws_api_gateway_rest_api.image_gen_api.id
    resource_id   = aws_api_gateway_resource.image_gen_resource.id
    http_method   = "POST"
    authorization = "NONE"
}

# Integrate GET method with Lambda
resource "aws_api_gateway_integration" "get_image_gen_integration" {
    rest_api_id = aws_api_gateway_rest_api.image_gen_api.id
    resource_id = aws_api_gateway_resource.image_gen_resource.id
    http_method = aws_api_gateway_method.get_image_gen.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.image_gen_lambda.arn}/invocations"
}

# Integrate POST method with Lambda
resource "aws_api_gateway_integration" "post_image_gen_integration" {
    rest_api_id = aws_api_gateway_rest_api.image_gen_api.id
    resource_id = aws_api_gateway_resource.image_gen_resource.id
    http_method = aws_api_gateway_method.post_image_gen.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.image_gen_lambda.arn}/invocations"
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "image_gen_api_deployment" {
    rest_api_id = aws_api_gateway_rest_api.image_gen_api.id
    stage_name  = "prod"
}

# Allow API Gateway to invoke Lambda
resource "aws_lambda_permission" "allow_api_gateway" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    principal     = "apigateway.amazonaws.com"
    function_name = aws_lambda_function.image_gen_lambda.function_name
}