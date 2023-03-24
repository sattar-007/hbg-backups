--------------------------------------------------------
--  DDL for Package Body HBG_SO_MASS_UPDATE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."HBG_SO_MASS_UPDATE_PKG" AS

    PROCEDURE get_sales_orders (
        p_header_id           IN NUMBER,
        p_organization_id     IN NUMBER,
        p_org_name            IN VARCHAR2,
        p_invetory_item_id    IN NUMBER,
        p_item_number         IN VARCHAR2,
        p_order_number        IN VARCHAR2,
        p_cust_account_id     IN NUMBER,
      --  p_cust_acct_number    IN VARCHAR2,
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
    ) AS

        CURSOR so_cur IS
        SELECT DISTINCT
            hp.party_name,
            hp.party_id,
            dha.source_order_id,
            dha.header_id,
            dha.source_order_system,
            dla.source_line_id,
            dla.inventory_organization_id,
            dla.inventory_item_id,
            hca.cust_account_id,
            hps.party_site_id,
            org.organization_code inv_organization_code,
            hca.account_number,
            dha.status_code       header_order_status,
            dha.request_cancel_date,
            dha.freight_terms_code,
            dha.ordered_date      actual_ship_date,
            dfla.request_arrival_date,
            dla.display_line_number line_number,
            dfla.status_code line_status,
            dla.ordered_qty,
            ntt.net_total         ordered_net_qty,
            egp.item_number,
            dha.customer_po_number,
            dhcv_line.hold_code   apply_hold_reson_code,
            dla.status_code       line_status_code,
            dha.order_number,
            eib.attribute_char1   owner_code,
            eib.attribute_char2   reporting_group,
            eib.attribute_char3   category1,
            eib.attribute_char4   category2,
            egp.attribute1        offer_code,
            dla.last_update_date
        FROM
            doo_headers_all        dha,
            doo_lines_all          dla,
            doo_fulfill_lines_all  dfla,
            egp_system_items_b     egp,
            hz_cust_accounts       hca,
            hz_parties             hp,
            hz_cust_site_uses_all  hcsu,
            hz_cust_acct_sites_all hcsa,
            hz_party_sites         hps,
            doo_hold_instances     dhi_line,
            doo_hold_codes_vl      dhcv_line,
            inv_org_parameters     org,
            ego_item_eff_b         eib,
            (
                SELECT
                    SUM(dfla1.extended_amount) net_total,
                    dfla1.header_id
                FROM
                    doo_fulfill_lines_all dfla1
                WHERE
                        1 = 1
                    AND dfla1.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'SHIPPED' )
                GROUP BY
                    dfla1.header_id
            )                      ntt
        WHERE
                dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND ntt.header_id = dha.header_id
            AND dla.inventory_item_id = egp.inventory_item_id
            AND dla.inventory_organization_id = egp.organization_id
            AND dla.inventory_organization_id = org.organization_id
            AND eib.context_code(+) = 'Family Code'
            AND egp.inventory_item_id = eib.inventory_item_id (+)
            AND egp.organization_id = eib.organization_id (+)
            AND dfla.ship_to_party_id = hp.party_id
            AND dfla.bill_to_customer_id = hca.cust_account_id
            AND dfla.bill_to_site_use_id = hcsu.site_use_id
            AND dfla.ship_to_party_site_id = hps.party_site_id
         -- AND hcsu.site_use_id=dfla.BILL_TO_SITE_USE_ID
          --  AND hcsu.site_use_id = doa.cust_acct_site_use_id
            AND hcsa.cust_acct_site_id = hcsu.cust_acct_site_id
            AND hcsu.site_use_code (+) = 'BILL_TO'
            --AND hcsa.party_site_id = hps.party_site_id
            AND dla.source_line_id = dhi_line.transaction_entity_id1 (+)
            AND dhi_line.transaction_entity_name1 (+) = 'DOO_ORDER_LINES_V'
