terraform {
  required_version = ">= 1.6"

  required_providers {
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.2"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
  backend "s3" {

  }
}

provider "onepassword" {
  service_account_token = var.op_service_account_token
}

# Fetch the Cloudflare API token stored in 1Password.
data "onepassword_item" "cloudflare_token" {
  vault = var.op_vault_id
  title = var.op_cloudflare_item_title
}

provider "cloudflare" {
  api_token = data.onepassword_item.cloudflare_token.credential
}

# ── Cloudflare Pages project ──────────────────────────────────────────────────

resource "cloudflare_pages_project" "luvandre" {
  account_id        = var.cloudflare_account_id
  name              = "luvandre"
  production_branch = "hugo"

  build_config = {
    build_command   = "hugo --minify"
    destination_dir = "public"
    root_dir        = "/"
  }

  deployment_configs = {
    preview = {}
    production = {
      env_vars = {
        HUGO_VERSION = {
          type  = "plain_text"
          value = "0.148.0"
        }
      }
    }
  }

  source = {
    type = "github"
    config = {
      owner                          = "alexrf45"
      repo_name                      = "musings"
      production_branch              = "hugo"
      pr_comments_enabled            = true
      deployments_enabled            = true
      production_deployments_enabled = true
      preview_deployment_setting     = "custom"
      preview_branch_includes        = ["hugo"]
    }
  }
}

# ── Custom domain ─────────────────────────────────────────────────────────────

resource "cloudflare_pages_domain" "luvandre" {
  name         = "luvandre.com"
  account_id   = var.cloudflare_account_id
  project_name = cloudflare_pages_project.luvandre.name
}

# ── DNS — CNAME pointing to Cloudflare Pages ─────────────────────────────────
# proxied = true enables Cloudflare CDN and custom domain routing for Pages.

resource "cloudflare_dns_record" "blog_pages" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain
  type    = "CNAME"
  content = "${cloudflare_pages_project.luvandre.name}.pages.dev"
  ttl     = 1
  proxied = true
}
