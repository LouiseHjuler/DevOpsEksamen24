# API Gateway related resources

resource "aws_api_gateway_rest_api" "image_gen_api" {
  name        = "${var.prefix}_image_gen_api"
  description = "API Gateway for Image Generation Lambda"
  
  #added due to error regarding 120 API limit exceeded
  endpoint_configuration {
      types = ["REGIONAL"] 
  }
}

resource "aws_api_gateway_resource" "image_gen_resource" {
  rest_api_id = aws_api_gateway_rest_api.image_gen_api.id
  parent_id   = aws_api_gateway_rest_api.image_gen_api.root_resource_id
  path_part   = "imageGen"
}

#API methods POST / GET
resource "aws_api_gateway_method" "image_gen_get" {
  rest_api_id   = aws_api_gateway_rest_api.image_gen_api.id
  resource_id   = aws_api_gateway_resource.image_gen_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "image_gen_post" {
  rest_api_id   = aws_api_gateway_rest_api.image_gen_api.id
  resource_id   = aws_api_gateway_resource.image_gen_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "image_gen_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.image_gen_api.id
  resource_id = aws_api_gateway_resource.image_gen_resource.id
  http_method = aws_api_gateway_method.image_gen_get.http_method
  integration_http_method = "GET"
  type = "AWS_PROXY"
  uri  = aws_lambda_function.image_gen_lambda.invoke_arn
}

resource "aws_api_gateway_integration" "image_gen_post_integration" {
  rest_api_id = aws_api_gateway_rest_api.image_gen_api.id
  resource_id = aws_api_gateway_resource.image_gen_resource.id
  http_method = aws_api_gateway_method.image_gen_post.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri  = aws_lambda_function.image_gen_lambda.invoke_arn
}

# Lambda permissions for API Gateway to invoke Lambda
resource "aws_lambda_permission" "allow_api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_gen_lambda.arn
  principal     = "apigateway.amazonaws.com"
}

#Deployment of gateway
resource "aws_api_gateway_deployment" "image_gen_deployment" {
  depends_on = [
    aws_api_gateway_integration.image_gen_get_integration,
    aws_api_gateway_integration.image_gen_post_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.image_gen_api.id
  stage_name  = "prod"
}

output "api_gateway_url" {
  value = "${aws_api_gateway_deployment.image_gen_deployment.invoke_url}/imageGen"
}