module "route53" {
  source             = "../modules/r53"
  alb_dns_name       = module.alb.alb_dns_name
  alb_hosted_zone_id = module.alb.alb_hosted_zone_id
  sub_domain         = var.sub_domain
  hosted_zone_name   = var.hosted_zone_name
}



module "network" {
  source             = "../modules/network"
  region             = var.region
  module_prefix      = var.project_name
  vpc_cidr           = var.vpc_cidr
  pub_sub_a_cidr     = var.pub_sub_a_cidr
  pub_sub_b_cidr     = var.pub_sub_b_cidr
  jenkins_sub_a_cidr = var.pub_sub_jenkins_a_cidr
  jenkins_sub_b_cidr = var.pub_sub_jenkins_b_cidr
}

module "security-group" {
  source                     = "../modules/security-group"
  module_prefix              = var.project_name
  vpc_id                     = module.network.vpc_id
  jenkins_allowed_http_cidrs = var.jenkins_allowed_http_cidrs
}



module "s3" {
  source = "../modules/s3"
  name   = var.bucket_name
}

module "jenkins-agent-key" {
  source     = "../modules/key-pair"
  key_name   = var.jenkins_agent_key_name
  public_key = var.jenkins_agent_public_key
}

module "instance-profiles" {
  source        = "../modules/iam-instance-profile"
  module_prefix = var.project_name
  s3_bucket_arn = module.s3.arn
}

# Jenkins Controller EC2 (Web UI, orchestration only)
module "jenkins-controller" {
  source               = "../modules/ec2"
  module_prefix        = "${var.project_name}-controller"
  vpc_id               = module.network.vpc_id
  subnet_id            = module.network.jenkins_sub_a_id
  sg_id                = module.security-group.jenkins_controller_sg_id
  ami_id               = data.aws_ami.ubuntu_2204.id
  iam_instance_profile = module.instance-profiles.jenkins_controller_ec2_instance_profile_name
  instance_type        = "t3.micro" # Controller only orchestrates, doesn't run builds
  user_data            = filebase64("${path.module}/user-data-scripts/jenkins-controller.sh")
}

# Jenkins Agent EC2 (Build execution, SSM commands, S3 access)
module "jenkins-agent" {
  source               = "../modules/ec2"
  module_prefix        = "${var.project_name}-agent"
  vpc_id               = module.network.vpc_id
  subnet_id            = module.network.jenkins_sub_b_id
  sg_id                = module.security-group.jenkins_agent_sg_id
  ami_id               = data.aws_ami.ubuntu_2204.id
  iam_instance_profile = module.instance-profiles.jenkins_agent_ec2_instance_profile_name
  instance_type        = "t3.small" # Agent runs build jobs, needs more resources
  user_data            = filebase64("${path.module}/user-data-scripts/jenkins-agent.sh")
  key_name             = module.jenkins-agent-key.key_name
}

module "alb" {
  source        = "../modules/alb"
  module_prefix = var.project_name
  alb_sg_id     = module.security-group.alb_sg_id
  pub_sub_a_id  = module.network.pub_sub_a_id
  pub_sub_b_id  = module.network.pub_sub_b_id
  vpc_id        = module.network.vpc_id
}

module "asg" {
  source                        = "../modules/asg"
  module_prefix                 = var.project_name
  sg_id                         = module.security-group.web_sg_id
  sub_a_id                      = module.network.pub_sub_a_id
  sub_b_id                      = module.network.pub_sub_b_id
  tg_arn                        = module.alb.tg_arn
  ami_id                        = data.aws_ami.amazon_linux.id
  asg_health_check_grace_period = 300
  iam_instance_profile          = module.instance-profiles.app_ec2_instance_profile_arn
  instance_role_tag_key         = var.instance_role_tag_key
  instance_role_tag_value       = var.instance_role_tag_value
  user_data                     = filebase64("${path.module}/user-data-scripts/nginx-deploy.sh")
}
