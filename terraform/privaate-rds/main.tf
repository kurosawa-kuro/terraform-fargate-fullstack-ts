#########################################
# プロバイダ設定 & ローカル変数
#########################################
provider "aws" {
  region = "ap-northeast-1" # 例: 東京リージョン
}

locals {
  prefix = "private-rds"

  # VPC全体CIDR
  vpc_cidr_block = "10.0.0.0/16"

  # パブリックサブネット用 CIDR (NATGW/IGW配置)
  public_subnets = {
    a = "10.0.1.0/24"
    c = "10.0.2.0/24"
  }

  # プライベートサブネット用 CIDR (RDS配置先)
  private_subnets = {
    a = "10.0.11.0/24"
    c = "10.0.12.0/24"
  }

  # RDS の初期設定 (DB名, ユーザー名, パスワードなど)
  db_name     = "myapp_db"
  db_username = "dbuser"
  db_password = "P@ssw0rd!"    # 実運用では秘匿管理 (例: SSM, Vaultなど)
  db_engine_version = "14.7"   # PostgreSQLのバージョン例
}

#########################################
# VPC
#########################################
resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.prefix}-vpc"
  }
}

#########################################
# インターネットゲートウェイ (IGW) & NAT Gateway
#########################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-igw"
  }
}

# NAT Gateway 用の EIP
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "${local.prefix}-nat-eip"
  }
}

#########################################
# パブリックサブネット
#########################################
resource "aws_subnet" "public" {
  for_each               = local.public_subnets
  vpc_id                 = aws_vpc.main.id
  cidr_block             = each.value
  availability_zone      = "ap-northeast-1${each.key}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.prefix}-public-subnet-${each.key}"
  }
}

#########################################
# プライベートサブネット
#########################################
resource "aws_subnet" "private" {
  for_each               = local.private_subnets
  vpc_id                 = aws_vpc.main.id
  cidr_block             = each.value
  availability_zone      = "ap-northeast-1${each.key}"
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.prefix}-private-subnet-${each.key}"
  }
}

#########################################
# ルートテーブル (パブリック)
#########################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.prefix}-public-rt"
  }
}

# パブリックサブネットとRT紐付け
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

#########################################
# NAT Gateway (パブリックサブネットに1つ配置)
#########################################
# 例: public-subnet-a に NATGW を配置する構成
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["a"].id

  tags = {
    Name = "${local.prefix}-nat-gw"
  }
}

#########################################
# ルートテーブル (プライベート)
#########################################
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${local.prefix}-private-rt"
  }
}

# プライベートサブネットとRT紐付け
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  route_table_id = aws_route_table.private.id
  subnet_id      = each.value.id
}

#########################################
# RDS 用セキュリティグループ
#########################################
resource "aws_security_group" "rds_sg" {
  name        = "${local.prefix}-rds-sg"
  description = "RDS Postgres SG (Private Access)"
  vpc_id      = aws_vpc.main.id

  # インバウンドは任意の接続元(例: アプリケーションサーバSGなど)に合わせて調整する
  # サンプルでは 5432 を「同じVPC内からのみ許可」とする例
  ingress {
    description       = "Allow Postgres from VPC range"
    from_port         = 5432
    to_port           = 5432
    protocol          = "tcp"
    cidr_blocks       = [local.vpc_cidr_block]
  }

  # アウトバウンドはデフォルト全許可
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-rds-sg"
  }
}

#########################################
# DB サブネットグループ (RDS用にプライベートサブネットを指定)
#########################################
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${local.prefix}-db-subnet-group"
  subnet_ids = values(aws_subnet.private)[*].id

  tags = {
    Name = "${local.prefix}-db-subnet-group"
  }
}

#########################################
# RDS Parameter Group (任意)
#########################################
resource "aws_db_parameter_group" "postgres_params" {
  name        = "${local.prefix}-param-group"
  family      = "postgres14"  # engine_versionに合わせる
  description = "Custom parameter group for PostgreSQL 14"

  # カスタムパラメータが必要な場合は parameter ブロックを追加
  # 例: ログ設定を変更
  parameter {
    name  = "log_statement"
    value = "all"
  }

  tags = {
    Name = "${local.prefix}-param-group"
  }
}

#########################################
# RDS インスタンス
#########################################
resource "aws_db_instance" "postgres" {
  identifier             = "${local.prefix}-db-instance"
  engine                 = "postgres"
  engine_version         = local.db_engine_version
  instance_class         = "db.t3.micro"         # 例: 開発/検証用
  allocated_storage      = 20                    # ストレージサイズ (GB)
  storage_type           = "gp2"                 # 例: 一般的な汎用SSD
  db_name                = local.db_name         # DB名
  username               = local.db_username     # ユーザ名
  password               = local.db_password     # パスワード
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  parameter_group_name   = aws_db_parameter_group.postgres_params.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # Multi-AZ やバックアップ等の設定
  multi_az               = false                  # マルチAZ要件に応じて設定
  publicly_accessible    = false                 # パブリックIPを持たない
  skip_final_snapshot    = true                  # 試験用: 削除時にスナップショット作成しない

  tags = {
    Name = "${local.prefix}-rds-postgres"
  }
}

#########################################
# 出力
#########################################
output "db_endpoint" {
  description = "RDS (PostgreSQL) Endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "db_port" {
  description = "RDS (PostgreSQL) Port"
  value       = aws_db_instance.postgres.port
}

output "db_subnet_group_name" {
  description = "RDS Subnet Group Name"
  value       = aws_db_subnet_group.rds_subnet_group.name
}
