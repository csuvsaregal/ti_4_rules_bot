resource "aws_lambda_function" "ti_lambda" {
  filename         = "${path.module}/../lambdas/${var.lambda_config.zip_name}"
  function_name    = var.lambda_config.function_name
  role             = aws_iam_role.lambda_exec.arn
  handler          = var.lambda_config.handler
  runtime          = var.lambda_config.runtime
  source_code_hash = filebase64sha256("${path.module}/../lambdas/${var.lambda_config.zip_name}")
  layers           = ["arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python313:1"]
    
    lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_execution_role_ti"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name                = "four-hour-lambda-trigger"
  description         = "Trigger Lambda every 4 hours"
  schedule_expression = "rate(4 hours)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_schedule.name
  target_id = "trigger-lambda"
  arn       = aws_lambda_function.ti_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ti_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule.arn
}

resource "aws_iam_role_policy" "lambda_logs" {
  name = "lambda_logging_policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}
