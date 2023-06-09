--------------------------------------------------------
--  DDL for Package Body HBG_SO_DIST_TITLE_RIGHTS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."HBG_SO_DIST_TITLE_RIGHTS_PKG" IS

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Country Group & Associations Deletion                        
-- |Description      : This Program is used to delete the country associations available under particular group 					    
-- +===================================================================+

    PROCEDURE hbg_country_assoc_deletion (
        p_country_id       IN VARCHAR2,
        p_country_group_id IN NUMBER,
        p_return_status    OUT VARCHAR2
    ) IS
        l_return_status VARCHAR2(200);
    BEGIN
        l_return_status := 'SUCCESS';
        IF ( p_country_id LIKE 'All rows are selected except row key(s)%' ) THEN
            DELETE FROM hbg_country_group_assoc_ext
            WHERE
                    1 = 1
                AND country_id NOT IN (
                    SELECT
                        TRIM(regexp_substr(substr(p_country_id, instr(p_country_id, ':') + 1), '[^,]+', 1, level))
                    FROM
                        dual
                    CONNECT BY
                        regexp_substr(substr(p_country_id, instr(p_country_id, ':') + 1), '[^,]+', 1, level) IS NOT NULL
                )
                AND country_group_id = p_country_group_id;

        ELSIF ( p_country_id LIKE 'All rows are selected' ) THEN
            DELETE FROM hbg_country_group_assoc_ext
            WHERE
                    1 = 1
                AND country_group_id = p_country_group_id;

        ELSE
            DELETE FROM hbg_country_group_assoc_ext
            WHERE
                    1 = 1
                AND country_id IN (
                    SELECT
                        TRIM(regexp_substr(substr(p_country_id, instr(p_country_id, ':') + 1), '[^,]+', 1, level))
                    FROM
                        dual
                    CONNECT BY
                        regexp_substr(substr(p_country_id, instr(p_country_id, ':') + 1), '[^,]+', 1, level) IS NOT NULL
                )
                AND country_group_id = p_country_group_id;

        END IF;

        p_return_status := l_return_status;
    EXCEPTION
        WHEN OTHERS THEN
            l_return_status := sqlerrm;
            p_return_status := l_return_status;
    END hbg_country_assoc_deletion;

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Country Group Update                        
-- |Description      : This Program is used to Update the country group information  					    
-- +===================================================================+

    PROCEDURE hbg_country_group_update (
        p_country_group_id   IN NUMBER,
        p_comments           IN VARCHAR2,
        p_country_group_name IN VARCHAR2,
        p_enabled_flag       IN VARCHAR2,
        p_return_status      OUT VARCHAR2
    ) IS
        l_return_status VARCHAR2(200);
    BEGIN
        l_return_status := 'SUCCESS';
        UPDATE hbg_country_groups_ext
        SET
            country_group_name = p_country_group_name,
            comments = p_comments,
            enabled_flag = p_enabled_flag
        WHERE
            country_group_id = p_country_group_id;

        p_return_status := l_return_status;
    EXCEPTION
        WHEN OTHERS THEN
            l_return_status := sqlerrm;
            p_return_status := l_return_status;
    END hbg_country_group_update;

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Country Group Update                        
-- |Description      : This Program is used to create the association with the country group  					    
-- +===================================================================+

    PROCEDURE hbg_add_country_assocation (
        p_country_group_id IN NUMBER,
        p_country_id       IN NUMBER,
        p_created_by       IN VARCHAR2,
        p_last_updated_by  IN VARCHAR2,
        p_return_status    OUT VARCHAR2
    ) IS
        l_return_status VARCHAR2(200) := 'SUCCESS';
        l_count         NUMBER;
        l_country_code  VARCHAR2(200);
    BEGIN
        BEGIN
            SELECT
                COUNT(1)
            INTO l_count
            FROM
                hbg_country_group_assoc_ext
            WHERE
                    country_id = p_country_id
                AND country_group_id = p_country_group_id;

        EXCEPTION
            WHEN OTHERS THEN
                l_return_status := sqlerrm;
                p_return_status := l_return_status;
        END;

        IF ( l_count = 0 ) THEN
            BEGIN
                SELECT
                    geography_code
                INTO l_country_code
                FROM
                    hz_geographies
                WHERE
                        geography_id = p_country_id
                    AND geography_type = 'COUNTRY';

            EXCEPTION
                WHEN OTHERS THEN
                    l_return_status := sqlerrm;
                    p_return_status := l_return_status;
            END;

            IF ( l_country_code IS NOT NULL ) THEN
                BEGIN
                    INSERT INTO hbg_country_group_assoc_ext (
                        country_group_id,
                        country_id,
                        country_code,
                        creation_date,
                        created_by,
                        last_update_date,
                        last_updated_by
                    ) VALUES (
                        p_country_group_id,
                        p_country_id,
                        l_country_code, -- (select country_code from hz_geographies where geography_id = p_country_id)
                        sysdate,
                        p_created_by,
                        sysdate,
                        p_last_updated_by
                    );

                    COMMIT;
                    p_return_status := l_return_status;
                EXCEPTION
                    WHEN OTHERS THEN
                        p_return_status := sqlerrm;
                END;

            ELSE
                p_return_status := 'Country Code Selected Does not Exists';
            END IF;

        ELSE
            p_return_status := 'Country Group and Country Association already exists';
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := sqlerrm;
    END hbg_add_country_assocation;

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Country Group Update                        
-- |Description      : This Program is used to create the association with the country group  					    
-- +===================================================================+

    PROCEDURE hbg_create_country_group (
        p_country_group_code IN VARCHAR2,
        p_country_group_name IN VARCHAR2,
        p_comments           IN VARCHAR2,
        p_enabled_flag       IN VARCHAR2,
        p_created_by         IN VARCHAR2,
        p_last_updated_by    IN VARCHAR2,
        p_return_status      OUT VARCHAR2,
        p_country_group_id   OUT NUMBER
    ) IS
        l_return_status VARCHAR2(200);
        l_count         NUMBER;
    BEGIN
        l_return_status := 'SUCCESS';
        l_count := 1;
        BEGIN
            SELECT
                COUNT(1)
            INTO l_count
            FROM
                hbg_country_groups_ext
            WHERE
                upper(country_group_code) = upper(p_country_group_code);

        END;

        IF (
            l_count = 0
            AND p_country_group_code IS NOT NULL
        ) THEN
            INSERT INTO hbg_country_groups_ext (
                country_group_code,
                country_group_name,
                comments,
                enabled_flag,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date
            ) VALUES (
                p_country_group_code,
                p_country_group_name,
                p_comments,
                p_enabled_flag,
                p_created_by,
                sysdate,
                p_last_updated_by,
                sysdate
            );

            COMMIT;
            p_return_status := l_return_status;
            p_country_group_id := hbg_country_groups_seq.currval;
        ELSIF ( p_country_group_code IS NULL ) THEN
            p_return_status := 'Country Group is mandatory';
        ELSE
            p_return_status := 'Country Code with this information already exists';
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := sqlerrm;
    END hbg_create_country_group;

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Country Group Copy & Edit                        
-- |Description      : This Program is used to create using the copy & Edit of existing country group  					    
-- +===================================================================+

    PROCEDURE hbg_copyedit_country_group (
        p_country_group      IN NUMBER,
        p_country_group_code IN VARCHAR2,
        p_country_group_name IN VARCHAR2,
        p_comments           IN VARCHAR2,
        p_enabled_flag       IN VARCHAR2,
        p_created_by         IN VARCHAR2,
        p_last_updated_by    IN VARCHAR2,
        p_return_status      OUT VARCHAR2,
        p_country_group_id   OUT NUMBER
    ) IS
        l_return_status VARCHAR2(200);
        l_count         NUMBER;
    BEGIN
        l_return_status := 'SUCCESS';
        l_count := 1;
        BEGIN
            SELECT
                COUNT(1)
            INTO l_count
            FROM
                hbg_country_groups_ext
            WHERE
                upper(country_group_code) = upper(p_country_group_code);

        END;

        IF (
            l_count = 0
            AND p_country_group_code IS NOT NULL
        ) THEN
            INSERT INTO hbg_country_groups_ext (
                country_group_code,
                country_group_name,
                comments,
                enabled_flag,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date
            ) VALUES (
                p_country_group_code,
                p_country_group_name,
                p_comments,
                p_enabled_flag,
                p_created_by,
                sysdate,
                p_last_updated_by,
                sysdate
            );

            COMMIT;
            INSERT INTO hbg_country_group_assoc_ext (
                country_group_id,
                country_id,
                country_code,
                creation_date,
                created_by,
                last_update_date,
                last_updated_by
            )
                SELECT
                    hbg_country_groups_seq.CURRVAL,
                    country_id,
                    country_code,
                    sysdate,
                    p_created_by,
                    sysdate,
                    p_last_updated_by
                FROM
                    hbg_country_group_assoc_ext
                WHERE
                    country_group_id = p_country_group;

            p_return_status := l_return_status;
            p_country_group_id := hbg_country_groups_seq.currval;
        ELSIF ( p_country_group_code IS NULL ) THEN
            p_return_status := 'Country Group is mandatory';
        ELSE
            p_return_status := 'Country Code with this information already exists';
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := sqlerrm;
    END hbg_copyedit_country_group;

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Distribution Rights Creation                        
-- |Description      : This Program is used to create distribution rights  					    
-- +===================================================================+

    PROCEDURE hbg_dist_rights_creation (
        p_owner             IN VARCHAR2,
        p_reporting_group   IN VARCHAR2,
        p_category_1        IN VARCHAR2,
        p_category_2        IN VARCHAR2,
        p_format            IN VARCHAR2,
        p_subformat         IN VARCHAR2,
        p_from_pubdate      IN DATE,
        p_to_pubdate        IN DATE,
        p_country_group     IN NUMBER,
        p_country_code      IN NUMBER,
        p_edition           IN VARCHAR2,
        p_item_number       IN VARCHAR2,
        p_account_number    IN NUMBER,
        p_account_type      IN VARCHAR2,
        p_default_acct_type IN VARCHAR2,
        p_outcome           IN VARCHAR2,
        p_start_date        IN DATE,
        p_end_date          IN DATE,
        p_group_rule        IN VARCHAR2,
        p_comments          IN VARCHAR2,
        p_created_by        IN VARCHAR2,
        p_last_updated_by   IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    ) IS
        l_existing_count NUMBER;
    BEGIN
        BEGIN
            SELECT
                COUNT(1)
            INTO l_existing_count
            FROM
                hbg_dist_rights_ext
            WHERE
                    1 = 1
                AND nvl(owner, '999999') = nvl(p_owner, '999999')
                AND nvl(reporting_group, '999999') = nvl(p_reporting_group, '999999')
                AND nvl(category_1, '999999') = nvl(p_category_1, '999999')
                AND nvl(category_2, '999999') = nvl(p_category_2, '999999')
                AND nvl(format, '999999') = nvl(p_format, '999999')
                AND nvl(sub_format, '999999') = nvl(p_subformat, '999999')
                AND nvl(edition, '999999') = nvl(p_edition, '999999')
                AND nvl(item_number, '999999') = nvl(p_item_number, '999999')
                AND nvl(from_pub_date, sysdate) = nvl(p_from_pubdate, sysdate)
                AND nvl(to_pub_date, sysdate) = nvl(p_to_pubdate, sysdate)
                AND nvl(country_group_id, 999999) = nvl(p_country_group, 999999)
                AND nvl(country_id, 999999) = nvl(p_country_code, 999999)
                AND nvl(cust_account_id, 999999) = nvl(p_account_number, 999999)
                AND nvl(account_type, '999999') = nvl(p_account_type, '999999')
                AND nvl(default_account_type, '999999') = nvl(p_default_acct_type, '999999')
                AND ( nvl(p_start_date, sysdate) BETWEEN start_date AND nvl(end_date, TO_DATE('4712-12-31', 'yyyy-mm-dd'))
                      OR nvl(p_end_date, sysdate) BETWEEN start_date AND nvl(end_date, TO_DATE('4712-12-31', 'yyyy-mm-dd')) );

        EXCEPTION
            WHEN OTHERS THEN
                l_existing_count := 0;
        END;

        IF ( l_existing_count > 0 ) THEN
            p_return_status := 'Rule Combination within the date range already exists, enter a new rule';
        ELSE
            INSERT INTO hbg_dist_rights_ext (
                owner,
                reporting_group,
                category_1,
                category_2,
                format,
                sub_format,
                edition,
                item_number,
                from_pub_date,
                to_pub_date,
                country_group_id,
                country_id,
                cust_account_id,
                account_type,
                default_account_type,
                outcome,
                comments,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                rules_group,
                start_date,
                end_date
            ) VALUES (
                p_owner,
                p_reporting_group,
                p_category_1,
                p_category_2,
                p_format,
                p_subformat,
                p_edition,
                p_item_number,
                p_from_pubdate,
                p_to_pubdate,
                p_country_group,
                p_country_code,
                p_account_number,
                p_account_type,
                p_default_acct_type,
                p_outcome,
                p_comments,
                p_created_by,
                sysdate,
                p_last_updated_by,
                sysdate,
                p_group_rule,
                p_start_date,
                p_end_date
            );

            p_return_status := 'SUCCESS';
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := sqlerrm;
    END hbg_dist_rights_creation;

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Distribution Rights Update                        
-- |Description      : This Program is used to update distribution rights  					    
-- +===================================================================+

    PROCEDURE hbg_dist_rights_update (
        p_distribution_right_id IN NUMBER,
        p_end_date              IN DATE,
        p_group_rule            IN VARCHAR2,
        p_comments              IN VARCHAR2,
        p_last_updated_by       IN VARCHAR2,
        p_return_status         OUT VARCHAR2
    ) IS
        l_return_status VARCHAR2(200) := NULL;
    BEGIN
        UPDATE hbg_dist_rights_ext
        SET
            end_date = p_end_date,
            comments = p_comments,
            rules_group = p_group_rule,
            last_updated_by = p_last_updated_by,
            last_update_date = sysdate
        WHERE
            distribution_right_id = p_distribution_right_id;

        COMMIT;
        l_return_status := 'SUCCESS';
        p_return_status := l_return_status;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'FAILURE';
            p_return_status := l_return_status;
    END hbg_dist_rights_update;

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Distribution Rights Validation                        
-- |Description      : This Program is used to Validate distribution & title rights  					    
-- +===================================================================+

    PROCEDURE hbg_dist_title_rights_val (
        p_source_line_id     IN VARCHAR2,
        p_batch_id           IN VARCHAR2,
        return_status        OUT VARCHAR2,
        p_so_auto_hold_array OUT hbg_so_auto_holds_type_array
    ) IS

        l_return_status                VARCHAR2(255);
        CURSOR c_get_distrights_lines IS
        SELECT
            dha.source_order_id,
            dla.source_line_id,
            dha.creation_date,
            dheb.attribute_char1                        one_time_address,
            hcasa.attribute1                            final_destination_address,
            nvl(dheb.attribute_char1, hcasa.attribute1) one_time_final_address,
            dfla.bill_to_customer_id                    cust_account_id,
            esib.item_number,
            hps.location_id                             shipto_site,
            dfla.bill_to_site_use_id,
            esib.attribute_date1                        pub_date,
            eieb_edition.attribute_char1                edition,
            eieb.attribute_char1                        owner,
            eieb.attribute_char2                        reporting_group,
            eieb.attribute_char3                        category1,
            eieb.attribute_char4                        category2,
            eieb.attribute_char7                        format,
            eieb.attribute_char8                        subformat
        FROM
            ego_item_eff_b          eieb_edition,
            doo_headers_eff_b       dheb_override,
            doo_fulfill_lines_eff_b dfleb,
            ego_item_eff_b          eieb,
            egp_system_items_b      esib,
            hz_cust_acct_sites_all  hcasa,
            hz_party_sites          hps,
            doo_headers_eff_b       dheb,
            doo_fulfill_lines_all   dfla,
            doo_lines_all           dla,
            doo_headers_all         dha
        WHERE
                1 = 1
            AND (dla.source_line_id = nvl(p_source_line_id, dla.source_line_id)
            OR dha.order_number = nvl(p_source_line_id, dha.order_number) )
			--AND dha.order_number = '1543'
            AND dla.dist_title_hold_flag IS NULL
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dha.status_code NOT IN ( 'DOO_DRAFT', 'DOO_REFERENCE' )
            AND dfla.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'BACKORDERED',
                                          'SHIPPED' )
            AND dha.header_id = dheb.header_id (+)
            AND dheb.context_code (+) = 'One Time Address'
            AND dfla.ship_to_party_site_id = hps.party_site_id (+)
            AND hps.party_site_id = hcasa.party_site_id (+)
            AND dfla.inventory_item_id = esib.inventory_item_id
            AND dfla.inventory_organization_id = esib.organization_id
            AND esib.inventory_item_id = eieb.inventory_item_id (+)
            AND esib.organization_id = eieb.organization_id (+)
            AND eieb.context_code (+) = 'Family Code'
            AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
            AND dfleb.context_code (+) = 'Override'
            AND dha.header_id = dheb_override.header_id (+)
            AND dheb_override.context_code (+) = 'Override'
            AND nvl(dfleb.attribute_char3, nvl(dfleb.attribute_char6, nvl(dheb_override.attribute_char3, nvl(dheb_override.attribute_char7,
            'N')))) = 'N'
            AND esib.inventory_item_id = eieb_edition.inventory_item_id (+)
            AND esib.organization_id = eieb_edition.organization_id (+)
            AND eieb_edition.context_code (+) = 'Edition Information'
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
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        1 = 1
                    AND dhi.transaction_entity_id1 = dla.line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code IN ( 'HBG_Distribution_Rights', 'HBG_Title_Rights' )
            );

        CURSOR c_get_distrights_lines_int IS
        SELECT
            dha.source_order_id,
            dla.source_line_id,
            dha.creation_date,
            dheb.attribute_char1                        one_time_address,
            hcasa.attribute1                            final_destination_address,
            nvl(dheb.attribute_char1, hcasa.attribute1) one_time_final_address,
            dfla.bill_to_customer_id                    cust_account_id,
            esib.item_number,
            hps.location_id                             shipto_site,
            dfla.bill_to_site_use_id,
            esib.attribute_date1                        pub_date,
            eieb_edition.attribute_char1                edition,
            eieb.attribute_char1                        owner,
            eieb.attribute_char2                        reporting_group,
            eieb.attribute_char3                        category1,
            eieb.attribute_char4                        category2,
            eieb.attribute_char7                        format,
            eieb.attribute_char8                        subformat
        FROM
            ego_item_eff_b          eieb_edition,
            doo_headers_eff_b       dheb_override,
            doo_fulfill_lines_eff_b dfleb,
            ego_item_eff_b          eieb,
            egp_system_items_b      esib,
            hz_cust_acct_sites_all  hcasa,
            hz_party_sites          hps,
            doo_headers_eff_b       dheb,
            doo_fulfill_lines_all   dfla,
            doo_lines_all           dla,
            doo_headers_eff_b       dheb_batch,
            doo_headers_all         dha
        WHERE
                1 = 1
            --AND dla.source_line_id = nvl(p_source_line_id, dla.source_line_id)
            AND dha.order_number = nvl(p_source_line_id, dha.order_number)
            AND dha.header_id = dheb_batch.header_id (+)
            AND dheb_batch.context_code (+) = 'EDI General'
            AND dheb_batch.attribute_char18 = p_batch_id
            AND dla.dist_title_hold_flag IS NULL
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dha.status_code IN ( 'DOO_DRAFT' )
            AND dfla.status_code IN ( 'CREATED', 'NOT_STARTED' )
            AND dha.header_id = dheb.header_id (+)
            AND dheb.context_code (+) = 'One Time Address'
            AND dfla.ship_to_party_site_id = hps.party_site_id (+)
            AND hps.party_site_id = hcasa.party_site_id (+)
            AND dfla.inventory_item_id = esib.inventory_item_id
            AND dfla.inventory_organization_id = esib.organization_id
            AND esib.inventory_item_id = eieb.inventory_item_id (+)
            AND esib.organization_id = eieb.organization_id (+)
            AND eieb.context_code (+) = 'Family Code'
            AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
            AND dfleb.context_code (+) = 'Override'
            AND dha.header_id = dheb_override.header_id (+)
            AND dheb_override.context_code (+) = 'Override'
            AND nvl(dfleb.attribute_char3, nvl(dfleb.attribute_char6, nvl(dheb_override.attribute_char3, nvl(dheb_override.attribute_char7,
            'N')))) = 'N'
            AND esib.inventory_item_id = eieb_edition.inventory_item_id (+)
            AND esib.organization_id = eieb_edition.organization_id (+)
            AND eieb_edition.context_code (+) = 'Edition Information'
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
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        1 = 1
                    AND dhi.transaction_entity_id1 = dla.line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code IN ( 'HBG_Distribution_Rights', 'HBG_Title_Rights' )
            );

        CURSOR c_title_rights_val IS
        SELECT
            dha.source_order_id,
            dla.source_line_id,
            dha.creation_date,
            dheb.attribute_char1                        one_time_address,
            hcasa.attribute1                            final_destination_address,
            nvl(dheb.attribute_char1, hcasa.attribute1) one_time_final_address,
            dfla.bill_to_customer_id                    cust_account_id,
            dfla.inventory_item_id,
            hps.location_id                             shipto_site,
            dfla.bill_to_site_use_id
        FROM
            doo_headers_eff_b       dheb_override,
            doo_fulfill_lines_eff_b dfleb,
            hz_cust_acct_sites_all  hcasa,
            hz_party_sites          hps,
            doo_headers_eff_b       dheb,
            doo_fulfill_lines_all   dfla,
            doo_lines_all           dla,
            doo_headers_all         dha
        WHERE
                1 = 1
          AND (dla.source_line_id = nvl(p_source_line_id, dla.source_line_id)
            OR dha.order_number = nvl(p_source_line_id, dha.order_number) )
			--AND dha.order_number = '1543'
            AND nvl(dla.dist_title_hold_flag, 'EVALUATE TITLE RIGHTS') = 'EVALUATE TITLE RIGHTS'
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dha.status_code NOT IN ( 'DOO_DRAFT', 'DOO_REFERENCE' )
            AND dfla.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'BACKORDERED',
                                          'SHIPPED' )
            AND dha.header_id = dheb.header_id (+)
            AND dheb.context_code (+) = 'One Time Address'
            AND dfla.ship_to_party_site_id = hps.party_site_id (+)
            AND hps.party_site_id = hcasa.party_site_id (+)
            AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
            AND dfleb.context_code (+) = 'Override'
            AND dha.header_id = dheb_override.header_id (+)
            AND dheb_override.context_code (+) = 'Override'
            AND nvl(dfleb.attribute_char3, nvl(dfleb.attribute_char6, nvl(dheb_override.attribute_char3, nvl(dheb_override.attribute_char7,
            'N')))) = 'N'
            AND nvl(dfleb.attribute_char4, nvl(dfleb.attribute_char6, nvl(dheb_override.attribute_char4, nvl(dheb_override.attribute_char7,
            'N')))) = 'N'
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
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        1 = 1
                    AND dhi.transaction_entity_id1 = dla.line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code IN ( 'HBG_Distribution_Rights', 'HBG_Title_Rights' )
            );

        CURSOR c_title_rights_val_int IS
        SELECT
            dha.source_order_id,
            dla.source_line_id,
            dha.creation_date,
            dheb.attribute_char1                        one_time_address,
            hcasa.attribute1                            final_destination_address,
            nvl(dheb.attribute_char1, hcasa.attribute1) one_time_final_address,
            dfla.bill_to_customer_id                    cust_account_id,
            dfla.inventory_item_id,
            hps.location_id                             shipto_site,
            dfla.bill_to_site_use_id
        FROM
            doo_headers_eff_b       dheb_override,
            doo_fulfill_lines_eff_b dfleb,
            hz_cust_acct_sites_all  hcasa,
            hz_party_sites          hps,
            doo_headers_eff_b       dheb,
            doo_fulfill_lines_all   dfla,
            doo_lines_all           dla,
            doo_headers_eff_b       dheb_batch,
            doo_headers_all         dha
        WHERE
                1 = 1
            --AND dla.source_line_id = nvl(p_source_line_id, dla.source_line_id)
            AND dha.order_number = nvl(p_source_line_id, dha.order_number)
            AND dha.header_id = dheb_batch.header_id (+)
            AND dheb_batch.context_code (+) = 'EDI General'
            AND dheb_batch.attribute_char18 = p_batch_id
            AND nvl(dla.dist_title_hold_flag, 'EVALUATE TITLE RIGHTS') = 'EVALUATE TITLE RIGHTS'
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dha.status_code IN ( 'DOO_DRAFT' )
            AND dfla.status_code IN ( 'CREATED', 'NOT_STARTED' )
            AND dha.header_id = dheb.header_id (+)
            AND dheb.context_code (+) = 'One Time Address'
            AND dfla.ship_to_party_site_id = hps.party_site_id (+)
            AND hps.party_site_id = hcasa.party_site_id (+)
            AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
            AND dfleb.context_code (+) = 'Override'
            AND dha.header_id = dheb_override.header_id (+)
            AND dheb_override.context_code (+) = 'Override'
            AND nvl(dfleb.attribute_char3, nvl(dfleb.attribute_char6, nvl(dheb_override.attribute_char3, nvl(dheb_override.attribute_char7,
            'N')))) = 'N'
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
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        1 = 1
                    AND dhi.transaction_entity_id1 = dla.line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code IN ( 'HBG_Distribution_Rights', 'HBG_Title_Rights' )
            );

        CURSOR c_get_val_lines IS
        SELECT DISTINCT
            dla.source_order_system,
            dla.source_order_id,
            dla.source_line_id,
            CASE
                WHEN dla.dist_title_hold_flag = 'BLOCK'    THEN
                    'HBG_Distribution_Rights'
                WHEN dla.dist_title_hold_flag = 'EXCLUDED' THEN
                    'HBG_Title_Rights'
            END                          hold_name,
            dla.dist_title_hold_comments hold_comments
