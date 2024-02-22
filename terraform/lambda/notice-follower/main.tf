provider "aws" {
  region  = "ap-northeast-1"
}

terraform {
  backend "s3" {
    bucket  = "consel-terraform"
    region  = "ap-northeast-1"
    key     = "lambda-notice-follower.tfstate"
    encrypt = true
  }
}

module "notice-follower" {
  source = "../../modules"

  scripts_path = "${path.module}/../../.."
  event_bridge_rule_name = "daily7"
  aws_lambda_function_name = "notice-follower"
  aws_lambda_layer_arn = "arn:aws:lambda:ap-northeast-1:408633466991:layer:amazonAffiliateLayer:16"
  aws_lambda_handler = "lambda_function.lambda_handler"
  aws_lambda_timeout = 600
  source_dir = "${path.module}/../../../../../src"
  output_zip_path = "${path.module}/../../../../../local/function.zip"
  runtime = "python3.11"
}
