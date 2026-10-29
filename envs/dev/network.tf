# Reused from the aws-platform-as-code repository, pinned to an exact commit.
module "network" {
  source = "git::https://github.com/fiehna-hue/aws-platform-as-code.git//modules/network?ref=e196efcfb4042da44b4e880d1f7c8eecaec6a7e8"

  name                    = "inventory-eks"
  cidr                    = "10.50.0.0/16"
  map_public_ip_on_launch = true
}
