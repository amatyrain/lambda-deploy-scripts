provider "aws" {
  region  = "ap-northeast-1"
}

terraform {
  backend "s3" {
    bucket  = "consel-terraform"
    region  = "ap-northeast-1"
    key     = "lambda-notice-lambda.tfstate"
    encrypt = true
  }
}

module "notice-lambda" {
  source = "../../modules"

  scripts_path = "${path.module}/../../.."
  event_bridge_rule_name = ""
  aws_lambda_function_name = "notice-lambda"
  aws_lambda_layer_arn = ""
  aws_lambda_handler = "lambda_function.lambda_handler"
  aws_lambda_timeout = 600
  source_dir = "${path.module}/../../../../../src"
  output_zip_path = "${path.module}/../../../../../local/function.zip"
  runtime = "python3.11"
}