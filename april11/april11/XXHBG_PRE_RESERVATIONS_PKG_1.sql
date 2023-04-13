--------------------------------------------------------
--  DDL for Package Body XXHBG_PRE_RESERVATIONS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."XXHBG_PRE_RESERVATIONS_PKG" AS

    PROCEDURE hbg_pre_res_header_create (
        p_resevation_dtls  IN   xxhbg_pre_reservation_hdr_crt_tbl,
        p_return_status    OUT  VARCHAR2
    ) AS
    BEGIN
        IF p_resevation_dtls.count > 0 THEN
            FOR i IN p_resevation_dtls.first..p_resevation_dtls.last LOOP
                IF ( p_resevation_dtls(i).p_inventory_organization IS NULL OR p_resevation_dtls(i).p_requester IS NULL OR p_resevation_dtls(
                i).p_reason_code IS NULL OR p_resevation_dtls(i).p_reservation_type IS NULL ) THEN
                    p_return_status := 'Please enter the mandatory feilds Inventory Organization, Requestor, Reason Code, Reservation Type and Expiration Date';
                ELSE
                    INSERT INTO xxhbg_res_pre_reservation_header (
                        pre_reservation_number,
                        inventory_organization,
                        requester,
                        approver,
                        reason_code,
                        reservation_type,
                        print_number,
                        expiration_date,
                        comments,
                        status,
                        created_by,
                        created_date,
                        last_updated_by,
                        last_update_date
                    ) VALUES (
                        p_resevation_dtls(i).p_pre_reservation_number,
                        p_resevation_dtls(i).p_inventory_organization,
                        p_resevation_dtls(i).p_requester,
                        p_resevation_dtls(i).p_approver,
                        p_resevation_dtls(i).p_reason_code,
                        p_resevation_dtls(i).p_reservation_type,
                        p_resevation_dtls(i).p_print_number,
                        p_resevation_dtls(i).p_expiration_date,
                        p_resevation_dtls(i).p_comments,
                        p_resevation_dtls(i).p_status,
                        p_resevation_dtls(i).p_created_by,
                        sysdate,
                        p_resevation_dtls(i).p_last_updated_by,
                        sysdate
                    );

                    COMMIT;
                  
                END IF;
                
                -----------insert lines ---

                IF p_resevation_dtls(i).reservation_lines.count > 0 THEN
                    FOR j IN p_resevation_dtls(i).reservation_lines.first..p_resevation_dtls(i).reservation_lines.last LOOP
                        IF ( p_resevation_dtls(i).reservation_lines(j).p_inventory_organization IS NULL OR p_resevation_dtls(i).reservation_lines(
                        j).p_item_code IS NULL OR p_resevation_dtls(i).reservation_lines(j).p_status IS NULL OR p_resevation_dtls(
                        i).reservation_lines(j).p_reservation_type IS NULL ) THEN
                            p_return_status := 'Please enter the mandatory feilds Item Code, Status, Inventory organization & Reservation Type';
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
                                created_by,
                                created_date,
                                last_updated_by,
                                last_update_date,
                                reservation_number
                            ) VALUES (
                                p_resevation_dtls(i).reservation_lines(j).p_item_code,
                                p_resevation_dtls(i).reservation_lines(j).p_isbn_on_book,
                                p_resevation_dtls(i).reservation_lines(j).p_short_title,
                                p_resevation_dtls(i).reservation_lines(j).p_status,
                                p_resevation_dtls(i).reservation_lines(j).p_reservation_type,
                                p_resevation_dtls(i).reservation_lines(j).p_print_number,
                                p_resevation_dtls(i).reservation_lines(j).p_inventory_organization,
                                p_resevation_dtls(i).reservation_lines(j).p_lot_number,
                                p_resevation_dtls(i).reservation_lines(j).p_subinventory,
                                p_resevation_dtls(i).reservation_lines(j).p_requested_quantity,
                                p_resevation_dtls(i).reservation_lines(j).p_reserved_quantity,
                                p_resevation_dtls(i).reservation_lines(j).p_released_via_cuid,
                                p_resevation_dtls(i).reservation_lines(j).p_available_reserved,
                                p_resevation_dtls(i).reservation_lines(j).p_ip_only,
                                p_resevation_dtls(i).reservation_lines(j).p_pre_reserved_balance,
                                p_resevation_dtls(i).reservation_lines(j).p_usable_balance,
                                p_resevation_dtls(i).reservation_lines(j).p_end_balance,
                                p_resevation_dtls(i).reservation_lines(j).p_created_by,
                                sysdate,
                                p_resevation_dtls(i).reservation_lines(j).p_last_updated_by,
                                sysdate,
                                p_resevation_dtls(i).reservation_lines(j).p_reservation_number
                            );

                          commit;
                        END IF;
                    END LOOP;

                END IF;

            END LOOP;

        END IF;
          p_return_status := 'SUCCESS';
    END hbg_pre_res_header_create;

END xxhbg_pre_reservations_pkg;

/
