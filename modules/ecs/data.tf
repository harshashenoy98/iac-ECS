locals {
  cluster_name = "${var.cluster_name}-${var.vpc_name}"
}

data "aws_vpc" "selected" {
  provider = aws.module
  tags = {
    Name        = var.vpc_name
    Environment = var.environment
  }
}

data "aws_subnet_ids" "private" {
  provider = aws.module
  vpc_id   = data.aws_vpc.selected.id

  tags = {
    Type        = "private"
    Environment = var.environment
  }
}

data "aws_subnet_ids" "public" {
  provider = aws.module
  vpc_id   = data.aws_vpc.selected.id

  tags = {
    Type        = "public"
    Environment = var.environment
  }
}

data "aws_security_group" "ecs_security_group" {
  provider = aws.module
  vpc_id   = data.aws_vpc.selected.id
  id       = var.security_group_id
}
