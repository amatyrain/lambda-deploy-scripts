provider "aws" {
  region = "ap-northeast-1"
}

terraform {
  backend "s3" {
    bucket  = "consel-terraform"
    region  = "ap-northeast-1"
    key     = "github-actions-iam.tfstate"
    encrypt = true
  }
}

module "iam" {
  source = "../modules/iam"
  github_repository = "amatyrain/schedule-deliver"
}