--            ,
--            hca.account_number,
--            dha.order_number
        FROM
            doo_lines_all         dla,
            doo_headers_all       dha,
            doo_fulfill_lines_all dfla
        WHERE
                1 = 1
            AND (dla.source_line_id = nvl(p_source_line_id, dla.source_line_id)
            OR dha.order_number = nvl(p_source_line_id, dha.order_number) )
            AND dha.order_number NOT IN ( '356', '391', '543' )
--            AND DHA.ORDER_NUMBER NOT LIKE '54%'
--            AND dha.source_order_id IN ('5376d76d-2861-4f8c-9be3-61f5ea18c9994')
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dha.status_code NOT IN ( 'DOO_DRAFT', 'DOO_REFERENCE' )
            AND dfla.status_code NOT IN ( 'CLOSED', 'CANCELED', 'AWAIT_BILLING', 'AWAIT_RECEIVING', 'BACKORDERED',
                                          'SHIPPED' )
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
            --AND p_batch_id IS NULL
            AND dla.dist_title_hold_flag IN ( 'BLOCK', 'EXCLUDED' )
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        1 = 1
                    AND dhi.transaction_entity_id1 = dla.line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code IN ( 'HBG_Distribution_Rights', 'HBG_Title_Rights' )
                UNION
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        1 = 1
                    AND dhi.transaction_entity_id1 = dla.source_line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code IN ( 'HBG_Distribution_Rights', 'HBG_Title_Rights' )
            );

        CURSOR c_get_val_lines_int IS
        SELECT DISTINCT
            dla.source_order_system,
            dla.source_order_id,
            dla.source_line_id,
            CASE
                WHEN dla.dist_title_hold_flag = 'BLOCK'    THEN
                    'HBG_Distribution_Rights'
                WHEN dla.dist_title_hold_flag = 'EXCLUDED' THEN
                    'HBG_Title_Rights'
            END                          hold_name,
            dla.dist_title_hold_comments hold_comments
