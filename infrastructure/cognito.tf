resource "aws_cognito_user_pool" "user_pool" {
    name = "${var.project}-${terraform.workspace}-user-pool"
    count = "${var.enable_cognito_user_pool ? 1 : 0}"
    
    alias_attributes = ["email", "preferred_username"]
    auto_verified_attributes = ["email"]
    email_verification_subject = "${var.project} - ${var.cognito_config["email_verification_subject"]}"
    email_verification_message = "${var.cognito_config["email_verification_message"]}"
    

    verification_message_template {
        default_email_option = "${var.cognito_config["default_email_option"]}"
    }

    password_policy {
        minimum_length    = 10
        require_lowercase = true
        require_numbers   = true
        require_symbols   = true
        require_uppercase = true
    }

    schema {
        attribute_data_type      = "String"
        developer_only_attribute = false
        mutable                  = false
        name                     = "email"
        required                 = true

        string_attribute_constraints {
            min_length = 7
            max_length = 15
        }
    }

    tags = {
        Terraform = "true"
        Environment = "${terraform.workspace}"
        Project = "${var.project}"
    }

}


resource "aws_cognito_user_pool_client" "user_pool_client" {
    name = "${var.project}-${terraform.workspace}-user-pool-client"
    count = "${var.enable_cognito_user_pool ? 1 : 0}"
    user_pool_id = "${join("", aws_cognito_user_pool.user_pool.*.id)}"

    generate_secret     = true
    explicit_auth_flows = ["ADMIN_NO_SRP_AUTH"]

    allowed_oauth_flows = "${var.oauth_flows["allowed_oauth_scopes"]}"
    callback_urls = "${var.oauth_flows["callback_urls"]}"
    supported_identity_providers = ["COGNITO"]

    allowed_oauth_scopes = ["openid", "email"]
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain = "${var.project}-${terraform.workspace}"
  count = "${var.enable_cognito_user_pool && !var.enable_cognito_custom_domain ? 1 : 0}" 
  user_pool_id = "${join("", aws_cognito_user_pool.user_pool.*.id)}"
}

# TODO Route53, ACM, ACM Validation for Custom Domain