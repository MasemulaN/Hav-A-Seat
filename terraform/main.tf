terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.15.0"
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------
# AMI
# ---------------------------------------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# ---------------------------------------------------------
# VPC
# ---------------------------------------------------------

resource "aws_vpc" "hav_a_seat" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = "Hav-A-Seat"
  }
}

# ---------------------------------------------------------
# Public Subnets
# ---------------------------------------------------------

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.hav_a_seat.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-public-subnet-${count.index + 1}"
    Project = "Hav-A-Seat"
    Tier    = "Public"
  }
}

# ---------------------------------------------------------
# Private Subnets
# ---------------------------------------------------------

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.hav_a_seat.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name    = "${var.project_name}-private-subnet-${count.index + 1}"
    Project = "Hav-A-Seat"
    Tier    = "Private"
  }
}

# ---------------------------------------------------------
# Internet Gateway
# ---------------------------------------------------------

resource "aws_internet_gateway" "hav_a_seat" {
  vpc_id = aws_vpc.hav_a_seat.id

  tags = {
    Name    = "nm-hav-a-seat-igw"
    Project = "Hav-A-Seat"
  }
}

# ---------------------------------------------------------
# Public Route Table
# ---------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.hav_a_seat.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hav_a_seat.id
  }

  tags = {
    Name    = "nm-hav-a-seat-public-rt"
    Project = "Hav-A-Seat"
    Tier    = "Public"
  }
}

resource "aws_route_table_association" "public" {
  # Temporarily explicit while reconstructing Terraform state.
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------
# Private Route Table
# ---------------------------------------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.hav_a_seat.id

  tags = {
    Name    = "nm-hav-a-seat-private-rt"
    Project = "Hav-A-Seat"
    Tier    = "Private"
  }
}

resource "aws_route_table_association" "private" {
  # Temporarily explicit while reconstructing Terraform state.
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ---------------------------------------------------------
# NAT Gateway
# ---------------------------------------------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name    = "nm-hav-a-seat-nat-eip"
    Project = "Hav-A-Seat"
  }
}

resource "aws_nat_gateway" "hav_a_seat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name    = "nm-hav-a-seat-nat-gateway"
    Project = "Hav-A-Seat"
  }

  depends_on = [
    aws_internet_gateway.hav_a_seat
  ]
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.hav_a_seat.id
}

# ---------------------------------------------------------
# Security Groups
# ---------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "nm-hav-a-seat-alb-sg"
  description = "Security group for the Hav-A-Seat Application Load Balancer"
  vpc_id      = aws_vpc.hav_a_seat.id

  ingress {
    description = "Allow HTTP traffic from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "nm-hav-a-seat-alb-sg"
    Project = "Hav-A-Seat"
    Tier    = "Public"
  }
}

resource "aws_security_group" "app" {
  name        = "nm-hav-a-seat-app-sg"
  description = "Security group for Hav-A-Seat application servers"
  vpc_id      = aws_vpc.hav_a_seat.id

  ingress {
    description     = "Allow HTTP traffic from the load balancer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "nm-hav-a-seat-app-sg"
    Project = "Hav-A-Seat"
    Tier    = "Private"
  }
}

resource "aws_security_group" "db" {
  name        = "nm-hav-a-seat-db-sg"
  description = "Security group for the Hav-A-Seat PostgreSQL database"
  vpc_id      = aws_vpc.hav_a_seat.id

  ingress {
    description     = "Allow PostgreSQL traffic from application servers"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "nm-hav-a-seat-db-sg"
    Project = "Hav-A-Seat"
    Tier    = "Private"
  }
}

# ---------------------------------------------------------
# IAM Role for EC2 / Systems Manager
# ---------------------------------------------------------

resource "aws_iam_role" "ec2_ssm" {
  name = "${var.project_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-ec2-ssm-role"
    Project = "Hav-A-Seat"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "${var.project_name}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name
}

# ---------------------------------------------------------
# GitHub Actions OIDC Provider
# ---------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = {
    Name    = "${var.project_name}-github-oidc"
    Project = "Hav-A-Seat"
  }
}

# ---------------------------------------------------------
# IAM Role for GitHub Actions
# ---------------------------------------------------------

resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }

          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:MasemulaN/Hav-A-Seat:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-github-actions-role"
    Project = "Hav-A-Seat"
  }
}

# ---------------------------------------------------------
# GitHub Actions Deployment Policy
# ---------------------------------------------------------

resource "aws_iam_role_policy" "github_actions_deployment" {
  name = "${var.project_name}-github-actions-deployment-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "SSMCommandExecution"
        Effect = "Allow"

        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:ListCommandInvocations",
          "ssm:ListCommands"
        ]

        Resource = "*"
      },

      {
        Sid    = "EC2Discovery"
        Effect = "Allow"

        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeTags"
        ]

        Resource = "*"
      }
    ]
  })
}

# ---------------------------------------------------------
# Launch Template
# ---------------------------------------------------------

