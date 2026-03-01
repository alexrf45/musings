terraform {
  required_version = ">= 1.6"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.49"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.2"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
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

# ── SSH key ──────────────────────────────────────────────────────────────────
# Generate an ED25519 keypair entirely in Terraform — the private key is held
# in state and written to 1Password; it never touches the local filesystem.

resource "tls_private_key" "blog" {
  algorithm = "ED25519"
}

resource "hcloud_ssh_key" "blog" {
  name       = "${var.server_name}-key"
  public_key = tls_private_key.blog.public_key_openssh
}

# Store the keypair in 1Password so you can SSH in later via the 1Password
# SSH agent without the private key ever being written to disk.
resource "onepassword_item" "blog_ssh_key" {
  vault    = var.op_vault_id
  title    = "${var.server_name}-ssh-key"
  category = "ssh_key"

  section {
    label = "Keypair"

    field {
      label = "private key"
      type  = "CONCEALED"
      value = tls_private_key.blog.private_key_openssh
    }

    field {
      label = "public key"
      type  = "STRING"
      value = tls_private_key.blog.public_key_openssh
    }
  }
}

# ── Firewall ──────────────────────────────────────────────────────────────────
# Allow SSH, HTTP, HTTPS inbound. All outbound traffic is permitted by default.

resource "hcloud_firewall" "blog" {
  name = "${var.server_name}-fw"

  # SSH
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # HTTP (needed for ACME challenge + redirect)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # HTTPS
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # ICMP (ping)
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

# ── Server ────────────────────────────────────────────────────────────────────
# cx22: 2 vCPU (AMD), 4 GB RAM, 40 GB root disk — Frankfurt (fsn1)

resource "hcloud_server" "blog" {
  name         = var.server_name
  server_type  = "cx22"
  image        = "ubuntu-24.04"
  location     = "fsn1"
  ssh_keys     = [hcloud_ssh_key.blog.id]
  firewall_ids = [hcloud_firewall.blog.id]

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    domain = var.domain
  })

  labels = {
    project = "musings"
    env     = "production"
  }
}

# ── Data volume ───────────────────────────────────────────────────────────────
# 50 GB block storage for Postgres data, TLS certs, and nginx state.
# Lives independently of the server so data survives a server rebuild.

resource "hcloud_volume" "data" {
  name     = "${var.server_name}-data"
  size     = 50
  location = "fsn1"
  format   = "ext4"

  labels = {
    project = "musings"
  }
}

resource "hcloud_volume_attachment" "data" {
  volume_id = hcloud_volume.data.id
  server_id = hcloud_server.blog.id
  automount = false # We configure the mount ourselves via remote-exec below
}

# ── Mount volume on first attach ──────────────────────────────────────────────

resource "null_resource" "mount_volume" {
  depends_on = [hcloud_volume_attachment.data, hcloud_server.blog]

  triggers = {
    volume_id = hcloud_volume.data.id
    server_id = hcloud_server.blog.id
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = tls_private_key.blog.private_key_openssh
    host        = hcloud_server.blog.ipv4_address
    timeout     = "3m"
  }

  provisioner "remote-exec" {
    inline = [
      # Wait for cloud-init to finish before mounting
      "cloud-init status --wait",

      # Mount the Hetzner volume at our data path
      "mkdir -p /opt/musings/data",
      "mount -o discard,defaults /dev/disk/by-id/scsi-0HC_Volume_${hcloud_volume.data.id} /opt/musings/data",

      # Persist in fstab
      "echo '/dev/disk/by-id/scsi-0HC_Volume_${hcloud_volume.data.id} /opt/musings/data ext4 discard,defaults 0 0' >> /etc/fstab",

      # Create subdirs used by docker-compose services
      "mkdir -p /opt/musings/data/{postgres,certbot-certs,certbot-www}",

      # Give the deploy user ownership
      "chown -R deploy:deploy /opt/musings/data",
    ]
  }
}

# ── DNS records ───────────────────────────────────────────────────────────────
# DNS-only (proxied = false) so Let's Encrypt ACME challenges reach the server
# directly and fail2ban sees real client IPs in nginx logs.

resource "cloudflare_dns_record" "blog_a" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain
  type    = "A"
  content = hcloud_server.blog.ipv4_address
  ttl     = 300
  proxied = false
}

resource "cloudflare_dns_record" "blog_aaaa" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain
  type    = "AAAA"
  content = hcloud_server.blog.ipv6_address
  ttl     = 300
  proxied = false
}