--            ,
--            hca.account_number,
--            dha.order_number
        FROM
            doo_lines_all         dla,
            doo_headers_all       dha,
            doo_fulfill_lines_all dfla,
            doo_headers_eff_b     dheb_batch
        WHERE
                1 = 1
            --AND dla.source_line_id = nvl(p_source_line_id, dla.source_line_id)
            AND dha.order_number = nvl(p_source_line_id, dha.order_number)
            AND dha.order_number NOT IN ( '356', '391' )
            AND dha.header_id = dla.header_id
            AND dla.line_id = dfla.line_id
            AND dha.status_code IN ( 'DOO_DRAFT' )
            AND dfla.status_code IN ( 'CREATED', 'NOT_STARTED' )
            AND dha.header_id = dheb_batch.header_id (+)
            AND dheb_batch.context_code (+) = 'EDI General'
            AND dheb_batch.attribute_char18 = p_batch_id
            AND dha.object_version_number = (
                SELECT
                    MAX(object_version_number)
                FROM
                    doo_headers_all
                WHERE
                        dha.source_order_id = source_order_id
                    AND dha.source_order_system = source_order_system
            )
            AND dla.dist_title_hold_flag IN ( 'BLOCK', 'EXCLUDED' )
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        1 = 1
                    AND dhi.transaction_entity_id1 = dla.line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code IN ( 'HBG_Distribution_Rights', 'HBG_Title_Rights' )
                UNION
                SELECT
                    1
                FROM
                    doo_hold_instances dhi,
                    doo_hold_codes_vl  dhcv
                WHERE
                        1 = 1
                    AND dhi.transaction_entity_id1 = dla.source_line_id
                    AND dhi.hold_code_id = dhcv.hold_code_id
                    AND dhcv.hold_code IN ( 'HBG_Distribution_Rights', 'HBG_Title_Rights' )
            );

        loop_index                     NUMBER := 1;
        onefinal_distribution_right_id NUMBER;
        onefinal_outcome               VARCHAR2(255);
        billto_distribution_right_id   NUMBER;
        billto_outcome                 VARCHAR2(255);
        billto_country                 VARCHAR2(255);
        shipto_distribution_right_id   NUMBER;
        shipto_outcome                 VARCHAR2(255);
        shipto_country                 VARCHAR2(255);
        v_so_hold_array_disp           hbg_so_auto_holds_type_array := hbg_so_auto_holds_type_array();
    BEGIN
        l_return_status := 'SUCCESS';
        IF ( p_batch_id IS NULL ) THEN
            FOR c_get_distrights_valid_lines IN c_get_distrights_lines LOOP
                IF ( c_get_distrights_valid_lines.one_time_final_address IS NOT NULL ) THEN
                    onefinal_outcome := NULL;
                    onefinal_distribution_right_id := NULL;
                    BEGIN
                        SELECT
                            outcome,
                            distribution_right_id
                        INTO
                            onefinal_outcome,
                            onefinal_distribution_right_id
                        FROM
                            (
                                SELECT DISTINCT
                                    hdre.distribution_right_id,
                                    hg.geography_code,
                                    hcge.country_group_code,
                                    hdre.outcome,
                                    DENSE_RANK()
                                    OVER(PARTITION BY c_get_distrights_valid_lines.source_order_id, c_get_distrights_valid_lines.source_line_id
                                         ORDER BY
                                             hdrple.precedence_level
                                    ) rank
                                FROM
                                    hbg_dist_rights_prec_lev_ext hdrple,
                                    hbg_client_info_tbl          hcit,
                                    hz_cust_accounts             hca,
                                    fnd_common_lookups           fcl_reportinggroup,
                                    fnd_common_lookups           fcl_category1,
                                    fnd_common_lookups           fcl_category2,
                                    hbg_country_group_assoc_ext  hcgae,
                                    hbg_country_groups_ext       hcge,
                                    hz_geographies               hg,
                                    hbg_dist_rights_ext          hdre
                                WHERE
                                        1 = 1
                                    AND hdre.country_id = hg.geography_id (+)
                                    AND hg.geography_type (+) = 'COUNTRY'
                                    AND hdre.country_group_id = hcge.country_group_id (+)
                                    AND hcge.country_group_id = hcgae.country_group_id (+)
                                    AND hdre.reporting_group = fcl_reportinggroup.lookup_code (+)
                                    AND fcl_reportinggroup.lookup_type (+) = 'HBG_REPORTING_GROUP'
                                    AND hdre.category_1 = fcl_category1.lookup_code (+)
                                    AND fcl_category1.lookup_type (+) = 'HBG_CATEGORY_1'
                                    AND hdre.category_2 = fcl_category2.lookup_code (+)
                                    AND fcl_category2.lookup_type (+) = 'HBG_CATEGORY_2'
                                    AND c_get_distrights_valid_lines.cust_account_id = hca.cust_account_id
                                    AND hca.cust_account_id = hcit.cust_account_id (+)
                                    AND c_get_distrights_valid_lines.creation_date BETWEEN hdre.start_date AND nvl(hdre.end_date, sysdate +
                                    1)
                                    AND c_get_distrights_valid_lines.one_time_final_address = nvl(hg.geography_code, hcgae.country_code)
                                    AND nvl(c_get_distrights_valid_lines.item_number, '#NULL') = nvl(nvl(hdre.item_number, c_get_distrights_valid_lines.
                                    item_number), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.cust_account_id, '999999999') = nvl(nvl(hdre.cust_account_id,
                                    c_get_distrights_valid_lines.cust_account_id), '999999999')
                                    AND nvl(c_get_distrights_valid_lines.owner, '#NULL') = nvl(nvl(hdre.owner, c_get_distrights_valid_lines.
                                    owner), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.reporting_group, '#NULL') = nvl(nvl(fcl_reportinggroup.description,
                                    c_get_distrights_valid_lines.reporting_group), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.category1, '#NULL') = nvl(nvl(fcl_category1.description, c_get_distrights_valid_lines.
                                    category1), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.category2, '#NULL') = nvl(nvl(fcl_category2.description, c_get_distrights_valid_lines.
                                    category2), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.format, '#NULL') = nvl(nvl(hdre.format, c_get_distrights_valid_lines.
                                    format), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.subformat, '#NULL') = nvl(nvl(hdre.sub_format, c_get_distrights_valid_lines.
                                    subformat), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.pub_date, sysdate) BETWEEN nvl(hdre.from_pub_date, nvl(c_get_distrights_valid_lines.
                                    pub_date, sysdate)) AND nvl(hdre.to_pub_date, nvl(c_get_distrights_valid_lines.pub_date, sysdate))
                                    AND nvl(c_get_distrights_valid_lines.edition, '999999999') = nvl(hdre.edition, nvl(c_get_distrights_valid_lines.
                                    edition, '999999999'))
                                    AND nvl(hcit.account_type, '#NULL') = nvl(nvl(hdre.account_type, hcit.account_type), '#NULL')
                                    AND nvl(hcit.default_account_type, '#NULL') = nvl(nvl(hdre.default_account_type, hcit.default_account_type),
                                    '#NULL')
                                    AND CASE
                                            WHEN hdre.owner IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.owner
                                    AND CASE
                                            WHEN hdre.reporting_group IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.reporting_group
                                    AND CASE
                                            WHEN hdre.category_1 IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.category_1
                                    AND CASE
                                            WHEN hdre.category_2 IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.category_2
                                    AND CASE
                                            WHEN hdre.format IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.format
                                    AND CASE
                                            WHEN hdre.sub_format IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.subformat
                                    AND CASE
                                            WHEN hdre.edition IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.edition
                                    AND CASE
                                            WHEN hdre.item_number IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.item_number
                                    AND CASE
                                            WHEN hdre.from_pub_date IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.from_pub_date
                                    AND CASE
                                            WHEN hdre.to_pub_date IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.to_pub_date
                                    AND CASE
                                            WHEN hdre.country_group_id IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.country_group
                                    AND CASE
                                            WHEN hdre.country_id IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.country_code
                                    AND CASE
                                            WHEN hdre.cust_account_id IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.account_number
                                    AND CASE
                                            WHEN hdre.account_type IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.account_type
                                    AND CASE
                                            WHEN hdre.default_account_type IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.default_acct_type
                            )
                        WHERE
                            rank = 1;

                        UPDATE doo_lines_all
                        SET
                            dist_title_hold_flag = onefinal_outcome,
                            dist_title_hold_comments =
                                CASE
                                    WHEN onefinal_outcome = 'BLOCK'
                                         AND c_get_distrights_valid_lines.one_time_address IS NOT NULL THEN
                                        'One-time Address Country: '
                                        || c_get_distrights_valid_lines.one_time_address
                                        || ' evaluates to BLOCK in rule '
                                        || onefinal_distribution_right_id
                                    WHEN onefinal_outcome = 'BLOCK'
                                         AND c_get_distrights_valid_lines.final_destination_address IS NOT NULL THEN
                                        'Ship-to Final Destination Country: '
                                        || c_get_distrights_valid_lines.final_destination_address
                                        || ' evaluates to BLOCK in rule '
                                        || onefinal_distribution_right_id
                                END
                        WHERE
                                source_order_id = c_get_distrights_valid_lines.source_order_id
                            AND source_line_id = c_get_distrights_valid_lines.source_line_id;

                        COMMIT;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_return_status := sqlerrm;
                            onefinal_distribution_right_id := NULL;
                            onefinal_outcome := NULL;
                    END;

                ELSE
                    billto_outcome := NULL;
                    billto_distribution_right_id := NULL;
                    shipto_outcome := NULL;
                    shipto_distribution_right_id := NULL;
                    BEGIN
                        SELECT
                            outcome,
                            distribution_right_id,
                            country
                        INTO
                            billto_outcome,
                            billto_distribution_right_id,
                            billto_country
                        FROM
                            (
                                SELECT DISTINCT
                                    hdre.distribution_right_id,
                                    hg.geography_code,
                                    hcge.country_group_code,
                                    hl_billto.country,
                                    hdre.outcome,
                                    DENSE_RANK()
                                    OVER(PARTITION BY c_get_distrights_valid_lines.source_order_id, c_get_distrights_valid_lines.source_line_id
                                         ORDER BY
                                             hdrple.precedence_level
                                    ) rank
                                FROM
                                    hz_locations                 hl_billto,
                                    hz_party_sites               hps_billto,
                                    hz_cust_acct_sites_all       hcasa_billto,
                                    hz_cust_site_uses_all        hcsua_billto,
                                    hbg_dist_rights_prec_lev_ext hdrple,
                                    hz_cust_accounts             hca,
                                    hbg_client_info_tbl          hcit,
                                    fnd_common_lookups           fcl_reportinggroup,
                                    fnd_common_lookups           fcl_category1,
                                    fnd_common_lookups           fcl_category2,
                                    hbg_country_group_assoc_ext  hcgae,
                                    hbg_country_groups_ext       hcge,
                                    hz_geographies               hg,
                                    hbg_dist_rights_ext          hdre
                                WHERE
                                        1 = 1
                                    AND hdre.country_id = hg.geography_id (+)
                                    AND hg.geography_type (+) = 'COUNTRY'
                                    AND hdre.country_group_id = hcge.country_group_id (+)
                                    AND hcge.country_group_id = hcgae.country_group_id (+)
                                    AND hdre.reporting_group = fcl_reportinggroup.lookup_code (+)
                                    AND fcl_reportinggroup.lookup_type (+) = 'HBG_REPORTING_GROUP'
                                    AND hdre.category_1 = fcl_category1.lookup_code (+)
                                    AND fcl_category1.lookup_type (+) = 'HBG_CATEGORY_1'
                                    AND hdre.category_2 = fcl_category2.lookup_code (+)
                                    AND fcl_category2.lookup_type (+) = 'HBG_CATEGORY_2'
                                    AND c_get_distrights_valid_lines.bill_to_site_use_id = hcsua_billto.site_use_id
                                    AND hcsua_billto.cust_acct_site_id = hcasa_billto.cust_acct_site_id
                                    AND hcasa_billto.party_site_id = hps_billto.party_site_id
                                    AND hps_billto.location_id = hl_billto.location_id
                                    AND c_get_distrights_valid_lines.cust_account_id = hca.cust_account_id
                                    AND hca.cust_account_id = hcit.cust_account_id (+)
                                    AND c_get_distrights_valid_lines.creation_date BETWEEN hdre.start_date AND nvl(hdre.end_date, sysdate +
                                    1)
                                    AND hl_billto.country = nvl(hg.geography_code, hcgae.country_code)
                                    AND nvl(c_get_distrights_valid_lines.item_number, '#NULL') = nvl(nvl(hdre.item_number, c_get_distrights_valid_lines.
                                    item_number), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.cust_account_id, '999999999') = nvl(nvl(hdre.cust_account_id,
                                    c_get_distrights_valid_lines.cust_account_id), '999999999')
                                    AND nvl(c_get_distrights_valid_lines.owner, '#NULL') = nvl(nvl(hdre.owner, c_get_distrights_valid_lines.
                                    owner), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.reporting_group, '#NULL') = nvl(nvl(fcl_reportinggroup.description,
                                    c_get_distrights_valid_lines.reporting_group), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.category1, '#NULL') = nvl(nvl(fcl_category1.description, c_get_distrights_valid_lines.
                                    category1), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.category2, '#NULL') = nvl(nvl(fcl_category2.description, c_get_distrights_valid_lines.
                                    category2), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.format, '#NULL') = nvl(nvl(hdre.format, c_get_distrights_valid_lines.
                                    format), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.subformat, '#NULL') = nvl(nvl(hdre.sub_format, c_get_distrights_valid_lines.
                                    subformat), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.pub_date, sysdate) BETWEEN nvl(hdre.from_pub_date, nvl(c_get_distrights_valid_lines.
                                    pub_date, sysdate)) AND nvl(hdre.to_pub_date, nvl(c_get_distrights_valid_lines.pub_date, sysdate))
                                    AND nvl(c_get_distrights_valid_lines.edition, '999999999') = nvl(hdre.edition, nvl(c_get_distrights_valid_lines.
                                    edition, '999999999'))
                                    AND nvl(hcit.account_type, '#NULL') = nvl(nvl(hdre.account_type, hcit.account_type), '#NULL')
                                    AND nvl(hcit.default_account_type, '#NULL') = nvl(nvl(hdre.default_account_type, hcit.default_account_type),
                                    '#NULL')
                                    AND CASE
                                            WHEN hdre.owner IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.owner
                                    AND CASE
                                            WHEN hdre.reporting_group IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.reporting_group
                                    AND CASE
                                            WHEN hdre.category_1 IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.category_1
                                    AND CASE
                                            WHEN hdre.category_2 IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.category_2
                                    AND CASE
                                            WHEN hdre.format IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.format
                                    AND CASE
                                            WHEN hdre.sub_format IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.subformat
                                    AND CASE
                                            WHEN hdre.edition IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.edition
                                    AND CASE
                                            WHEN hdre.item_number IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.item_number
                                    AND CASE
                                            WHEN hdre.from_pub_date IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.from_pub_date
                                    AND CASE
                                            WHEN hdre.to_pub_date IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.to_pub_date
                                    AND CASE
                                            WHEN hdre.country_group_id IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.country_group
                                    AND CASE
                                            WHEN hdre.country_id IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.country_code
                                    AND CASE
                                            WHEN hdre.cust_account_id IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.account_number
                                    AND CASE
                                            WHEN hdre.account_type IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.account_type
                                    AND CASE
                                            WHEN hdre.default_account_type IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.default_acct_type
                            )
                        WHERE
                            rank = 1;

                    EXCEPTION
                        WHEN OTHERS THEN
                            l_return_status := sqlerrm;
                            billto_outcome := NULL;
                            billto_distribution_right_id := NULL;
                    END;

                    IF ( c_get_distrights_valid_lines.shipto_site IS NOT NULL ) THEN
                        BEGIN
                            SELECT
                                outcome,
                                distribution_right_id,
                                country
                            INTO
                                shipto_outcome,
                                shipto_distribution_right_id,
                                shipto_country
                            FROM
                                (
                                    SELECT DISTINCT
                                        hdre.distribution_right_id,
                                        hg.geography_code,
                                        hcge.country_group_code,
                                        hl_shipto.country,
                                        hdre.outcome,
                                        DENSE_RANK()
                                        OVER(PARTITION BY c_get_distrights_valid_lines.source_order_id, c_get_distrights_valid_lines.
                                        source_line_id
                                             ORDER BY
                                                 hdrple.precedence_level
                                        ) rank
                                    FROM
                                        hz_locations                 hl_shipto,
                                        hbg_dist_rights_prec_lev_ext hdrple,
                                        hbg_client_info_tbl          hcit,
                                        hz_cust_accounts             hca,
                                        fnd_common_lookups           fcl_reportinggroup,
                                        fnd_common_lookups           fcl_category1,
                                        fnd_common_lookups           fcl_category2,
                                        hbg_country_group_assoc_ext  hcgae,
                                        hbg_country_groups_ext       hcge,
                                        hz_geographies               hg,
                                        hbg_dist_rights_ext          hdre
                                    WHERE
                                            1 = 1
                                        AND hdre.country_id = hg.geography_id (+)
                                        AND hg.geography_type (+) = 'COUNTRY'
                                        AND hdre.country_group_id = hcge.country_group_id (+)
                                        AND hcge.country_group_id = hcgae.country_group_id (+)
                                        AND hdre.reporting_group = fcl_reportinggroup.lookup_code (+)
                                        AND fcl_reportinggroup.lookup_type (+) = 'HBG_REPORTING_GROUP'
                                        AND hdre.category_1 = fcl_category1.lookup_code (+)
                                        AND fcl_category1.lookup_type (+) = 'HBG_CATEGORY_1'
                                        AND hdre.category_2 = fcl_category2.lookup_code (+)
                                        AND fcl_category2.lookup_type (+) = 'HBG_CATEGORY_2'
                                        AND c_get_distrights_valid_lines.shipto_site = hl_shipto.location_id
                                        AND c_get_distrights_valid_lines.cust_account_id = hca.cust_account_id
                                        AND hca.cust_account_id = hcit.cust_account_id (+)
                                        AND c_get_distrights_valid_lines.creation_date BETWEEN hdre.start_date AND nvl(hdre.end_date,
                                        sysdate + 1)
                                        AND hl_shipto.country = nvl(hg.geography_code, hcgae.country_code)
                                        AND nvl(c_get_distrights_valid_lines.item_number, '#NULL') = nvl(nvl(hdre.item_number, c_get_distrights_valid_lines.
                                        item_number), '#NULL')
                                        AND nvl(c_get_distrights_valid_lines.cust_account_id, '999999999') = nvl(nvl(hdre.cust_account_id,
                                        c_get_distrights_valid_lines.cust_account_id), '999999999')
                                        AND nvl(c_get_distrights_valid_lines.owner, '#NULL') = nvl(nvl(hdre.owner, c_get_distrights_valid_lines.
                                        owner), '#NULL')
                                        AND nvl(c_get_distrights_valid_lines.reporting_group, '#NULL') = nvl(nvl(fcl_reportinggroup.description,
                                        c_get_distrights_valid_lines.reporting_group), '#NULL')
                                        AND nvl(c_get_distrights_valid_lines.category1, '#NULL') = nvl(nvl(fcl_category1.description,
                                        c_get_distrights_valid_lines.category1), '#NULL')
                                        AND nvl(c_get_distrights_valid_lines.category2, '#NULL') = nvl(nvl(fcl_category2.description,
                                        c_get_distrights_valid_lines.category2), '#NULL')
                                        AND nvl(c_get_distrights_valid_lines.format, '#NULL') = nvl(nvl(hdre.format, c_get_distrights_valid_lines.
                                        format), '#NULL')
                                        AND nvl(c_get_distrights_valid_lines.subformat, '#NULL') = nvl(nvl(hdre.sub_format, c_get_distrights_valid_lines.
                                        subformat), '#NULL')
                                        AND nvl(c_get_distrights_valid_lines.pub_date, sysdate) BETWEEN nvl(hdre.from_pub_date, nvl(c_get_distrights_valid_lines.
                                        pub_date, sysdate)) AND nvl(hdre.to_pub_date, nvl(c_get_distrights_valid_lines.pub_date, sysdate))
                                        AND nvl(c_get_distrights_valid_lines.edition, '999999999') = nvl(hdre.edition, nvl(c_get_distrights_valid_lines.
                                        edition, '999999999'))
                                        AND nvl(hcit.account_type, '#NULL') = nvl(nvl(hdre.account_type, hcit.account_type), '#NULL')
                                        AND nvl(hcit.default_account_type, '#NULL') = nvl(nvl(hdre.default_account_type, hcit.default_account_type),
                                        '#NULL')
                                        AND CASE
                                                WHEN hdre.owner IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.owner
                                        AND CASE
                                                WHEN hdre.reporting_group IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.reporting_group
                                        AND CASE
                                                WHEN hdre.category_1 IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.category_1
                                        AND CASE
                                                WHEN hdre.category_2 IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.category_2
                                        AND CASE
                                                WHEN hdre.format IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.format
                                        AND CASE
                                                WHEN hdre.sub_format IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.subformat
                                        AND CASE
                                                WHEN hdre.edition IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.edition
                                        AND CASE
                                                WHEN hdre.item_number IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.item_number
                                        AND CASE
                                                WHEN hdre.from_pub_date IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.from_pub_date
                                        AND CASE
                                                WHEN hdre.to_pub_date IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.to_pub_date
                                        AND CASE
                                                WHEN hdre.country_group_id IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.country_group
                                        AND CASE
                                                WHEN hdre.country_id IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.country_code
                                        AND CASE
                                                WHEN hdre.cust_account_id IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.account_number
                                        AND CASE
                                                WHEN hdre.account_type IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.account_type
                                        AND CASE
                                                WHEN hdre.default_account_type IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.default_acct_type
                                )
                            WHERE
                                rank = 1;

                        EXCEPTION
                            WHEN OTHERS THEN
                                l_return_status := l_return_status || sqlerrm;
                                shipto_outcome := NULL;
                                shipto_distribution_right_id := NULL;
                        END;
                    END IF;

                    UPDATE doo_lines_all
                    SET
                        dist_title_hold_flag =
                            CASE
                                WHEN billto_outcome = 'BLOCK'
                                     OR shipto_outcome = 'BLOCK' THEN
                                    'BLOCK'
                                WHEN billto_outcome = 'OVERRIDE'
                                     OR shipto_outcome = 'OVERRIDE' THEN
                                    'OVERRIDE'
                                WHEN billto_outcome = 'EVALUATE TITLE RIGHTS'
                                     AND shipto_outcome = 'EVALUATE TITLE RIGHTS' THEN
                                    'EVALUATE TITLE RIGHTS'
                            END,
                        dist_title_hold_comments =
                            CASE
                                WHEN billto_outcome = 'BLOCK'
                                     AND shipto_outcome = 'BLOCK' THEN
                                    'Ship-to Country: '
                                    || shipto_country
                                    || ' evaluates to BLOCK in rule '
                                    || shipto_distribution_right_id
                                WHEN billto_outcome <> 'BLOCK'
                                     AND shipto_outcome = 'BLOCK' THEN
                                    'Ship-to Country: '
                                    || shipto_country
                                    || ' evaluates to BLOCK in rule '
                                    || shipto_distribution_right_id
                                WHEN billto_outcome = 'BLOCK'
                                     AND shipto_outcome <> 'BLOCK' THEN
                                    'Bill-to Country: '
                                    || billto_country
                                    || ' evaluates to BLOCK in rule '
                                    || billto_distribution_right_id
                                WHEN billto_outcome = 'BLOCK'
                                     AND shipto_outcome IS NULL THEN
                                    'Bill-to Country: '
                                    || billto_country
                                    || ' evaluates to BLOCK in rule '
                                    || billto_distribution_right_id
                                WHEN billto_outcome IS NULL
                                     AND shipto_outcome = 'BLOCK' THEN
                                    'Ship-to Country: '
                                    || shipto_country
                                    || ' evaluates to BLOCK in rule '
                                    || shipto_distribution_right_id
                            END
                    WHERE
                            source_order_id = c_get_distrights_valid_lines.source_order_id
                        AND source_line_id = c_get_distrights_valid_lines.source_line_id;

                    COMMIT;
                END IF;
            END LOOP;

            FOR c_title_rights_val_rec IN c_title_rights_val LOOP
                IF ( c_title_rights_val_rec.one_time_final_address IS NOT NULL ) THEN
                    onefinal_outcome := NULL;
                    BEGIN
                        SELECT
                            htrde.title_right_category
                        INTO onefinal_outcome
                        FROM
                            hz_geographies              hg,
                            hbg_title_right_details_ext htrde,
                            hbg_title_rights_ext        htre
                        WHERE
                                1 = 1
                            AND htre.inventory_item_id = c_title_rights_val_rec.inventory_item_id
                            AND htre.title_right_id = htrde.title_right_id
                            AND htrde.country_id = hg.geography_id
                            AND hg.geography_type = 'COUNTRY'
                            AND hg.geography_code = c_title_rights_val_rec.one_time_final_address;

                        UPDATE doo_lines_all
                        SET
                            dist_title_hold_flag = onefinal_outcome,
                            dist_title_hold_comments =
                                CASE
                                    WHEN onefinal_outcome = 'EXCLUDED'
                                         AND c_title_rights_val_rec.one_time_address IS NOT NULL THEN
                                        'One-Time Address Country: '
                                        || c_title_rights_val_rec.one_time_address
                                        || ' evaluates to EXCLUDED due to match with Country: '
                                        || c_title_rights_val_rec.one_time_address
                                    WHEN onefinal_outcome = 'BLOCK'
                                         AND c_title_rights_val_rec.final_destination_address IS NOT NULL THEN
                                        'Ship-to Final Destination Country: '
                                        || c_title_rights_val_rec.final_destination_address
                                        || ' evaluates to EXCLUDED due to match with Country: '
                                        || c_title_rights_val_rec.final_destination_address
                                END
                        WHERE
                                source_order_id = c_title_rights_val_rec.source_order_id
                            AND source_line_id = c_title_rights_val_rec.source_line_id;

                    EXCEPTION
                        WHEN OTHERS THEN
                            onefinal_outcome := NULL;
                    END;

                ELSE
                    billto_outcome := NULL;
                    billto_country := NULL;
                    shipto_country := NULL;
                    shipto_outcome := NULL;
                    BEGIN
                        SELECT
                            htrde.title_right_category,
                            hl_billto.country
                        INTO
                            billto_outcome,
                            billto_country
                        FROM
                            hz_locations                hl_billto,
                            hz_party_sites              hps_billto,
                            hz_cust_acct_sites_all      hcasa_billto,
                            hz_cust_site_uses_all       hcsua_billto,
                            hz_geographies              hg,
                            hbg_title_right_details_ext htrde,
                            hbg_title_rights_ext        htre
                        WHERE
                                1 = 1
                            AND htre.inventory_item_id = c_title_rights_val_rec.inventory_item_id
                            AND htre.title_right_id = htrde.title_right_id
                            AND htrde.country_id = hg.geography_id
                            AND hg.geography_type = 'COUNTRY'
                            AND c_title_rights_val_rec.bill_to_site_use_id = hcsua_billto.site_use_id
                            AND hcsua_billto.cust_acct_site_id = hcasa_billto.cust_acct_site_id
                            AND hcasa_billto.party_site_id = hps_billto.party_site_id
                            AND hps_billto.location_id = hl_billto.location_id
                            AND hg.geography_code = hl_billto.country;

                    EXCEPTION
                        WHEN OTHERS THEN
                            billto_country := NULL;
                            billto_outcome := NULL;
                    END;

                    IF ( c_title_rights_val_rec.shipto_site IS NOT NULL ) THEN
                        BEGIN
                            SELECT
                                htrde.title_right_category,
                                hl_shipto.country
                            INTO
                                shipto_outcome,
                                shipto_country
                            FROM
                                hz_locations                hl_shipto,
                                hz_party_sites              hps_shipto,
                                hz_geographies              hg,
                                hbg_title_right_details_ext htrde,
                                hbg_title_rights_ext        htre
                            WHERE
                                    1 = 1
                                AND htre.inventory_item_id = c_title_rights_val_rec.inventory_item_id
                                AND htre.title_right_id = htrde.title_right_id
                                AND htrde.country_id = hg.geography_id
                                AND hg.geography_type = 'COUNTRY'
                                AND c_title_rights_val_rec.shipto_site = hps_shipto.party_site_id
                                AND hps_shipto.location_id = hl_shipto.location_id
                                AND hg.geography_code = hl_shipto.country;

                        EXCEPTION
                            WHEN OTHERS THEN
                                shipto_country := NULL;
                                shipto_outcome := NULL;
                        END;
                    END IF;

                    UPDATE doo_lines_all
                    SET
                        dist_title_hold_flag =
                            CASE
                                WHEN billto_outcome = 'EXCLUDED'
                                     OR shipto_outcome = 'EXCLUDED' THEN
                                    'EXCLUDED'
                                WHEN billto_outcome = 'NON-EXCLUSIVE'
                                     OR shipto_outcome = 'NON-EXCLUSIVE' THEN
                                    'NON-EXCLUSIVE'
                                WHEN billto_outcome = 'EXCLUSIVE'
                                     OR shipto_outcome = 'EXCLUSIVE' THEN
                                    'EXCLUSIVE'
                            END,
                        dist_title_hold_comments =
                            CASE
                                WHEN billto_outcome = 'EXCLUDED'
                                     AND shipto_outcome = 'EXCLUDED' THEN
                                    'Ship-to Country: '
                                    || shipto_country
                                    || ' evaluates to EXCLUDED due to match with Country: '
                                    || shipto_country
                                WHEN billto_outcome <> 'EXCLUDED'
                                     AND shipto_outcome = 'EXCLUDED' THEN
                                    'Ship-to Country: '
                                    || shipto_country
                                    || ' evaluates to EXCLUDED due to match with Country: '
                                    || shipto_country
                                WHEN billto_outcome = 'EXCLUDED'
                                     AND shipto_outcome <> 'EXCLUDED' THEN
                                    'Bill-to Country: '
                                    || billto_country
                                    || ' evaluates to EXCLUDED due to match with Country: '
                                    || billto_country
                                WHEN billto_outcome = 'EXCLUDED'
                                     AND shipto_outcome IS NULL THEN
                                    'Bill-to Country: '
                                    || billto_country
                                    || ' evaluates to EXCLUDED due to match with Country: '
                                    || billto_country
                                WHEN billto_outcome IS NULL
                                     AND shipto_outcome = 'EXCLUDED' THEN
                                    'Ship-to Country: '
                                    || shipto_country
                                    || ' evaluates to EXCLUDED due to match with Country: '
                                    || shipto_country
                            END
                    WHERE
                            source_order_id = c_title_rights_val_rec.source_order_id
                        AND source_line_id = c_title_rights_val_rec.source_line_id;

                END IF;
            END LOOP;

            COMMIT;
            FOR c_missing_rights_val_rec IN c_title_rights_val LOOP
                IF ( c_missing_rights_val_rec.one_time_final_address IS NOT NULL ) THEN
                    onefinal_outcome := NULL;
                    BEGIN
                        SELECT DISTINCT
                            htre.title_right_id
                        INTO onefinal_outcome
                        FROM
                            hbg_title_rights_ext htre,
                            egp_system_items_b   esib
                        WHERE
                                1 = 1
                            AND esib.inventory_item_id = c_missing_rights_val_rec.inventory_item_id
                            AND esib.inventory_item_id = htre.inventory_item_id (+)
                            AND NOT EXISTS (
                                SELECT
                                    1
                                FROM
                                    hbg_title_right_details_ext htrde,
                                    hz_geographies              hg
                                WHERE
                                        1 = 1
                                    AND htre.title_right_id = htrde.title_right_id
                                    AND htrde.country_id = hg.geography_id
                                    AND hg.geography_type = 'COUNTRY'
                                    AND c_missing_rights_val_rec.one_time_final_address = hg.geography_code
                            );

                        UPDATE doo_lines_all
                        SET
                            dist_title_hold_flag = 'EXCLUDED',
                            dist_title_hold_comments =
                                CASE
                                    WHEN c_missing_rights_val_rec.one_time_address IS NOT NULL THEN
                                        'Missing Title Rights for ' || c_missing_rights_val_rec.one_time_address
                                    WHEN c_missing_rights_val_rec.final_destination_address IS NOT NULL THEN
                                        'Missing Title Rights for ' || c_missing_rights_val_rec.final_destination_address
                                END
                        WHERE
                                source_order_id = c_missing_rights_val_rec.source_order_id
                            AND source_line_id = c_missing_rights_val_rec.source_line_id;

                    EXCEPTION
                        WHEN OTHERS THEN
                            onefinal_outcome := NULL;
                    END;

                ELSE
                    billto_outcome := NULL;
                    billto_country := NULL;
                    shipto_country := NULL;
                    shipto_outcome := NULL;
                    BEGIN
                        SELECT DISTINCT
                            htre.title_right_id,
                            hl_billto.country
                        INTO
                            billto_outcome,
                            billto_country
                        FROM
                            hz_locations           hl_billto,
                            hz_party_sites         hps_billto,
                            hz_cust_acct_sites_all hcasa_billto,
                            hz_cust_site_uses_all  hcsua_billto,
                            hbg_title_rights_ext   htre,
                            egp_system_items_b     esib
                        WHERE
                                1 = 1
                            AND esib.inventory_item_id = c_missing_rights_val_rec.inventory_item_id
                            AND htre.inventory_item_id (+) = esib.inventory_item_id
                            AND c_missing_rights_val_rec.bill_to_site_use_id = hcsua_billto.site_use_id
                            AND hcsua_billto.cust_acct_site_id = hcasa_billto.cust_acct_site_id
                            AND hcasa_billto.party_site_id = hps_billto.party_site_id
                            AND hps_billto.location_id = hl_billto.location_id
                            AND NOT EXISTS (
                                SELECT
                                    1
                                FROM
                                    hbg_title_right_details_ext htrde,
                                    hz_geographies              hg
                                WHERE
                                        1 = 1
                                    AND htre.title_right_id = htrde.title_right_id
                                    AND htrde.country_id = hg.geography_id
                                    AND hg.geography_type = 'COUNTRY'
                                    AND hl_billto.country = hg.geography_code
                            );

                    EXCEPTION
                        WHEN OTHERS THEN
                            billto_country := NULL;
                            billto_outcome := NULL;
                    END;

                    IF ( c_missing_rights_val_rec.shipto_site IS NOT NULL ) THEN
                        BEGIN
                            SELECT DISTINCT
                                htre.title_right_id,
                                hl_shipto.country
                            INTO
                                shipto_outcome,
                                shipto_country
                            FROM
                                hz_locations         hl_shipto,
                                hz_party_sites       hps_shipto,
                                hbg_title_rights_ext htre,
                                egp_system_items_b   esib
                            WHERE
                                    1 = 1
                                AND esib.inventory_item_id = c_missing_rights_val_rec.inventory_item_id
                                AND htre.inventory_item_id (+) = esib.inventory_item_id
                                AND c_missing_rights_val_rec.shipto_site = hps_shipto.party_site_id
                                AND hps_shipto.location_id = hl_shipto.location_id
                                AND NOT EXISTS (
                                    SELECT
                                        1
                                    FROM
                                        hbg_title_right_details_ext htrde,
                                        hz_geographies              hg
                                    WHERE
                                            1 = 1
                                        AND htre.title_right_id = htrde.title_right_id
                                        AND htrde.country_id = hg.geography_id
                                        AND hg.geography_type = 'COUNTRY'
                                        AND hl_shipto.country = hg.geography_code
                                );

                        EXCEPTION
                            WHEN OTHERS THEN
                                shipto_country := NULL;
                                shipto_outcome := NULL;
                        END;
                    END IF;

                    UPDATE doo_lines_all
                    SET
                        dist_title_hold_flag = 'EXCLUDED',
                        dist_title_hold_comments =
                            CASE
                                WHEN shipto_outcome IS NOT NULL THEN
                                    'Missing Title Rights for ' || shipto_country
                                WHEN billto_outcome IS NOT NULL THEN
                                    'Missing Title Rights for ' || billto_country
                                ELSE
                                    'Missing Title Rights for ' || billto_country
                            END
                    WHERE
                            source_order_id = c_missing_rights_val_rec.source_order_id
                        AND source_line_id = c_missing_rights_val_rec.source_line_id;

                END IF;
            END LOOP;

            COMMIT;
            FOR c_get_valid_lines IN c_get_val_lines LOOP
                v_so_hold_array_disp.extend;
                v_so_hold_array_disp(loop_index) := hbg_so_auto_holds_type(c_get_valid_lines.source_order_system, c_get_valid_lines.source_order_id,
                c_get_valid_lines.source_line_id, c_get_valid_lines.hold_name, c_get_valid_lines.hold_comments,
                                                                          NULL, NULL, NULL, NULL, NULL);

                loop_index := loop_index + 1;
            END LOOP;

        ELSIF ( p_batch_id IS NOT NULL ) THEN
            FOR c_get_distrights_valid_lines IN c_get_distrights_lines_int LOOP
                IF ( c_get_distrights_valid_lines.one_time_final_address IS NOT NULL ) THEN
                    onefinal_outcome := NULL;
                    onefinal_distribution_right_id := NULL;
                    BEGIN
                        SELECT
                            outcome,
                            distribution_right_id
                        INTO
                            onefinal_outcome,
                            onefinal_distribution_right_id
                        FROM
                            (
                                SELECT
                                    hdre.distribution_right_id,
                                    hg.geography_code,
                                    hcge.country_group_code,
                                    hdre.outcome,
                                    DENSE_RANK()
                                    OVER(PARTITION BY c_get_distrights_valid_lines.source_order_id, c_get_distrights_valid_lines.source_line_id
                                         ORDER BY
                                             hdrple.precedence_level
                                    ) rank
                                FROM
                                    hbg_dist_rights_prec_lev_ext hdrple,
                                    hbg_client_info_tbl          hcit,
                                    hz_cust_accounts             hca,
                                    fnd_common_lookups           fcl_reportinggroup,
                                    fnd_common_lookups           fcl_category1,
                                    fnd_common_lookups           fcl_category2,
                                    hbg_country_group_assoc_ext  hcgae,
                                    hbg_country_groups_ext       hcge,
                                    hz_geographies               hg,
                                    hbg_dist_rights_ext          hdre
                                WHERE
                                        1 = 1
                                    AND hdre.country_id = hg.geography_id (+)
                                    AND hg.geography_type (+) = 'COUNTRY'
                                    AND hdre.country_group_id = hcge.country_group_id (+)
                                    AND hcge.country_group_id = hcgae.country_group_id (+)
                                    AND hdre.reporting_group = fcl_reportinggroup.lookup_code (+)
                                    AND fcl_reportinggroup.lookup_type (+) = 'HBG_REPORTING_GROUP'
                                    AND hdre.category_1 = fcl_category1.lookup_code (+)
                                    AND fcl_category1.lookup_type (+) = 'HBG_CATEGORY_1'
                                    AND hdre.category_2 = fcl_category2.lookup_code (+)
                                    AND fcl_category2.lookup_type (+) = 'HBG_CATEGORY_2'
                                    AND c_get_distrights_valid_lines.cust_account_id = hca.cust_account_id
                                    AND hca.cust_account_id = hcit.cust_account_id (+)
                                    AND c_get_distrights_valid_lines.creation_date BETWEEN hdre.start_date AND nvl(hdre.end_date, sysdate +
                                    1)
                                    AND c_get_distrights_valid_lines.one_time_final_address = nvl(hg.geography_code, hcgae.country_code)
                                    AND nvl(c_get_distrights_valid_lines.item_number, '#NULL') = nvl(nvl(hdre.item_number, c_get_distrights_valid_lines.
                                    item_number), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.cust_account_id, '999999999') = nvl(nvl(hdre.cust_account_id,
                                    c_get_distrights_valid_lines.cust_account_id), '999999999')
                                    AND nvl(c_get_distrights_valid_lines.owner, '#NULL') = nvl(nvl(hdre.owner, c_get_distrights_valid_lines.
                                    owner), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.reporting_group, '#NULL') = nvl(nvl(fcl_reportinggroup.description,
                                    c_get_distrights_valid_lines.reporting_group), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.category1, '#NULL') = nvl(nvl(fcl_category1.description, c_get_distrights_valid_lines.
                                    category1), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.category2, '#NULL') = nvl(nvl(fcl_category2.description, c_get_distrights_valid_lines.
                                    category2), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.format, '#NULL') = nvl(nvl(hdre.format, c_get_distrights_valid_lines.
                                    format), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.subformat, '#NULL') = nvl(nvl(hdre.sub_format, c_get_distrights_valid_lines.
                                    subformat), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.pub_date, sysdate) BETWEEN nvl(hdre.from_pub_date, nvl(c_get_distrights_valid_lines.
                                    pub_date, sysdate)) AND nvl(hdre.to_pub_date, nvl(c_get_distrights_valid_lines.pub_date, sysdate))
                                    AND nvl(c_get_distrights_valid_lines.edition, '999999999') = nvl(hdre.edition, nvl(c_get_distrights_valid_lines.
                                    edition, '999999999'))
                                    AND nvl(hcit.account_type, '#NULL') = nvl(nvl(hdre.account_type, hcit.account_type), '#NULL')
                                    AND nvl(hcit.default_account_type, '#NULL') = nvl(nvl(hdre.default_account_type, hcit.default_account_type),
                                    '#NULL')
                                    AND CASE
                                            WHEN hdre.owner IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.owner
                                    AND CASE
                                            WHEN hdre.reporting_group IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.reporting_group
                                    AND CASE
                                            WHEN hdre.category_1 IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.category_1
                                    AND CASE
                                            WHEN hdre.category_2 IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.category_2
                                    AND CASE
                                            WHEN hdre.format IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.format
                                    AND CASE
                                            WHEN hdre.sub_format IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.subformat
                                    AND CASE
                                            WHEN hdre.edition IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.edition
                                    AND CASE
                                            WHEN hdre.item_number IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.item_number
                                    AND CASE
                                            WHEN hdre.from_pub_date IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.from_pub_date
                                    AND CASE
                                            WHEN hdre.to_pub_date IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.to_pub_date
                                    AND CASE
                                            WHEN hdre.country_group_id IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.country_group
                                    AND CASE
                                            WHEN hdre.country_id IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.country_code
                                    AND CASE
                                            WHEN hdre.cust_account_id IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.account_number
                                    AND CASE
                                            WHEN hdre.account_type IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.account_type
                                    AND CASE
                                            WHEN hdre.default_account_type IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.default_acct_type
                            )
                        WHERE
                            rank = 1;

                        UPDATE doo_lines_all
                        SET
                            dist_title_hold_flag = onefinal_outcome,
                            dist_title_hold_comments =
                                CASE
                                    WHEN onefinal_outcome = 'BLOCK'
                                         AND c_get_distrights_valid_lines.one_time_address IS NOT NULL THEN
                                        'One-time Address Country: '
                                        || c_get_distrights_valid_lines.one_time_address
                                        || ' evaluates to BLOCK in rule '
                                        || onefinal_distribution_right_id
                                    WHEN onefinal_outcome = 'BLOCK'
                                         AND c_get_distrights_valid_lines.final_destination_address IS NOT NULL THEN
                                        'Ship-to Final Destination Country: '
                                        || c_get_distrights_valid_lines.final_destination_address
                                        || ' evaluates to BLOCK in rule '
                                        || onefinal_distribution_right_id
                                END
                        WHERE
                                source_order_id = c_get_distrights_valid_lines.source_order_id
                            AND source_line_id = c_get_distrights_valid_lines.source_line_id;

                        COMMIT;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_return_status := sqlerrm;
                            onefinal_distribution_right_id := NULL;
                            onefinal_outcome := NULL;
                    END;

                ELSE
                    billto_outcome := NULL;
                    billto_distribution_right_id := NULL;
                    shipto_outcome := NULL;
                    shipto_distribution_right_id := NULL;
                    BEGIN
                        SELECT
                            outcome,
                            distribution_right_id,
                            country
                        INTO
                            billto_outcome,
                            billto_distribution_right_id,
                            billto_country
                        FROM
                            (
                                SELECT
                                    hdre.distribution_right_id,
                                    hg.geography_code,
                                    hcge.country_group_code,
                                    hl_billto.country,
                                    hdre.outcome,
                                    DENSE_RANK()
                                    OVER(PARTITION BY c_get_distrights_valid_lines.source_order_id, c_get_distrights_valid_lines.source_line_id
                                         ORDER BY
                                             hdrple.precedence_level
                                    ) rank
                                FROM
                                    hz_locations                 hl_billto,
                                    hz_party_sites               hps_billto,
                                    hz_cust_acct_sites_all       hcasa_billto,
                                    hz_cust_site_uses_all        hcsua_billto,
                                    hbg_dist_rights_prec_lev_ext hdrple,
                                    hz_cust_accounts             hca,
                                    hbg_client_info_tbl          hcit,
                                    fnd_common_lookups           fcl_reportinggroup,
                                    fnd_common_lookups           fcl_category1,
                                    fnd_common_lookups           fcl_category2,
                                    hbg_country_group_assoc_ext  hcgae,
                                    hbg_country_groups_ext       hcge,
                                    hz_geographies               hg,
                                    hbg_dist_rights_ext          hdre
                                WHERE
                                        1 = 1
                                    AND hdre.country_id = hg.geography_id (+)
                                    AND hg.geography_type (+) = 'COUNTRY'
                                    AND hdre.country_group_id = hcge.country_group_id (+)
                                    AND hcge.country_group_id = hcgae.country_group_id (+)
                                    AND hdre.reporting_group = fcl_reportinggroup.lookup_code (+)
                                    AND fcl_reportinggroup.lookup_type (+) = 'HBG_REPORTING_GROUP'
                                    AND hdre.category_1 = fcl_category1.lookup_code (+)
                                    AND fcl_category1.lookup_type (+) = 'HBG_CATEGORY_1'
                                    AND hdre.category_2 = fcl_category2.lookup_code (+)
                                    AND fcl_category2.lookup_type (+) = 'HBG_CATEGORY_2'
                                    AND c_get_distrights_valid_lines.bill_to_site_use_id = hcsua_billto.site_use_id
                                    AND hcsua_billto.cust_acct_site_id = hcasa_billto.cust_acct_site_id
                                    AND hcasa_billto.party_site_id = hps_billto.party_site_id
                                    AND hps_billto.location_id = hl_billto.location_id
                                    AND c_get_distrights_valid_lines.cust_account_id = hca.cust_account_id
                                    AND hca.cust_account_id = hcit.cust_account_id (+)
                                    AND c_get_distrights_valid_lines.creation_date BETWEEN hdre.start_date AND nvl(hdre.end_date, sysdate +
                                    1)
                                    AND hl_billto.country = nvl(hg.geography_code, hcgae.country_code)
                                    AND nvl(c_get_distrights_valid_lines.item_number, '#NULL') = nvl(nvl(hdre.item_number, c_get_distrights_valid_lines.
                                    item_number), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.cust_account_id, '999999999') = nvl(nvl(hdre.cust_account_id,
                                    c_get_distrights_valid_lines.cust_account_id), '999999999')
                                    AND nvl(c_get_distrights_valid_lines.owner, '#NULL') = nvl(nvl(hdre.owner, c_get_distrights_valid_lines.
                                    owner), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.reporting_group, '#NULL') = nvl(nvl(fcl_reportinggroup.description,
                                    c_get_distrights_valid_lines.reporting_group), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.category1, '#NULL') = nvl(nvl(fcl_category1.description, c_get_distrights_valid_lines.
                                    category1), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.category2, '#NULL') = nvl(nvl(fcl_category2.description, c_get_distrights_valid_lines.
                                    category2), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.format, '#NULL') = nvl(nvl(hdre.format, c_get_distrights_valid_lines.
                                    format), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.subformat, '#NULL') = nvl(nvl(hdre.sub_format, c_get_distrights_valid_lines.
                                    subformat), '#NULL')
                                    AND nvl(c_get_distrights_valid_lines.pub_date, sysdate) BETWEEN nvl(hdre.from_pub_date, nvl(c_get_distrights_valid_lines.
                                    pub_date, sysdate)) AND nvl(hdre.to_pub_date, nvl(c_get_distrights_valid_lines.pub_date, sysdate))
                                    AND nvl(c_get_distrights_valid_lines.edition, '999999999') = nvl(hdre.edition, nvl(c_get_distrights_valid_lines.
                                    edition, '999999999'))
                                    AND nvl(hcit.account_type, '#NULL') = nvl(nvl(hdre.account_type, hcit.account_type), '#NULL')
                                    AND nvl(hcit.default_account_type, '#NULL') = nvl(nvl(hdre.default_account_type, hcit.default_account_type),
                                    '#NULL')
                                    AND CASE
                                            WHEN hdre.owner IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.owner
                                    AND CASE
                                            WHEN hdre.reporting_group IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.reporting_group
                                    AND CASE
                                            WHEN hdre.category_1 IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.category_1
                                    AND CASE
                                            WHEN hdre.category_2 IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.category_2
                                    AND CASE
                                            WHEN hdre.format IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.format
                                    AND CASE
                                            WHEN hdre.sub_format IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.subformat
                                    AND CASE
                                            WHEN hdre.edition IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.edition
                                    AND CASE
                                            WHEN hdre.item_number IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.item_number
                                    AND CASE
                                            WHEN hdre.from_pub_date IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.from_pub_date
                                    AND CASE
                                            WHEN hdre.to_pub_date IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.to_pub_date
                                    AND CASE
                                            WHEN hdre.country_group_id IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.country_group
                                    AND CASE
                                            WHEN hdre.country_id IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.country_code
                                    AND CASE
                                            WHEN hdre.cust_account_id IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.account_number
                                    AND CASE
                                            WHEN hdre.account_type IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.account_type
                                    AND CASE
                                            WHEN hdre.default_account_type IS NULL THEN
                                                0
                                            ELSE
                                                1
                                        END = hdrple.default_acct_type
                            )
                        WHERE
                            rank = 1;

                    EXCEPTION
                        WHEN OTHERS THEN
                            l_return_status := sqlerrm;
                            billto_outcome := NULL;
                            billto_distribution_right_id := NULL;
                    END;

                    IF ( c_get_distrights_valid_lines.shipto_site IS NOT NULL ) THEN
                        BEGIN
                            SELECT
                                outcome,
                                distribution_right_id,
                                country
                            INTO
                                shipto_outcome,
                                shipto_distribution_right_id,
                                shipto_country
                            FROM
                                (
                                    SELECT
                                        hdre.distribution_right_id,
                                        hg.geography_code,
                                        hcge.country_group_code,
                                        hl_shipto.country,
                                        hdre.outcome,
                                        DENSE_RANK()
                                        OVER(PARTITION BY c_get_distrights_valid_lines.source_order_id, c_get_distrights_valid_lines.
                                        source_line_id
                                             ORDER BY
                                                 hdrple.precedence_level
                                        ) rank
                                    FROM
                                        hz_locations                 hl_shipto,
                                        hbg_dist_rights_prec_lev_ext hdrple,
                                        hbg_client_info_tbl          hcit,
                                        hz_cust_accounts             hca,
                                        fnd_common_lookups           fcl_reportinggroup,
                                        fnd_common_lookups           fcl_category1,
                                        fnd_common_lookups           fcl_category2,
                                        hbg_country_group_assoc_ext  hcgae,
                                        hbg_country_groups_ext       hcge,
                                        hz_geographies               hg,
                                        hbg_dist_rights_ext          hdre
                                    WHERE
                                            1 = 1
                                        AND hdre.country_id = hg.geography_id (+)
                                        AND hg.geography_type (+) = 'COUNTRY'
                                        AND hdre.country_group_id = hcge.country_group_id (+)
                                        AND hcge.country_group_id = hcgae.country_group_id (+)
                                        AND hdre.reporting_group = fcl_reportinggroup.lookup_code (+)
                                        AND fcl_reportinggroup.lookup_type (+) = 'HBG_REPORTING_GROUP'
                                        AND hdre.category_1 = fcl_category1.lookup_code (+)
                                        AND fcl_category1.lookup_type (+) = 'HBG_CATEGORY_1'
                                        AND hdre.category_2 = fcl_category2.lookup_code (+)
                                        AND fcl_category2.lookup_type (+) = 'HBG_CATEGORY_2'
                                        AND c_get_distrights_valid_lines.shipto_site = hl_shipto.location_id
                                        AND c_get_distrights_valid_lines.cust_account_id = hca.cust_account_id
                                        AND hca.cust_account_id = hcit.cust_account_id (+)
                                        AND c_get_distrights_valid_lines.creation_date BETWEEN hdre.start_date AND nvl(hdre.end_date,
                                        sysdate + 1)
                                        AND hl_shipto.country = nvl(hg.geography_code, hcgae.country_code)
                                        AND nvl(c_get_distrights_valid_lines.item_number, '#NULL') = nvl(nvl(hdre.item_number, c_get_distrights_valid_lines.
                                        item_number), '#NULL')
                                        AND nvl(c_get_distrights_valid_lines.cust_account_id, '999999999') = nvl(nvl(hdre.cust_account_id,
                                        c_get_distrights_valid_lines.cust_account_id), '999999999')
                                        AND nvl(c_get_distrights_valid_lines.owner, '#NULL') = nvl(nvl(hdre.owner, c_get_distrights_valid_lines.
                                        owner), '#NULL')
                                        AND nvl(c_get_distrights_valid_lines.reporting_group, '#NULL') = nvl(nvl(fcl_reportinggroup.description,
                                        c_get_distrights_valid_lines.reporting_group), '#NULL')
                                        AND nvl(c_get_distrights_valid_lines.category1, '#NULL') = nvl(nvl(fcl_category1.description,
                                        c_get_distrights_valid_lines.category1), '#NULL')
                                        AND nvl(c_get_distrights_valid_lines.category2, '#NULL') = nvl(nvl(fcl_category2.description,
                                        c_get_distrights_valid_lines.category2), '#NULL')
                                        AND nvl(c_get_distrights_valid_lines.format, '#NULL') = nvl(nvl(hdre.format, c_get_distrights_valid_lines.
                                        format), '#NULL')
                                        AND nvl(c_get_distrights_valid_lines.subformat, '#NULL') = nvl(nvl(hdre.sub_format, c_get_distrights_valid_lines.
                                        subformat), '#NULL')
                                        AND nvl(c_get_distrights_valid_lines.pub_date, sysdate) BETWEEN nvl(hdre.from_pub_date, nvl(c_get_distrights_valid_lines.
                                        pub_date, sysdate)) AND nvl(hdre.to_pub_date, nvl(c_get_distrights_valid_lines.pub_date, sysdate))
                                        AND nvl(c_get_distrights_valid_lines.edition, '999999999') = nvl(hdre.edition, nvl(c_get_distrights_valid_lines.
                                        edition, '999999999'))
                                        AND nvl(hcit.account_type, '#NULL') = nvl(nvl(hdre.account_type, hcit.account_type), '#NULL')
                                        AND nvl(hcit.default_account_type, '#NULL') = nvl(nvl(hdre.default_account_type, hcit.default_account_type),
                                        '#NULL')
                                        AND CASE
                                                WHEN hdre.owner IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.owner
                                        AND CASE
                                                WHEN hdre.reporting_group IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.reporting_group
                                        AND CASE
                                                WHEN hdre.category_1 IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.category_1
                                        AND CASE
                                                WHEN hdre.category_2 IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.category_2
                                        AND CASE
                                                WHEN hdre.format IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.format
                                        AND CASE
                                                WHEN hdre.sub_format IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.subformat
                                        AND CASE
                                                WHEN hdre.edition IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.edition
                                        AND CASE
                                                WHEN hdre.item_number IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.item_number
                                        AND CASE
                                                WHEN hdre.from_pub_date IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.from_pub_date
                                        AND CASE
                                                WHEN hdre.to_pub_date IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.to_pub_date
                                        AND CASE
                                                WHEN hdre.country_group_id IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.country_group
                                        AND CASE
                                                WHEN hdre.country_id IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.country_code
                                        AND CASE
                                                WHEN hdre.cust_account_id IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.account_number
                                        AND CASE
                                                WHEN hdre.account_type IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.account_type
                                        AND CASE
                                                WHEN hdre.default_account_type IS NULL THEN
                                                    0
                                                ELSE
                                                    1
                                            END = hdrple.default_acct_type
                                )
                            WHERE
                                rank = 1;

                        EXCEPTION
                            WHEN OTHERS THEN
                                l_return_status := l_return_status || sqlerrm;
                                shipto_outcome := NULL;
                                shipto_distribution_right_id := NULL;
                        END;
                    END IF;

                    UPDATE doo_lines_all
                    SET
                        dist_title_hold_flag =
                            CASE
                                WHEN billto_outcome = 'BLOCK'
                                     OR shipto_outcome = 'BLOCK' THEN
                                    'BLOCK'
                                WHEN billto_outcome = 'OVERRIDE'
                                     OR shipto_outcome = 'OVERRIDE' THEN
                                    'OVERRIDE'
                                WHEN billto_outcome = 'EVALUATE TITLE RIGHTS'
                                     AND shipto_outcome = 'EVALUATE TITLE RIGHTS' THEN
                                    'EVALUATE TITLE RIGHTS'
                            END,
                        dist_title_hold_comments =
                            CASE
                                WHEN billto_outcome = 'BLOCK'
                                     AND shipto_outcome = 'BLOCK' THEN
                                    'Ship-to Country: '
                                    || shipto_country
                                    || ' evaluates to BLOCK in rule '
                                    || shipto_distribution_right_id
                                WHEN billto_outcome <> 'BLOCK'
                                     AND shipto_outcome = 'BLOCK' THEN
                                    'Ship-to Country: '
                                    || shipto_country
                                    || ' evaluates to BLOCK in rule '
                                    || shipto_distribution_right_id
                                WHEN billto_outcome = 'BLOCK'
                                     AND shipto_outcome <> 'BLOCK' THEN
                                    'Bill-to Country: '
                                    || billto_country
                                    || ' evaluates to BLOCK in rule '
                                    || billto_distribution_right_id
                                WHEN billto_outcome = 'BLOCK'
                                     AND shipto_outcome IS NULL THEN
                                    'Bill-to Country: '
                                    || billto_country
                                    || ' evaluates to BLOCK in rule '
                                    || billto_distribution_right_id
                                WHEN billto_outcome IS NULL
                                     AND shipto_outcome = 'BLOCK' THEN
                                    'Ship-to Country: '
                                    || shipto_country
                                    || ' evaluates to BLOCK in rule '
                                    || shipto_distribution_right_id
                            END
                    WHERE
                            source_order_id = c_get_distrights_valid_lines.source_order_id
                        AND source_line_id = c_get_distrights_valid_lines.source_line_id;

                    COMMIT;
                END IF;
            END LOOP;

            FOR c_title_rights_val_rec IN c_title_rights_val_int LOOP
                IF ( c_title_rights_val_rec.one_time_final_address IS NOT NULL ) THEN
                    onefinal_outcome := NULL;
                    BEGIN
                        SELECT
                            htrde.title_right_category
                        INTO onefinal_outcome
                        FROM
                            hz_geographies              hg,
                            hbg_title_right_details_ext htrde,
                            hbg_title_rights_ext        htre
                        WHERE
                                1 = 1
                            AND htre.inventory_item_id = c_title_rights_val_rec.inventory_item_id
                            AND htre.title_right_id = htrde.title_right_id
                            AND htrde.country_id = hg.geography_id
                            AND hg.geography_type = 'COUNTRY'
                            AND hg.geography_code = c_title_rights_val_rec.one_time_final_address;

                        UPDATE doo_lines_all
                        SET
                            dist_title_hold_flag = onefinal_outcome,
                            dist_title_hold_comments =
                                CASE
                                    WHEN onefinal_outcome = 'EXCLUDED'
                                         AND c_title_rights_val_rec.one_time_address IS NOT NULL THEN
                                        'One-Time Address Country: '
                                        || c_title_rights_val_rec.one_time_address
                                        || ' evaluates to EXCLUDED due to match with Country: '
                                        || c_title_rights_val_rec.one_time_address
                                    WHEN onefinal_outcome = 'BLOCK'
                                         AND c_title_rights_val_rec.final_destination_address IS NOT NULL THEN
                                        'Ship-to Final Destination Country: '
                                        || c_title_rights_val_rec.final_destination_address
                                        || ' evaluates to EXCLUDED due to match with Country: '
                                        || c_title_rights_val_rec.final_destination_address
                                END
                        WHERE
                                source_order_id = c_title_rights_val_rec.source_order_id
                            AND source_line_id = c_title_rights_val_rec.source_line_id;

                    EXCEPTION
                        WHEN OTHERS THEN
                            onefinal_outcome := NULL;
                    END;

                ELSE
                    billto_outcome := NULL;
                    billto_country := NULL;
                    shipto_country := NULL;
                    shipto_outcome := NULL;
                    BEGIN
                        SELECT
                            htrde.title_right_category,
                            hl_billto.country
                        INTO
                            billto_outcome,
                            billto_country
                        FROM
                            hz_locations                hl_billto,
                            hz_party_sites              hps_billto,
                            hz_cust_acct_sites_all      hcasa_billto,
                            hz_cust_site_uses_all       hcsua_billto,
                            hz_geographies              hg,
                            hbg_title_right_details_ext htrde,
                            hbg_title_rights_ext        htre
                        WHERE
                                1 = 1
                            AND htre.inventory_item_id = c_title_rights_val_rec.inventory_item_id
                            AND htre.title_right_id = htrde.title_right_id
                            AND htrde.country_id = hg.geography_id
                            AND hg.geography_type = 'COUNTRY'
                            AND c_title_rights_val_rec.bill_to_site_use_id = hcsua_billto.site_use_id
                            AND hcsua_billto.cust_acct_site_id = hcasa_billto.cust_acct_site_id
                            AND hcasa_billto.party_site_id = hps_billto.party_site_id
                            AND hps_billto.location_id = hl_billto.location_id
                            AND hg.geography_code = hl_billto.country;

                    EXCEPTION
                        WHEN OTHERS THEN
                            billto_country := NULL;
                            billto_outcome := NULL;
                    END;

                    IF ( c_title_rights_val_rec.shipto_site IS NOT NULL ) THEN
                        BEGIN
                            SELECT
                                htrde.title_right_category,
                                hl_shipto.country
                            INTO
                                shipto_outcome,
                                shipto_country
                            FROM
                                hz_locations                hl_shipto,
                                hz_party_sites              hps_shipto,
                                hz_geographies              hg,
                                hbg_title_right_details_ext htrde,
                                hbg_title_rights_ext        htre
                            WHERE
                                    1 = 1
                                AND htre.inventory_item_id = c_title_rights_val_rec.inventory_item_id
                                AND htre.title_right_id = htrde.title_right_id
                                AND htrde.country_id = hg.geography_id
                                AND hg.geography_type = 'COUNTRY'
                                AND c_title_rights_val_rec.shipto_site = hps_shipto.party_site_id
                                AND hps_shipto.location_id = hl_shipto.location_id
                                AND hg.geography_code = hl_shipto.country;

                        EXCEPTION
                            WHEN OTHERS THEN
                                shipto_country := NULL;
                                shipto_outcome := NULL;
                        END;
                    END IF;

                    UPDATE doo_lines_all
                    SET
                        dist_title_hold_flag =
                            CASE
                                WHEN billto_outcome = 'EXCLUDED'
                                     OR shipto_outcome = 'EXCLUDED' THEN
                                    'EXCLUDED'
                                WHEN billto_outcome = 'NON-EXCLUSIVE'
                                     OR shipto_outcome = 'NON-EXCLUSIVE' THEN
                                    'NON-EXCLUSIVE'
                                WHEN billto_outcome = 'EXCLUSIVE'
                                     OR shipto_outcome = 'EXCLUSIVE' THEN
                                    'EXCLUSIVE'
                            END,
                        dist_title_hold_comments =
                            CASE
                                WHEN billto_outcome = 'EXCLUDED'
                                     AND shipto_outcome = 'EXCLUDED' THEN
                                    'Ship-to Country: '
                                    || shipto_country
                                    || ' evaluates to EXCLUDED due to match with Country: '
                                    || shipto_country
                                WHEN billto_outcome <> 'EXCLUDED'
                                     AND shipto_outcome = 'EXCLUDED' THEN
                                    'Ship-to Country: '
                                    || shipto_country
                                    || ' evaluates to EXCLUDED due to match with Country: '
                                    || shipto_country
                                WHEN billto_outcome = 'EXCLUDED'
                                     AND shipto_outcome <> 'EXCLUDED' THEN
                                    'Bill-to Country: '
                                    || billto_country
                                    || ' evaluates to EXCLUDED due to match with Country: '
                                    || billto_country
                                WHEN billto_outcome = 'EXCLUDED'
                                     AND shipto_outcome IS NULL THEN
                                    'Bill-to Country: '
                                    || billto_country
                                    || ' evaluates to EXCLUDED due to match with Country: '
                                    || billto_country
                                WHEN billto_outcome IS NULL
                                     AND shipto_outcome = 'EXCLUDED' THEN
                                    'Ship-to Country: '
                                    || shipto_country
                                    || ' evaluates to EXCLUDED due to match with Country: '
                                    || shipto_country
                            END
                    WHERE
                            source_order_id = c_title_rights_val_rec.source_order_id
                        AND source_line_id = c_title_rights_val_rec.source_line_id;

                END IF;
            END LOOP;

            COMMIT;
            FOR c_missing_rights_val_rec IN c_title_rights_val_int LOOP
                IF ( c_missing_rights_val_rec.one_time_final_address IS NOT NULL ) THEN
                    onefinal_outcome := NULL;
                    BEGIN
                        SELECT DISTINCT
                            htre.title_right_id
                        INTO onefinal_outcome
                        FROM
                            hbg_title_rights_ext htre,
                            egp_system_items_b   esib
                        WHERE
                                1 = 1
                            AND esib.inventory_item_id = c_missing_rights_val_rec.inventory_item_id
                            AND esib.inventory_item_id = htre.inventory_item_id (+)
                            AND NOT EXISTS (
                                SELECT
                                    1
                                FROM
                                    hbg_title_right_details_ext htrde,
                                    hz_geographies              hg
                                WHERE
                                        1 = 1
                                    AND htre.title_right_id = htrde.title_right_id
                                    AND htrde.country_id = hg.geography_id
                                    AND hg.geography_type = 'COUNTRY'
                                    AND c_missing_rights_val_rec.one_time_final_address = hg.geography_code
                            );

                        UPDATE doo_lines_all
                        SET
                            dist_title_hold_flag = 'EXCLUDED',
                            dist_title_hold_comments =
                                CASE
                                    WHEN onefinal_outcome = 'EXCLUDED'
                                         AND c_missing_rights_val_rec.one_time_address IS NOT NULL THEN
                                        'Missing Title Rights for ' || c_missing_rights_val_rec.one_time_address
                                    WHEN onefinal_outcome = 'BLOCK'
                                         AND c_missing_rights_val_rec.final_destination_address IS NOT NULL THEN
                                        'Missing Title Rights for ' || c_missing_rights_val_rec.final_destination_address
                                END
                        WHERE
                                source_order_id = c_missing_rights_val_rec.source_order_id
                            AND source_line_id = c_missing_rights_val_rec.source_line_id;

                    EXCEPTION
                        WHEN OTHERS THEN
                            onefinal_outcome := NULL;
                    END;

                ELSE
                    billto_outcome := NULL;
                    billto_country := NULL;
                    shipto_country := NULL;
                    shipto_outcome := NULL;
                    BEGIN
                        SELECT DISTINCT
                            htre.title_right_id,
                            hl_billto.country
                        INTO
                            billto_outcome,
                            billto_country
                        FROM
                            hz_locations           hl_billto,
                            hz_party_sites         hps_billto,
                            hz_cust_acct_sites_all hcasa_billto,
                            hz_cust_site_uses_all  hcsua_billto,
                            hbg_title_rights_ext   htre,
                            egp_system_items_b     esib
                        WHERE
                                1 = 1
                            AND esib.inventory_item_id = c_missing_rights_val_rec.inventory_item_id
                            AND htre.inventory_item_id (+) = esib.inventory_item_id
                            AND c_missing_rights_val_rec.bill_to_site_use_id = hcsua_billto.site_use_id
                            AND hcsua_billto.cust_acct_site_id = hcasa_billto.cust_acct_site_id
                            AND hcasa_billto.party_site_id = hps_billto.party_site_id
                            AND hps_billto.location_id = hl_billto.location_id
                            AND NOT EXISTS (
                                SELECT
                                    1
                                FROM
                                    hbg_title_right_details_ext htrde,
                                    hz_geographies              hg
                                WHERE
                                        1 = 1
                                    AND htre.title_right_id = htrde.title_right_id
                                    AND htrde.country_id = hg.geography_id
                                    AND hg.geography_type = 'COUNTRY'
                                    AND hl_billto.country = hg.geography_code
                            );

                    EXCEPTION
                        WHEN OTHERS THEN
                            billto_country := NULL;
                            billto_outcome := NULL;
                    END;

                    IF ( c_missing_rights_val_rec.shipto_site IS NOT NULL ) THEN
                        BEGIN
                            SELECT DISTINCT
                                htre.title_right_id,
                                hl_shipto.country
                            INTO
                                shipto_outcome,
                                shipto_country
                            FROM
                                hz_locations         hl_shipto,
                                hz_party_sites       hps_shipto,
                                hbg_title_rights_ext htre,
                                egp_system_items_b   esib
                            WHERE
                                    1 = 1
                                AND esib.inventory_item_id = c_missing_rights_val_rec.inventory_item_id
                                AND htre.inventory_item_id (+) = esib.inventory_item_id
                                AND c_missing_rights_val_rec.shipto_site = hps_shipto.party_site_id
                                AND hps_shipto.location_id = hl_shipto.location_id
                                AND NOT EXISTS (
                                    SELECT
                                        1
                                    FROM
                                        hbg_title_right_details_ext htrde,
                                        hz_geographies              hg
                                    WHERE
                                            1 = 1
                                        AND htre.title_right_id = htrde.title_right_id
                                        AND htrde.country_id = hg.geography_id
                                        AND hg.geography_type = 'COUNTRY'
                                        AND hl_shipto.country = hg.geography_code
                                );

                        EXCEPTION
                            WHEN OTHERS THEN
                                shipto_country := NULL;
                                shipto_outcome := NULL;
                        END;
                    END IF;

                    UPDATE doo_lines_all
                    SET
                        dist_title_hold_flag = 'EXCLUDED',
                        dist_title_hold_comments =
                            CASE
                                WHEN shipto_outcome IS NOT NULL THEN
                                    'Missing Title Rights for ' || shipto_country
                                WHEN billto_outcome IS NOT NULL THEN
                                    'Missing Title Rights for ' || billto_country
                            END
                    WHERE
                            source_order_id = c_missing_rights_val_rec.source_order_id
                        AND source_line_id = c_missing_rights_val_rec.source_line_id;

                END IF;
            END LOOP;

            COMMIT;
            FOR c_get_valid_lines IN c_get_val_lines_int LOOP
                v_so_hold_array_disp.extend;
                v_so_hold_array_disp(loop_index) := hbg_so_auto_holds_type(c_get_valid_lines.source_order_system, c_get_valid_lines.source_order_id,
                c_get_valid_lines.source_line_id, c_get_valid_lines.hold_name, c_get_valid_lines.hold_comments,
                                                                          NULL, NULL, NULL, NULL, NULL);

                loop_index := loop_index + 1;
            END LOOP;

        END IF;

        return_status := l_return_status;
        p_so_auto_hold_array := v_so_hold_array_disp;
    EXCEPTION
        WHEN OTHERS THEN
            l_return_status := 'FAILURE';
            return_status := l_return_status;
            p_so_auto_hold_array := v_so_hold_array_disp;
    END hbg_dist_title_rights_val;

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Country Groups Conversion                        
-- |Description      : This Program is used to Load the Country Groups				    
-- +===================================================================+

    PROCEDURE hbg_country_group_load IS

        CURSOR c_country_group IS
        SELECT
            hcgs.*,
            hcge.country_group_id
        FROM
            hbg_country_groups_stg hcgs,
            hbg_country_groups_ext hcge
        WHERE
                1 = 1
            AND hcgs.country_group_code = hcge.country_group_code (+);

        CURSOR c_group_detail IS
        SELECT
            hcgas.*,
            hcge.country_group_id,
            hcgae.country_id,
            hg.geography_id
        FROM
            hz_geographies              hg,
            hbg_country_group_assoc_stg hcgas,
            hbg_country_group_assoc_ext hcgae,
            hbg_country_groups_ext      hcge
        WHERE
                1 = 1
            AND hcgas.country_group_code = hcge.country_group_code
            AND hcge.country_group_id = hcgae.country_group_id (+)
            AND hcgas.country = hcgae.country_code (+)
            AND hcgas.country = hg.geography_code (+)
            AND hg.geography_type (+) = 'COUNTRY';

        x_success_message VARCHAR2(255);
    BEGIN
        FOR c_country_group_rec IN c_country_group LOOP
            BEGIN
                IF ( c_country_group_rec.country_group_id IS NULL ) THEN
                    INSERT INTO hbg_country_groups_ext (
                        country_group_code,
                        country_group_name,
                        comments,
                        enabled_flag,
                        created_by,
                        creation_date,
                        last_updated_by,
                        last_update_date
                    ) VALUES (
                        c_country_group_rec.country_group_code,
                        c_country_group_rec.country_group_name,
                        c_country_group_rec.cmt_text,
                        'Y',
                        c_country_group_rec.ins_user,
                        sysdate,
                        c_country_group_rec.last_upd_user,
                        sysdate
                    );

                    UPDATE hbg_country_groups_stg
                    SET
                        status = 'Success'
                    WHERE
                        cg_uid = c_country_group_rec.cg_uid;

                ELSE
                    UPDATE hbg_country_groups_ext
                    SET
                        country_group_name = c_country_group_rec.country_group_name,
                        comments = c_country_group_rec.cmt_text
                    WHERE
                        country_group_id = c_country_group_rec.country_group_id;

                    UPDATE hbg_country_groups_stg
                    SET
                        status = 'Updated'
                    WHERE
                        cg_uid = c_country_group_rec.cg_uid;

                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    x_success_message := sqlerrm;
                    UPDATE hbg_country_groups_stg
                    SET
                        status = x_success_message
                    WHERE
                        cg_uid = c_country_group_rec.cg_uid;

            END;
        END LOOP;

        COMMIT;
        FOR c_group_detail_rec IN c_group_detail LOOP
            BEGIN
                IF (
                    c_group_detail_rec.country_id IS NULL
                    AND c_group_detail_rec.geography_id IS NOT NULL
                ) THEN
                    INSERT INTO hbg_country_group_assoc_ext (
                        country_group_id,
                        country_id,
                        country_code,
                        created_by,
                        creation_date,
                        last_updated_by,
                        last_update_date
                    ) VALUES (
                        c_group_detail_rec.country_group_id,
                        c_group_detail_rec.geography_id,
                        c_group_detail_rec.country,
                        c_group_detail_rec.ins_user,
                        sysdate,
                        c_group_detail_rec.last_upd_user,
                        sysdate
                    );

                    UPDATE hbg_country_group_assoc_stg
                    SET
                        status = 'Success'
                    WHERE
                        cgd_uid = c_group_detail_rec.cgd_uid;

                ELSIF ( c_group_detail_rec.geography_id IS NULL ) THEN
                    UPDATE hbg_country_group_assoc_stg
                    SET
                        status = 'Country '
                                 || c_group_detail_rec.country
                                 || ' is not valid country'
                    WHERE
                        cgd_uid = c_group_detail_rec.cgd_uid;

                ELSE
                    UPDATE hbg_country_group_assoc_stg
                    SET
                        status = 'Association Already Exists'
                    WHERE
                        cgd_uid = c_group_detail_rec.cgd_uid;

                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    x_success_message := sqlerrm;
                    UPDATE hbg_country_group_assoc_stg
                    SET
                        status = x_success_message
                    WHERE
                        cgd_uid = c_group_detail_rec.cgd_uid;

            END;
        END LOOP;

        COMMIT;
        x_success_message := 'success';
    END hbg_country_group_load;