--            AND to_char(dhi_line.object_version_number) = (
--                SELECT
--                    MAX(object_version_number)
--                FROM
--                    doo_hold_instances hold_latest
--                WHERE
--                    hold_latest.transaction_entity_id1 = dla.source_line_id
--            )
            AND nvl(dhi_line.hold_release_reason_code, 'A') = 'A'
            AND dhi_line.hold_code_id = dhcv_line.hold_code_id (+)
            --AND nvl(dha.status_code, 'A') NOT IN ( 'DOO_DRAFT', 'DOO_REFERENCE' )
            AND dha.status_code = 'OPEN'
            AND dfla.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'SHIPPED' )
            AND dha.object_version_number = (
                SELECT
                    MAX(object_version_number)
                FROM
                    doo_headers_all dha_latest
                WHERE
                        dha_latest.order_number = dha.order_number
                    AND dha_latest.status_code = dha.status_code
            )
			--------------------------------------------

            AND ( p_owner_id IS NULL
                  OR eib.attribute_char1 = p_owner_id )
            AND ( p_rpg_grp IS NULL
                  OR eib.attribute_char2 = p_rpg_grp )
            AND ( p_cat1 IS NULL
                  OR eib.attribute_char3 = p_cat1 )
            AND ( p_cat2 IS NULL
                  OR eib.attribute_char4 = p_cat2 )
--            AND ( p_offer_code IS NULL
--                  OR egp.attribute1 = p_offer_code )
            AND ( p_organization_id IS NULL
                  OR hp.party_id = p_organization_id )
--            AND ( p_org_name IS NULL
--                  OR upper(hp.party_name) = upper(p_org_name) )

--            AND ( p_invetory_item_id IS NULL
--                  OR dla.inventory_item_id = p_invetory_item_id )
            AND ( p_cust_account_id IS NULL
                  OR hca.cust_account_id = p_cust_account_id )
--            AND ( p_cust_acct_number IS NULL
--                  OR hca.account_number = p_cust_acct_number )
            AND ( p_ex_cust_account_id IS NULL
                  OR hca.cust_account_id <> p_ex_cust_account_id )
--            AND ( p_ex_cust_acct_number IS NULL
--                  OR hca.account_number = p_ex_cust_acct_number )
            AND ( p_party_site_id IS NULL
                  OR hps.party_site_id = p_party_site_id )
            AND ( p_line_status IS NULL
                  OR dfla.status_code = p_line_status )
