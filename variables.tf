# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------

variable "subscription_id" {
  description = "The Azure subscription ID"
}

variable "tenant_id" {
  description = "The Azure tenant ID"
}

variable "client_id" {
  description = "The Azure client ID"
}

variable "client_secret" {
  description = "The Azure secret access key"
}

variable "image_resource_group_name" {}

variable "resource_group_name" {
  description = "The name of the Azure resource group consul will be deployed into. This RG should already exist"
  default     = "catavault"
}

variable "storage_account_name" {
  description = "The name of an Azure Storage Account. This SA should already exist"
  default     = "testconsul"
}

variable "image_regex" {
  description = "The expression to find the managed Azure image that should be deployed to the consul cluster."
  default     = "com.lgc.vault-centos-7.3-v*"
}

variable "admin_user_name" {
  default = "haladmin"
}

variable "private_key_path" {
  default = "~/.ssh/hal_vault_admin_rsa"
}

variable "key_data" {
  description = "The SSH public key that will be added to SSH authorized_users on the consul instances"
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDE/k1xTljO8cw3knf1jsnLhs0QMyCkM1ZlIRiIEAFZtlrkzdTuVDHBFKZmRKBeBH7ozogyeUVnqsaBFdqm8dH7z7Mp5ecCz/bBxOp/XsTSuXSrjgemgdiievFmtwYvIdraEYJr9fUYid6zWrC3tkbM7GVvrS+BKaDwK33QbN99/NQxtGpeWO6ivqhWu4+8KrAeL8rllsAhEzl8JuzOeNRdsVzwjaHgoUfK0d+SfNOJVjNrY8IIdq2Czi+b+iORh4iamwXkefT89Nnk5Ipri/SvliE9GatbHTbMktHsKZ5ZS9Hb0mVAdfevBViPXcZ1Tyamt08r6BIsKQNbbpQ4xYUJxGFm76jU0RbPwjCP8Tg5shn1/SKew56eDRtvIiJV0dp+Mp5R5vzbfrMaCzyZNdvFtdowq9mKc9N+J+9FyMHzgMOFBuwstSC6XuTUF+2nc2NZDYgqTmwgaLOrPkyoOM1FGI9uFGYacGI1ekMY4hcJZ8237I9nCdTyqnJro0rIn2erv3hkZBidBk1jrDCiEJuaiVQ/sWQT/tn06JQBNwny532SnJxBRaPuhUEDMJNoKFh2k6MJ3QPrgr3x2Ygx9/s5dAxwOI/QBy8bkT4gCb3JySi1kozTM3XssWOU4JfziE9fdDQo70yVYhGXcv0RPC1kX5bsoo1/ExeyLDKobhfAyQ== haladmin@core-hal"
}

variable "allowed_inbound_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the Azure Instances will allow connections to Consul"
  type        = "list"
  default     = ["10.0.0.0/16"]
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
variable "location" {
  description = "The Azure region the consul cluster will be deployed in"
  default     = "East US"
}

variable "allowed_ssh_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the Azure Instances will allow SSH connections"
  type        = "list"
  default     = []
}

variable "test_address_space" {
  description = "The supernet for the resources that will be created"
  default     = "10.0.0.0/16"
}

variable "test_subnet_address" {
  description = "The subnet that consul resources will be deployed into"
  default     = "10.0.10.0/24"
}

variable "cluster_name" {
  description = "What to name the Consul cluster and all of its associated resources"
  default     = "consul-example"
}

variable "instance_size" {
  description = "The instance size for the servers"
  default     = "Standard_A1_v2"
}

variable "num_servers" {
  description = "The number of Consul server nodes to deploy. We strongly recommend using 3 or 5."
  default     = 3
}

variable "num_clients" {
  description = "The number of Consul client nodes to deploy. You typically run the Consul client alongside your apps, so set this value to however many Instances make sense for your app code."
  default     = 1
}

variable "cluster_tag_key" {
  description = "The tag the Azure Instances will look for to automatically discover each other and form a cluster."
  default     = "consul-servers"
}
