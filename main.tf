locals {
  // We need a unique key for the "everyone" (all users) rules,
  // so we use a UUIDv4 for it that should never appear as a group ID.
  // Unless, of course, you look at this module and try to break it by
  // purposefully using this UUID as a group ID. But you wouldn't do that...
  everyone_group_uuid = "eb8325b4-c0c4-4b49-962f-71a5949efb24"

  // All rules, with the everyone group UUID added for all-user rules
  all_rules_initial = {
    for key, value in var.authorization_rules :
    key => value.authorize_all_groups ? merge(value, {
      access_group_id = local.everyone_group_uuid
    }) : value
  }

  // A list of all group IDs that are used in any rule
  all_group_ids = distinct([
    for rule in local.all_rules_initial :
    rule.access_group_id
  ])

  // Categorize the rules by group
  rules_by_group = {
    for group_id in local.all_group_ids :
    (group_id == null ? tonumber(0) : tostring(group_id)) => {
      for key, value in local.all_rules_initial :
      key => value.description == "" ? merge(value, {
        description = "${value.authorize_all_groups ? "ALL_USERS" : value.access_group_id}:${value.target_network_cidr}"
      }) : value
      if value.access_group_id == group_id
    }
  }
}

/*
For each rule:
1. If there's a larger rule for the same group, delete the smaller one (done with CIDR merging module)
2. If there's nothing smaller within the CIDR or larger that covers the CIDR, AND there's an everyone rule that covers it, delete it (done in rules_with_everyone_duplicates_removed)
3. If there's a smaller one within the CIDR for another group, add that smaller one specifically (done in rules_with_additional_cidrs)
4. If a larger CIDR is entirely completed by smaller CIDRs that are required, delete the larger one (done in rules_with_unnecessary_larger_removed)
*/

// Start by reducing all rules within each group to the minimum set.
module "cidr_merge" {
  source  = "Invicton-Labs/merge-cidrs/null"
  version = "~>0.1.0"
  cidr_sets_ipv4 = {
    for group_id, rules in local.rules_by_group :
    group_id => [
      for rule in rules :
      {
        cidr = rule.target_network_cidr
        metadata = {
          description = rule.description
        }
      }
    ]
  }
}

locals {
  // Use our merged rules to create a new set of rules for each group, with additional metadata.
  merged_rules = {
    for group_id, cidr_datas in module.cidr_merge.merged_cidr_sets_ipv4_with_meta :
    group_id => [
      for cidr_data in cidr_datas :
      {
        group_id    = group_id
        cidr        = cidr_data.cidr
        description = join(var.merged_rule_description_joiner, [for contained in cidr_data.contains : contained.metadata.description])
        first_ip    = cidrhost(cidr_data.cidr, 0)
        last_ip     = cidrhost(cidr_data.cidr, pow(2, 32 - tonumber(split("/", cidr_data.cidr)[1])) - 1)
      }
    ]
  }

  // Add decimal conversions of the first and last IPs for each rule.
  rules_with_first_last_decimal = {
    for group_id, rules in local.merged_rules :
    group_id => [
      for rule in rules :
      merge(rule, {
        first_ip_decimal = pow(2, 24) * tonumber(split(".", rule.first_ip)[0]) + pow(2, 16) * tonumber(split(".", rule.first_ip)[1]) + pow(2, 8) * tonumber(split(".", rule.first_ip)[2]) + tonumber(split(".", rule.first_ip)[3])
        last_ip_decimal  = pow(2, 24) * tonumber(split(".", rule.last_ip)[0]) + pow(2, 16) * tonumber(split(".", rule.last_ip)[1]) + pow(2, 8) * tonumber(split(".", rule.last_ip)[2]) + tonumber(split(".", rule.last_ip)[3])
      })
    ]
  }

  // Add a field that indicates if this rule is covered by an everyone group rule,
  // i.e. if an everyone rule would provide the same access if this rule didn't exist.
  rules_with_everyone_meta = {
    for group_id, rules in local.rules_with_first_last_decimal :
    group_id => [
      for rule in rules :
      merge(rule, {
        covered_by_everyone_rule = length([
          for everyone_rule in local.rules_with_first_last_decimal[local.everyone_group_uuid] :
          true
          if(
            rule.group_id != local.everyone_group_uuid ? (
              everyone_rule.first_ip_decimal <= rule.first_ip_decimal ? (
                everyone_rule.last_ip_decimal >= rule.last_ip_decimal
              ) : false
            ) : false
          )
        ]) > 0
      })
    ]
  }

  // Create a flat list of all rules across all groups.
  all_rules_with_everyone_meta = concat(values(local.rules_with_everyone_meta)...)

  // Remove any rules where the same access is granted by an everyone rule.
  // There are many conditions to doing this, check the comments within.
  rules_with_everyone_duplicates_removed = {
    for group_id, rules in local.rules_with_everyone_meta :
    group_id => [
      for rule in rules :
      rule
      if(
        // If it's an everyone group rule, it has to remain
        group_id == local.everyone_group_uuid ||
        // Always include it if it's not subsumed by an everyone rule
        !rule.covered_by_everyone_rule ||
        // OR, if there's any other CIDR from a different group that includes this one, or is a part of this one.
        length([
          for compare_rule in local.all_rules_with_everyone_meta :
          true
          if(
            // The rule has to be for a different group to qualify
            compare_rule.group_id != rule.group_id &&
            // That other group can't be the everyone group, since we're considering deleting in favour of the everyone group rule
            compare_rule.group_id != local.everyone_group_uuid &&
            // The rule can't be one that is covered by an everyone rule, since we'd like to disappear that rule too.
            !compare_rule.covered_by_everyone_rule &&
            (
              // The other rule subsumes this rule, OR
              (compare_rule.first_ip_decimal <= rule.first_ip_decimal && compare_rule.last_ip_decimal >= rule.last_ip_decimal) ||
              // The other rule is subsumed by this one
              (rule.first_ip_decimal <= compare_rule.first_ip_decimal && rule.last_ip_decimal >= compare_rule.last_ip_decimal)
            ) &&
            // There can't be an everyone rule that is the same size or smaller than the compare rule
            length([
              for everyone_rule in local.rules_with_first_last_decimal[local.everyone_group_uuid] :
              true
              if(
                // The everyone rule has to subsume this rule
                (everyone_rule.first_ip_decimal <= rule.first_ip_decimal && everyone_rule.last_ip_decimal >= rule.last_ip_decimal) &&
                // The everyone rule has to be subsumed by the compare rule
                (compare_rule.first_ip_decimal <= everyone_rule.first_ip_decimal && compare_rule.last_ip_decimal >= everyone_rule.last_ip_decimal)
              )
            ]) == 0
          )
        ]) > 0
      )
    ]
  }

  // For each rule, add additional rules to match any longer-prefix rules for other groups.
  rules_with_additional_cidrs = {
    for group_id, rules in local.rules_with_everyone_duplicates_removed :
    group_id => flatten([
      for rule in rules :
      concat([
        merge(rule, {
          extra_due_to_other_group = false
        })
        ], [
        for compare_rule in local.all_rules_with_everyone_meta :
        merge(compare_rule, {
          description              = "${rule.description} (covering longest prefix path from \"${compare_rule.description}\")"
          group_id                 = rule.group_id
          extra_due_to_other_group = true
        })
        if(
          // Only consider rules from other groups
          compare_rule.group_id != rule.group_id &&
          // That other group can't be the everyone group, since the everyone group would provide access
          // to this group as well anyways.
          compare_rule.group_id != local.everyone_group_uuid &&
          // We don't need to add a duplicate of the compare rule for this rule if it's identical, since that wouldn't accomplish anything.
          !(compare_rule.first_ip_decimal == rule.first_ip_decimal && compare_rule.last_ip_decimal == rule.last_ip_decimal) &&
          // The compare rule needs to be subsumed by this rule (longer prefix length).
          (rule.first_ip_decimal <= compare_rule.first_ip_decimal && rule.last_ip_decimal >= compare_rule.last_ip_decimal)
        )
      ])
    ])
  }

  // For each group, eliminate any duplicate rules by only taking the first rule for each distinct CIDR.
  // Duplicates may exist if the same extra rule was added once each for multiple other groups.
  rules_with_additional_cidrs_distinct = {
    for group_id, rules in local.rules_with_additional_cidrs :
    group_id => [
      for cidr in distinct([for rule in rules : rule.cidr]) :
      [
        for rule in rules :
        rule
        if rule.cidr == cidr
      ][0]
    ]
  }
}