--            AND ( p_order_status IS NULL
--                  OR dha.status_code = p_order_status )
            AND ( p_from_ordered_qty IS NULL
                  OR dla.ordered_qty >= p_from_ordered_qty )
            AND ( p_to_ordered_qty IS NULL
                  OR dla.ordered_qty <= p_to_ordered_qty )
            AND ( p_from_ordered_qty IS NULL
                  OR dla.ordered_qty >= p_from_ordered_qty )
            AND ( p_from_ord_net_value IS NULL
                  OR ( ntt.net_total ) >= p_from_ord_net_value )
            AND ( p_to_ord_net_value IS NULL
                  OR ( ntt.net_total ) <= p_to_ord_net_value )
            AND ( p_po_number IS NULL
                  OR ( dha.customer_po_number IN (
                SELECT
                    regexp_substr(p_po_number, '[^,]+', 1, level)
                FROM
                    dual
                CONNECT BY
                    regexp_substr(p_po_number, '[^,]+', 1, level) IS NOT NULL
            ) ) )
            AND ( p_apply_reason_code IS NULL
                  OR dhcv_line.hold_code = p_apply_reason_code )
            AND ( p_release_reason_code IS NULL
                  OR dhcv_line.hold_code = p_release_reason_code )
            AND ( p_received_from_date IS NULL
                  OR to_char(dha.ordered_date, 'YYYY-MM-DD') >= p_received_from_date )
            AND ( p_received_to_date IS NULL
                  OR to_char(dha.ordered_date, 'YYYY-MM-DD') <= p_received_to_date )
            AND ( p_item_number IS NULL
                  OR ( egp.item_number IN (
                SELECT
                    regexp_substr(p_item_number, '[^,]+', 1, level)
                FROM
                    dual
                CONNECT BY
                    regexp_substr(p_item_number, '[^,]+', 1, level) IS NOT NULL
            ) ) )
            AND ( p_order_number IS NULL
                  OR ( dha.order_number IN (
                SELECT
                    regexp_substr(p_order_number, '[^,]+', 1, level)
                FROM
                    dual
                CONNECT BY
                    regexp_substr(p_order_number, '[^,]+', 1, level) IS NOT NULL
            ) ) )
        ORDER BY
            dla.last_update_date DESC;

    BEGIN
        DELETE hbg_so_mass_update_stg;

        COMMIT;
        FOR so_rec IN so_cur LOOP
              INSERT INTO hbg_so_mass_update_stg (
                source_order_system,                source_order_id,
                inv_organization_id,                inv_organization_code,
                inventory_item_id,                cust_account_id,
                party_name,                party_site_id,
                account_number,                line_number,
                line_status,                header_order_status,
                request_cancel_date,                freight_terms_code,
                actual_ship_date,                request_arrival_date,
                ordered_qty,                ordered_net_qty,
                item_number,                customer_po_number,
                source_line_id,                apply_reson_code,
                owner_code,                reporting_group,
                category1,                category2,
                offer_code,                apply_reson_comments,
                release_reson_code,                release_reson_comments,
                line_status_code,                order_number,
                oic_run_id,                status,
                creation_date,                created_by,
                last_updated_by,                last_update_date
            ) VALUES (
                so_rec.source_order_system,                so_rec.source_order_id,
                so_rec.inventory_organization_id,                so_rec.inv_organization_code,
                so_rec.inventory_item_id,                so_rec.cust_account_id,
                so_rec.party_name,                so_rec.party_site_id,
                so_rec.account_number,                so_rec.line_number,   so_rec.line_status,  
                so_rec.header_order_status,                so_rec.request_cancel_date,
                so_rec.freight_terms_code,                so_rec.actual_ship_date,
                so_rec.request_arrival_date,                so_rec.ordered_qty,
                so_rec.ordered_net_qty,                so_rec.item_number,
                            so_rec.customer_po_number,
                so_rec.source_line_id,                so_rec.apply_hold_reson_code,
                so_rec.owner_code,                so_rec.reporting_group,
                so_rec.category1,                so_rec.category2,
                so_rec.offer_code,                NULL,
                NULL,                NULL,                so_rec.line_status_code,
                so_rec.order_number,                p_oic_run_id,                'N',
                sysdate,                'OIC',                'OIC',
                sysdate            );

            COMMIT;
        END LOOP;

        x_staus_code := 'SUCCESS';
    EXCEPTION
        WHEN OTHERS THEN
            x_staus_code := 'Unhandled exception while inserting data into stage :' || sqlerrm;
    END get_sales_orders;

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
    ) AS
    BEGIN
        IF p_hold_flag = 'Apply' THEN
            UPDATE hbg_so_mass_update_stg
            SET
                new_apply_reson_comments = p_new_apply_reason_comments,
                new_apply_reson_code = p_new_apply_reason_code,
                hold_action = p_hold_flag,
                status = 'V'
            WHERE
                    1 = 1
                AND ( p_apply_reason_code IS NULL
                      OR nvl(apply_reson_code, 1) = nvl(p_apply_reason_code, 1) )
                AND ( p_order_status IS NULL
                      OR header_order_status = p_order_status )
                AND ( p_inventory_item_id IS NULL
                      OR inventory_item_id = p_inventory_item_id )
                AND ( p_line_status IS NULL
                      OR line_status_code = p_line_status )
                AND ( p_from_ordered_qty IS NULL
                      OR ordered_qty = p_from_ordered_qty )
                AND status = 'N';

            COMMIT;
            x_staus_code := 'SUCCESS';
        END IF;

        IF p_hold_flag = 'Release' THEN
            UPDATE hbg_so_mass_update_stg
            SET
                new_release_reson_comments = p_new_release_reason_comments,
                new_release_reson_code = p_new_release_reason_code,
                hold_action = p_hold_flag,
                status = 'V'
            WHERE
                    1 = 1
                AND ( apply_reson_code IS NULL
                      OR nvl(apply_reson_code, 1) = nvl(p_release_reason_code, 1) )
                AND ( p_order_status IS NULL
                      OR header_order_status = p_order_status )
                AND ( p_inventory_item_id IS NULL
                      OR inventory_item_id = p_inventory_item_id )
                AND ( p_line_status IS NULL
                      OR line_status_code = p_line_status )
                AND ( p_from_ordered_qty IS NULL
                      OR ordered_qty = p_from_ordered_qty )
                AND status = 'N';

            COMMIT;
            x_staus_code := 'SUCCESS';
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            x_staus_code := 'Unhandled exception while inserting data into stage :' || sqlerrm;
    END update_sales_orders;

END hbg_so_mass_update_pkg;

/
