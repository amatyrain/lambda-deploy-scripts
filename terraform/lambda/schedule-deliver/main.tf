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

# SSMパラメータへのアクセス権限を付与
resource "aws_iam_policy" "ssm_policy" {
  name = "ssm-parameter-access-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:ap-northeast-1:408633466991:parameter/NOTION_SECRETS",
          "arn:aws:ssm:ap-northeast-1:408633466991:parameter/TWITTER_SECRET_AMATYRAIN"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ssm" {
  role       = "lambda-role"
  policy_arn = aws_iam_policy.ssm_policy.arn
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
  output_zip_path = "${path.module}/../../../../../local/function.zip"
  runtime = "nodejs18.x"
}