resource "aws_launch_template" "hav_a_seat" {
  name = "${var.project_name}-launch-template"

  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm.name
  }

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  user_data = base64encode(<<-EOF
  #!/bin/bash

  # Update the system
  dnf update -y

  # Install Docker and Git
  dnf install -y docker git

  # Start Docker
  systemctl enable docker
  systemctl start docker

  # Clone the application
  cd /opt
  git clone https://github.com/MasemulaN/Hav-A-Seat.git

  # Build the Docker image
  cd /opt/Hav-A-Seat
  docker build -t hav-a-seat .

  # Database connection settings
  DB_HOST="${aws_db_instance.hav_a_seat.address}"
  DB_PORT="${aws_db_instance.hav_a_seat.port}"
  DB_NAME="${aws_db_instance.hav_a_seat.db_name}"
  DB_USER="${aws_db_instance.hav_a_seat.username}"
  DB_PASSWORD="${var.db_password}"

  # Wait for RDS to become available
  echo "Waiting for RDS database to become available..."

  until docker run --rm \
    -e PGPASSWORD="$DB_PASSWORD" \
    postgres:17 \
    pg_isready \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_USER" \
    -d "$DB_NAME"
  do
    echo "RDS is not ready yet. Waiting 5 seconds..."
    sleep 5
  done

  echo "RDS is available."

  # Check whether the database schema already exists
  TABLE_EXISTS=$(docker run --rm \
    -e PGPASSWORD="$DB_PASSWORD" \
    postgres:17 \
    psql \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    -tAc "SELECT to_regclass('public.events');")

  # Initialize the database only when the schema does not exist
  if [ "$TABLE_EXISTS" = "events" ]; then
    echo "Database schema already exists. Skipping initialization."
  else
    echo "Database schema not found. Initializing database..."

    docker run --rm \
      -e PGPASSWORD="$DB_PASSWORD" \
      -v /opt/Hav-A-Seat/database/init:/init:ro \
      postgres:17 \
      psql \
      -h "$DB_HOST" \
      -p "$DB_PORT" \
      -U "$DB_USER" \
      -d "$DB_NAME" \
      -f /init/01-init.sql

    echo "Database initialization completed."
  fi

  # Run the application
  docker run -d \
    --name hav-a-seat \
    --restart unless-stopped \
    -p 80:5000 \
    -e DB_HOST="$DB_HOST" \
    -e DB_PORT="$DB_PORT" \
    -e DB_NAME="$DB_NAME" \
    -e DB_USER="$DB_USER" \
    -e DB_PASSWORD="$DB_PASSWORD" \
    hav-a-seat
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name    = "${var.project_name}-app-server"
      Project = "Hav-A-Seat"
      Tier    = "Private"
    }
  }

  tags = {
    Name    = "${var.project_name}-launch-template"
    Project = "Hav-A-Seat"
  }
}

# ---------------------------------------------------------
# Auto Scaling Group
# ---------------------------------------------------------

resource "aws_autoscaling_group" "hav_a_seat" {
  name = "${var.project_name}-asg"

  min_size         = 2
  desired_capacity = 2
  max_size         = 4

  vpc_zone_identifier = aws_subnet.private[*].id

  health_check_type         = "ELB"
  health_check_grace_period = 300

  target_group_arns = [
    aws_lb_target_group.hav_a_seat.arn
  ]

  launch_template {
    id      = aws_launch_template.hav_a_seat.id
    version = aws_launch_template.hav_a_seat.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app-server"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "Hav-A-Seat"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "Private"
    propagate_at_launch = true
  }
}

# ---------------------------------------------------------
# Application Load Balancer
# ---------------------------------------------------------

resource "aws_lb" "hav_a_seat" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name    = "${var.project_name}-alb"
    Project = "Hav-A-Seat"
    Tier    = "Public"
  }
}

# ---------------------------------------------------------
# Target Group
# ---------------------------------------------------------

resource "aws_lb_target_group" "hav_a_seat" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.hav_a_seat.id

  health_check {
    enabled  = true
    protocol = "HTTP"
    path     = "/"
    port     = "traffic-port"
  }

  tags = {
    Name    = "${var.project_name}-target-group"
    Project = "Hav-A-Seat"
  }
}

# ---------------------------------------------------------
# ALB Listener
# ---------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.hav_a_seat.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hav_a_seat.arn
  }
}

# ---------------------------------------------------------
# RDS Subnet Group
# ---------------------------------------------------------

resource "aws_db_subnet_group" "hav_a_seat" {
  name       = "nm-hav-a-seat-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name    = "nm-hav-a-seat-db-subnet-group"
    Project = "Hav-A-Seat"
  }
}

# ---------------------------------------------------------
# RDS PostgreSQL
# ---------------------------------------------------------

resource "aws_db_instance" "hav_a_seat" {
  identifier = "nm-hav-a-seat-db"

  engine         = "postgres"
  engine_version = "18.4"

  allow_major_version_upgrade = true
  apply_immediately           = true

  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"

  db_name  = "hav_a_seat"
  username = "postgres"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.hav_a_seat.name
  vpc_security_group_ids = [aws_security_group.db.id]

  publicly_accessible = false
  multi_az            = false
  storage_encrypted   = true

  backup_retention_period = 1

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name    = "nm-hav-a-seat-db"
    Project = "Hav-A-Seat"
    Tier    = "Private"
  }
}