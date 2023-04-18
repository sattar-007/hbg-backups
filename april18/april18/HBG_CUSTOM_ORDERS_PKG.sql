--------------------------------------------------------
--  DDL for Package HBG_CUSTOM_ORDERS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."HBG_CUSTOM_ORDERS_PKG" AS
    PROCEDURE hbg_co_template_headers_create (
        p_template_name        IN VARCHAR2,
        p_template_description IN VARCHAR2,
        p_cust_account_id      IN NUMBER,
        p_owner_code           IN VARCHAR2,
        p_owner_name           IN VARCHAR2,
        p_account_number       IN VARCHAR2,
        p_account_description  IN VARCHAR2,
        p_start_date           IN VARCHAR2,
        p_end_date             IN VARCHAR2,
        p_entered_by           IN VARCHAR2,
        p_updated_by           IN VARCHAR2,
        p_return_status        OUT VARCHAR2
    );

    PROCEDURE hbg_co_template_headers_update (
        p_template_id          IN NUMBER,
        p_template_name        IN VARCHAR2,
        p_template_description IN VARCHAR2,
        p_cust_account_id      IN NUMBER,
        p_owner_code           IN VARCHAR2,
        p_owner_name           IN VARCHAR2,
        p_account_number       IN VARCHAR2,
        p_account_description  IN VARCHAR2,
        p_start_date           IN VARCHAR2,
        p_end_date             IN VARCHAR2,
        p_updated_by           IN VARCHAR2,
        p_return_status        OUT VARCHAR2
    );

    PROCEDURE hbg_co_template_lines_create (
        p_template_id       IN NUMBER,
        p_sequence          IN NUMBER,
        p_category_code     IN VARCHAR2,
        p_category_name     IN VARCHAR2,
        p_instructions_text IN VARCHAR2,
        p_entered_by        IN VARCHAR2,
        p_updated_by        IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    );

    PROCEDURE hbg_co_template_lines_update (
        p_line_id           IN NUMBER,
        p_template_id       IN NUMBER,
        p_sequence          IN NUMBER,
        p_category_code     IN VARCHAR2,
        p_category_name     IN VARCHAR2,
        p_instructions_text IN VARCHAR2,
        p_updated_by        IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    );

    PROCEDURE hbg_co_rules_headers_create (
        p_organization_id     IN NUMBER,
        p_organization_number IN VARCHAR2,
        p_organization_name   IN VARCHAR2,
        p_cust_account_id     IN NUMBER,
        p_account_number      IN VARCHAR2,
        p_account_description IN VARCHAR2,
        p_destination_account IN VARCHAR2,
        p_department_id       IN NUMBER,
        p_sales_channel       IN VARCHAR2,
        p_start_date          IN VARCHAR2,
        p_end_date            IN VARCHAR2,
        p_entered_by          IN VARCHAR2,
        p_updated_by          IN VARCHAR2,
        p_return_status       OUT VARCHAR2
    );

    PROCEDURE hbg_co_rules_headers_update (
        p_rule_id             IN NUMBER,
        p_organization_id     IN NUMBER,
        p_organization_number IN VARCHAR2,
        p_organization_name   IN VARCHAR2,
        p_cust_account_id     IN NUMBER,
        p_account_number      IN VARCHAR2,
        p_account_description IN VARCHAR2,
        p_destination_account IN VARCHAR2,
        p_department_id       IN NUMBER,
        p_sales_channel       IN VARCHAR2,
        p_start_date          IN VARCHAR2,
        p_end_date            IN VARCHAR2,
        p_updated_by          IN VARCHAR2,
        p_return_status       OUT VARCHAR2
    );

    PROCEDURE hbg_co_rules_lines_create (
        p_rule_id                     IN NUMBER,
        p_sequence                    IN NUMBER,
        p_ship_to_number              IN VARCHAR2,
        p_ship_to_name                IN VARCHAR2,
        p_owner_code                  IN VARCHAR2,
        p_owner_name                  IN VARCHAR2,
        p_reporting_group             IN VARCHAR2,
        p_reporting_group_description IN VARCHAR2,
        p_publisher                   IN VARCHAR2,
        p_publisher_name              IN VARCHAR2,
        p_imprint                     IN VARCHAR2,
        p_imprint_name                IN VARCHAR2,
        p_format                      IN VARCHAR2,
        p_format_name                 IN VARCHAR2,
        p_sub_format                  IN VARCHAR2,
        p_sub_format_name             IN VARCHAR2,
        p_item                        IN VARCHAR2,
        p_price_on_book               IN VARCHAR2,
        p_shrink_wrap                 IN VARCHAR2,
        p_master_pack                 IN VARCHAR2,
        p_inner_pack                  IN VARCHAR2,
        p_new_pack_quantity           IN VARCHAR2,
        p_entered_by                  IN VARCHAR2,
        p_updated_by                  IN VARCHAR2,
        p_return_status               OUT VARCHAR2
    );

    PROCEDURE hbg_co_rules_lines_update (
        p_rule_line_id                IN NUMBER,
        p_rule_id                     IN NUMBER,
        p_sequence                    IN NUMBER,
        p_ship_to_number              IN VARCHAR2,
        p_ship_to_name                IN VARCHAR2,
        p_owner_code                  IN VARCHAR2,
        p_owner_name                  IN VARCHAR2,
        p_reporting_group             IN VARCHAR2,
        p_reporting_group_description IN VARCHAR2,
        p_publisher                   IN VARCHAR2,
        p_publisher_name              IN VARCHAR2,
        p_imprint                     IN VARCHAR2,
        p_imprint_name                IN VARCHAR2,
        p_format                      IN VARCHAR2,
        p_format_name                 IN VARCHAR2,
        p_sub_format                  IN VARCHAR2,
        p_sub_format_name             IN VARCHAR2,
        p_item                        IN VARCHAR2,
        p_price_on_book               IN VARCHAR2,
        p_shrink_wrap                 IN VARCHAR2,
        p_master_pack                 IN VARCHAR2,
        p_inner_pack                  IN VARCHAR2,
        p_new_pack_quantity           IN VARCHAR2,
        p_updated_by                  IN VARCHAR2,
        p_return_status               OUT VARCHAR2
    );

    PROCEDURE hbg_co_line_actions_create (
        p_rule_line_id   IN NUMBER,
        p_template_level IN VARCHAR2,
        p_template_name  IN VARCHAR2,
        p_template_id    IN NUMBER,
        p_hold_flag      IN VARCHAR2,
        p_hold_level     IN VARCHAR2,
        p_hold_name      IN VARCHAR2,
        p_start_date     IN VARCHAR2,
        p_end_date       IN VARCHAR2,
        p_entered_by     IN VARCHAR2,
        p_updated_by     IN VARCHAR2,
        p_return_status  OUT VARCHAR2
    );

    PROCEDURE hbg_co_line_actions_update (
        p_line_action_id IN NUMBER,
        p_rule_line_id   IN NUMBER,
        p_template_level IN VARCHAR2,
        p_template_name  IN VARCHAR2,
        p_template_id    IN NUMBER,
        p_hold_flag      IN VARCHAR2,
        p_hold_level     IN VARCHAR2,
        p_hold_name      IN VARCHAR2,
        p_start_date     IN VARCHAR2,
        p_end_date       IN VARCHAR2,
        p_updated_by     IN VARCHAR2,
        p_return_status  OUT VARCHAR2
    );

    PROCEDURE hbg_custom_orders_val (
        p_source_line_id     IN VARCHAR2,
        p_batch_id           IN VARCHAR2,
        return_status        OUT VARCHAR2
    );

END hbg_custom_orders_pkg;

/
