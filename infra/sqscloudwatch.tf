resource "aws_cloudwatch_metric_alarm" "alarm" {
  alarm_name          = "${var.prefix}AproxAgeOfOldestMsg"
  alarm_description   = "Alarm that goes off when the messages take too long to send"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateAgeOfOldestMessage"
  statistic           = "Average"
  threshold           = var.threshold 
  evaluation_periods  = 10 # minimum 10            
  period              = 60 #in seconds minimum 60          
  treat_missing_data  = "notBreaching" 
  
  dimensions = {
    QueueName = "${var.prefix}_sqs_queue"
  }

  alarm_actions = [aws_sns_topic.topic.arn] 
}

resource "aws_sns_topic" "topic" {
  name = "${var.prefix}queue-alarm-topic"
}

resource "aws_sns_topic_subscription" "email-target" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = var.ALARM_MAIL 
}