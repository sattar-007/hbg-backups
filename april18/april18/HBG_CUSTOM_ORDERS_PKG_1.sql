--------------------------------------------------------
--  DDL for Package Body HBG_CUSTOM_ORDERS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."HBG_CUSTOM_ORDERS_PKG" IS

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
    ) IS
        l_temp_cnt NUMBER := 0;
    BEGIN
        IF ( p_template_name IS NULL OR p_template_description IS NULL ) THEN
            p_return_status := ' Template Name, Template Description cannot be blank';
        ELSE
            BEGIN
                SELECT
                    COUNT(*)
                INTO l_temp_cnt
                FROM
                    hbg_co_template_headers
                WHERE
                    template_name = p_template_name 
--                        and template_description = p_template_description
                    ;

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

            IF l_temp_cnt > 0 THEN
                p_return_status := 'Record with template name '
                                   || p_template_name
                                   || ' already exists, please enter the unique value';
            ELSE
                INSERT INTO hbg_co_template_headers (
                    template_name,
                    template_description,
                    cust_account_id,
                    owner_code,
                    owner_name,
                    account_number,
                    account_description,
                    start_date,
                    end_date,
                    entered_by,
                    entered_date,
                    updated_by,
                    updated_date
                ) VALUES (
                    p_template_name,
                    p_template_description,
                    p_cust_account_id,
                    p_owner_code,
                    p_owner_name,
                    p_account_number,
                    p_account_description,
                    to_date(p_start_date, 'YYYY-MM-DD'),
                    to_date(p_end_date, 'YYYY-MM-DD'),
                    p_entered_by,
                    sysdate,
                    p_updated_by,
                    sysdate
                );

                p_return_status := 'SUCCESS';
            END IF;

            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating Template Header :' || sqlerrm;
    END hbg_co_template_headers_create;

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
    ) AS
        l_status VARCHAR2(20);
    BEGIN
        IF p_template_id IS NOT NULL THEN
            UPDATE hbg_co_template_headers
            SET
                template_name = p_template_name,
                template_description = p_template_description,
                cust_account_id = p_cust_account_id,
                owner_code = p_owner_code,
                owner_name = p_owner_name,
                account_number = p_account_number,
                account_description = p_account_description,
                start_date = to_date(p_start_date, 'YYYY-MM-DD'),
                end_date = to_date(p_end_date, 'YYYY-MM-DD'),
                updated_by = p_updated_by,
                updated_date = sysdate
            WHERE
                template_id = p_template_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Headers :' || sqlerrm;
    END hbg_co_template_headers_update;

    PROCEDURE hbg_co_template_lines_create (
        p_template_id       IN NUMBER,
        p_sequence          IN NUMBER,
        p_category_code     IN VARCHAR2,
        p_category_name     IN VARCHAR2,
        p_instructions_text IN VARCHAR2,
        p_entered_by        IN VARCHAR2,
        p_updated_by        IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    ) IS
        l_templn_cnt      NUMBER := 0;
        l_sequence_exists NUMBER := 0;
    BEGIN
        IF ( p_template_id IS NULL ) THEN
            p_return_status := ' Template Header Id cannot be blank';
        ELSE
            BEGIN
                SELECT
                    COUNT(*)
                INTO l_templn_cnt
                FROM
                    hbg_co_template_lines
                WHERE
                        template_id = p_template_id
                    AND category_code = p_category_code;

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

            BEGIN
                SELECT
                    COUNT(*)
                INTO l_sequence_exists
                FROM
                    hbg_co_template_lines
                WHERE
                        template_id = p_template_id
                    AND sequence = p_sequence;

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

            IF l_templn_cnt > 0 THEN
                p_return_status := 'Record with template and category combination already exists, please select the valid combination';
            ELSIF l_sequence_exists > 0 THEN
                p_return_status := 'Sequence '
                                   || p_sequence
                                   || ' already used under this template, please enter the valid Sequence Number';
            ELSE
                INSERT INTO hbg_co_template_lines (
                    template_id,
                    sequence,
                    category_code,
                    category_name,
                    instructions_text,
                    entered_by,
                    entered_date,
                    updated_by,
                    updated_date
                ) VALUES (
                    p_template_id,
                    p_sequence,
                    p_category_code,
                    p_category_name,
                    p_instructions_text,
                    p_entered_by,
                    sysdate,
                    p_updated_by,
                    sysdate
                );

                COMMIT;
                p_return_status := 'SUCCESS';
            END IF;

            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating Template Line :' || sqlerrm;
    END hbg_co_template_lines_create;

    PROCEDURE hbg_co_template_lines_update (
        p_line_id           IN NUMBER,
        p_template_id       IN NUMBER,
        p_sequence          IN NUMBER,
        p_category_code     IN VARCHAR2,
        p_category_name     IN VARCHAR2,
        p_instructions_text IN VARCHAR2,
        p_updated_by        IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    ) IS
    BEGIN
        IF p_line_id IS NOT NULL THEN
            UPDATE hbg_co_template_lines
            SET
                template_id = p_template_id,
                sequence = p_sequence,
                category_code = p_category_code,
                category_name = p_category_name,
                instructions_text = p_instructions_text,
                updated_by = p_updated_by,
                updated_date = sysdate
            WHERE
                line_id = p_line_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Lines :' || sqlerrm;
    END;

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
    ) IS
        l_hdr_cnt NUMBER := 0;
    BEGIN
        IF ( p_organization_number IS NULL OR p_organization_name IS NULL OR p_account_number IS NULL ) THEN
            p_return_status := ' Organization Number, Account Number cannot be blank';
        ELSE
            BEGIN
                SELECT
                    COUNT(*)
                INTO l_hdr_cnt
                FROM
                    hbg_co_rules_headers
                WHERE
                        organization_number = p_organization_number
                    AND account_number = p_account_number
                    AND nvl(destination_account, '#NULL') = p_destination_account;

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

            IF l_hdr_cnt > 0 THEN
                p_return_status := ' Organization Number or Account Number already exists Please Create unique Organization Number and Account Number';
            ELSE
                INSERT INTO hbg_co_rules_headers (
                    organization_id,
                    organization_number,
                    organization_name,
                    cust_account_id,
                    account_number,
                    account_description,
                    destination_account,
                    department_id,
                    sales_channel,
                    entered_by,
                    entered_date,
                    updated_by,
                    updated_date,
                    start_date,
                    end_date
                ) VALUES (
                    p_organization_id,
                    p_organization_number,
                    p_organization_name,
                    p_cust_account_id,
                    p_account_number,
                    p_account_description,
                    p_destination_account,
                    p_department_id,
                    p_sales_channel,
                    p_entered_by,
                    sysdate,
                    p_updated_by,
                    sysdate,
                    to_date(p_start_date, 'YYYY-MM-DD'),
                    to_date(p_end_date, 'YYYY-MM-DD')
                );

                p_return_status := 'SUCCESS';
            END IF;

            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating Rule Header :' || sqlerrm;
    END;

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
    ) AS
    BEGIN
        IF p_rule_id IS NOT NULL THEN
            UPDATE hbg_co_rules_headers
            SET
                organization_id = p_organization_id,
                organization_number = p_organization_number,
                organization_name = p_organization_name,
                cust_account_id = p_cust_account_id,
                account_number = p_account_number,
                account_description = p_account_description,
                destination_account = p_destination_account,
                department_id = p_department_id,
                sales_channel = p_sales_channel,
                start_date = to_date(p_start_date, 'YYYY-MM-DD'),
                end_date = to_date(p_end_date, 'YYYY-MM-DD'),
                updated_by = p_updated_by
            WHERE
                rule_id = p_rule_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Rule Header :' || sqlerrm;
    END;

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
    ) IS
        l_rule_ln_cnt   NUMBER := 0;
        l_seq_existence NUMBER := 0;
    BEGIN
        IF ( p_sequence IS NULL OR p_rule_id IS NULL ) THEN
            p_return_status := ' Sequence, Rule Id cannot be blank';
        ELSE
            BEGIN
                SELECT
                    COUNT(*)
                INTO l_rule_ln_cnt
                FROM
                    hbg_co_rules_lines
                WHERE
                        rule_id = p_rule_id
