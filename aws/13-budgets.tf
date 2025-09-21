resource "aws_budgets_budget" "platform_cost" {
  name         = "Platform-Cost-Budget"
  budget_type  = "COST"
  time_unit    = "MONTHLY"
  limit_amount = var.platform_budget_limit
  limit_unit   = "USD"

  cost_filter {
    name   = "BillingEntity"
    values = ["AWS"]
  }

  dynamic "notification" {
    for_each = var.budget_notification_thresholds
    content {
      comparison_operator        = "GREATER_THAN"
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      threshold                  = notification.value
      subscriber_email_addresses = var.budget_notification_emails
    }
  }

  dynamic "notification" {
    for_each = var.budget_notification_thresholds
    content {
      comparison_operator        = "GREATER_THAN"
      threshold_type             = "PERCENTAGE"
      notification_type          = "FORECASTED"
      threshold                  = notification.value
      subscriber_email_addresses = var.budget_notification_emails
    }
  }
}

resource "aws_budgets_budget" "marketplace_cost" {
  name         = "Marketplace-External-Models-Budget"
  budget_type  = "COST"
  time_unit    = "MONTHLY"
  limit_amount = var.marketplace_budget_limit
  limit_unit   = "USD"

  cost_filter {
    name   = "BillingEntity"
    values = ["AWS Marketplace"]
  }

  dynamic "notification" {
    for_each = var.budget_notification_thresholds
    content {
      comparison_operator        = "GREATER_THAN"
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      threshold                  = notification.value
      subscriber_email_addresses = var.budget_notification_emails
    }
  }

  dynamic "notification" {
    for_each = var.budget_notification_thresholds
    content {
      comparison_operator        = "GREATER_THAN"
      threshold_type             = "PERCENTAGE"
      notification_type          = "FORECASTED"
      threshold                  = notification.value
      subscriber_email_addresses = var.budget_notification_emails
    }
  }
}
