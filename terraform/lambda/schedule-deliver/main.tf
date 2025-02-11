provider "aws" {
  region  = "ap-northeast-1"
}

terraform {
  backend "s3" {
    bucket  = "consel-terraform"
    region  = "ap-northeast-1"
    key     = "lambda-schedule-deliver.tfstate"
    encrypt = true
  }
}

module "schedule-deliver" {
  source = "../../modules/lambda"

  scripts_path = "${path.module}/../../.."
  event_bridge_rule_name = "hourly"
  destination_tfstate_name = "lambda-notice-lambda"
  aws_lambda_role_name = "lambda-role"
  aws_lambda_function_name = "schedule-deliver"
  aws_lambda_handler = "index.handler"
  aws_lambda_timeout = 900
  source_dir = "${path.module}/../../../../../dist"
  output_zip_path = "${path.module}/../../../lambda/function.zip"
  runtime = "nodejs18.x"
}

output "arn" {
  value = module.schedule-deliver.arn
}
