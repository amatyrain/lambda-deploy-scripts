provider "aws" {
  region  = "ap-northeast-1"
}

terraform {
  backend "s3" {
    bucket  = "consel-terraform"
    region  = "ap-northeast-1"
    key     = "lambda-affiliate-bot.tfstate"
    encrypt = true
  }
}

module "affiliate-bot" {
  source = "../../modules/lambda"

  scripts_path = "${path.module}/../../.."
  event_bridge_rule_name = "hourly"
  destination_tfstate_name = "lambda-notice-lambda"
  aws_lambda_role_name = "lambda-role"
  aws_lambda_function_name = "affiliate-bot"
  aws_lambda_layer_arn = "arn:aws:lambda:ap-northeast-1:408633466991:layer:amazonAffiliateLayer:17"
  aws_lambda_handler = "app.lambda_handler"
  aws_lambda_timeout = 600
  source_dir = "${path.module}/../../../../../src"
  output_zip_path = "${path.module}/../../../../../local/function.zip"
  runtime = "python3.10"
}
