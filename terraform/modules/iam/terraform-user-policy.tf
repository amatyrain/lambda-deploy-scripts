resource "aws_iam_user_policy" "terraform_lambda_policy" {
  name = "terraform-lambda-policy"
  user = "terraform"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:*",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy" "terraform_iam_base_policy" {
  name = "terraform-iam-base-policy"
  user = "terraform"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:PassRole",
          "iam:GetUserPolicy",
          "iam:PutUserPolicy",
          "iam:DeleteUserPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy" "terraform_iam_policy_management" {
  name = "terraform-iam-policy-management"
  user = "terraform"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:ListRolePolicies"
        ]
        Resource = "*"
      }
    ]
  })
}
