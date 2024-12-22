provider "aws" {
  region  = "ap-northeast-1"
}

terraform {
  backend "s3" {
    bucket  = "consel-terraform"
    region  = "ap-northeast-1"
    key     = "lambda-rss-feed-reader.tfstate"
    encrypt = true
  }
}

module "rss-feed-reader" {
  source = "../../modules/lambda"

  scripts_path = "${path.module}/../../.."
  event_bridge_rule_name = "hourly"
  destination_tfstate_name = "lambda-notice-lambda"
  aws_lambda_role_name = "lambda-role"
  aws_lambda_function_name = "rss-feed-reader"
  aws_lambda_layer_arn = "arn:aws:lambda:ap-northeast-1:408633466991:layer:rss-feed-reader:5"
  aws_lambda_handler = "app.lambda_handler"
  aws_lambda_timeout = 900
  source_dir = "${path.module}/../../../../../src"
  output_zip_path = "${path.module}/../../../../../local/function.zip"
  runtime = "python3.11"
}
