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