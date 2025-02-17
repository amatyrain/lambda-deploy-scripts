data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_actions" {
  name = "github-actions-role"
  force_detach_policies = true
  path = "/"  # 既存のロールのパスと一致させる

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub": ["repo:amatyrain/*"]
            "token.actions.githubusercontent.com:aud": ["sts.amazonaws.com"]
          }
        }
      }
    ]
  })

  # 既存のロールを維持するための設定
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name = "github-actions-deploy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "events:*",
          "logs:*",
          "lambda:*",
          "s3:*",
          "iam:*",
          "ssm:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda基本実行ロールの追加
resource "aws_iam_role_policy_attachment" "github_actions_lambda_execution" {
  role       = aws_iam_role.github_actions.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
