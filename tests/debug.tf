module "vpn_authorization_rules" {
  source = "../"
  authorization_rules = [
    {
      description         = "Admin 1"
      target_network_cidr = "1.0.0.0/16"
      access_group_id     = "admin"
    },
    {
      description          = "Everyone 1"
      authorize_all_groups = true
      target_network_cidr  = "1.0.0.0/17"
    },
    {
      description         = "Dev 1"
      target_network_cidr = "1.0.0.0/18"
      access_group_id     = "dev"
    },
    {
      description         = "Dev 2"
      target_network_cidr = "1.0.128.0/19"
      access_group_id     = "dev"
    },
    {
      description         = "Dev 3"
      target_network_cidr = "1.0.160.0/19"
      access_group_id     = "dev"
    },
  ]
}

output "merged_authorization_rules" {
  value = module.vpn_authorization_rules.merged_authorization_rules
}
