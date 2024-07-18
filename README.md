# Terraform AWS Client VPN Authorization Rule Calculator

This module takes a list of Client VPN authorization rules for zero or more groups and returns a minimal set of authorization rules that is functionally equivalent. This is useful for handling the Client VPN [longest prefix path](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/cvpn-working-rules.html) networking, which can lead to unexpected behaviour as documented [here](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/troubleshooting.html#ad-group-auth-rules). It also minimizes the number of authorization rules that need to be created by merging rules where possible and eliminating redundant rules.

Note that this module **does not** actually create the rules. The set of inputs for rules is returned, and the user can then create the rules or do something else with the result.

The module works by:
1. For each group (considering "all users" rules as a separate group), reduce the rules to the minimum equivalent set by merging CIDR blocks where possible (using the [Invicton-Labs/merge-cidrs/null](https://registry.terraform.io/modules/Invicton-Labs/merge-cidrs/null/latest) module).
2. Remove any rules where the same effect is achieved by an "all-users" rule, as they are redundant.
3. For each remaining rule, if a different group has a rule within the first rule's prefix (but with a longer prefix length), add a rule with the same prefix to the first group. This handles funny behaviour with longest-prefix evaluation.
4. Eliminate any duplicate rules within a single group that may have occurred if the same longer prefix rule was present in multiple other groups (a corresponding one would have been added for each).
5. Eliminate any rules within a group where other, longer-prefix rules within the same group combine to be functionally equivalent.


Example:
```terraform
module "vpn_authorization_rules" {
  source = "Invicton-Labs/client-vpn-authorization-rules/aws"
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
```

```
$ terraform apply -auto-approve

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

merged_authorization_rules = {
  "admin|1.0.0.0/16" = {
    "access_group_id" = "admin"
    "authorize_all_groups" = tobool(null)
    "description" = "Admin 1 [1.0.0.0/16]"
    "target_network_cidr" = "1.0.0.0/16"
  }
  "admin|1.0.128.0/18" = {
    "access_group_id" = "admin"
    "authorize_all_groups" = tobool(null)
    "description" = "Admin 1 [1.0.0.0/16] (covering longer prefix path from \"Dev 2 [1.0.128.0/19]; Dev 3 [1.0.160.0/19]\")"
    "target_network_cidr" = "1.0.128.0/18"
  }
  "dev|1.0.128.0/18" = {
    "access_group_id" = "dev"
    "authorize_all_groups" = tobool(null)
    "description" = "Dev 2 [1.0.128.0/19]; Dev 3 [1.0.160.0/19]"
    "target_network_cidr" = "1.0.128.0/18"
  }
  "eb8325b4-c0c4-4b49-962f-71a5949efb24|1.0.0.0/17" = {
    "access_group_id" = tostring(null)
    "authorize_all_groups" = true
    "description" = "Everyone 1 [1.0.0.0/17]"
    "target_network_cidr" = "1.0.0.0/17"
  }
}
```
