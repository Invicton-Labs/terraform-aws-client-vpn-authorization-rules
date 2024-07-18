module "vpn_authorization_rules" {
  source = "../"
  authorization_rules = [
    # {
    #   #description          = "192.168.0.0/23 everyone"
    #   target_network_cidr  = "192.168.0.0/23"
    #   authorize_all_groups = true
    # },
    # {
    #   description         = "192.168.1.0/24 dev"
    #   target_network_cidr = "192.168.1.0/24"
    #   access_group_id     = "dev"
    # },
    # {
    #   description         = "192.168.1.0/24 admin"
    #   target_network_cidr = "192.168.1.0/24"
    #   access_group_id     = "admin"
    # },
    # {
    #   description         = "192.168.8.0/24 admin"
    #   target_network_cidr = "192.168.8.0/24"
    #   access_group_id     = "admin"
    # },
    # {
    #   description         = "192.168.8.1/32 dev"
    #   target_network_cidr = "192.168.8.1/32"
    #   access_group_id     = "dev"
    # },
    # {
    #   description         = "192.168.20.0/24 admin"
    #   target_network_cidr = "192.168.20.0/24"
    #   access_group_id     = "admin"
    # },
    # {
    #   description         = "192.168.20.0/25 dev"
    #   target_network_cidr = "192.168.20.0/25"
    #   access_group_id     = "dev"
    # },
    # {
    #   description         = "192.168.20.128/25 dev"
    #   target_network_cidr = "192.168.20.128/25"
    #   access_group_id     = "test"
    # },

    # {
    #   description         = "0.0.0.0/0 bigadmin"
    #   target_network_cidr = "0.0.0.0/0"
    #   access_group_id     = "bigadmin"
    # },
    # {
    #   description          = "0.0.0.0/1 everyone"
    #   authorize_all_groups = true
    #   target_network_cidr  = "0.0.0.0/1"
    # },
    # {
    #   description         = "0.0.0.0/16 dev2"
    #   target_network_cidr = "0.0.0.0/16"
    #   access_group_id     = "dev2"
    # },
    {
      description         = "1.0.0.0/16 bigadmin"
      target_network_cidr = "1.0.0.0/16"
      access_group_id     = "bigadmin"
    },
    {
      description          = "1.0.0.0/17 everyone"
      authorize_all_groups = true
      target_network_cidr  = "1.0.0.0/17"
    },
    {
      description         = "1.0.0.0/18 dev2"
      target_network_cidr = "1.0.0.0/18"
      access_group_id     = "dev2"
    },
  ]
  client_vpn_endpoint_id = "my-client-vpn"
}

output "vpn_authorization_rules" {
  value = module.vpn_authorization_rules
}
