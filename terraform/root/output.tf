output "project-url" {
  value = "http://${var.sub_domain}.${var.hosted_zone_name}"
}

output "alb-alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "jenkins-controller-url" {
  value = "http://${module.jenkins-controller.public_ip}:8080"
}

output "jenkins-controller-webhook" {
  value = "http://${module.jenkins-controller.public_ip}:8080/github-webhook/"
}

output "jenkins-agent-public-dns" {
  description = "Public DNS hostname of Jenkins Agent (for SSH connection setup)"
  value       = module.jenkins-agent.public_dns
}

output "jenkins-agent-private-dns" {
  description = "Private DNS hostname of Jenkins Agent (for internal SSH connection)"
  value       = module.jenkins-agent.private_dns
}

output "jenkins-agent-public-ip" {
  description = "Public IP of Jenkins Agent"
  value       = module.jenkins-agent.public_ip
}

output "s3-bucket-name" {
  value = var.bucket_name
}
