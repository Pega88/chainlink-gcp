output "api-credentials" {
  value     = random_password.api-password.result
  sensitive = false
}

output "wallet-credentials" {
  value     = random_password.wallet-password.result
  sensitive = false
}