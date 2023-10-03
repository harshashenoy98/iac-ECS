
# to create an ECS cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = local.cluster_name
  tags = merge(
    var.tags,
    {
      "Name"             = "ecs-${local.cluster_name}",
      "Environment"      = var.environment
    }
  )
}

# creating an ecs task definition
resource "aws_ecs_task_definition" "my_task" {
  family                   = "my-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn        = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "my-app-container"
      image = "docker-image-url:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

}

# IAM role for ECS task execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policies to the ECS task execution role as needed
resource "aws_iam_policy_attachment" "ecs_execution_role_attachment" {
  name       = "ecs-execution-role-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  roles      = [aws_iam_role.ecs_execution_role.name]
}

# Create an ECS service
resource "aws_ecs_service" "my_service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets = data.aws_subnet_ids.public.id

    security_groups = [data.aws_security_group.ecs_security_group.id]
  }
}

# Create an Application Load Balancer
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.public.id
  enable_deletion_protection = false

  enable_http2 = true

  tags = merge(
    var.tags,
    {
      "Name"             = "ecs-${local.cluster_name}",
      "Environment"      = var.environment
    }
  )
}

# Create an ALB listener and target group
resource "aws_lb_listener" "my_alb_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      status_code  = "200"
    }
  }
}

resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "my_alb_rule" {
  listener_arn = aws_lb_listener.my_alb_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }

  condition {
    host_header {
      values = ["example.com"]
    }
  }
}

# Attach ECS service to target group
resource "aws_lb_target_group_attachment" "ecs_target_group_attachment" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id        = aws_ecs_service.my_service.id
}