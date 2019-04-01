provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

data "aws_caller_identity" "current" {}

locals {
  product_domain = "michael"
  environment_type = "dev"
  eks_cluster_name    = "${var.region}-${local.product_domain}-${local.environment_type}-ops"
  eks_cluster_context = "arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${local.eks_cluster_name}"
}

module "aws_fluentd_es_docker" {
  source = "github.com/greermichael/terraform-aws-docker-ecr"

  git_repo_url    = "https://github.com/greermichael/fluentd-aws-elasticsearch.git"
  repository_name = "aws-fluentd-elasticsearch"
}

module "logging_infrastructure" {
  source = "github.com/greermichael/terraform-aws-logging"

  region                                        = "${var.region}"
  vpc_id                                        = "${var.vpc_id}"
  subnet_ids                                    = "${var.subnet_ids}"
  config_context                                = "${local.eks_cluster_context}"
  elasticsearch_domain_name                     = "${local.eks_cluster_name}"
  fluentd_aws_elasticsearch_image_url           = "${module.aws_fluentd_es_docker.aws_ecr_repository}"
  elasticsearch_dedicated_master_instance_count = "${var.instance_count}"
  elasticsearch_instance_count                  = "${var.instance_count}"
}
