output "pages_url" {
  description = "Cloudflare Pages deployment URL"
  value       = "https://${cloudflare_pages_project.luvandre.name}.pages.dev"
}

output "custom_domain" {
  description = "Custom domain CNAME record"
  value       = "${var.domain} → ${cloudflare_dns_record.blog_pages.content}"
}
