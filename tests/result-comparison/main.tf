variable "expected_rules" {}
variable "actual_rules" {}

locals {
  rule_comparison = merge({
    for key, expected in var.expected_rules :
    key => {
      unexpected = false
      found      = lookup(var.actual_rules, key, null) != null
      access_group_id = lookup(var.actual_rules, key, null) == null ? null : {
        expected = expected.access_group_id
        actual   = var.actual_rules[key].access_group_id
      }
      target_network_cidr = lookup(var.actual_rules, key, null) == null ? null : {
        expected = expected.target_network_cidr
        actual   = var.actual_rules[key].target_network_cidr
      }
    }
    }, {
    for key, unexpected in var.actual_rules :
    key => {
      unexpected          = true
      found               = true
      access_group_id     = null
      target_network_cidr = null
    }
    if lookup(var.expected_rules, key, null) == null
  })

  mismatched_rules = {
    for key, rule in local.rule_comparison :
    key => rule
    if(rule.unexpected ? true : (
      !rule.found ? true : (rule.access_group_id.expected != rule.access_group_id.actual) ? true : (
        rule.target_network_cidr.expected != rule.target_network_cidr.actual
      )
      )
    )
  }
}

output "mismatched_rules" {
  value = local.mismatched_rules
}
