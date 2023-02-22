# Add a record to the domain
resource "cloudflare_record" "cloudflare_dns" {
  count   = var.is_https ? 1 : 0
  zone_id = var.cloudflare_zone
  name    = var.subdomain
  value   = aws_instance.k3s.public_ip
  type    = "A"
}
