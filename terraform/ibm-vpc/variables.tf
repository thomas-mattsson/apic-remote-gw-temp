variable "ibmcloud_api_key" {
  sensitive = true
}

variable "name" {
  description = "A given name for the complete structure"
}

variable "ibmcloud_region" {
  default = "eu-de"
}

variable "ibmcloud_zone" {
  default = "eu-de-1"
}

variable "ibmcloud_subnet_cidr" {
  default = "10.10.0.0/24"
}

variable "kube_version" {
  default = "1.24.10"
}

variable "machine_flavor" {
  default = "bx2.16x64"
} 

variable "worker_count" {
  default = "3"
}
