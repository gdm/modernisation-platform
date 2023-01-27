data "aws_caller_identity" "modernisation-platform" {
  provider = aws.modernisation-platform
}

data "aws_organizations_organization" "root_account" {}

locals {
  application_name           = "core-network-services"
  environment_management     = jsondecode(data.aws_secretsmanager_secret_version.environment_management.secret_string)
  pagerduty_integration_keys = jsondecode(data.aws_secretsmanager_secret_version.pagerduty_integration_keys.secret_string)

  # This takes the name of the Terraform workspace (e.g. core-vpc-production), strips out the application name (e.g. core-vpc), and checks if
  # the string leftover is `-production`, if it isn't (e.g. core-vpc-non-production => -non-production) then it sets the var to false.
  is-production = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-production"

  tags = {
    business-unit = "Platforms"
    application   = "Modernisation Platform: core-network-services"
    is-production = local.is-production
    owner         = "Modernisation Platform: modernisation-platform@digital.justice.gov.uk"
  }

  active_tgw_peering_attachments = [
    "PTTP-Transit-Gateway-attachment-accepter"
  ]

  active_tgw_vpc_attachments = [
    "hmcts-production-attachment",
    "hmpps-production-attachment",
    "core-network-services-live_data-attachment",
  ]

  development_rules   = fileexists("./development_rules.json") ? jsondecode(file("./development_rules.json")) : {}
  test_rules          = fileexists("./test_rules.json") ? jsondecode(file("./test_rules.json")) : {}
  preproduction_rules = fileexists("./preproduction_rules.json") ? jsondecode(file("./preproduction_rules.json")) : {}
  production_rules    = fileexists("./production_rules.json") ? jsondecode(file("./production_rules.json")) : {}
  firewall_rules      = merge(local.development_rules, local.test_rules, local.preproduction_rules, local.production_rules)

  vpn_attachments = fileexists("./vpn_attachments.json") ? jsondecode(file("./vpn_attachments.json")) : {}

  noms_dr_vpn_static_routes = [
    "10.40.64.0/18",
    "10.40.144.0/20",
    "10.40.176.0/20",
    "10.111.0.0/16",
    "10.112.0.0/16",
    "10.244.0.0/20",
    "10.247.0.0/20"
  ]
  noms_live_vpn_static_routes = [
    "10.40.0.0/18",
    "10.40.128.0/20",
    "10.40.160.0/20",
    "10.101.0.0/16",
    "10.102.0.0/16",
    "10.47.0.0/26",
    "10.47.0.64/26",
    "10.47.0.128/26"
  ]

  sixdg_dev_vpn_static_routes   = ["10.221.0.0/16"]
  sixdg_test_vpn_static_routes  = ["10.224.0.0/16"]
  sixdg_stage_vpn_static_routes = ["10.223.0.0/16"]
  sixdg_uat_vpn_static_routes   = ["10.222.0.0/16"]
  sixdg_prod_vpn_static_routes  = ["10.225.0.0/16"]

  core-vpcs = {
    for file in fileset("../../../environments-networks", "*.json") :
    replace(file, ".json", "") => jsondecode(file("../../../environments-networks/${file}"))
  }
}
