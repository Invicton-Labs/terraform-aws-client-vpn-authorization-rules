run "set_1" {
  variables {
    authorization_rules = [
      # {
      #   description          = "192.168.0.0/23 everyone"
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
      {
        description         = "1.0.0.0/16 bigadmin"
        target_network_cidr = "1.0.0.0/16"
        access_group_id     = "bigadmin"
      },
      {
        description          = "1.0.0.0/15 everyone"
        authorize_all_groups = true
        target_network_cidr  = "1.0.0.0/15"
      },
      {
        description         = "1.0.0.0/18 dev2"
        target_network_cidr = "0.0.0.0/18"
        access_group_id     = "dev2"
      },
    ]
  }

  assert {
    condition = { for k, v in output.merged_authorization_rules : k => {
      access_group_id      = v.access_group_id
      authorize_all_groups = v.authorize_all_groups
      target_network_cidr  = v.target_network_cidr
      }} == {
      "192.168.1.0/24",
      "192.168.2.0/23",
      "192.168.4.0/22",
      "192.168.8.0/24",
    ]
    error_message = "Incorrect respose in set 0: ${jsonencode(output.merged_cidr_sets_ipv4.set-0)}"
  }
}
