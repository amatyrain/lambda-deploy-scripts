provider "aws" {
  region  = "ap-northeast-1"
}

terraform {
  backend "s3" {
    bucket  = "consel-terraform"
    region  = "ap-northeast-1"
    key     = "lambda-mini-scripts.tfstate"
    encrypt = true
  }
}

module "mini-scripts" {
  source = "../../modules/lambda"

  scripts_path = "scripts/deploy"  # scripts/deployディレクトリへの相対パス
  event_bridge_rule_name = "hourly"  # Run every hour
  destination_tfstate_name = "lambda-notice-lambda"
  aws_lambda_role_name = "lambda-role"
  aws_lambda_function_name = "mini-scripts"
  aws_lambda_layer_arn = "arn:aws:lambda:ap-northeast-1:408633466991:layer:amazonAffiliateLayer:16"
  aws_lambda_handler = "lambda_function.lambda_handler"
  aws_lambda_timeout = 600
  source_dir = "${path.module}/../../../../../src"
  output_zip_path = "${path.module}/../../../../../local/function.zip"
  runtime = "python3.11"
}

output "arn" {
  value = module.mini-scripts.arn
}
