variable "kubeconfig" {
  description = "Raw kubeconfig object yaml encoded"
  type        = string
}

variable "cloudprovider" {
  description = "Cloud provider (ibm-vpc, ...)"
  type        = string
}

variable "namespace" {
  description = "The namespace for the apiconnect resources"
  type        = string
  default     = "apic"
}

variable "entitlement-key" {
  description = "IBM entitlement key"
  type        = string
}

variable "apimanager-ca-file" {
  description = "API manager CA file location"
  type        = string
}

variable "ingress-subdomain" {
  description = "The ingress subdomain for the cluster ingress controller"
  type        = string
}
