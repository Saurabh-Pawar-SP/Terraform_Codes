```hcl
# ============================================================
# AWS PROVIDER
# ============================================================

provider "aws" {
  region = "us-east-1"
}


# ============================================================
# DATA SOURCES
# ============================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


# ============================================================
# 1. BASIC S3 BUCKET CONFIGURATION
# ============================================================

resource "aws_s3_bucket" "S3" {

  # Globally unique bucket name.
  #
  # IMPORTANT:
  # S3 bucket names are globally unique across AWS.
  #
  bucket = "mycompany-prod-application-data-001"

  # If true, Terraform can delete the bucket even when
  # objects exist inside it.
  #
  # PRODUCTION:
  # Usually keep this false.
  #
  force_destroy = false

  # ----------------------------------------------------------
  # OBJECT LOCK
  # ----------------------------------------------------------
  #
  # Object Lock provides WORM-style protection.
  #
  # Useful for:
  # - Compliance
  # - Audit records
  # - Financial records
  # - Immutable backups
  # - Ransomware protection
  #
  # IMPORTANT:
  # Object Lock is a bucket creation-time design decision.
  #
  object_lock_enabled = false

  # ----------------------------------------------------------
  # TAGS
  # ----------------------------------------------------------

  tags = {
    Name        = "mycompany-prod-application-data"
    Environment = "prod"
    Owner       = "Saurabh"
    Project     = "Terraform"
    Department  = "IT"
    Application = "MyApplication"
    CostCenter  = "CC-1001"
    ManagedBy   = "Terraform"
    Backup      = "Required"
    DataClass   = "Internal"
  }
}


# ============================================================
# 2. OBJECT OWNERSHIP / ACL CONFIGURATION
# ============================================================
#
# Recommended modern configuration:
#
# BucketOwnerEnforced
#
# This disables ACL-based ownership/access control.
#
# This is generally preferable for new applications.
#
# ============================================================

resource "aws_s3_bucket_ownership_controls" "S3" {

  bucket = aws_s3_bucket.S3.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}


# ============================================================
# 3. PUBLIC ACCESS BLOCK
# ============================================================
#
# Production S3 buckets should normally have all four
# Public Access Block settings enabled.
#
# This protects against accidental public exposure.
#
# ============================================================

resource "aws_s3_bucket_public_access_block" "S3" {

  bucket = aws_s3_bucket.S3.id

  # Block public ACLs
  block_public_acls = true

  # Block public bucket policies
  block_public_policy = true

  # Ignore public ACLs
  ignore_public_acls = true

  # Restrict public bucket access
  restrict_public_buckets = true
}


# ============================================================
# 4. VERSIONING
# ============================================================
#
# Versioning protects against:
#
# - Accidental deletion
# - Accidental overwrite
# - Application bugs
# - Data recovery
# - Ransomware scenarios
#
# ============================================================

resource "aws_s3_bucket_versioning" "S3" {

  bucket = aws_s3_bucket.S3.id

  versioning_configuration {
    status = "Enabled"
  }
}


# ============================================================
# 5. DEFAULT SERVER-SIDE ENCRYPTION
# ============================================================
#
# Option 1:
#   AES256 / SSE-S3
#
# Option 2:
#   aws:kms / SSE-KMS
#
# Production sensitive data:
# Usually SSE-KMS.
#
# ============================================================

resource "aws_s3_bucket_server_side_encryption_configuration" "S3" {

  bucket = aws_s3_bucket.S3.id

  rule {

    apply_server_side_encryption_by_default {

      # ------------------------------------------------------
      # KMS encryption
      # ------------------------------------------------------

      sse_algorithm = "aws:kms"

      # Replace this with your real KMS key ARN.
      #
      # Example:
      #
      # kms_master_key_id =
      # "arn:aws:kms:us-east-1:123456789012:key/xxxxxxxx"
      #
      kms_master_key_id = aws_kms_key.S3.arn
    }

    # S3 Bucket Key reduces KMS request costs.
    bucket_key_enabled = true
  }
}


# ============================================================
# 6. KMS KEY
# ============================================================
#
# Customer-managed KMS key for S3 encryption.
#
# ============================================================

resource "aws_kms_key" "S3" {

  description = "KMS key for S3 bucket encryption"

  # Number of days AWS waits before deleting the key.
  #
  # Valid range:
  # 7 - 30
  #
  deletion_window_in_days = 30

  # Enable automatic annual key rotation.
  enable_key_rotation = true

  tags = {
    Name        = "mycompany-prod-s3-kms"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}


# ============================================================
# 7. KMS ALIAS
# ============================================================

resource "aws_kms_alias" "S3" {

  name = "alias/mycompany-prod-s3"

  target_key_id = aws_kms_key.S3.key_id
}


# ============================================================
# 8. LIFECYCLE MANAGEMENT
# ============================================================
#
# Example lifecycle:
#
# Day 0
#     STANDARD
#
# Day 30
#     STANDARD_IA
#
# Day 90
#     GLACIER
#
# Old versions:
#     STANDARD_IA
#     GLACIER
#     Eventually deleted
#
# Multipart uploads:
#     Aborted after 7 days
#
# ============================================================

resource "aws_s3_bucket_lifecycle_configuration" "S3" {

  bucket = aws_s3_bucket.S3.id

  rule {

    id = "production-data-lifecycle"

    status = "Enabled"

    # Empty filter means:
    # Apply this rule to all objects.
    filter {}

    # --------------------------------------------------------
    # CURRENT OBJECT TRANSITION
    # --------------------------------------------------------

    transition {

      days = 30

      storage_class = "STANDARD_IA"
    }

    transition {

      days = 90

      storage_class = "GLACIER"
    }

    # --------------------------------------------------------
    # NON-CURRENT VERSION TRANSITION
    # --------------------------------------------------------

    noncurrent_version_transition {

      noncurrent_days = 30

      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {

      noncurrent_days = 90

      storage_class = "GLACIER"
    }

    # --------------------------------------------------------
    # DELETE OLD VERSIONS
    # --------------------------------------------------------
    #
    # Example:
    # Delete non-current versions after 365 days.
    #
    # --------------------------------------------------------

    noncurrent_version_expiration {

      noncurrent_days = 365
    }

    # --------------------------------------------------------
    # ABORT INCOMPLETE MULTIPART UPLOADS
    # --------------------------------------------------------
    #
    # Prevents incomplete uploads from accumulating.
    #
    # --------------------------------------------------------

    abort_incomplete_multipart_upload {

      days_after_initiation = 7
    }
  }
}


# ============================================================
# 9. INTELLIGENT-TIERING
# ============================================================
#
# Useful when object access patterns are unpredictable.
#
# NOTE:
# Do not blindly combine Intelligent-Tiering and lifecycle
# transitions for the same objects without understanding
# the cost/storage behavior.
#
# ============================================================

resource "aws_s3_bucket_intelligent_tiering_configuration" "S3" {

  bucket = aws_s3_bucket.S3.id

  name = "EntireBucket"

  status = "Enabled"

  filter {
    prefix = ""
  }

  tiering {

    access_tier = "ARCHIVE_ACCESS"

    days = 90
  }

  tiering {

    access_tier = "DEEP_ARCHIVE_ACCESS"

    days = 180
  }
}


# ============================================================
# 10. CORS
# ============================================================
#
# Useful when browser applications directly access S3.
#
# Example:
#
# React / Angular / Vue
#        |
#        |
#        +------> S3
#
# ============================================================

resource "aws_s3_bucket_cors_configuration" "S3" {

  bucket = aws_s3_bucket.S3.id

  cors_rule {

    allowed_methods = [
      "GET",
      "PUT",
      "POST",
      "HEAD"
    ]

    allowed_origins = [
      "https://app.example.com",
      "https://admin.example.com"
    ]

    allowed_headers = [
      "*"
    ]

    expose_headers = [
      "ETag",
      "x-amz-version-id"
    ]

    max_age_seconds = 3600
  }
}


# ============================================================
# 11. S3 ACCESS LOGGING
# ============================================================
#
# IMPORTANT:
# The target bucket should normally be a separate bucket.
#
# Example:
#
# Application bucket
#       |
#       +----> S3 Access Logs Bucket
#
# ============================================================

resource "aws_s3_bucket_logging" "S3" {

  bucket = aws_s3_bucket.S3.id

  target_bucket = "mycompany-prod-s3-access-logs-001"

  target_prefix = "application-data/"
}


# ============================================================
# 12. OBJECT LOCK CONFIGURATION
# ============================================================
#
# Only use this if object_lock_enabled = true above.
#
# GOVERNANCE:
# Authorized users may be able to bypass retention.
#
# COMPLIANCE:
# Much stronger immutability.
#
# ============================================================

resource "aws_s3_bucket_object_lock_configuration" "S3" {

  bucket = aws_s3_bucket.S3.id

  rule {

    default_retention {

      mode = "GOVERNANCE"

      days = 30
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.S3
  ]
}


# ============================================================
# 13. S3 WEBSITE CONFIGURATION
# ============================================================
#
# Use this only when S3 is intended to serve a static website.
#
# For modern production architecture, prefer:
#
# User
#   |
#   v
# CloudFront
#   |
#   v
# Private S3
#
# using CloudFront Origin Access Control.
#
# ============================================================

resource "aws_s3_bucket_website_configuration" "S3" {

  bucket = aws_s3_bucket.S3.id

  index_document {

    suffix = "index.html"
  }

  error_document {

    key = "error.html"
  }
}


# ============================================================
# 14. S3 BUCKET POLICY
# ============================================================
#
# Security requirements:
#
# 1. HTTPS only
# 2. TLS 1.2+
# 3. Require KMS encryption
# 4. Require our specific KMS key
#
# ============================================================

data "aws_iam_policy_document" "S3" {

  # ----------------------------------------------------------
  # DENY HTTP
  # ----------------------------------------------------------

  statement {

    sid = "DenyInsecureTransport"

    effect = "Deny"

    principals {

      type = "*"

      identifiers = [
        "*"
      ]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.S3.arn,
      "${aws_s3_bucket.S3.arn}/*"
    ]

    condition {

      test = "Bool"

      variable = "aws:SecureTransport"

      values = [
        "false"
      ]
    }
  }


  # ----------------------------------------------------------
  # DENY OLD TLS
  # ----------------------------------------------------------

  statement {

    sid = "DenyOldTLS"

    effect = "Deny"

    principals {

      type = "*"

      identifiers = [
        "*"
      ]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.S3.arn,
      "${aws_s3_bucket.S3.arn}/*"
    ]

    condition {

      test = "NumericLessThan"

      variable = "s3:TlsVersion"

      values = [
        "1.2"
      ]
    }
  }


  # ----------------------------------------------------------
  # REQUIRE SSE-KMS
  # ----------------------------------------------------------

  statement {

    sid = "DenyUnencryptedObjectUploads"

    effect = "Deny"

    principals {

      type = "*"

      identifiers = [
        "*"
      ]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.S3.arn}/*"
    ]

    condition {

      test = "StringNotEquals"

      variable = "s3:x-amz-server-side-encryption"

      values = [
        "aws:kms"
      ]
    }
  }


  # ----------------------------------------------------------
  # REQUIRE SPECIFIC KMS KEY
  # ----------------------------------------------------------

  statement {

    sid = "DenyWrongKMSKey"

    effect = "Deny"

    principals {

      type = "*"

      identifiers = [
        "*"
      ]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.S3.arn}/*"
    ]

    condition {

      test = "StringNotEquals"

      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"

      values = [
        aws_kms_key.S3.arn
      ]
    }
  }
}


resource "aws_s3_bucket_policy" "S3" {

  bucket = aws_s3_bucket.S3.id

  policy = data.aws_iam_policy_document.S3.json

  depends_on = [
    aws_s3_bucket_public_access_block.S3
  ]
}


# ============================================================
# 15. S3 ACCELERATE
# ============================================================
#
# Useful for certain globally distributed upload/download
# workloads.
#
# Usually NOT required for normal applications.
#
# ============================================================

resource "aws_s3_bucket_accelerate_configuration" "S3" {

  bucket = aws_s3_bucket.S3.id

  status = "Suspended"

  # Change to:
  #
  # status = "Enabled"
  #
  # when S3 Transfer Acceleration is required.
}


# ============================================================
# 16. S3 TRANSFER ACCELERATION
# ============================================================
#
# Example:
#
# Users worldwide
#       |
#       v
# S3 Transfer Acceleration
#       |
#       v
# S3 Bucket
#
# ============================================================


# ============================================================
# 17. S3 INVENTORY
# ============================================================
#
# Useful for large buckets.
#
# Generates periodic inventory reports containing information
# about objects.
#
# Example information:
#
# - Object key
# - Size
# - Last modified
# - Storage class
# - Encryption
# - Replication status
#
# ============================================================

resource "aws_s3_bucket_inventory" "S3" {

  bucket = aws_s3_bucket.S3.id

  name = "daily-inventory"

  included_object_versions = "All"

  schedule {

    frequency = "Daily"
  }

  destination {

    bucket {

      bucket_arn = "arn:aws:s3:::mycompany-prod-s3-inventory-001"

      format = "CSV"

      encryption {

        sse_s3 {}
      }
    }
  }

  optional_fields = [

    "Size",

    "LastModifiedDate",

    "StorageClass",

    "ETag",

    "IsMultipartUploaded",

    "ReplicationStatus",

    "EncryptionStatus"
  ]
}


# ============================================================
# 18. CROSS REGION REPLICATION
# ============================================================
#
# Example architecture:
#
# PRIMARY
# us-east-1
#     |
#     | CRR
#     v
# DR
# us-west-2
#
# ============================================================

resource "aws_iam_role" "S3_replication" {

  name = "S3-CrossRegion-Replication-Role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {

        Effect = "Allow"

        Principal = {

          Service = "s3.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}


# ============================================================
# 19. REPLICATION IAM POLICY
# ============================================================

resource "aws_iam_role_policy" "S3_replication" {

  role = aws_iam_role.S3_replication.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      # ------------------------------------------------------
      # SOURCE BUCKET
      # ------------------------------------------------------

      {

        Effect = "Allow"

        Action = [

          "s3:GetReplicationConfiguration",

          "s3:ListBucket"
        ]

        Resource = aws_s3_bucket.S3.arn
      },


      # ------------------------------------------------------
      # SOURCE OBJECTS
      # ------------------------------------------------------

      {

        Effect = "Allow"

        Action = [

          "s3:GetObjectVersion",

          "s3:GetObjectVersionAcl",

          "s3:GetObjectVersionForReplication",

          "s3:GetObjectLegalHold",

          "s3:GetObjectRetention",

          "s3:GetObjectVersionTagging"
        ]

        Resource = "${aws_s3_bucket.S3.arn}/*"
      },


      # ------------------------------------------------------
      # DESTINATION OBJECTS
      # ------------------------------------------------------

      {

        Effect = "Allow"

        Action = [

          "s3:ReplicateObject",

          "s3:ReplicateDelete",

          "s3:ReplicateTags"
        ]

        Resource = "arn:aws:s3:::mycompany-dr-bucket-001/*"
      }
    ]
  })
}


# ============================================================
# 20. REPLICATION CONFIGURATION
# ============================================================
#
# IMPORTANT:
# Destination bucket must exist.
#
# Both source and destination buckets need versioning.
#
# ============================================================

resource "aws_s3_bucket_replication_configuration" "S3" {

  bucket = aws_s3_bucket.S3.id

  role = aws_iam_role.S3_replication.arn

  rule {

    id = "production-cross-region-replication"

    status = "Enabled"

    filter {

      prefix = ""
    }

    destination {

      bucket = "arn:aws:s3:::mycompany-dr-bucket-001"

      storage_class = "STANDARD"
    }
  }

  depends_on = [

    aws_s3_bucket_versioning.S3
  ]
}


# ============================================================
# 21. EVENT NOTIFICATION - SQS
# ============================================================
#
# Example:
#
# S3 Object Created
#        |
#        v
#       SQS
#        |
#        v
# Worker / Application
#
# ============================================================

resource "aws_s3_bucket_notification" "S3" {

  bucket = aws_s3_bucket.S3.id

  queue {

    queue_arn = "arn:aws:sqs:us-east-1:123456789012:s3-events"

    events = [
      "s3:ObjectCreated:*"
    ]

    filter_prefix = "uploads/"

    filter_suffix = ".json"
  }
}


# ============================================================
# 22. EVENT NOTIFICATION - SNS
# ============================================================
#
# Example:
#
# S3
#  |
#  +----> SNS
#          |
#          +----> Email
#          +----> Lambda
#          +----> SQS
#
# Configure using an SNS topic ARN.
#
# ============================================================

# Example only:
#
# topic {
#   topic_arn = "arn:aws:sns:us-east-1:123456789012:s3-events"
#
#   events = [
#     "s3:ObjectCreated:*",
#     "s3:ObjectRemoved:*"
#   ]
# }


# ============================================================
# 23. EVENT NOTIFICATION - LAMBDA
# ============================================================
#
# Example:
#
# S3 upload
#     |
#     v
# Lambda
#     |
#     +----> Process image
#     +----> Validate file
#     +----> Start workflow
#
# ============================================================

# Example:
#
# lambda_function {
#
#   lambda_function_arn =
#     "arn:aws:lambda:us-east-1:123456789012:function:process-upload"
#
#   events = [
#     "s3:ObjectCreated:*"
#   ]
#
#   filter_prefix = "uploads/"
#
#   filter_suffix = ".jpg"
# }


# ============================================================
# 24. STATIC WEBSITE
# ============================================================
#
# If using this:
#
# enable:
# aws_s3_bucket_website_configuration
#
# But for production:
#
# Browser
#    |
#    v
# CloudFront
#    |
#    v
# Private S3
#
# is generally preferred.
#
# ============================================================


# ============================================================
# 25. S3 OBJECT EXAMPLE
# ============================================================
#
# Terraform can also upload objects.
#
# Usually application files should NOT be managed this way
# for production applications.
#
# ============================================================

# resource "aws_s3_object" "example" {
#
#   bucket = aws_s3_bucket.S3.id
#
#   key = "config/application.json"
#
#   source = "./application.json"
#
#   etag = filemd5("./application.json")
#
#   server_side_encryption = "aws:kms"
#
#   kms_key_id = aws_kms_key.S3.arn
# }


# ============================================================
# 26. S3 OBJECT WITH CONTENT
# ============================================================

# resource "aws_s3_object" "example_text" {
#
#   bucket = aws_s3_bucket.S3.id
#
#   key = "hello.txt"
#
#   content = "Hello from Terraform"
#
#   content_type = "text/plain"
#
#   server_side_encryption = "aws:kms"
#
#   kms_key_id = aws_kms_key.S3.arn
# }


# ============================================================
# 27. BUCKET LIFECYCLE
# ============================================================
#
# Terraform resource lifecycle.
#
# This is NOT the same as S3 object lifecycle.
#
# ============================================================

# resource "aws_s3_bucket" "S3" {
#
#   lifecycle {
#
#     prevent_destroy = true
#
#     ignore_changes = [
#       tags
#     ]
#   }
# }


# ============================================================
# 28. OUTPUTS
# ============================================================

output "s3_bucket_name" {

  description = "S3 bucket name"

  value = aws_s3_bucket.S3.bucket
}


output "s3_bucket_arn" {

  description = "S3 bucket ARN"

  value = aws_s3_bucket.S3.arn
}


output "s3_bucket_region" {

  description = "S3 bucket region"

  value = data.aws_region.current.name
}


output "s3_bucket_domain_name" {

  description = "S3 bucket regional domain name"

  value = aws_s3_bucket.S3.bucket_regional_domain_name
}


output "s3_kms_key_arn" {

  description = "S3 KMS key ARN"

  value = aws_kms_key.S3.arn
}


output "s3_kms_alias" {

  description = "S3 KMS alias"

  value = aws_kms_alias.S3.name
}
```