-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Distribution Rights Conversion                        
-- |Description      : This Program is used to Load the Distribution Rights				    
-- +===================================================================+

    PROCEDURE hbg_dist_rights_load IS

        CURSOR c_dist_rights_load IS
        SELECT
            hdrs.*,
            xfco.owner_id,
            xfcrg.reporting_group_id     reporting_group_id,
            xfcrc1.category1_id          fcl_category1_id,
            xfcrc2.category2_id          fcl_category2_id,
            ffvl_format.flex_value_id    format_id,
            ffvl_subformat.flex_value_id subformat_id,
            (
                SELECT
                    COUNT(1)
                FROM
                    egp_system_items_b
                WHERE
                    item_number = hdrs.item_number
            )                            item_existence,
            hcge.country_group_id,
            hg.geography_id              country_id,
            hca.cust_account_id
        FROM
            hbg_dist_rights_stg                   hdrs,
            xxhbg_family_code_owner               xfco,
            xxhbg_family_code_reporting_group     xfcrg,
            xxhbg_family_code_reporting_category1 xfcrc1,
            xxhbg_family_code_reporting_category2 xfcrc2,
            fnd_flex_values_vl                    ffvl_format,
            fnd_flex_values_vl                    ffvl_subformat,
            hbg_country_groups_ext                hcge,
            hz_geographies                        hg,
            hz_cust_accounts                      hca
        WHERE
                1 = 1
            AND xfco.owner_id = xfcrg.owner_id (+)
            AND xfcrg.reporting_group_id = xfcrc1.reporting_group_id (+)
            AND xfcrc1.category1_id = xfcrc2.category1_id (+)
            AND hdrs.owner = xfco.owner_code (+)
            AND hdrs.reporting_group = xfco.owner_code
                                       || xfcrg.reporting_grp_code (+)
            AND hdrs.category_1 = xfco.owner_code
                                  || xfcrg.reporting_grp_code
                                  || xfcrc1.category1_code (+)
            AND hdrs.category_2 = xfco.owner_code
                                  || xfcrg.reporting_grp_code
                                  || xfcrc1.category1_code
                                  || xfcrc2.category2_code (+)
            AND hdrs.format = ffvl_format.flex_value (+)
            AND ffvl_format.value_category (+) = 'HBG_Format'
            AND hdrs.sub_format = ffvl_subformat.flex_value (+)
            AND ffvl_subformat.value_category (+) = 'HBG_Subformat'
            AND hdrs.country_group_code = hcge.country_group_code (+)
            AND hdrs.country_code = hg.geography_code (+)
            AND hg.geography_type (+) = 'COUNTRY'
            AND hdrs.customer_account = hca.account_number (+);

        x_success_message VARCHAR2(255);
    BEGIN
        FOR c_dist_rights_rec IN c_dist_rights_load LOOP
            BEGIN
                IF (
                    c_dist_rights_rec.owner IS NOT NULL
                    AND c_dist_rights_rec.owner_id IS NULL
                ) THEN
                    UPDATE hbg_dist_rights_stg
                    SET
                        status = 'Owner does not exists'
                    WHERE
                        distribution_right_id = c_dist_rights_rec.distribution_right_id;

                ELSIF (
                    c_dist_rights_rec.reporting_group IS NOT NULL
                    AND c_dist_rights_rec.reporting_group_id IS NULL
                ) THEN
                    UPDATE hbg_dist_rights_stg
                    SET
                        status = 'Reporting Group does not exists'
                    WHERE
                        distribution_right_id = c_dist_rights_rec.distribution_right_id;

                ELSIF (
                    c_dist_rights_rec.category_1 IS NOT NULL
                    AND c_dist_rights_rec.fcl_category1_id IS NULL
                ) THEN
                    UPDATE hbg_dist_rights_stg
                    SET
                        status = 'Category 1 does not exists'
                    WHERE
                        distribution_right_id = c_dist_rights_rec.distribution_right_id;

                ELSIF (
                    c_dist_rights_rec.category_2 IS NOT NULL
                    AND c_dist_rights_rec.fcl_category2_id IS NULL
                ) THEN
                    UPDATE hbg_dist_rights_stg
                    SET
                        status = 'Category 2 does not exists'
                    WHERE
                        distribution_right_id = c_dist_rights_rec.distribution_right_id;

                ELSIF (
                    c_dist_rights_rec.format IS NOT NULL
                    AND c_dist_rights_rec.format_id IS NULL
                ) THEN
                    UPDATE hbg_dist_rights_stg
                    SET
                        status = 'Format does not exists'
                    WHERE
                        distribution_right_id = c_dist_rights_rec.distribution_right_id;

                ELSIF (
                    c_dist_rights_rec.sub_format IS NOT NULL
                    AND c_dist_rights_rec.subformat_id IS NULL
                ) THEN
                    UPDATE hbg_dist_rights_stg
                    SET
                        status = 'Sub Format does not exists'
                    WHERE
                        distribution_right_id = c_dist_rights_rec.distribution_right_id;

                ELSIF (
                    c_dist_rights_rec.item_number IS NOT NULL
                    AND c_dist_rights_rec.item_existence = 0
                ) THEN
                    UPDATE hbg_dist_rights_stg
                    SET
                        status = 'Item does not exists'
                    WHERE
                        distribution_right_id = c_dist_rights_rec.distribution_right_id;

                ELSIF (
                    c_dist_rights_rec.country_group_code IS NOT NULL
                    AND c_dist_rights_rec.country_group_id IS NULL
                ) THEN
                    UPDATE hbg_dist_rights_stg
                    SET
                        status = 'Country Group does not exists'
                    WHERE
                        distribution_right_id = c_dist_rights_rec.distribution_right_id;

                ELSIF (
                    c_dist_rights_rec.country_code IS NOT NULL
                    AND c_dist_rights_rec.country_id IS NULL
                ) THEN
                    UPDATE hbg_dist_rights_stg
                    SET
                        status = 'Country does not exists'
                    WHERE
                        distribution_right_id = c_dist_rights_rec.distribution_right_id;

                ELSIF (
                    c_dist_rights_rec.customer_account IS NOT NULL
                    AND c_dist_rights_rec.cust_account_id IS NULL
                ) THEN
                    UPDATE hbg_dist_rights_stg
                    SET
                        status = 'Customer Account does not exists'
                    WHERE
                        distribution_right_id = c_dist_rights_rec.distribution_right_id;

                ELSE
                    INSERT INTO hbg_dist_rights_ext (
                        owner,
                        reporting_group,
                        category_1,
                        category_2,
                        format,
                        sub_format,
                        edition,
                        from_pub_date,
                        to_pub_date,
                        item_number,
                        country_group_id,
                        country_id,
                        outcome,
                        comments,
                        created_by,
                        creation_date,
                        last_updated_by,
                        last_update_date,
                        rules_group,
                        start_date,
                        end_date,
                        account_type,
                        default_account_type,
                        cust_account_id
                    ) VALUES (
                        c_dist_rights_rec.owner,
                        c_dist_rights_rec.reporting_group,
                        c_dist_rights_rec.category_1,
                        c_dist_rights_rec.category_2,
                        c_dist_rights_rec.format,
                        c_dist_rights_rec.sub_format,
                        c_dist_rights_rec.edition,
                        c_dist_rights_rec.from_pub_date,
                        c_dist_rights_rec.to_pub_date,
                        c_dist_rights_rec.item_number,
                        c_dist_rights_rec.country_group_id,
                        c_dist_rights_rec.country_id,
                        c_dist_rights_rec.outcome,
                        c_dist_rights_rec.comments,
                        c_dist_rights_rec.created_by,
                        c_dist_rights_rec.creation_date,
                        c_dist_rights_rec.last_updated_by,
                        c_dist_rights_rec.last_update_date,
                        c_dist_rights_rec.rules_group,
                        c_dist_rights_rec.start_date,
                        c_dist_rights_rec.end_date,
                        c_dist_rights_rec.account_type,
                        c_dist_rights_rec.default_account_type,
                        c_dist_rights_rec.cust_account_id
                    );

                    UPDATE hbg_dist_rights_stg
                    SET
                        status = 'Successfully Loaded'
                    WHERE
                        distribution_right_id = c_dist_rights_rec.distribution_right_id;

                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    x_success_message := sqlerrm;
                    UPDATE hbg_dist_rights_stg
                    SET
                        status = x_success_message
                    WHERE
                        distribution_right_id = c_dist_rights_rec.distribution_right_id;

            END;
        END LOOP;
    END hbg_dist_rights_load;

