output "api-credentials" {
  value     = random_password.api-password.result
  sensitive = true
}

output "wallet-credentials" {
  value     = random_password.wallet-password.result
  sensitive = true
}