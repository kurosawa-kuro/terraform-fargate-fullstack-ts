#########################################
# プロバイダ & ローカル変数
#########################################
provider "aws" {
  region = "ap-northeast-1"
}

locals {
  prefix         = "fullstack-public-01"
  account_id     = "503561449641"
  region         = "ap-northeast-1"

  backend_image  = "kurosawakuro/backend-express-8000"
  frontend_image = "kurosawakuro/frontend-nextjs-3000"

  ssm_prefix = "/${local.prefix}"

  public_subnets = {
    a = "10.0.1.0/24"
    c = "10.0.2.0/24"
  }

  ssm_parameter_keys = [
    "BACKEND_PORT",
    "FRONTEND_PORT",
    "DATABASE_URL",
    "JWT_SECRET_KEY",
    "NODE_ENV",
    "UPLOAD_DIR"
  ]
}

#########################################
# VPC, Subnet, IGW, RouteTable
#########################################
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.prefix}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.prefix}-igw"
  }
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = "${local.region}${each.key}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.prefix}-public-subnet-${each.key}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

#########################################
# セキュリティグループ (1つのみ)
#########################################
resource "aws_security_group" "ecs_sg" {
  name        = "${local.prefix}-ecs-sg"
  description = "Allow inbound on ports 3000(front) & 8000(backend)"
  vpc_id      = aws_vpc.main.id

  # バックエンド用(8000)を開放
  ingress {
    description = "Allow inbound on port 8000"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # フロントエンド用(3000)を開放
  ingress {
    description = "Allow inbound on port 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 全ての外向き通信を許可
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-ecs-sg"
  }
}

#########################################
# ECS クラスタ
#########################################
resource "aws_ecs_cluster" "default" {
  name = "${local.prefix}-cluster"

  # サービスディスカバリー用の設定
  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.services.arn
  }
}

#########################################
# IAM ロール & ポリシー
#########################################
resource "aws_iam_role" "ecs_execution_role" {
  name = "${local.prefix}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# SSM パラメータアクセス用 (必要に応じて)
data "aws_iam_policy" "ssm_parameter_access" {
  # ここはユーザー定義ポリシー or AWS管理ポリシーに合わせる
  name = "${local.prefix}-ssm-parameter-access"
}

resource "aws_iam_role_policy_attachment" "ecs_ssm_policy_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = data.aws_iam_policy.ssm_parameter_access.arn
}

#########################################
# CloudWatch Logs
#########################################
resource "aws_cloudwatch_log_group" "backend_logs" {
  name              = "/ecs/${local.prefix}-backend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "frontend_logs" {
  name              = "/ecs/${local.prefix}-frontend"
  retention_in_days = 7
}

#########################################
# ECS Task Definition (コンテナ設定)
#########################################
locals {
  container_secrets = [
    for key in local.ssm_parameter_keys : {
      name      = key
      valueFrom = "arn:aws:ssm:${local.region}:${local.account_id}:parameter${local.ssm_prefix}/${key}"
    }
  ]
}

# バックエンド Task
resource "aws_ecs_task_definition" "backend_task" {
  family                   = "${local.prefix}-backend-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = local.backend_image
      essential = true
      portMappings = [
        {
          name          = "backend-port"
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]
      secrets = local.container_secrets

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend_logs.name
          "awslogs-region"        = local.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# フロントエンド Task
resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "${local.prefix}-frontend-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = local.frontend_image
      essential = true
      portMappings = [
        {
          name          = "frontend-port"
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      secrets = local.container_secrets
      
      # バックエンドAPIのURL
      environment = [
        {
          name  = "API_URL"
          value = "http://${local.prefix}-backend-service:8000"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend_logs.name
          "awslogs-region"        = local.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

#########################################
# ECS Service (バックエンド)
#########################################
resource "aws_ecs_service" "backend_service" {
  name            = "${local.prefix}-backend-service"
  cluster         = aws_ecs_cluster.default.id
  task_definition = aws_ecs_task_definition.backend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # サービスディスカバリー設定
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.services.arn
    service {
      port_name      = "backend-port"
      discovery_name = "${local.prefix}-backend-service"
      client_alias {
        port     = 8000
        dns_name = "${local.prefix}-backend-service"
      }
    }
  }

  network_configuration {
    subnets          = values(aws_subnet.public)[*].id
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}

#########################################
# ECS Service (フロントエンド)
#########################################
resource "aws_ecs_service" "frontend_service" {
  name            = "${local.prefix}-frontend-service"
  cluster         = aws_ecs_cluster.default.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # サービスディスカバリー設定
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.services.arn
    service {
      port_name      = "frontend-port"
      discovery_name = "${local.prefix}-frontend-service"
      client_alias {
        port     = 3000
        dns_name = "${local.prefix}-frontend-service"
      }
    }
  }

  network_configuration {
    subnets          = values(aws_subnet.public)[*].id
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}

#########################################
# アウトプット (注意: 動的に変わる可能性あり)
#########################################
output "backend_service_info" {
  description = "Backend ECS service details"
  value = {
    service_name    = aws_ecs_service.backend_service.name
    task_definition = aws_ecs_service.backend_service.task_definition
    # ECSタスクのPublic IPは可変なので、安定して参照できません
    # ここではサービス名などを出力し、アクセス確認は後述
  }
}

output "frontend_service_info" {
  description = "Frontend ECS service details"
  value = {
    service_name    = aws_ecs_service.frontend_service.name
    task_definition = aws_ecs_service.frontend_service.task_definition
  }
}

# サービスディスカバリー名前空間
resource "aws_service_discovery_http_namespace" "services" {
  name        = "${local.prefix}-namespace"
  description = "Service discovery namespace for ECS services"
}
