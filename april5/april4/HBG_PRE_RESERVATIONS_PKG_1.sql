--------------------------------------------------------
--  DDL for Package Body HBG_PRE_RESERVATIONS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."HBG_PRE_RESERVATIONS_PKG" AS

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
    ) IS
        l_res_id NUMBER;
        l_count  NUMBER;
    BEGIN
        IF ( ( p_requester IS NULL OR p_requester = 'undefined' OR p_requester = '' OR p_requester = ' ' ) OR ( p_expiration_date IS NULL )
        OR ( p_reason_code IS NULL OR p_reason_code = 'undefined' OR p_reason_code = '' OR p_reason_code = ' ' ) 
            --OR ( p_reservation_type IS NULL OR p_reservation_type = 'undefined' OR p_reservation_type = '' OR p_reservation_type = ' ' ) 
         OR ( p_status IS NULL OR p_status = 'undefined' OR p_status = '' OR p_status = ' ' ) ) THEN
            p_return_status := 'Error';
        ELSE
            SELECT
                COUNT(1) pre_reservation_number
            INTO l_count
            FROM
                xxhbg_res_pre_reservation_header
            WHERE
                pre_reservation_number = p_pre_reservation_number;

            IF l_count > 0 THEN
                l_res_id := p_pre_reservation_number;
                UPDATE xxhbg_res_pre_reservation_header
                SET
                    inventory_organization = p_inventory_organization,
                    requester = p_requester,
                    approver = p_approver,
                    reason_code = p_reason_code,
                    reservation_type = p_reservation_type,
                    print_number = nvl(p_print_number, ''),
                    expiration_date = p_expiration_date,
                    auto_clear_on_expiry_date = p_auto_clear_on_expiry_date,
                    comments = p_comments,
                    status = p_status,
                    last_updated_by = p_last_updated_by,
                    last_update_date = sysdate
                WHERE
                    pre_reservation_number = p_pre_reservation_number;

                COMMIT;
            ELSE
                l_res_id := hbg_integration.xxhbg_res_pre_reservation_id_seq.nextval;
                INSERT INTO xxhbg_res_pre_reservation_header (
                    pre_reservation_number,
                    inventory_organization,
                    requester,
                    approver,
                    reason_code,
                    reservation_type,
                    print_number,
                    expiration_date,
                    auto_clear_on_expiry_date,
                    comments,
                    status,
                    created_by,
                    created_date,
                    last_updated_by,
                    last_update_date
                ) VALUES (
                    l_res_id,
                    p_inventory_organization,
                    p_requester,
                    p_approver,
                    p_reason_code,
                    p_reservation_type,
                    p_print_number,
                    substr(p_expiration_date, 1, 10),
                    p_auto_clear_on_expiry_date,
                    p_comments,
                    'In Process',
                    p_created_by,
                    sysdate,
                    p_last_updated_by,
                    sysdate
                );

                COMMIT;
            END IF;

            p_return_status := l_res_id;
        END IF;
    END hbg_pre_res_header_create;

    PROCEDURE hbg_pre_res_header_id (
        p_return_status OUT NUMBER
    ) IS
        l_reservation_id NUMBER;
    BEGIN
        SELECT
            hbg_integration.xxhbg_res_pre_reservation_id_seq.nextval
        INTO l_reservation_id
        FROM
            dual;

        p_return_status := l_reservation_id;
    END hbg_pre_res_header_id;

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
    ) IS

        l_count                  NUMBER := 0;
        l_check_count            NUMBER := 0;
        l_item_count             NUMBER := 0;
        l_rtype_future_count     NUMBER := 0;
        l_rtype_print_count      NUMBER := 0;
        l_inventory_organization VARCHAR2(200) := NULL;
        l_subinventory           VARCHAR2(200) := NULL;
        l_lot_number             VARCHAR2(200) := NULL;
        l_reservation_type       VARCHAR2(200) := NULL;
        l_requested_quantity     NUMBER := 0;
        l_reserved_quantity      NUMBER := 0;
        l_available_reserved     NUMBER := 0;
        l_submitted_count        NUMBER := 0;
    BEGIN
        BEGIN
            SELECT
                COUNT(1)
            INTO l_count
            FROM
                egp_system_items_b
            WHERE
                item_number = p_item_code;

            SELECT
                COUNT(1)
            INTO l_check_count
            FROM
                xxhbg_res_pre_reservation_lines
            WHERE
                    reservation_number = p_reservation_number
                AND record_id = p_record_id;

            SELECT
                COUNT(1)
            INTO l_item_count
            FROM
                xxhbg_res_pre_reservation_lines
            WHERE
                    item_code = p_item_code
                AND reservation_number = p_reservation_number
                AND inventory_organization = p_inventory_organization
                AND subinventory = p_subinventory
                --AND reservation_type = p_reservation_type
                AND lot_number = p_lot_number;
				
				
        --EXCEPTION
          --  WHEN OTHERS THEN
            --    l_count := 0;
        END;

        IF ( p_item_code IS NULL OR p_reservation_type IS NULL OR p_requested_quantity IS NULL ) THEN
            p_return_status := 'Please enter the mandatory feilds Item Code, Reservation Type & Requested Quantity';
        ELSIF (
            l_count = 0
            AND p_item_code IS NOT NULL
        ) THEN
            p_return_status := 'Item code does not exists, please enter the valid item number';
        ELSIF
            p_reservation_type = 'Print & Bind'
            AND ( p_wo_number || p_po_number IS NULL )
        THEN
            p_return_status := 'For Print & Bind type enter one of the values PO Number or WO Number';
        ELSIF
            p_reservation_type = 'Regular'
            AND p_requested_quantity > p_usable_balance
        THEN
            p_return_status := 'Quantity to reserve is greater than the Available to Reserve';
        ELSIF l_item_count > 0 and l_check_count < 1 THEN
            p_return_status := 'Item '
                               || p_item_code
                               || ' with subinventory '
                               || p_subinventory
                               || ' & Lot Number '
                               || p_lot_number
                               || ' already used in reservation number '
                               || p_reservation_number;    
        ELSIF l_check_count > 0 THEN
            SELECT
                inventory_organization
            INTO l_inventory_organization
            FROM
                xxhbg_res_pre_reservation_lines
            WHERE
                    reservation_number = p_reservation_number
                AND record_id = p_record_id;

            SELECT
                subinventory
            INTO l_subinventory
            FROM
                xxhbg_res_pre_reservation_lines
            WHERE
                    reservation_number = p_reservation_number
                AND record_id = p_record_id;

            SELECT
                lot_number
            INTO l_lot_number
            FROM
                xxhbg_res_pre_reservation_lines
            WHERE
                    reservation_number = p_reservation_number
                AND record_id = p_record_id;

            SELECT
                requested_quantity
            INTO l_requested_quantity
            FROM
                xxhbg_res_pre_reservation_lines
            WHERE
                    reservation_number = p_reservation_number
                AND record_id = p_record_id;
            SELECT
                reserved_quantity
            INTO l_reserved_quantity
            FROM
                xxhbg_res_pre_reservation_lines
            WHERE
                    reservation_number = p_reservation_number
                AND record_id = p_record_id;    
            SELECT
                available_reserved
            INTO l_available_reserved
            FROM
                xxhbg_res_pre_reservation_lines
            WHERE
                    reservation_number = p_reservation_number
                AND record_id = p_record_id;
            SELECT
                reservation_type
            INTO l_reservation_type
            FROM
                xxhbg_res_pre_reservation_lines
            WHERE
                    reservation_number = p_reservation_number
                AND record_id = p_record_id;    

            UPDATE xxhbg_res_pre_reservation_lines
            SET
                item_code = p_item_code,
                isbn_on_book = p_isbn_on_book,
                short_title = p_short_title,
                status = p_status,
                reservation_type = p_reservation_type,
                print_number = p_print_number,
                inventory_organization = p_inventory_organization,
                lot_number = p_lot_number,
                subinventory = p_subinventory,
                requested_quantity = p_requested_quantity,
                reserved_quantity = p_reserved_quantity,
                released_via_cuid = p_released_via_cuid,
                available_reserved = p_available_reserved,
                ip_only = p_ip_only,
                pre_reserved_balance = p_pre_reserved_balance,
                usable_balance = p_usable_balance,
                end_balance = p_end_balance,
                po_number = p_po_number,
                wo_number = p_wo_number,
                last_updated_by = p_last_updated_by,
                last_update_date = sysdate
            WHERE
                    reservation_number = p_reservation_number
                AND record_id = p_record_id;

            COMMIT;
            p_return_status := 'SUCCESS';
            IF l_inventory_organization <> p_inventory_organization THEN
                INSERT INTO xxhbg_res_pre_reservation_history (
                    pre_reservation_number,
                    item_code,
                    criteria_uid,
                    field_name,
                    user_name,
                    changed_date,
                    changed_from,
                    changed_to,
                    order_type,
                    order_reference_number,
                    purchase_order_number,
                    work_order_number,
                    organization_number,
                    organization_name,
                    account_number,
                    account_name,
                    released_from_pre_reservation_quantity,
                    transaction_type
                ) VALUES (
                    p_reservation_number,
                    p_item_code,
                    NULL,
                    'Inventory Organization',
                    p_created_by,
                    sysdate,
                    l_inventory_organization,
                    p_inventory_organization,
                    NULL,
                    NULL,
                    p_po_number,
                    p_wo_number,
                    NULL,
                    p_inventory_organization,
                    NULL,
                    NULL,
                    NULL,
                    'Updated'
                );

                COMMIT;
                END IF;
                                                
            IF l_subinventory <> p_subinventory THEN
                INSERT INTO xxhbg_res_pre_reservation_history (
                    pre_reservation_number,
                    item_code,
                    criteria_uid,
                    field_name,
                    user_name,
                    changed_date,
                    changed_from,
                    changed_to,
                    order_type,
                    order_reference_number,
                    purchase_order_number,
                    work_order_number,
                    organization_number,
                    organization_name,
                    account_number,
                    account_name,
                    released_from_pre_reservation_quantity,
                    transaction_type
                ) VALUES (
                    p_reservation_number,
                    p_item_code,
                    NULL,
                    'Subinventory',
                    p_created_by,
                    sysdate,
                    l_subinventory,
                    p_subinventory,
                    NULL,
                    NULL,
                    p_po_number,
                    p_wo_number,
                    NULL,
                    p_inventory_organization,
                    NULL,
                    NULL,
                    NULL,
                    'Updated'
                );

                COMMIT;
              END IF;
                
            IF l_reservation_type <> p_reservation_type THEN
                INSERT INTO xxhbg_res_pre_reservation_history (
                    pre_reservation_number,
                    item_code,
                    criteria_uid,
                    field_name,
                    user_name,
                    changed_date,
                    changed_from,
                    changed_to,
                    order_type,
                    order_reference_number,
                    purchase_order_number,
                    work_order_number,
                    organization_number,
                    organization_name,
                    account_number,
                    account_name,
                    released_from_pre_reservation_quantity,
                    transaction_type
                ) VALUES (
                    p_reservation_number,
                    p_item_code,
                    NULL,
                    'Reservation Type',
                    p_created_by,
                    sysdate,
                    l_reservation_type,
                    p_reservation_type,
                    NULL,
                    NULL,
                    p_po_number,
                    p_wo_number,
                    NULL,
                    p_inventory_organization,
                    NULL,
                    NULL,
                    NULL,
                    'Updated'
                );

                COMMIT;    
              END IF;  
            IF l_lot_number <> p_lot_number THEN
                INSERT INTO xxhbg_res_pre_reservation_history (
                    pre_reservation_number,
                    item_code,
                    criteria_uid,
                    field_name,
                    user_name,
                    changed_date,
                    changed_from,
                    changed_to,
                    order_type,
                    order_reference_number,
                    purchase_order_number,
                    work_order_number,
                    organization_number,
                    organization_name,
                    account_number,
                    account_name,
                    released_from_pre_reservation_quantity,
                    transaction_type
                ) VALUES (
                    p_reservation_number,
                    p_item_code,
                    NULL,
                    'Lot Number',
                    p_created_by,
                    sysdate,
                    l_lot_number,
                    p_lot_number,
                    NULL,
                    NULL,
                    p_po_number,
                    p_wo_number,
                    NULL,
                    p_inventory_organization,
                    NULL,
                    NULL,
                    NULL,
                    'Updated'
                );
                COMMIT;
                END IF;
            
            IF l_requested_quantity <> p_requested_quantity THEN
                INSERT INTO xxhbg_res_pre_reservation_history (
                    pre_reservation_number,
                    item_code,
                    criteria_uid,
                    field_name,
                    user_name,
                    changed_date,
                    changed_from,
                    changed_to,
                    order_type,
                    order_reference_number,
                    purchase_order_number,
                    work_order_number,
                    organization_number,
                    organization_name,
                    account_number,
                    account_name,
                    released_from_pre_reservation_quantity,
                    transaction_type
                ) VALUES (
                    p_reservation_number,
                    p_item_code,
                    NULL,
                    'Requested Quantity',
                    p_created_by,
                    sysdate,
                    l_requested_quantity,
                    p_requested_quantity,
                    NULL,
                    NULL,
                    p_po_number,
                    p_wo_number,
                    NULL,
                    p_inventory_organization,
                    NULL,
                    NULL,
                    NULL,
                    'Updated'
                );
                COMMIT;
                END IF;
            IF l_reserved_quantity <> p_reserved_quantity THEN
                INSERT INTO xxhbg_res_pre_reservation_history (
                    pre_reservation_number,
                    item_code,
                    criteria_uid,
                    field_name,
                    user_name,
                    changed_date,
                    changed_from,
                    changed_to,
                    order_type,
                    order_reference_number,
                    purchase_order_number,
                    work_order_number,
                    organization_number,
                    organization_name,
                    account_number,
                    account_name,
                    released_from_pre_reservation_quantity,
                    transaction_type
                ) VALUES (
                    p_reservation_number,
                    p_item_code,
                    NULL,
                    'Reserved Quantity',
                    p_created_by,
                    sysdate,
                    l_requested_quantity,
                    p_requested_quantity,
                    NULL,
                    NULL,
                    p_po_number,
                    p_wo_number,
                    NULL,
                    p_inventory_organization,
                    NULL,
                    NULL,
                    NULL,
                    'Updated'
                );
                COMMIT;    
                END IF;
            IF l_available_reserved <> p_available_reserved THEN
                INSERT INTO xxhbg_res_pre_reservation_history (
                    pre_reservation_number,
                    item_code,
                    criteria_uid,
                    field_name,
                    user_name,
                    changed_date,
                    changed_from,
                    changed_to,
                    order_type,
                    order_reference_number,
                    purchase_order_number,
                    work_order_number,
                    organization_number,
                    organization_name,
                    account_number,
                    account_name,
                    released_from_pre_reservation_quantity,
                    transaction_type
                ) VALUES (
                    p_reservation_number,
                    p_item_code,
                    NULL,
                    'Available Reserved',
                    p_created_by,
                    sysdate,
                    l_requested_quantity,
                    p_requested_quantity,
                    NULL,
                    NULL,
                    p_po_number,
                    p_wo_number,
                    NULL,
                    p_inventory_organization,
                    NULL,
                    NULL,
                    NULL,
                    'Updated'
                );
                COMMIT;
                END IF;            
