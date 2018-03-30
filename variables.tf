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
  default     = "consuelo"
}

variable "image_regex" {
  description = "The expression to find the managed Azure image that should be deployed to the consul cluster."
  default     = "com.lgc.vault-centos-7.3-v*"
}

variable "admin_user_name" {
  default = "haladmin"
}

variable "public_ssh_key_data" {
  description = "The SSH public key that will be added to SSH authorized_users on the consul instances"
}

variable "allowed_inbound_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the Azure Instances will allow connections to Consul"
  type        = "list"
  default     = ["10.0.0.0/16"]
}

variable "gossip_encryption_key" {
  description = "The encryption key for consul to encrypt gossip traffic"
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

variable "cluster_tag_key" {
  description = "The tag the Azure Instances will look for to automatically discover each other and form a cluster."
  default     = "consul-servers"
}
