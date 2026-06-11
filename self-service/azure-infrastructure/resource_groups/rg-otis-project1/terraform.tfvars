# Terraform Variables for rg-otis-project1
# This file contains the actual values for variables used in the deployment
# 
# ⚠️ SECURITY WARNING: This file contains sensitive information
# - DO NOT commit this file to version control
# - Add terraform.tfvars to .gitignore
# - Use secure pipeline variables/secrets in CI/CD
# - Rotate passwords regularly

# Azure Location
location = "East US"

# Virtual Machine Admin Password
# Password Requirements:
# - Must be 12-123 characters long
# - Must contain at least 3 of the following:
#   * Uppercase letters (A-Z)
#   * Lowercase letters (a-z)
#   * Numbers (0-9)
#   * Special characters (!@#$%^&*()_+-=[]{}|;:,.<>?)
#
# ⚠️ REPLACE THIS WITH YOUR ACTUAL SECURE PASSWORD
admin_password = "ChangeMe123!SecureP@ssw0rd"

# Optional: Uncomment and customize the VM size if needed
# vm_size = "Standard_B2s"
