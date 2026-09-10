provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_user" "Dev1-user" {
  name = "devops-user"

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_group" "Dev1-Group" {
  name = "Dev1-Group"
}

resource "aws_iam_policy" "s3-access" {
  name        = "s3-access-policy"
  description = "Allow access to application S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]

        Resource = [
          "arn:aws:s3:::my-application-bucket",
          "arn:aws:s3:::my-application-bucket/*"
        ]
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "s3_access" {
  group      = aws_iam_group.dev1_group.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role" "dev1_role" {
  name = "Dev1-Admin-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          AWS = aws_iam_user.dev1_user.arn
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "dev1_admin_access" {
  role       = aws_iam_role.dev1_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "iam_user_name" {
  value = aws_iam_user.dev1_user.name
}

output "iam_user_arn" {
  value = aws_iam_user.dev1_user.arn
}

output "iam_group_name" {
  value = aws_iam_group.dev1_group.name
}

output "iam_role_name" {
  value = aws_iam_role.dev1_role.name
}

output "iam_role_arn" {
  value = aws_iam_role.dev1_role.arn
}

