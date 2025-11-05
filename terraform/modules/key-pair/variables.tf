variable "key_name" {
  description = "The name of the SSH key pair"
  type        = string
}

variable "public_key" {
  description = "The public key material (content of .pub file)"
  type        = string
}
