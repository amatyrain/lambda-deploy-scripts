terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "aws_lambda_layer_version" "ai" {
  filename            = "${path.module}/layer.zip"
  layer_name         = "ai"
  compatible_runtimes = ["python3.9"]
  description        = chomp(file("${path.module}/.description"))
  source_code_hash   = filebase64sha256("${path.module}/layer.zip")
}
