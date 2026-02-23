variable "vnet_data" {
  default = {
    "hub"   = "10.100.0.0/16"
    "spoke" = "10.50.0.0/16"
  }
}

variable "database_password" {
  description = "The database password"
  type        = string
  sensitive   = true
}
variable "docker_password" {
  description = "The Docker registry password"
  type        = string
  sensitive   = true
}