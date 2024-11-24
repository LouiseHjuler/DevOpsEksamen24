resource "aws_sqs_queue" "queue"{
    name                        = "kandidat24_sqs_queue"
    delay_seconds               = 10
    visibility_timeout_seconds  = 30
    max_message_size            = 2048
    message_retention_seconds   = 86400
    receive_wait_time_seconds   = 2
    sqs_managed_sse_enabled     = true
}

data "aws_iam_policy_document" "policy" {
    statement {
        sid     = "sqsStatement"
        effect  = "Allow"
        
        principals {
            type        = "AWS"
            identifiers = ["*"]
        }
        
        actions = [
            "sqs:SendMessage",
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes"
        ]
        
        resources = [
            aws_sqs_queue.queue.arn
        ]
    }
}

resource "aws_sqs_queue_policy" "policy" {
    queue_url   = aws_sqs_queue.queue.url
    policy      = data.aws_iam_policy_document.policy.json
}

#sqs resource
resource "aws_lambda_event_source_mapping" "even_source_mapping" {
    event_source_arn    = aws_sqs_queue.queue.arn
    enabled             = true
    function_name       = aws_lambda_function.image_gen_lambda.arn
    batch_size          = 1
}