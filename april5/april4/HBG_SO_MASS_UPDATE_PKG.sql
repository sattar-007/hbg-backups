--------------------------------------------------------
--  DDL for Package HBG_SO_MASS_UPDATE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."HBG_SO_MASS_UPDATE_PKG" AS
    PROCEDURE get_sales_orders (
        p_header_id           IN NUMBER,
        p_organization_id     IN NUMBER,
        p_org_name            IN VARCHAR2,
        p_invetory_item_id    IN NUMBER,
        p_item_number         IN VARCHAR2,
        p_order_number        IN VARCHAR2,
        p_cust_account_id     IN NUMBER,
       -- p_cust_acct_number    IN VARCHAR2,
      --  p_ex_cust_acct_number IN VARCHAR2,
        p_ex_cust_account_id  IN NUMBER,
        p_party_site_id       IN NUMBER,
        p_line_status         IN VARCHAR2,
        p_order_status        IN VARCHAR2,
        p_owner_id            IN VARCHAR2,
        p_rpg_grp             IN VARCHAR2,
        p_cat1                IN VARCHAR2,
        p_cat2                IN VARCHAR2,
        p_from_ordered_qty    IN NUMBER,
        p_to_ordered_qty      IN NUMBER,
        p_po_number           IN VARCHAR2,
        p_apply_reason_code   IN VARCHAR2,
        p_release_reason_code IN VARCHAR2,
        p_received_from_date  IN VARCHAR2,
        p_received_to_date    IN VARCHAR2,
        p_offer_code          IN VARCHAR2,
        p_from_ord_net_value  IN NUMBER,
        p_to_ord_net_value    IN NUMBER,
        p_oic_run_id          IN NUMBER,
        x_staus_code          OUT VARCHAR2,
        x_staus_message       OUT VARCHAR2
    );

    PROCEDURE update_sales_orders (
        p_organization_id             IN NUMBER,
        p_inventory_item_id           IN NUMBER,
        p_cust_account_id             IN NUMBER,
        p_ex_cust_account_id          IN NUMBER,
        p_line_status                 IN VARCHAR2,
        p_order_status                IN VARCHAR2,
        p_from_ordered_qty            IN NUMBER,
        p_to_ordered_qty              IN NUMBER,
        p_po_number                   IN VARCHAR2,
        p_apply_reason_code           IN VARCHAR2,
        p_hold_flag                   IN VARCHAR2,
        p_release_reason_code         IN VARCHAR2,
        p_new_apply_reason_code       IN VARCHAR2,
        p_new_release_reason_code     IN VARCHAR2,
        p_new_apply_reason_comments   IN VARCHAR2,
        p_new_release_reason_comments IN VARCHAR2,
        p_received_from_date          IN VARCHAR2,
        p_received_to_date            IN VARCHAR2,
        p_oic_run_id                  NUMBER,
        x_staus_code                  OUT VARCHAR2,
        x_staus_message               OUT VARCHAR2
    );

END hbg_so_mass_update_pkg;

/