-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Distribution Rights Conversion                        
-- |Description      : This Program is used to Load the Title Rights				    
-- +===================================================================+

    PROCEDURE hbg_title_rights_load IS

        CURSOR c_title_headers IS
        SELECT DISTINCT
            htrs.tm_sr_uid,
            htrs.isbn,
            upper(htrs.exclusive_category)     AS exclusive_category,
            upper(htrs.non_exclusive_category) AS non_exclusive_category,
            upper(htrs.excluded_category)      AS excluded_category,
            htrs.active_indicator,
            esib.inventory_item_id,
            htre.title_right_id,
            htrs.transaction_user,
            htrs.transaction_date,
            htrs.last_upd_user,
            htrs.last_upd_date
        FROM
            hbg_title_rights_stg htrs,
            hbg_title_rights_ext htre,
            egp_system_items_b   esib,
            inv_org_parameters   iop
        WHERE
                1 = 1
            AND htrs.isbn = esib.item_number (+)
            AND esib.organization_id = iop.organization_id (+)
            AND iop.organization_code (+) = 'ITEM_MASTER'
            AND esib.inventory_item_id = htre.inventory_item_id (+)
--            AND htrs.tm_sr_uid IN ( 30225583, 30236872 )
            AND htrs.status IS NULL;

        CURSOR c_right_details (
            p_values         VARCHAR2,
            p_title_right_id NUMBER
        ) IS
        SELECT
            a.country_code,
            hg.geography_id,
            htrde.title_right_detail_id
        FROM
            (
                SELECT
                    regexp_substr(p_values, '[^;]+', 1, level) country_code
                FROM
                    dual
                CONNECT BY
                    regexp_substr(p_values, '[^;]+', 1, level) IS NOT NULL
            )                           a,
            hz_geographies              hg,
            hbg_title_right_details_ext htrde
        WHERE
                a.country_code = hg.geography_code (+)
            AND hg.geography_type (+) = 'COUNTRY'
            AND hg.geography_id = htrde.country_id (+)
            AND htrde.title_right_id (+) = p_title_right_id;

        x_success_message VARCHAR2(255);
        l_title_right_id  NUMBER;
        eerror EXCEPTION;
    BEGIN
        FOR c_title_headers_rec IN c_title_headers LOOP
            BEGIN
                x_success_message := NULL;
                l_title_right_id := NULL;
                IF ( c_title_headers_rec.inventory_item_id IS NULL ) THEN
                    UPDATE hbg_title_rights_stg
                    SET
                        status = 'Item does not exists'
                    WHERE
                        tm_sr_uid = c_title_headers_rec.tm_sr_uid;

                ELSE
                    l_title_right_id := c_title_headers_rec.title_right_id;
                    IF ( l_title_right_id IS NULL ) THEN
                        BEGIN
                            INSERT INTO hbg_title_rights_ext (
                                inventory_item_id,
                                created_by,
                                creation_date,
                                last_updated_by,
                                last_update_date,
                                active_indicator
                            ) VALUES (
                                c_title_headers_rec.inventory_item_id,
                                c_title_headers_rec.transaction_user,
                                sysdate,
                                c_title_headers_rec.last_upd_user,
                                sysdate,
                                c_title_headers_rec.active_indicator
                            );

                            l_title_right_id := hbg_title_rights_seq.currval;
                        EXCEPTION
                            WHEN OTHERS THEN
                                x_success_message := sqlerrm;
                                RAISE eerror;
                        END;

                    END IF;

                    IF (
                        c_title_headers_rec.exclusive_category IS NOT NULL
                        AND c_title_headers_rec.exclusive_category <> 'WORLD'
                    ) THEN
                        FOR c_right_details_rec IN c_right_details(c_title_headers_rec.exclusive_category, l_title_right_id) LOOP
                            IF ( c_right_details_rec.title_right_detail_id IS NOT NULL ) THEN
                                UPDATE hbg_title_right_details_ext
                                SET
                                    title_right_category = 'EXCLUSIVE',
                                    country_group = NULL,
                                    last_updated_by = c_title_headers_rec.last_upd_user,
                                    last_update_date = sysdate
                                WHERE
                                    title_right_detail_id = c_right_details_rec.title_right_detail_id;

                            ELSIF ( c_right_details_rec.geography_id IS NULL ) THEN
                                x_success_message := x_success_message
                                                     || ' ; '
                                                     || 'Country '
                                                     || c_right_details_rec.country_code
                                                     || ' does not exists';
                            ELSE
                                INSERT INTO hbg_title_right_details_ext (
                                    title_right_id,
                                    title_right_category,
                                    country_id,
                                    country_group,
                                    created_by,
                                    creation_date,
                                    last_updated_by,
                                    last_update_date
                                ) VALUES (
                                    l_title_right_id,
                                    'EXCLUSIVE',
                                    c_right_details_rec.geography_id,
                                    NULL,
                                    c_title_headers_rec.transaction_user,
                                    sysdate,
                                    c_title_headers_rec.last_upd_user,
                                    sysdate
                                );

                            END IF;
                        END LOOP;
                    ELSIF ( c_title_headers_rec.exclusive_category = 'WORLD' ) THEN
                        DELETE FROM hbg_title_right_details_ext
                        WHERE
                            title_right_id = l_title_right_id;

                        INSERT INTO hbg_title_right_details_ext (
                            title_right_id,
                            title_right_category,
                            country_id,
                            country_group,
                            created_by,
                            creation_date,
                            last_updated_by,
                            last_update_date
                        )
                            SELECT
                                l_title_right_id,
                                'EXCLUSIVE',
                                geography_id,
                                'WWD',
                                c_title_headers_rec.transaction_user,
                                sysdate,
                                c_title_headers_rec.last_upd_user,
                                sysdate
                            FROM
                                hz_geographies
                            WHERE
                                geography_type = 'COUNTRY';

                    END IF;

                    IF (
                        c_title_headers_rec.non_exclusive_category IS NOT NULL
                        AND c_title_headers_rec.non_exclusive_category <> 'WORLD'
                    ) THEN
                        FOR c_right_details_rec IN c_right_details(c_title_headers_rec.non_exclusive_category, l_title_right_id) LOOP
                            IF ( c_right_details_rec.title_right_detail_id IS NOT NULL ) THEN
                                UPDATE hbg_title_right_details_ext
                                SET
                                    title_right_category = 'NON-EXCLUSIVE',
                                    country_group = NULL,
                                    last_updated_by = c_title_headers_rec.last_upd_user,
                                    last_update_date = sysdate
                                WHERE
                                    title_right_detail_id = c_right_details_rec.title_right_detail_id;

                            ELSIF ( c_right_details_rec.geography_id IS NULL ) THEN
                                x_success_message := x_success_message
                                                     || ' ; '
                                                     || 'Country '
                                                     || c_right_details_rec.country_code
                                                     || ' does not exists';
                            ELSE
                                INSERT INTO hbg_title_right_details_ext (
                                    title_right_id,
                                    title_right_category,
                                    country_id,
                                    country_group,
                                    created_by,
                                    creation_date,
                                    last_updated_by,
                                    last_update_date
                                ) VALUES (
                                    l_title_right_id,
                                    'NON-EXCLUSIVE',
                                    c_right_details_rec.geography_id,
                                    NULL,
                                    c_title_headers_rec.transaction_user,
                                    sysdate,
                                    c_title_headers_rec.last_upd_user,
                                    sysdate
                                );

                            END IF;
                        END LOOP;
                    ELSIF ( c_title_headers_rec.non_exclusive_category = 'WORLD' ) THEN
                        DELETE FROM hbg_title_right_details_ext
                        WHERE
                            title_right_id = l_title_right_id;

                        INSERT INTO hbg_title_right_details_ext (
                            title_right_id,
                            title_right_category,
                            country_id,
                            country_group,
                            created_by,
                            creation_date,
                            last_updated_by,
                            last_update_date
                        )
                            SELECT
                                l_title_right_id,
                                'NON-EXCLUSIVE',
                                geography_id,
                                'WWD',
                                c_title_headers_rec.transaction_user,
                                sysdate,
                                c_title_headers_rec.last_upd_user,
                                sysdate
                            FROM
                                hz_geographies
                            WHERE
                                geography_type = 'COUNTRY';

                    END IF;

                    IF (
                        c_title_headers_rec.excluded_category IS NOT NULL
                        AND c_title_headers_rec.excluded_category <> 'WORLD'
                    ) THEN
                        FOR c_right_details_rec IN c_right_details(c_title_headers_rec.excluded_category, l_title_right_id) LOOP
                            IF ( c_right_details_rec.title_right_detail_id IS NOT NULL ) THEN
                                UPDATE hbg_title_right_details_ext
                                SET
                                    title_right_category = 'EXCLUDED',
                                    country_group = NULL,
                                    last_updated_by = c_title_headers_rec.last_upd_user,
                                    last_update_date = sysdate
                                WHERE
                                    title_right_detail_id = c_right_details_rec.title_right_detail_id;

                            ELSIF ( c_right_details_rec.geography_id IS NULL ) THEN
                                x_success_message := x_success_message
                                                     || ' ; '
                                                     || 'Country '
                                                     || c_right_details_rec.country_code
                                                     || ' does not exists';
                            ELSE
                                INSERT INTO hbg_title_right_details_ext (
                                    title_right_id,
                                    title_right_category,
                                    country_id,
                                    country_group,
                                    created_by,
                                    creation_date,
                                    last_updated_by,
                                    last_update_date
                                ) VALUES (
                                    l_title_right_id,
                                    'EXCLUDED',
                                    c_right_details_rec.geography_id,
                                    NULL,
                                    c_title_headers_rec.transaction_user,
                                    sysdate,
                                    c_title_headers_rec.last_upd_user,
                                    sysdate
                                );

                            END IF;
                        END LOOP;
                    ELSIF ( c_title_headers_rec.excluded_category = 'WORLD' ) THEN
                        DELETE FROM hbg_title_right_details_ext
                        WHERE
                            title_right_id = l_title_right_id;

                        INSERT INTO hbg_title_right_details_ext (
                            title_right_id,
                            title_right_category,
                            country_id,
                            country_group,
                            created_by,
                            creation_date,
                            last_updated_by,
                            last_update_date
                        )
                            SELECT
                                l_title_right_id,
                                'EXCLUDED',
                                geography_id,
                                'WWD',
                                c_title_headers_rec.transaction_user,
                                sysdate,
                                c_title_headers_rec.last_upd_user,
                                sysdate
                            FROM
                                hz_geographies
                            WHERE
                                geography_type = 'COUNTRY';

                    END IF;

                    UPDATE hbg_title_rights_stg
                    SET
                        status =
                            CASE
                                WHEN x_success_message IS NOT NULL THEN
                                    x_success_message
                                ELSE
                                    'Successfully Loaded'
                            END
                    WHERE
                        tm_sr_uid = c_title_headers_rec.tm_sr_uid;

                END IF;

                COMMIT;
            EXCEPTION
                WHEN eerror THEN
                    ROLLBACK;
                    UPDATE hbg_title_rights_stg
                    SET
                        status = x_success_message
                    WHERE
                        isbn = c_title_headers_rec.tm_sr_uid;

            END;
        END LOOP;
--        x_status_code := 'SUCCESS';
    END hbg_title_rights_load;


-- +===================================================================+
-- +      		   Hachette Book Group                                 +
-- +===================================================================+
-- |Object Name      : Wrapper Program                        
-- |Description      : This Program is call title rights load procedure				    
-- +===================================================================+

    PROCEDURE hbg_title_rights_wrapper(oic_run_id NUMBER) IS
    BEGIN
        dbms_scheduler.create_job(job_name => 'Title_Rights_Load'||oic_run_id, 
                                  job_type => 'PLSQL_BLOCK',
                                  job_action => 'BEGIN
                                                 hbg_so_dist_title_rights_pkg.hbg_title_rights_load;
                                                 END;',
                                  start_date => sysdate,
                                  enabled => TRUE);

        dbms_scheduler.run_job(job_name => 'Title_Rights_Load'||oic_run_id,
                               use_current_session => TRUE
                               );
    END hbg_title_rights_wrapper;

END hbg_so_dist_title_rights_pkg;

/