--            ELSE
                p_return_status := 'SUCCESS';
--            END

        
        ELSE
            INSERT INTO xxhbg_res_pre_reservation_lines (
                item_code,
                isbn_on_book,
                short_title,
                status,
                reservation_type,
                print_number,
                inventory_organization,
                lot_number,
                subinventory,
                requested_quantity,
                reserved_quantity,
                released_via_cuid,
                available_reserved,
                ip_only,
                pre_reserved_balance,
                usable_balance,
                end_balance,
                po_number,
                wo_number,
                created_by,
                created_date,
                last_updated_by,
                last_update_date,
                reservation_number
            ) VALUES (
                p_item_code,
                p_isbn_on_book,
                p_short_title,
                p_status,
                p_reservation_type,
                p_print_number,
                p_inventory_organization,
                p_lot_number,
                p_subinventory,
                p_requested_quantity,
                p_reserved_quantity,
                p_released_via_cuid,
                p_available_reserved,
                p_ip_only,
                p_pre_reserved_balance,
                p_usable_balance,
                p_end_balance,
                p_po_number,
                p_wo_number,
                p_created_by,
                sysdate,
                p_last_updated_by,
                sysdate,
                p_reservation_number
            );
            
            
                UPDATE xxhbg_res_pre_reservation_header
                set status = 'In Process'
                where pre_reservation_number = p_reservation_number;

            COMMIT;
            INSERT INTO xxhbg_res_pre_reservation_history (
                pre_reservation_number,
                item_code,
                criteria_uid,
                field_name,
                user_name,
                changed_date,
                changed_from,
                changed_to,
                order_type,
                order_reference_number,
                purchase_order_number,
                work_order_number,
                organization_number,
                organization_name,
                account_number,
                account_name,
                released_from_pre_reservation_quantity,
                transaction_type
            ) VALUES (
                p_reservation_number,
                p_item_code,
                NULL,
                NULL,
                p_created_by,
                sysdate,
                NULL,
                NULL,
                NULL,
                NULL,
                p_po_number,
                p_wo_number,
                NULL,
                p_inventory_organization,
                NULL,
                NULL,
                NULL,
                'Created'
            );
            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
