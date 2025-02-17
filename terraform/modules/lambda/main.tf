variable "event_bridge_rule_name" {
  description = "The name of the EventBridge rule"
  type        = string
  default     = ""
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
  default = ""
}

# roleの名前
variable "aws_lambda_role_name" {
  description = "The name of the IAM role for the Lambda function"
  type        = string
}

# 送信先のlambda関数名
variable "destination_tfstate_name" {
  description = "The name of the destination tfstate"
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


data "terraform_remote_state" "event_bridge" {
  count = var.event_bridge_rule_name != "" ? 1 : 0

  backend = "s3"
  config = {
    bucket  = "consel-terraform"
    key    = "event-bridge-${var.event_bridge_rule_name}.tfstate"
    region = "ap-northeast-1"
  }
}

data "terraform_remote_state" "destination" {
  count = var.destination_tfstate_name != "" ? 1 : 0

  backend = "s3"
  config = {
    bucket  = "consel-terraform"
    key    = "${var.destination_tfstate_name}.tfstate"
    region = "ap-northeast-1"
  }
}

data "terraform_remote_state" "lambda_role" {
  backend = "s3"
  config = {
    bucket  = "consel-terraform"
    key    = "iam-role-${var.aws_lambda_role_name}.tfstate"
    region = "ap-northeast-1"
  }
}

data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = var.output_zip_path
}
variable "scripts_path" {
  description = "The path to the scripts directory"
  type        = string
  default = "scripts/deploy"

}

data "external" "env_vars" {
  program = ["/bin/bash", "${path.module}/../../../../../${var.scripts_path}/env_to_json.sh"]
}

resource "aws_lambda_function" "aws_lambda_function" {
  function_name    = var.aws_lambda_function_name
  handler          = var.aws_lambda_handler
  runtime          = var.runtime
  filename         = data.archive_file.function_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.function_zip.output_path)
  role             = data.terraform_remote_state.lambda_role.outputs.arn
  layers = var.aws_lambda_layer_arn != "" ? [var.aws_lambda_layer_arn] : []
  timeout = var.aws_lambda_timeout
  reserved_concurrent_executions = 1

  environment {
    variables = data.external.env_vars.result
  }
}

resource "aws_lambda_function_event_invoke_config" "destination_config" {
  count = var.destination_tfstate_name != "" ? 1 : 0
  function_name = aws_lambda_function.aws_lambda_function.function_name

  destination_config {
    on_failure {
      destination = data.terraform_remote_state.destination[count.index].outputs.arn
    }
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
  count         = var.event_bridge_rule_name != "" ? 1 : 0
  source_arn    = data.terraform_remote_state.event_bridge[count.index].outputs.rule_arn
}

# EventBridgeルールとLambda関数の紐づけ
resource "aws_cloudwatch_event_target" "example_target" {
  count     = var.event_bridge_rule_name != "" ? 1 : 0
  rule      = data.terraform_remote_state.event_bridge[count.index].outputs.rule_name
  arn       = aws_lambda_function.aws_lambda_function.arn
}

resource "aws_cloudwatch_log_group" "example_log_group" {
  name = "/aws/lambda/${aws_lambda_function.aws_lambda_function.function_name}"
  retention_in_days = 30
}

output "arn" {
  value = aws_lambda_function.aws_lambda_function.arn
}
