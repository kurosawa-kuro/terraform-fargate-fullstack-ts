#########################################
# プロバイダ設定 & ローカル変数
#########################################
provider "aws" {
  region = "ap-northeast-1"  # 東京リージョン
}

locals {
  prefix        = "api-8000-public-01"
  account_id    = "503561449641"
  region        = "ap-northeast-1"

  # SSMパラメータのプレフィックス
  ssm_prefix = "/${local.prefix}"

  # 1.2 SSM パラメータを一括管理（キー名＝環境変数名）
  # type = "SecureString" などパラメータごとに必要なものを指定
  ssm_parameters = {
    BACKEND_PORT = {
      type        = "String"
      description = "Backend application port"
      value       = "8000"
    },
    FRONTEND_PORT = {
      type        = "String"
      description = "Frontend application port"
      value       = "3000"
    },
    DATABASE_URL = {
      type        = "SecureString"
      description = "Database connection URL"
      value       = "postgresql://postgres:postgres@api-3000-03-db.cluster-xxxxxxxxxx.ap-northeast-1.rds.amazonaws.com:5432/dev_db"
    },
    JWT_SECRET_KEY = {
      type        = "SecureString"
      description = "JWT secret key for authentication"
      value       = "secret"
    },
    NODE_ENV = {
      type        = "String"
      description = "Node environment"
      value       = "production"
    },
    UPLOAD_DIR = {
      type        = "String"
      description = "Upload directory path"
      value       = "uploads"
    }
  }
}


#########################################
# SSM パラメータ (for_each)
#########################################
resource "aws_ssm_parameter" "parameters" {
  for_each    = local.ssm_parameters

  name        = "${local.ssm_prefix}/${each.key}"
  type        = each.value.type
  description = each.value.description
  value       = each.value.value
  
}

# SSMポリシー (SSM パラメータへのアクセス)
resource "aws_iam_policy" "ssm_parameter_access" {
  name        = "${local.prefix}-ssm-parameter-access"
  description = "Allow access to SSM parameters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ssm:GetParameters", "ssm:GetParameter"],
        Effect   = "Allow",
        Resource = "arn:aws:ssm:${local.region}:${local.account_id}:parameter${local.ssm_prefix}/*"
      }
    ]
  })
}
