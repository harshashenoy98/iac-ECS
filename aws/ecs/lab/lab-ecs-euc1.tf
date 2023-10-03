  module "lab_ecs_euc1" {
  source = "../../../modules/ecs" # helps is reusing the code

  account_id          = "123456789"    # specify the aws account id
  region              = "eu-central-1"
  vpc_name            = "lab-ecs"      # specify the vpc name
  cluster_name        = "coderbyte"
  environment         = "lab"
  security_group_id   = "sg-123456789" # specify the securitygroup

  tags = {
    Tennant           = "coderbyte"
    "terraform/state" = "ecs"
  }

  }