--                    AND sequence = p_sequence
                    AND nvl(ship_to_number, '#NULL') = nvl(p_ship_to_number, '#NULL')
--                    AND ship_to_name = p_ship_to_name
                    AND nvl(owner_code, '#NULL') = nvl(p_owner_code, '#NULL')
                    AND nvl(reporting_group, '#NULL') = nvl(p_reporting_group, '#NULL')
                    AND nvl(publisher, '#NULL') = nvl(p_publisher, '#NULL')
                    AND nvl(imprint, '#NULL') = nvl(p_imprint, '#NULL')
                    AND nvl(format, '#NULL') = nvl(p_format, '#NULL')
                    AND nvl(sub_format, '#NULL') = nvl(p_sub_format, '#NULL')
                    AND nvl(item, '#NULL') = nvl(p_item, '#NULL');

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

            BEGIN
                SELECT
                    COUNT(*)
                INTO l_seq_existence
                FROM
                    hbg_co_rules_lines
                WHERE
                        rule_id = p_rule_id
                    AND sequence = p_sequence;

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

            IF l_rule_ln_cnt > 0 THEN
                p_return_status := 'A record with this combination already exists, please enter the valid combination';
            ELSIF l_seq_existence > 0 THEN
                p_return_status := 'Sequence '
                                   || p_sequence
                                   || ' already used under this Rule, Please Select the Valid Sequence Number';
            ELSE
                INSERT INTO hbg_co_rules_lines (
                    rule_id,
                    sequence,
                    ship_to_number,
                    ship_to_name,
                    owner_code,
                    owner_name,
                    reporting_group,
                    reporting_group_description,
                    publisher,
                    publisher_name,
                    imprint,
                    imprint_name,
                    format,
                    format_name,
                    sub_format,
                    sub_format_name,
                    item,
                    price_on_book,
                    shrink_wrap,
                    master_pack,
                    inner_pack,
                    new_pack_quantity,
                    entered_by,
                    entered_date,
                    updated_by,
                    updated_date
                ) VALUES (
                    p_rule_id,
                    p_sequence,
                    p_ship_to_number,
                    p_ship_to_name,
                    p_owner_code,
                    p_owner_name,
                    p_reporting_group,
                    p_reporting_group_description,
                    p_publisher,
                    p_publisher_name,
                    p_imprint,
                    p_imprint_name,
                    p_format,
                    p_format_name,
                    p_sub_format,
                    p_sub_format_name,
                    p_item,
                    p_price_on_book,
                    p_shrink_wrap,
                    p_master_pack,
                    p_inner_pack,
                    p_new_pack_quantity,
                    p_entered_by,
                    sysdate,
                    p_updated_by,
                    sysdate
                );

                p_return_status := 'SUCCESS';
            END IF;

            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating Rule Lines :' || sqlerrm;
    END;

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
    ) IS
    BEGIN
        IF ( p_sequence IS NULL OR p_rule_id IS NULL ) THEN
            p_return_status := ' Sequence, Rule Id cannot be blank';
        ELSE
            UPDATE hbg_co_rules_lines
            SET
                rule_id = p_rule_id,
                sequence = p_sequence,
                ship_to_number = p_ship_to_number,
                ship_to_name = p_ship_to_name,
                owner_code = p_owner_code,
                owner_name = p_owner_name,
                reporting_group = p_reporting_group,
                reporting_group_description = p_reporting_group_description,
                publisher = p_publisher,
                publisher_name = p_publisher_name,
                imprint = p_imprint,
                imprint_name = p_imprint_name,
                format = p_format,
                format_name = p_format_name,
                sub_format = p_sub_format,
                sub_format_name = p_sub_format_name,
                item = p_item,
                price_on_book = p_price_on_book,
                shrink_wrap = p_shrink_wrap,
                master_pack = p_master_pack,
                inner_pack = p_inner_pack,
                new_pack_quantity = p_new_pack_quantity,
                updated_by = p_updated_by
            WHERE
                rule_line_id = p_rule_line_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating Rule Lines :' || sqlerrm;
    END;

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
    ) IS
        l_actn_cnt NUMBER := 0;
    BEGIN
        IF ( p_rule_line_id IS NULL ) THEN
            p_return_status := ' Rule Line Id cannot be blank';
        ELSE
            BEGIN
                SELECT
                    COUNT(*)
                INTO l_actn_cnt
                FROM
                    hbg_co_line_actions
                WHERE
                        rule_line_id = p_rule_line_id
                    AND template_level = p_template_level
                    AND template_name = p_template_name
                    AND template_id = p_template_id
                    AND hold_level = p_hold_level
                    AND hold_name = p_hold_name;

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

            IF l_actn_cnt > 0 THEN
                p_return_status := 'A Record with this combination already exists, please enter the valid combination';
            ELSE
                INSERT INTO hbg_co_line_actions (
                    rule_line_id,
                    template_level,
                    template_name,
                    template_id,
                    hold_flag,
                    hold_level,
                    hold_name,
                    start_date,
                    end_date,
                    entered_by,
                    entered_date,
                    updated_by,
                    updated_date
                ) VALUES (
                    p_rule_line_id,
                    p_template_level,
                    p_template_name,
                    p_template_id,
                    p_hold_flag,
                    p_hold_level,
                    p_hold_name,
                    to_date(p_start_date, 'YYYY-MM-DD'),
                    to_date(p_end_date, 'YYYY-MM-DD'),
                    p_entered_by,
                    sysdate,
                    p_updated_by,
                    sysdate
                );

                p_return_status := 'SUCCESS';
            END IF;

            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating Line Actions :' || sqlerrm;
    END;

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
    ) AS
    BEGIN
        IF p_line_action_id IS NOT NULL THEN
            UPDATE hbg_co_line_actions
            SET
                rule_line_id = p_rule_line_id,
                template_level = p_template_level,
                template_name = p_template_name,
                template_id = p_template_id,
                hold_flag = p_hold_flag,
                hold_level = p_hold_level,
                hold_name = p_hold_name,
                start_date = to_date(p_start_date, 'YYYY-MM-DD'),
                end_date = to_date(p_end_date, 'YYYY-MM-DD'),
                updated_by = p_updated_by,
                updated_date = sysdate
            WHERE
                line_action_id = p_line_action_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Line Actions :' || sqlerrm;
    END;

    PROCEDURE hbg_custom_orders_val (
        p_source_line_id IN VARCHAR2,
        p_batch_id       IN VARCHAR2,
        return_status    OUT VARCHAR2
    ) IS

        CURSOR c_get_validation_lines IS
        SELECT
            dha.order_number,
            dha.source_order_id,
            dla.source_line_id,
            hcrh.rule_id,
            dheb_destination.attribute_char1,
            hcrh.destination_account,
            hps.party_site_number,
            hcrl.sequence,
            hcla.line_action_id,
            hcla.template_level,
            hcth.template_name,
            hctl.sequence   template_line_seq,
            hctl.category_code,
            hctl.instructions_text,
            hcla.hold_flag,
            hcla.hold_level,
            hcla.hold_name,
            dha.source_order_id
            || '-'
            || dla.source_line_id
            || '-'
            || hcrh.rule_id compare_string
        FROM
            hbg_co_template_lines   hctl,
            hbg_co_template_headers hcth,
            hbg_co_line_actions     hcla,
            hbg_co_rules_lines      hcrl,
            hbg_co_rules_headers    hcrh,
            hz_party_sites          hps,
            doo_headers_eff_b       dheb_destination,
            doo_fulfill_lines_eff_b dfleb_co,
            doo_headers_eff_b       dheb_co,
            doo_fulfill_lines_all   dfla,
            doo_lines_all           dla,
            doo_headers_all         dha
        WHERE
                1 = 1
            AND dla.source_line_id = nvl(p_source_line_id, dla.source_line_id)
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dha.status_code NOT IN ( 'DOO_DRAFT', 'DOO_REFERENCE' )
            AND dfla.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'BACKORDERED',
                                          'SHIPPED' )
            AND dha.header_id = dheb_co.header_id (+)
            AND dheb_co.context_code (+) = 'Custom Order'
            AND dfla.fulfill_line_id = dfleb_co.fulfill_line_id (+)
            AND dfleb_co.context_code (+) = 'Custom Order'
            AND nvl(nvl(dfleb_co.attribute_char2, dheb_co.attribute_char1), 'N') = 'Y'
            AND dha.header_id = dheb_destination.header_id (+)
            AND dheb_destination.context_code (+) = 'General'
            AND dfla.ship_to_party_site_id = hps.party_site_id (+)
            AND dfla.bill_to_customer_id = hcrh.cust_account_id
            AND nvl(dheb_destination.attribute_char1, '#NULL') = nvl(hcrh.destination_account, nvl(dheb_destination.attribute_char1, '#NULL'))
            AND hcrh.rule_id = hcrl.rule_id
            AND nvl(hps.party_site_number, '#NULL') = nvl(hcrl.ship_to_number, nvl(hps.party_site_number, '#NULL'))
            AND hcrl.rule_line_id = hcla.rule_line_id
            AND hcla.template_id = hcth.template_id
            AND hcth.template_id = hctl.template_id
            AND dha.object_version_number = (
                SELECT
                    MAX(object_version_number)
                FROM
                    doo_headers_all
                WHERE
                        dha.source_order_id = source_order_id
                    AND dha.source_order_system = source_order_system
                    AND status_code <> 'DOO_REFERENCE'
            )
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    hbg_co_attachments_ext
                WHERE
                    compare_string = dha.source_order_id
                                     || '-'
                                     || dla.source_line_id
                                     || '-'
                                     || hcrh.rule_id
            )
        ORDER BY
            dha.order_number,
            dha.source_order_id,
            dla.source_line_id,
            hcrh.rule_id,
            hcrl.sequence;

        CURSOR c_get_validation_lines_int IS
        SELECT
            dha.order_number,
            dha.source_order_id,
            dla.source_line_id,
            hcrh.rule_id,
            dheb_destination.attribute_char1,
            hcrh.destination_account,
            hps.party_site_number,
            hcrl.sequence,
            hcla.line_action_id,
            hcla.template_level,
            hcth.template_name,
            hctl.sequence   template_line_seq,
            hctl.category_code,
            hctl.instructions_text,
            hcla.hold_flag,
            hcla.hold_level,
            hcla.hold_name,
            dha.source_order_id
            || '-'
            || dla.source_line_id
            || '-'
            || hcrh.rule_id compare_string
        FROM
            hbg_co_template_lines   hctl,
            hbg_co_template_headers hcth,
            hbg_co_line_actions     hcla,
            hbg_co_rules_lines      hcrl,
            hbg_co_rules_headers    hcrh,
            hz_party_sites          hps,
            doo_headers_eff_b       dheb_destination,
            doo_fulfill_lines_eff_b dfleb_co,
            doo_headers_eff_b       dheb_co,
            doo_fulfill_lines_all   dfla,
            doo_lines_all           dla,
            doo_headers_all         dha,
            doo_headers_eff_b       dheb_batch
        WHERE
                1 = 1
            AND dla.source_line_id = nvl(p_source_line_id, dla.source_line_id)
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dha.status_code IN ( 'DOO_DRAFT' )
            AND dfla.status_code IN ( 'CREATED', 'NOT_STARTED' )
            AND dha.header_id = dheb_batch.header_id (+)
            AND dheb_batch.context_code (+) = 'EDI General'
            AND dheb_batch.attribute_char18 = p_batch_id
            AND dha.header_id = dheb_co.header_id (+)
            AND dheb_co.context_code (+) = 'Custom Order'
            AND dfla.fulfill_line_id = dfleb_co.fulfill_line_id (+)
            AND dfleb_co.context_code (+) = 'Custom Order'
            AND nvl(nvl(dfleb_co.attribute_char2, dheb_co.attribute_char1), 'N') = 'Y'
            AND dha.header_id = dheb_destination.header_id (+)
            AND dheb_destination.context_code (+) = 'General'
            AND dfla.ship_to_party_site_id = hps.party_site_id (+)
            AND dfla.bill_to_customer_id = hcrh.cust_account_id
            AND nvl(dheb_destination.attribute_char1, '#NULL') = nvl(hcrh.destination_account, nvl(dheb_destination.attribute_char1, '#NULL'))
            AND hcrh.rule_id = hcrl.rule_id
            AND nvl(hps.party_site_number, '#NULL') = nvl(hcrl.ship_to_number, nvl(hps.party_site_number, '#NULL'))
            AND hcrl.rule_line_id = hcla.rule_line_id
            AND hcla.template_id = hcth.template_id
            AND hcth.template_id = hctl.template_id
            AND dha.object_version_number = (
                SELECT
                    MAX(object_version_number)
                FROM
                    doo_headers_all
                WHERE
                        dha.source_order_id = source_order_id
                    AND dha.source_order_system = source_order_system
                    AND status_code <> 'DOO_REFERENCE'
            )
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    hbg_co_attachments_ext
                WHERE
                    compare_string = dha.source_order_id
                                     || '-'
                                     || dla.source_line_id
                                     || '-'
                                     || hcrh.rule_id
            )
        ORDER BY
            dha.order_number,
            dha.source_order_id,
            dla.source_line_id,
            hcrh.rule_id,
            hcrl.sequence;

    BEGIN
        IF ( p_batch_id IS NULL ) THEN
            FOR c_get_validation_rec IN c_get_validation_lines LOOP
                return_status := 'Success';
            END LOOP;
        ELSE
            FOR c_get_validation_rec IN c_get_validation_lines_int LOOP
                return_status := 'Success';
            END LOOP;
        END IF;
    END hbg_custom_orders_val;

END;

/