BEGIN
                SELECT
                    COUNT(1)
                INTO l_rtype_future_count
                FROM
                    xxhbg_res_pre_reservation_lines
                WHERE
                        reservation_number = p_reservation_number
                    AND reservation_type = 'Future';

                SELECT
                    COUNT(1)
                INTO l_rtype_print_count
                FROM
                    xxhbg_res_pre_reservation_lines
                WHERE
                        reservation_number = p_reservation_number
                    AND reservation_type = 'Print & Bind';

                IF l_rtype_future_count > 0 THEN
                    UPDATE xxhbg_res_pre_reservation_header
                    SET
                        reservation_type = 'Future'
                    WHERE
                        pre_reservation_number = p_reservation_number;

                ELSIF
                    l_rtype_print_count > 0
                    AND l_rtype_future_count = 0
                THEN
                    UPDATE xxhbg_res_pre_reservation_header
                    SET
                        reservation_type = 'Print & Bind'
                    WHERE
                        pre_reservation_number = p_reservation_number;

                ELSE
                    UPDATE xxhbg_res_pre_reservation_header
                    SET
                        reservation_type = 'Regular'
                    WHERE
                        pre_reservation_number = p_reservation_number;

                END IF;

            END;
    END hbg_pre_res_lines_create;

    PROCEDURE hbg_pre_res_lines_delete (
        p_item_code              IN VARCHAR2,
        p_inventory_organization IN VARCHAR2,
        p_lot_number             IN VARCHAR2,
        p_reservation_number     IN NUMBER,
        p_subinventory           IN VARCHAR2,
        p_requested_quantity     IN NUMBER,
        p_created_by             IN VARCHAR2,
        p_return_status          OUT VARCHAR2
    ) IS
        l_rtype_future_count NUMBER := 0;
        l_rtype_print_count  NUMBER := 0;
    BEGIN
        DELETE FROM xxhbg_res_pre_reservation_lines
        WHERE
                reservation_number = p_reservation_number
            AND item_code = p_item_code
            AND inventory_organization = p_inventory_organization
            AND lot_number = p_lot_number;

        COMMIT;
        SELECT
            COUNT(1)
        INTO l_rtype_future_count
        FROM
            xxhbg_res_pre_reservation_lines
        WHERE
                reservation_number = p_reservation_number
            AND reservation_type = 'Future';

        SELECT
            COUNT(1)
        INTO l_rtype_print_count
        FROM
            xxhbg_res_pre_reservation_lines
        WHERE
                reservation_number = p_reservation_number
            AND reservation_type = 'Print & Bind';

        IF l_rtype_future_count > 0 THEN
            UPDATE xxhbg_res_pre_reservation_header
            SET
                reservation_type = 'Future'
            WHERE
                pre_reservation_number = p_reservation_number;

        ELSIF
            l_rtype_print_count > 0
            AND l_rtype_future_count = 0
        THEN
            UPDATE xxhbg_res_pre_reservation_header
            SET
                reservation_type = 'Print & Bind'
            WHERE
                pre_reservation_number = p_reservation_number;

        ELSE
            UPDATE xxhbg_res_pre_reservation_header
            SET
                reservation_type = 'Regular'
            WHERE
                pre_reservation_number = p_reservation_number;

        END IF;

        INSERT INTO xxhbg_res_pre_reservation_history (
            pre_reservation_number,
            item_code,
            criteria_uid,
            field_name,
            user_name,
            changed_date,
            changed_from,
            changed_to,
            order_type,
            order_reference_number,
            purchase_order_number,
            work_order_number,
            organization_number,
            organization_name,
            account_number,
            account_name,
            released_from_pre_reservation_quantity,
            transaction_type
        ) VALUES (
            p_reservation_number,
            p_item_code,
            NULL,
            NULL,
            p_created_by,
            sysdate,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            p_inventory_organization,
            NULL,
            NULL,
            NULL,
            'Deleted'
        );

        COMMIT;
        p_return_status := 'Deleted reservation line with item '
                           || p_item_code
                           || ', Organization '
                           || p_inventory_organization
                           || '& Lot'
                           || p_lot_number;

    END hbg_pre_res_lines_delete;

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
    ) IS
        l_count        NUMBER := 0;
        l_criteria_uid NUMBER := 0;
    BEGIN
        SELECT
            COUNT(1)
        INTO l_count
        FROM
            xxhbg_res_pre_reservation_add_criteria
        WHERE
                reservation_number = p_reservation_number
        --and item_code = p_item_code
            AND criteria_uid = p_criteria_uid;

        SELECT
            xxhbg_res_pre_reservation_criteria_uid_seq.NEXTVAL
        INTO l_criteria_uid
        FROM
            dual;

        IF l_count > 0 THEN
            UPDATE xxhbg_res_pre_reservation_add_criteria
            SET
                order_number = p_order_number,
                release_date = p_release_date,
                entered_by = p_entered_by,
                purchase_order_number = p_purchase_order_number,
                work_order_number = p_work_order_number,
                organization_code = p_organization_code,
                account_type = p_account_type,
                bill_to_code = p_bill_to_code,
                ship_to_code = p_ship_to_code,
                sale_type = p_sale_type,
                offer_code = p_offer_code,
                override_hot_title = p_override_hot_title
            WHERE
                    reservation_number = p_reservation_number
                --AND item_code = p_item_code
                AND criteria_uid = p_criteria_uid;

            COMMIT;
        ELSE
            INSERT INTO xxhbg_res_pre_reservation_add_criteria (
                criteria_uid,
                order_number,
                release_date,
                entered_by,
                purchase_order_number,
                work_order_number,
                organization_code,
                account_type,
                bill_to_code,
                ship_to_code,
                sale_type,
                offer_code,
                override_hot_title,
                reservation_number,
                item_code
            ) VALUES (
                l_criteria_uid,
                p_order_number,
                p_release_date,
                p_entered_by,
                p_purchase_order_number,
                p_work_order_number,
                p_organization_code,
                p_account_type,
                p_bill_to_code,
                p_ship_to_code,
                p_sale_type,
                p_offer_code,
                p_override_hot_title,
                p_reservation_number,
                p_item_code
            );

            COMMIT;
        END IF;

        p_return_status := 'Reservation Criteria saved Successfully with Criteria UID ' || l_criteria_uid;
    END hbg_pre_res_criteria_create;

    PROCEDURE hbg_pre_res_header_check (
        p_requester        IN VARCHAR2,
        p_reason_code      IN VARCHAR2,
        p_reservation_type IN VARCHAR2,
        p_expiration_date  IN VARCHAR2,
        p_status           IN VARCHAR2,
        p_return_status    OUT VARCHAR2
    ) IS
    BEGIN
        IF ( ( p_requester IS NULL OR p_requester = 'undefined' OR p_requester = '' OR p_requester = ' ' ) OR ( p_expiration_date IS NULL
        OR p_expiration_date = 'undefined' OR p_expiration_date = '' OR p_expiration_date = ' ' ) OR ( p_reason_code IS NULL OR p_reason_code =
        'undefined' OR p_reason_code = '' OR p_reason_code = ' ' ) OR ( p_reservation_type IS NULL OR p_reservation_type = 'undefined'
        OR p_reservation_type = '' OR p_reservation_type = ' ' ) OR ( p_status IS NULL OR p_status = 'undefined' OR p_status = '' OR p_status =
        ' ' ) ) THEN
            p_return_status := 'Error';
        ELSE
            p_return_status := 'Success';
        END IF;
    END hbg_pre_res_header_check;

END hbg_pre_reservations_pkg;

/
