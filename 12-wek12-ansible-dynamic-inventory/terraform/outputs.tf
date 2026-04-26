output "redhat_db_ips" {
  value = aws_instance.redhat_db[*].public_ip
}

output "redhat_web_ips" {
  value = aws_instance.redhat_web[*].public_ip
}

output "ubuntu_backend_ips" {
  value = aws_instance.ubuntu_backend[*].public_ip
}

output "amazon_env_ips" {
  value = aws_instance.amazon_env[*].public_ip
}