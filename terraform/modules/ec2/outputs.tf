output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.this.public_ip
}

output "public_dns" {
  description = "The public DNS name of the EC2 instance"
  value       = aws_instance.this.public_dns
}

output "private_dns" {
  description = "The private DNS name of the EC2 instance"
  value       = aws_instance.this.private_dns
}
