resource "aws_key_pair" "ec2_key" {
  key_name   = "k3s_ssh_key"
  public_key = var.public_key
}

resource "aws_instance" "k3s" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.is_https ? "t2.small" : "t2.micro"
  key_name                    = aws_key_pair.ec2_key.key_name
  subnet_id                   = aws_subnet.k3s_subnet.id
  vpc_security_group_ids      = [aws_security_group.security_group.id]
  associate_public_ip_address = true

  tags = {
    Name = "k3s"
  }
}
