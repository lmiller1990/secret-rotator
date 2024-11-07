provider "aws" {
  region = "ap-southeast-2"  # Adjust as needed
}

variable "environment" {
  description = "The environment (uat, staging, prod, demo)"
  type        = string
}

# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "lambda_secret_rotator_role_${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

# Attach policies to the IAM role
resource "aws_iam_policy_attachment" "lambda_ssm_policy" {
  name       = "lambda_ssm_policy_attachment_${var.environment}"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = aws_iam_policy.lambda_ssm_policy.arn 
}

resource "aws_iam_policy" "lambda_ssm_policy" {
  name        = "lambda_ssm_policy"
  description = "Policy for Lambda to access SSM Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter",
          "ssm:DeleteParameter",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

# Create SSM Parameter Store parameter
resource "aws_ssm_parameter" "secret_parameter" {
  name        = "gitlab_bot_password-${var.environment}"
  type        = "SecureString"
  value       = "topsecret"
  tier        = "Standard"
}

# Create the Lambda function
resource "aws_lambda_function" "secret_rotator" {
  function_name = "SecretRotator_${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "rotate.lambda.handler"
  runtime       = "python3.12"

  # Your Lambda deployment package
  filename      = "lambda.zip"

  source_code_hash = filebase64sha256("lambda.zip")

  environment {
    variables = {
      SSM_PARAMETER_NAME = aws_ssm_parameter.secret_parameter.name
      AUTH_API_URL = "${var.auth_api_url}"
      AUTH_API_USERNAME =  "${var.auth_api_username}"
    }
  }
}

# Create EventBridge rule to trigger Lambda every 24 hours
resource "aws_cloudwatch_event_rule" "schedule" {
  name        = "SecretRotationSchedule"
  description = "Trigger Lambda every 1 min"
  schedule_expression = "rate(24 hours)"
}

# Create EventBridge target to invoke the Lambda function
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  arn       = aws_lambda_function.secret_rotator.arn
}

# Grant permission for EventBridge to invoke the Lambda function
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.secret_rotator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}