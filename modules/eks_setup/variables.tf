variable "cluster_name" {}
variable "oidc_provider_arn" {}
variable "oidc_issuer" {}
variable "public_subnet_ids" {
  type = list(string)
}
variable "private_subnet_ids" {
  type = list(string)
}