provider "aws" {
  region  = "ap-northeast-1"
}

terraform {
  backend "s3" {
    bucket  = "consel-terraform"
    region  = "ap-northeast-1"
    key     = "event-bridge-hourly.tfstate"
    encrypt = true
  }
}

# EventBridgeルールのimport
import {
  to = aws_cloudwatch_event_rule.rule
  id = "default/hourly"
}

# EventBridgeルールの作成
resource "aws_cloudwatch_event_rule" "rule" {
    name        = "hourly"
    schedule_expression = "cron(0 * * * ? *)"
}

output "rule_name" {
  value = aws_cloudwatch_event_rule.rule.name
}

output "rule_arn" {
  value = aws_cloudwatch_event_rule.rule.arn
}
