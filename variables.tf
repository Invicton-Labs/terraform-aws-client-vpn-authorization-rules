variable "authorization_rules" {
  description = "A list of Client VPN subnet access authorizations."
  type = list(object({
    description          = optional(string, "")
    target_network_cidr  = string
    access_group_id      = optional(string)
    authorize_all_groups = optional(bool, false)
  }))
  nullable = false

  // Ensure there are no rules with neither the access group ID nor the all groups set
  validation {
    condition = length([
      for idx, rule in var.authorization_rules :
      idx
      if rule.access_group_id == null && (rule.authorize_all_groups == null || rule.authorize_all_groups == false)
    ]) == 0
    error_message = "Authorization rules at indecies [${join(", ", [
      for idx, rule in var.authorization_rules :
      idx
      if rule.access_group_id == null && (rule.authorize_all_groups == null || rule.authorize_all_groups == false)
    ])}] must either provide an `access_group_id` or have `authorize_all_groups` set to `true`."
  }

  // Ensure there are no rules with both the access group ID and all groups set
  validation {
    condition = length([
      for idx, rule in var.authorization_rules :
      idx
      if rule.access_group_id != null && rule.authorize_all_groups == true
    ]) == 0
    error_message = "Authorization rules at indecies [${join(", ", [
      for idx, rule in var.authorization_rules :
      idx
      if rule.access_group_id != null && rule.authorize_all_groups == true
    ])}] have both an `access_group_id` provided and `authorize_all_groups` set to `true`, but these are mutually exclusive."
  }

  // Ensure all CIDR targets are valid
  validation {
    condition = length([
      for idx, rule in var.authorization_rules :
      idx
      if !can(cidrhost(rule.target_network_cidr, 0))
    ]) == 0
    error_message = "Authorization rules at indecies [${join(", ", [
      for idx, rule in var.authorization_rules :
      idx
      if !can(cidrhost(rule.target_network_cidr, 0))
    ])}] have invalid CIDR blocks in the `target_network_cidr` field."
  }
}

variable "merged_rule_description_joiner" {
  description = "The string to use for joining authorization rule descriptions when multiple rules are merged into one CIDR."
  type        = string
  default     = "; "
  nullable    = false
}
