variable "namespace_name" {
  default = "awscommunity-nttdata"
  type    = "string"
}

variable "nginx_pod_name" {
  default = "nginx-awscommunity"
  type    = "string"
}

variable "nginx_pod_image" {
  default = "nginx:latest"
  type    = "string"
}
