terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# S3 Bucket para artefatos do Pipeline
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket_prefix = "pricemonitor-pipeline-"
  force_destroy = true

  tags = {
    Name        = "PriceMonitor Pipeline Artifacts"
    Environment = "Dev"
  }
}

# IAM Role para CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "PriceMonitor-CodePipeline-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "PriceMonitor-CodePipeline-Policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.pipeline_artifacts.arn,
          "${aws_s3_bucket.pipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role para CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "PriceMonitor-CodeBuild-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "PriceMonitor-CodeBuild-Policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.pipeline_artifacts.arn,
          "${aws_s3_bucket.pipeline_artifacts.arn}/*",
          "arn:aws:s3:::aws-sam-cli-managed-default-samclisourcebucket-*",
          "arn:aws:s3:::aws-sam-cli-managed-default-samclisourcebucket-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudformation:*",
          "lambda:*",
          "apigateway:*",
          "dynamodb:*",
          "states:*",
          "iam:*",
          "s3:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# CodeBuild Project
resource "aws_codebuild_project" "sam_build" {
  name          = "PriceMonitor-SAM-Build"
  description   = "Build e Deploy do Monitor de Preços Serverless"
  build_timeout = 15
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "ci-cd/buildspec.yml"
  }

  tags = {
    Environment = "Dev"
  }
}

# CodePipeline
resource "aws_codepipeline" "pipeline" {
  name     = "PriceMonitor-Pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_owner
        Repo       = var.github_repo
        Branch     = var.github_branch
        OAuthToken = var.github_token
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "SAM_Build_Deploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.sam_build.name
      }
    }
  }

  tags = {
    Environment = "Dev"
  }
}

# Outputs
output "pipeline_name" {
  description = "Nome do CodePipeline"
  value       = aws_codepipeline.pipeline.name
}

output "codebuild_project" {
  description = "Nome do projeto CodeBuild"
  value       = aws_codebuild_project.sam_build.name
}

output "artifacts_bucket" {
  description = "Bucket S3 para artefatos"
  value       = aws_s3_bucket.pipeline_artifacts.bucket
}