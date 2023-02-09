output "hostname" {
  value = aws_instance.k3s.public_dns
}

output "ip" {
  value = aws_instance.k3s.public_ip
}