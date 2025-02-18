provider "aws" {
  region  = "ap-northeast-1"
}

terraform {
  backend "s3" {
    bucket  = "consel-terraform"
    region  = "ap-northeast-1"
    key     = "lambda-layer-amazon-affiliate.tfstate"
    encrypt = true
  }
}

resource "null_resource" "install_dependencies" {
  triggers = {
    requirements = filemd5("${path.module}/requirements/prod.txt")
    install_script = filemd5("${path.module}/install_dependencies.sh")
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/install_dependencies.sh"
  }
}

data "archive_file" "lambda_layer" {
  depends_on = [null_resource.install_dependencies]
  type        = "zip"
  source_dir  = "${path.module}/package"
  output_path = "${path.module}/layer.zip"
}

resource "aws_lambda_layer_version" "amazon_affiliate" {
  filename            = data.archive_file.lambda_layer.output_path
  layer_name         = "amazonAffiliateLayer"
  compatible_runtimes = ["python3.10"]
  description        = "Layer containing Amazon Affiliate related dependencies"
}

output "layer_arn" {
  value = aws_lambda_layer_version.amazon_affiliate.arn
  description = "ARN of the Amazon Affiliate Lambda layer"
}
