output "server_ipv4" {
  description = "Public IPv4 address of the blog server"
  value       = hcloud_server.blog.ipv4_address
}

output "server_ipv6" {
  description = "Public IPv6 address of the blog server"
  value       = hcloud_server.blog.ipv6_address
}

output "volume_id" {
  description = "ID of the attached data volume"
  value       = hcloud_volume.data.id
}

output "ssh_command" {
  description = "SSH command to connect to the server (use 1Password SSH agent)"
  value       = "ssh root@${hcloud_server.blog.ipv4_address}"
}

output "dns_a_record" {
  description = "Cloudflare A record — IPv4"
  value       = "${var.domain} → ${cloudflare_dns_record.blog_a.content}"
}

output "dns_aaaa_record" {
  description = "Cloudflare AAAA record — IPv6"
  value       = "${var.domain} → ${cloudflare_dns_record.blog_aaaa.content}"
}

output "op_ssh_key_item" {
  description = "1Password item holding the server SSH keypair"
  value       = data.onepassword_item.blog_ssh_key.title
}
