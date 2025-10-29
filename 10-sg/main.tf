# Using Open source module
/* module "catalogue" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${local.common_name_suffix}-catalogue"
  use_name_prefix = false
  description = "Security group for catalogue with custom ports open within VPC, egress all traffic"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

} */


module "sg" {
  count = length(var.sg_names)
  source = "git::https://github.com/sudheerthota2525-dot/terraform-aws-sg.git?ref=main"
  project_name = var.project_name
  environment = var.environment
  sg_name = var.sg_names[count.index]
  sg_description = "Created for ${var.sg_names[count.index]}"
  vpc_id =  local.vpc_id
}

# Frontend accepting traffic from frontend ALB
# resource "aws_security_group_rule" "frontend_frontend_alb" {
#   type              = "ingress"
#   security_group_id = module.sg[9].sg_id # frontend SG ID
#   source_security_group_id = module.sg[11].sg_id # frontend ALB SG ID
#   from_port         = 80
#   protocol          = "tcp"
#   to_port           = 80
# }

# Store Bastion Security Group ID in AWS SSM Parameter Store
resource "aws_ssm_parameter" "bastion_sg_id" {
  name       = "/${var.project_name}/${var.environment}/bastion_sg_id"
  type       = "String"
  value      = module.sg[0].sg_id
  overwrite  = true

  # This makes Terraform wait until SGs are fully created
  depends_on = [module.sg]
}

# Allow SSH from Bastion to all Private SGs (MongoDB, Redis, RabbitMQ)
resource "aws_security_group_rule" "bastion_to_private" {
  count                    = length(var.sg_names) - 1  # skip bastion index (0)
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = module.sg[0].sg_id        # bastion SG
  security_group_id        = module.sg[count.index + 1].sg_id
  description              = "Allow SSH from Bastion to private instances"
}
