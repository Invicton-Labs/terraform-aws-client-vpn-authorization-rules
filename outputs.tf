//==================================================
//     Outputs that match the input variables
//==================================================
output "authorization_rules" {
  description = "The value of the `authorization_rules` input variable."
  value       = var.authorization_rules
}
output "merged_rule_description_joiner" {
  description = "The value of the `merged_rule_description_joiner` input variable, or the default value if the input was `null`."
  value       = var.merged_rule_description_joiner
}

//==================================================
//       Outputs generated by this module
//==================================================
output "merged_authorization_rules" {
  description = "The reduced/merged inputs that can/will be used to create the actual rules."
  value       = local.all_rules
}

//==================================================
//             Debugging outputs
//==================================================
# output "_01_all_rules_initial" {
#   value = local.all_rules_initial
# }
# output "_02_all_group_ids" {
#   value = local.all_group_ids
# }
# output "_03_rules_by_group" {
#   value = local.rules_by_group
# }
# output "_04_merged_rules" {
#   value = local.merged_rules
# }
# output "_05_rules_with_first_last_decimal" {
#   value = local.rules_with_first_last_decimal
# }
# output "_06_rules_with_everyone_duplicates_removed" {
#   value = local.rules_with_everyone_duplicates_removed
# }
# output "_07_rules_with_additional_cidrs" {
#   value = local.rules_with_additional_cidrs
# }
# output "_08_rules_with_additional_cidrs_distinct" {
#   value = local.rules_with_additional_cidrs_distinct
# }
# output "_09_merge_cidr_for_redundancy_check" {
#   value = module.merge_cidr_for_redundancy_check.merged_cidr_sets_ipv4_with_meta
# }
# output "_10_rules_with_unnecessary_larger_removed" {
#   value = local.rules_with_unnecessary_larger_removed
# }
