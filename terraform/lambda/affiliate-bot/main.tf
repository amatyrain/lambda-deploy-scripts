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

data "terraform_remote_state" "amazon_affiliate_layer" {
  backend = "s3"
  config = {
    bucket = "consel-terraform"
    key    = "lambda-layer-amazon-affiliate.tfstate"
    region = "ap-northeast-1"
  }
}

module "affiliate-bot" {
  source = "../../modules/lambda"

  scripts_path = "${path.module}/../../.."
  event_bridge_rule_name = "hourly"
  destination_tfstate_name = "lambda-notice-lambda"
  aws_lambda_role_name = "lambda-role"
  aws_lambda_function_name = "affiliate-bot"
  aws_lambda_layer_arn = data.terraform_remote_state.amazon_affiliate_layer.outputs.layer_arn
  aws_lambda_handler = "app.lambda_handler"
  aws_lambda_timeout = 900
  source_dir = "${path.module}/../../../../../src"
  output_zip_path = "${path.module}/../../../../../local/function.zip"
  runtime = "python3.10"
}
