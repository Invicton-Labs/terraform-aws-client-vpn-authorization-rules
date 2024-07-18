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

NOTE: we use ternary operators instead of &&/|| throughout because it enables lazy evaluation, thereby speeding up the process by not running unnecessary checks.
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
        description = join(var.merged_rule_description_joiner, [for contained in cidr_data.contains : "${contained.metadata.description} [${contained.cidr}]"])
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

  // Remove any rules that are covered by "everyone" rules. This is possible because:
  // - any smaller rules that are subsets of a given rule will also be removed if the given rule
  //   is removed, as it will also be covered by the same everyone rule. Therefore, there is no
  //   need to duplicate the longer prefix path of that smaller rule.
  // - any larger rule that subsumes a given rule, which is also covered by an everyone rule,
  //   will also be removed. Therefore, there is no reason to keep this smaller prefix path rule.
  // - any larger rule that is larger than the everyone rule will not be considered in AWS routing
  //   evaluation, as the everyone rule will have a longer prefix length and will be considered first.
  rules_with_everyone_duplicates_removed = contains(keys(local.rules_with_first_last_decimal), local.everyone_group_uuid) ? {
    for group_id, rules in local.rules_with_first_last_decimal :
    group_id => [
      for rule in rules :
      rule
      if(
        // If it's an everyone group rule, it has to remain
        group_id == local.everyone_group_uuid ? true : (
          // Always include it if it's not subsumed by an everyone rule
          length([
            for everyone_rule in local.rules_with_first_last_decimal[local.everyone_group_uuid] :
            true
            if(
              rule.group_id != local.everyone_group_uuid ? (
                everyone_rule.first_ip_decimal <= rule.first_ip_decimal ? (
                  everyone_rule.last_ip_decimal >= rule.last_ip_decimal
                ) : false
              ) : false
            )
          ]) == 0
        )
      )
    ]
    // If there are no everyone rules, skip and move on
  } : local.rules_with_first_last_decimal

  // Create a flat list of all rules across all groups.
  all_rules_with_everyone_meta = concat(values(local.rules_with_everyone_duplicates_removed)...)

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
          description              = "${rule.description} (covering longer prefix path from \"${compare_rule.description}\")"
          group_id                 = rule.group_id
          extra_due_to_other_group = true
        })
        if(
          // Only consider rules from other groups
          compare_rule.group_id != rule.group_id ? (
            // That other group can't be the everyone group, since the everyone group would provide access
            // to this group as well anyways.
            compare_rule.group_id != local.everyone_group_uuid ? (
              // We don't need to add a duplicate of the compare rule for this rule if it's identical, since that wouldn't accomplish anything.
              !(compare_rule.first_ip_decimal == rule.first_ip_decimal ? compare_rule.last_ip_decimal == rule.last_ip_decimal : false) ? (
                // The compare rule needs to be subsumed by this rule (longer prefix length).
                (rule.first_ip_decimal <= compare_rule.first_ip_decimal ? rule.last_ip_decimal >= compare_rule.last_ip_decimal : false)
              ) : false
            ) : false
          ) : false
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
        rule.extra_due_to_other_group ? true : (
          (
            // Keep it if none of the merged CIDRs of required added rules subsume this CIDR
            length([
              for compare_rule in module.merge_cidr_for_redundancy_check.merged_cidr_sets_ipv4_with_meta[group_id] :
              true
              if(compare_rule.first_ip_decimal <= rule.first_ip_decimal ? compare_rule.last_ip_decimal >= rule.last_ip_decimal : false)
            ]) == 0
          )
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
}
