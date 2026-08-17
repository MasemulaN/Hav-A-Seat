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

resource "aws_internet_gateway" "hav_a_seat" {
  vpc_id = aws_vpc.hav_a_seat.id

  tags = {
    Name    = "nm-hav-a-seat-igw"
    Project = "Hav-A-Seat"
  }
}

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
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.hav_a_seat.id

  tags = {
    Name    = "nm-hav-a-seat-private-rt"
    Project = "Hav-A-Seat"
    Tier    = "Private"
  }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name    = "nm-hav-a-seat-nat-eip"
    Project = "Hav-A-Seat"
  }
}

# NAT Gateway in Public Subnet 1
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

# Route private subnet traffic through the NAT Gateway
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.hav_a_seat.id
}

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

resource "aws_launch_template" "hav_a_seat" {
  name = "${var.project_name}-launch-template"

  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  user_data = base64encode(<<-EOF
    #!/bin/bash

    dnf update -y
    dnf install -y docker

    systemctl enable docker
    systemctl start docker

    usermod -aG docker ec2-user
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
    version = "$Latest"
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

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.hav_a_seat.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hav_a_seat.arn
  }
}

resource "aws_db_subnet_group" "hav_a_seat" {
  name       = "nm-hav-a-seat-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name    = "nm-hav-a-seat-db-subnet-group"
    Project = "Hav-A-Seat"
  }
}

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