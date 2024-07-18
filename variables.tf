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
      if(
        !can(cidrhost(rule.target_network_cidr, 0))
        #     // Ensure there's one "/"
        #     length(split("/", rule.target_network_cidr)) != 2 ||
        #     // Ensure the IP part has 4 segments
        #     length(split(".", split("/", rule.target_network_cidr)[0])) != 4 ||
        #     // Ensure the prefix length part is an integer
        #     length(regexall("^[0-9]{1,2}$", split("/", rule.target_network_cidr)[1])) == 0 ||
        #     // Ensure the prefix length is a valid value
        #     tonumber(split("/", rule.target_network_cidr)[1]) < 0 ||
        #     tonumber(split("/", rule.target_network_cidr)[1]) > 32 ||
        #     // Ensure the first octet is a valid value
        #     length(regexall("^[0-9]{1,3}$", split(".", split("/", rule.target_network_cidr)[0])[0])) == 0 ||
        #     tonumber(split(".", split("/", rule.target_network_cidr)[0])[0]) < 0 ||
        #     tonumber(split(".", split("/", rule.target_network_cidr)[0])[0]) > 255 ||
        #     // Ensure the second octet is a valid value
        #     length(regexall("^[0-9]{1,3}$", split(".", split("/", rule.target_network_cidr)[0])[1])) == 0 ||
        #     tonumber(split(".", split("/", rule.target_network_cidr)[0])[1]) < 0 ||
        #     tonumber(split(".", split("/", rule.target_network_cidr)[0])[1]) > 255 ||
        #     // Ensure the third octet is a valid value
        #     length(regexall("^[0-9]{1,3}$", split(".", split("/", rule.target_network_cidr)[0])[2])) == 0 ||
        #     tonumber(split(".", split("/", rule.target_network_cidr)[0])[2]) < 0 ||
        #     tonumber(split(".", split("/", rule.target_network_cidr)[0])[2]) > 255 ||
        #     // Ensure the fourth octet is a valid value
        #     length(regexall("^[0-9]{1,3}$", split(".", split("/", rule.target_network_cidr)[0])[3])) == 0 ||
        #     tonumber(split(".", split("/", rule.target_network_cidr)[0])[3]) < 0 ||
        #     tonumber(split(".", split("/", rule.target_network_cidr)[0])[3]) > 255
      )
    ]) == 0
    error_message = "Authorization rules at indecies [${join(", ", [
      for idx, rule in var.authorization_rules :
      idx
      if(
        !can(cidrhost(rule.target_network_cidr, 0))
        #     // Ensure there's one "/"
        #     length(split("/", rule.target_network_cidr)) != 2 ||
        #     // Ensure the IP part has 4 segments
        #     length(split(".", split("/", rule.target_network_cidr)[0])) != 4 ||
        #     // Ensure the prefix length part is an integer
        #     length(regexall("^[0-9]{1,2}$", split("/", rule.target_network_cidr)[1])) == 0 ||
        #     // Ensure the prefix length is a valid value
        #     tonumber(split("/", rule.target_network_cidr)[1]) < 0 ||
        #     tonumber(split("/", rule.target_network_cidr)[1]) > 32 ||
        #     // Ensure the first octet is a valid value
        #     length(regexall("^[0-9]{1,3}$", split(".", split("/", rule.target_network_cidr)[0])[0])) == 0 ||
        #     tonumber(split(".", split("/", rule.target_network_cidr)[0])[0]) < 0 ||
        #     tonumber(split(".", split("/", rule.target_network_cidr)[0])[0]) > 255 ||
        #     // Ensure the second octet is a valid value
        #     length(regexall("^[0-9]{1,3}$", split(".", split("/", rule.target_network_cidr)[0])[1])) == 0 ||
        #     tonumber(split(".", split("/", rule.target_network_cidr)[0])[1]) < 0 ||
        #     tonumber(split(".", split("/", rule.target_network_cidr)[0])[1]) > 255 ||
        #     // Ensure the third octet is a valid value
        #     length(regexall("^[0-9]{1,3}$", split(".", split("/", rule.target_network_cidr)[0])[2])) == 0 ||
        #     tonumber(split(".", split("/", rule.target_network_cidr)[0])[2]) < 0 ||
        #     tonumber(split(".", split("/", rule.target_network_cidr)[0])[2]) > 255 ||
        #     // Ensure the fourth octet is a valid value
        #     length(regexall("^[0-9]{1,3}$", split(".", split("/", rule.target_network_cidr)[0])[3])) == 0 ||
        #     tonumber(split(".", split("/", rule.target_network_cidr)[0])[3]) < 0 ||
        #     tonumber(split(".", split("/", rule.target_network_cidr)[0])[3]) > 255
      )
    ])}] have invalid CIDR blocks in the `target_network_cidr` field."
  }
}

variable "client_vpn_endpoint_id" {
  description = "The ID of the Client VPN endpoint to associate the authorization rules with."
  type        = string
  nullable    = true
}

variable "merged_rule_description_joiner" {
  description = "The string to use for joining authorization rule descriptions when multiple rules are merged into one CIDR."
  type        = string
  default     = "; "
  nullable    = false
}

variable "create_rules" {
  description = "Whether to actually create the Client VPN authorization rules. If `false`, the output `merged_authorization_rules` can be used by the user to create the rules separately."
  type        = bool
  default     = false
  nullable    = false

  validation {
    condition     = var.create_rules ? var.client_vpn_endpoint_id != null : true
    error_message = "If the `create_rules` variable is `true`, then `client_vpn_endpoint_id` must be provided."
  }
}
