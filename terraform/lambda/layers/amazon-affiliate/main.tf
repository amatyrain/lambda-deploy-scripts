terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "aws_lambda_layer_version" "amazon_affiliate" {
  filename            = "${path.module}/layer.zip"
  layer_name         = "amazon-affiliate"
  compatible_runtimes = ["python3.9"]
  description        = "Layer containing Amazon affiliate related libraries"
  source_code_hash   = filebase64sha256("${path.module}/layer.zip")
}
