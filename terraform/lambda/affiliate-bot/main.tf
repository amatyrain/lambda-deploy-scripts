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
  source = "../../modules"

  scripts_path = "${path.module}/../../.."
  existing_event_rule_arn = "arn:aws:events:ap-northeast-1:408633466991:rule/hourly"
  aws_lambda_function_name = "affiliate-bot"
  aws_lambda_layer_arn = "arn:aws:lambda:ap-northeast-1:408633466991:layer:amazonAffiliateLayer:16"
  aws_lambda_handler = "app.lambda_handler"
  aws_lambda_timeout = 600
  source_dir = "${path.module}/../../../../../src"
  output_zip_path = "${path.module}/../../../../../local/function.zip"
  runtime = "python3.10"
}