// For each group, merge all of the rules that are required for longer prefixes in other groups.
module "merge_cidr_for_redundancy_check" {
  source  = "Invicton-Labs/merge-cidrs/null"
  version = "~>0.1.0"
  cidr_sets_ipv4 = {
    for group_id, rules in local.rules_with_additional_cidrs_distinct :
    group_id => [
      for rule in rules :
      {
        cidr = rule.cidr
      }
      if rule.extra_due_to_other_group
    ]
  }
}

locals {
  // Remove any rules that weren't added due to longer prefixes existing in other groups,
  // and that are redundant because the entire range is covered by smaller groups that WERE
  // added due to longer prefixes existing in other groups.
  rules_with_unnecessary_larger_removed = {
    for group_id, rules in local.rules_with_additional_cidrs_distinct :
    group_id => [
      for rule in rules :
      rule
      if(
        // Keep it if it had to be added due to a smaller prefix in another group
        rule.extra_due_to_other_group ||
        (
          // Keep it if none of the merged CIDRs of required added rules subsume this CIDR
          length([
            for compare_rule in module.merge_cidr_for_redundancy_check.merged_cidr_sets_ipv4_with_meta[group_id] :
            true
            if(compare_rule.first_ip_decimal <= rule.first_ip_decimal && compare_rule.last_ip_decimal >= rule.last_ip_decimal)
          ]) == 0
        )
      )
    ]
  }

  // The full set of rules, formatted with the fields expected by aws_ec2_client_vpn_authorization_rule
  all_rules = {
    for rule in flatten(values(local.rules_with_unnecessary_larger_removed)) :
    "${rule.group_id}|${rule.cidr}" => {
      target_network_cidr  = rule.cidr
      authorize_all_groups = rule.group_id == local.everyone_group_uuid ? true : null
      access_group_id      = rule.group_id == local.everyone_group_uuid ? null : rule.group_id
      description          = rule.description
    }
  }

  # TODO: replace and/or with ternary
}

// If desired, create the rules
# resource "aws_ec2_client_vpn_authorization_rule" "this" {
#   for_each               = var.create_rules ? local.all_rules : {}
#   client_vpn_endpoint_id = var.client_vpn_endpoint_id
#   target_network_cidr    = each.value.target_network_cidr
#   authorize_all_groups   = each.value.authorize_all_groups
#   access_group_id        = each.value.access_group_id
#   description            = each.value.description
# }
