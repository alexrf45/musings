variable "hcloud_token" {
  description = "Hetzner Cloud API token (read/write)"
  type        = string
  sensitive   = true
}

variable "domain" {
  description = "Domain name for the blog (e.g. blog.fr3d.dev)"
  type        = string
}

variable "server_name" {
  description = "Hetzner server resource name"
  type        = string
  default     = "musings-blog"
}

variable "op_service_account_token" {
  description = "1Password service account token used by the Terraform provider"
  type        = string
  sensitive   = true
}

variable "op_vault_id" {
  description = "UUID of the 1Password vault where infrastructure secrets are stored"
  type        = string
}

variable "op_cloudflare_item_title" {
  description = "Title of the 1Password item that holds the Cloudflare API token (credential field)"
  type        = string
  default     = "Cloudflare API Token"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the domain (found in the Cloudflare dashboard)"
  type        = string
}
