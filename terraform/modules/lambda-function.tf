variable "event_bridge_rule_name" {
  description = "The name of the EventBridge rule"
  type        = string
}

variable "aws_lambda_function_name" {
  description = "The name of the Lambda function"
  type        = string
}

variable "aws_lambda_handler" {
  description = "The name of the Lambda function handler"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "aws_lambda_layer_arn" {
  description = "The ARN of the Lambda layer"
  type        = string
}

variable "aws_lambda_timeout" {
  description = "The timeout for the Lambda function"
  type        = number
}

variable "source_dir" {
  description = "The directory containing the Lambda function source code"
  type        = string
}

variable "output_zip_path" {
  description = "The path to the output ZIP file"
  type        = string
}

variable "runtime" {
  description = "The runtime for the Lambda function"
  type        = string
  default     = "python3.10"

}

variable "scripts_path" {
  description = "The path to the scripts directory"
  type        = string

}

data "terraform_remote_state" "event_bridge" {
  backend = "s3"

  config = {
    bucket  = "consel-terraform"
    key    = "event-bridge-${var.event_bridge_rule_name}.tfstate"
    region = "ap-northeast-1"
  }
}

data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = var.output_zip_path
}

data "external" "env_vars" {
  program = ["/bin/sh", "${var.scripts_path}/env_to_json.sh"]
}

resource "aws_lambda_function" "aws_lambda_function" {
  function_name    = var.aws_lambda_function_name
  handler          = var.aws_lambda_handler
  runtime          = var.runtime
  filename         = data.archive_file.function_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.function_zip.output_path)
  role             = data.aws_iam_role.existing_role.arn
  layers = [var.aws_lambda_layer_arn]
  timeout = var.aws_lambda_timeout
  reserved_concurrent_executions = 1

  environment {
    variables = data.external.env_vars.result
  }
}

# Lambda関数への権限付与のimport
# import {
#   to = aws_lambda_permission.allow_cloudwatch
#   id = var.aws_lambda_function_name + "/AllowExecutionFromCloudWatch"
# }

# Lambda関数への権限付与
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.aws_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = data.terraform_remote_state.event_bridge.outputs.rule_arn
}


# EventBridgeルールとLambda関数の紐づけ
resource "aws_cloudwatch_event_target" "example_target" {
  rule      = data.terraform_remote_state.event_bridge.outputs.rule_name
  arn       = aws_lambda_function.aws_lambda_function.arn
}

data "aws_iam_role" "existing_role" {
  name = "read-only"
}

# resource "aws_iam_role" "lambda_role" {
#   name = "read-only"

#   assume_role_policy = <<EOF
# {yes
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Principal": {
#                 "Service": "lambda.amazonaws.com"
#             },
#             "Action": "sts:AssumeRole"
#         }
#     ]
# }
# EOF
# }

# 既存のポリシー1を参照
data "aws_iam_policy" "existing_policy_1" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 既存のポリシー2を参照
data "aws_iam_policy" "existing_policy_2" {
  arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ポリシー1をロールにアタッチ
resource "aws_iam_role_policy_attachment" "attach_policy_1" {
  role       = data.aws_iam_role.existing_role.name
  policy_arn = data.aws_iam_policy.existing_policy_1.arn
}

# ポリシー2をロールにアタッチ
resource "aws_iam_role_policy_attachment" "attach_policy_2" {
  role       = data.aws_iam_role.existing_role.name
  policy_arn = data.aws_iam_policy.existing_policy_2.arn
}

# resource "aws_iam_policy" "lambda_policy" {
#   name        = "example-lambda-policy"
#   description = "IAM policy for the example Lambda function"

#   policy = jsonencode({
#     Version   = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ]
#         Resource = [
#           aws_cloudwatch_log_group.example_log_group.arn,
#           "${aws_cloudwatch_log_group.example_log_group.arn}:*"
#         ]
#       }
#     ]
#   })
# }

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment_1" {
  role       = data.aws_iam_role.existing_role.name
  policy_arn = data.aws_iam_policy.existing_policy_1.arn
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment_2" {
  role       = data.aws_iam_role.existing_role.name
  policy_arn = data.aws_iam_policy.existing_policy_2.arn
}

resource "aws_cloudwatch_log_group" "example_log_group" {
  name = "/aws/lambda/${aws_lambda_function.aws_lambda_function.function_name}"
  retention_in_days = 30
}
