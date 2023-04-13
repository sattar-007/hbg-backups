--------------------------------------------------------
--  DDL for Package HBG_PRE_RESERVATIONS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."HBG_PRE_RESERVATIONS_PKG" IS
    PROCEDURE hbg_pre_res_header_create (
        p_pre_reservation_number    IN VARCHAR2,
        p_inventory_organization    IN VARCHAR2,
        p_requester                 IN VARCHAR2,
        p_approver                  IN VARCHAR2,
        p_reason_code               IN VARCHAR2,
        p_reservation_type          IN VARCHAR2,
        p_print_number              IN VARCHAR2,
        p_expiration_date           IN DATE,
        p_auto_clear_on_expiry_date IN VARCHAR2,
        p_comments                  IN VARCHAR2,
        p_status                    IN VARCHAR2,
        p_criteria_uid              IN VARCHAR2,
        p_created_by                IN VARCHAR2,
        p_last_updated_by           IN VARCHAR2,
        p_return_status             OUT VARCHAR2
    );

    PROCEDURE hbg_pre_res_header_id (
        p_return_status OUT NUMBER
    );

    PROCEDURE hbg_pre_res_lines_create (
        p_item_code              IN VARCHAR2,
        p_isbn_on_book           IN VARCHAR2,
        p_short_title            IN VARCHAR2,
        p_status                 IN VARCHAR2,
        p_reservation_type       IN VARCHAR2,
        p_print_number           IN VARCHAR2,
        p_inventory_organization IN VARCHAR2,
        p_lot_number             IN VARCHAR2,
        p_subinventory           IN VARCHAR2,
        p_requested_quantity     IN NUMBER,
        p_reserved_quantity      IN NUMBER,
        p_released_via_cuid      IN NUMBER,
        p_available_reserved     IN NUMBER,
        p_ip_only                IN VARCHAR2,
        p_pre_reserved_balance   IN NUMBER,
        p_usable_balance         IN NUMBER,
        p_end_balance            IN NUMBER,
        p_created_by             IN VARCHAR2,
        p_last_updated_by        IN VARCHAR2,
        p_reservation_number     IN NUMBER,
        p_record_id              IN NUMBER,
        p_po_number              IN VARCHAR2,
        p_wo_number              IN VARCHAR2,
        p_return_status          OUT VARCHAR2
    );
    
    
    PROCEDURE hbg_pre_res_lines_delete (
        p_item_code              IN VARCHAR2,
        p_inventory_organization IN VARCHAR2,
        p_lot_number             IN VARCHAR2,
        p_reservation_number     IN NUMBER,
        p_subinventory			 IN VARCHAR2,
		p_requested_quantity	 IN NUMBER,
        p_created_by             IN VARCHAR2,
        p_return_status          OUT VARCHAR2
    );

    PROCEDURE hbg_pre_res_criteria_create (
        p_order_number          IN VARCHAR2,
        p_release_date          IN DATE,
        p_entered_by            IN VARCHAR2,
        p_purchase_order_number IN VARCHAR2,
        p_work_order_number     IN VARCHAR2,
        p_organization_code     IN VARCHAR2,
        p_account_type          IN VARCHAR2,
        p_bill_to_code          IN VARCHAR2,
        p_ship_to_code          IN VARCHAR2,
        p_sale_type             IN VARCHAR2,
        p_offer_code            IN VARCHAR2,
        p_override_hot_title    IN VARCHAR2,
        p_reservation_number    IN NUMBER,
        p_criteria_uid          IN NUMBER,
        p_item_code             IN VARCHAR2,
        p_return_status         OUT VARCHAR2
    );

    
    PROCEDURE hbg_pre_res_header_check (
        p_requester        IN VARCHAR2,
        p_reason_code      IN VARCHAR2,
        p_reservation_type IN VARCHAR2,
        p_expiration_date  IN VARCHAR2,
        p_status           IN VARCHAR2,
        p_return_status    OUT VARCHAR2
    );

END hbg_pre_reservations_pkg;

/
