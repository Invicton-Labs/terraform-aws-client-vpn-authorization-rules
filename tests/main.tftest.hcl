variables {
  input_output_pairs = [
    [
      // Input
      [
        {
          target_network_cidr = "1.0.0.0/16"
          access_group_id     = "admin"
        },
        {
          target_network_cidr  = "1.0.0.0/17"
          authorize_all_groups = true
        },
        {
          target_network_cidr = "1.0.0.0/18"
          access_group_id     = "dev"
        },
      ],

      // Output
      {
        "admin|1.0.0.0/16" = {
          access_group_id      = "admin"
          authorize_all_groups = null
          target_network_cidr  = "1.0.0.0/16"
        }
        "eb8325b4-c0c4-4b49-962f-71a5949efb24|1.0.0.0/17" = {
          access_group_id      = null
          authorize_all_groups = true
          target_network_cidr  = "1.0.0.0/17"
        }
      },
    ],

    [
      [
        {
          target_network_cidr  = "192.168.0.0/23"
          authorize_all_groups = true
          description          = "192.168.0.0/23 everyone"
        },
        {
          target_network_cidr = "192.168.1.0/24"
          access_group_id     = "admin"
          description         = "192.168.1.0/24 admin"
        },
        {
          target_network_cidr = "192.168.8.0/24"
          access_group_id     = "admin"
          description         = "192.168.8.0/24 admin"
        },
        {
          target_network_cidr = "192.168.20.0/24"
          access_group_id     = "admin"
          description         = "192.168.20.0/24 admin"
        },
        {
          target_network_cidr = "200.100.2.0/24"
          access_group_id     = "admin"
          description         = "200.100.2.0/24 admin"
        },
        {
          target_network_cidr = "200.100.3.0/24"
          access_group_id     = "admin"
          description         = "200.100.3.0/24 admin"
        },
        {
          target_network_cidr = "192.168.8.1/32"
          access_group_id     = "dev"
          description         = "192.168.8.1/32 dev"
        },
        {
          target_network_cidr = "192.168.1.0/24"
          access_group_id     = "dev"
          description         = "192.168.1.0/24 dev"
        },
        {
          target_network_cidr = "192.168.20.0/25"
          access_group_id     = "dev"
          description         = "192.168.20.0/25 dev"
        },
        {
          target_network_cidr = "192.168.20.128/25"
          access_group_id     = "test"
          description         = "192.168.20.128/25 dev"
        },
        {
          target_network_cidr = "0.0.0.0/16"
          access_group_id     = "testers"
          description         = "0.0.0.0/16 testers"
        },
        {
          target_network_cidr = "0.0.0.0/0"
          access_group_id     = "superadmin"
          description         = "0.0.0.0/0 superadmin"
        },
        {
          target_network_cidr  = "0.0.0.0/1"
          authorize_all_groups = true
          description          = "0.0.0.0/1 everyone"
        },
      ],
      {
        "admin|192.168.20.0/25" = {
          access_group_id      = "admin"
          authorize_all_groups = null
          description          = "192.168.20.0/24 admin (covering longest prefix path from \"192.168.20.0/25 dev\")"
          target_network_cidr  = "192.168.20.0/25"
        }
        "admin|192.168.20.128/25" = {
          access_group_id      = "admin"
          authorize_all_groups = null
          description          = "192.168.20.0/24 admin (covering longest prefix path from \"192.168.20.128/25 dev\")"
          target_network_cidr  = "192.168.20.128/25"
        }
        "admin|192.168.8.0/24" = {
          access_group_id      = "admin"
          authorize_all_groups = null
          description          = "192.168.8.0/24 admin"
          target_network_cidr  = "192.168.8.0/24"
        }
        "admin|192.168.8.1/32" = {
          access_group_id      = "admin"
          authorize_all_groups = null
          description          = "192.168.8.0/24 admin (covering longest prefix path from \"192.168.8.1/32 dev\")"
          target_network_cidr  = "192.168.8.1/32"
        }
        "admin|200.100.2.0/23" = {
          access_group_id      = "admin"
          authorize_all_groups = null
          description          = "200.100.2.0/24 admin; 200.100.3.0/24 admin"
          target_network_cidr  = "200.100.2.0/23"
        }
        "dev|192.168.20.0/25" = {
          access_group_id      = "dev"
          authorize_all_groups = null
          description          = "192.168.20.0/25 dev"
          target_network_cidr  = "192.168.20.0/25"
        }
        "dev|192.168.8.1/32" = {
          access_group_id      = "dev"
          authorize_all_groups = null
          description          = "192.168.8.1/32 dev"
          target_network_cidr  = "192.168.8.1/32"
        }
        "eb8325b4-c0c4-4b49-962f-71a5949efb24|0.0.0.0/1" = {
          access_group_id      = null
          authorize_all_groups = true
          description          = "0.0.0.0/1 everyone"
          target_network_cidr  = "0.0.0.0/1"
        }
        "eb8325b4-c0c4-4b49-962f-71a5949efb24|192.168.0.0/23" = {
          access_group_id      = null
          authorize_all_groups = true
          description          = "192.168.0.0/23 everyone"
          target_network_cidr  = "192.168.0.0/23"
        }
        "superadmin|0.0.0.0/0" = {
          access_group_id      = "superadmin"
          authorize_all_groups = null
          description          = "0.0.0.0/0 superadmin"
          target_network_cidr  = "0.0.0.0/0"
        }
        "superadmin|192.168.20.0/24" = {
          access_group_id      = "superadmin"
          authorize_all_groups = null
          description          = "0.0.0.0/0 superadmin (covering longest prefix path from \"192.168.20.0/24 admin\")"
          target_network_cidr  = "192.168.20.0/24"
        }
        "superadmin|192.168.20.0/25" = {
          access_group_id      = "superadmin"
          authorize_all_groups = null
          description          = "0.0.0.0/0 superadmin (covering longest prefix path from \"192.168.20.0/25 dev\")"
          target_network_cidr  = "192.168.20.0/25"
        }
        "superadmin|192.168.20.128/25" = {
          access_group_id      = "superadmin"
          authorize_all_groups = null
          description          = "0.0.0.0/0 superadmin (covering longest prefix path from \"192.168.20.128/25 dev\")"
          target_network_cidr  = "192.168.20.128/25"
        }
        "superadmin|192.168.8.0/24" = {
          access_group_id      = "superadmin"
          authorize_all_groups = null
          description          = "0.0.0.0/0 superadmin (covering longest prefix path from \"192.168.8.0/24 admin\")"
          target_network_cidr  = "192.168.8.0/24"
        }
        "superadmin|192.168.8.1/32" = {
          access_group_id      = "superadmin"
          authorize_all_groups = null
          description          = "0.0.0.0/0 superadmin (covering longest prefix path from \"192.168.8.1/32 dev\")"
          target_network_cidr  = "192.168.8.1/32"
        }
        "superadmin|200.100.2.0/23" = {
          access_group_id      = "superadmin"
          authorize_all_groups = null
          description          = "0.0.0.0/0 superadmin (covering longest prefix path from \"200.100.2.0/24 admin; 200.100.3.0/24 admin\")"
          target_network_cidr  = "200.100.2.0/23"
        }
        "test|192.168.20.128/25" = {
          access_group_id      = "test"
          authorize_all_groups = null
          description          = "192.168.20.128/25 dev"
          target_network_cidr  = "192.168.20.128/25"
        }
      }
    ]
  ]
}

run "execute_0" {
  variables {
    authorization_rules = var.input_output_pairs[0][0]
  }
}

run "assert_0" {
  module {
    source = "./tests/result-comparison"
  }
  variables {
    expected_rules = var.input_output_pairs[0][1]
    actual_rules   = run.execute_0.merged_authorization_rules
  }

  assert {
    condition     = length(output.mismatched_rules) == 0
    error_message = "The following rules were mismatched:\n${jsonencode(output.mismatched_rules)}"
  }
}

run "execute_1" {
  variables {
    authorization_rules = var.input_output_pairs[1][0]
  }
}
run "assert_1" {
  module {
    source = "./tests/result-comparison"
  }
  variables {
    expected_rules = var.input_output_pairs[1][1]
    actual_rules   = run.execute_1.merged_authorization_rules
  }

  assert {
    condition     = length(output.mismatched_rules) == 0
    error_message = "The following rules were mismatched:\n${jsonencode(output.mismatched_rules)}"
  }
}
