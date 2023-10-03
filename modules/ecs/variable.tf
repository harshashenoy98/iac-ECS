variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "security_group_id" {
  type = string
}

