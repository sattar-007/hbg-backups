--------------------------------------------------------
--  DDL for Package Body HBG_SALES_CREDIT_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."HBG_SALES_CREDIT_PKG" IS

    PROCEDURE hbg_sales_credit_div_create (
        p_division_number    IN   VARCHAR2,
        p_division_name      IN   VARCHAR2,
        p_external_checkbox  IN   VARCHAR2,
        p_notes              IN   VARCHAR2,
        p_entered_by         IN   VARCHAR2,
        p_updated_by         IN   VARCHAR2,
        p_start_date         IN   VARCHAR2,
        p_end_date           IN   VARCHAR2,
        p_status             IN   VARCHAR2,
        p_sales_force_id     IN   NUMBER,
        p_return_status      OUT  VARCHAR2
    ) IS
        l_div_cnt NUMBER := 0;
    BEGIN
        IF ( p_division_number IS NULL OR p_division_name IS NULL ) THEN
            p_return_status := ' Division Number, Division Name cannot be blank';
        ELSE
            BEGIN
                SELECT
                    COUNT(*)
                INTO l_div_cnt
                FROM
                    xxhbg_sales_force_div_tbl
                WHERE
                        division_number = p_division_number
                    AND sales_force_id = p_sales_force_id;

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

            IF l_div_cnt > 0 THEN
                p_return_status := ' Division Number '
                                   || p_division_number
                                   || ' already exists please create unique division number';
            ELSE
                INSERT INTO xxhbg_sales_force_div_tbl (
                    division_number,
                    division_name,
                    external_checkbox,
                    notes,
                    entered_by,
                    entered_date,
                    updated_by,
                    updated_date,
                    start_date,
                    end_date,
                    status,
                    sales_force_id
                ) VALUES (
                    p_division_number,
                    p_division_name,
                    p_external_checkbox,
                    p_notes,
                    p_entered_by,
                    sysdate,
                    p_updated_by,
                    sysdate,
                    to_date(p_start_date, 'YYYY-MM-DD'),
                    to_date(p_end_date, 'YYYY-MM-DD'),
                    p_status,
                    p_sales_force_id
                );

                p_return_status := 'SUCCESS';
            END IF;

            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating Division :' || sqlerrm;
    END;

    PROCEDURE hbg_sales_credit_div_update (
        p_sf_div_id          IN   NUMBER,
        p_division_number    IN   VARCHAR2,
        p_division_name      IN   VARCHAR2,
        p_external_checkbox  IN   VARCHAR2,
        p_notes              IN   VARCHAR2,
        p_updated_by         IN   VARCHAR2,
        p_start_date         IN   VARCHAR2,
        p_end_date           IN   VARCHAR2,
        p_status             IN   VARCHAR2,
        p_sales_force_id     IN   NUMBER,
        p_return_status      OUT  VARCHAR2
    ) AS
        l_status VARCHAR2(20);
    BEGIN
        IF p_sf_div_id IS NOT NULL THEN
--            IF to_date(to_char(sysdate, 'YYYY-MM-DD'), 'YYYY-MM-DD') > to_date(to_char(p_end_date, 'YYYY-MM-DD'), 'YYYY-MM-DD') THEN
--                l_status := 'Inactive';
--            ELSE
--                l_status := 'Active';
--            END IF;

            UPDATE xxhbg_sales_force_div_tbl
            SET
                division_number = p_division_number,
                division_name = p_division_name,
                external_checkbox = p_external_checkbox,
                notes = p_notes,
                updated_by = p_updated_by,
                updated_date = sysdate,
                start_date = to_date(p_start_date, 'YYYY-MM-DD'),
                end_date = to_date(p_end_date, 'YYYY-MM-DD'),
                status = p_status,
                sales_force_id = p_sales_force_id
            WHERE
                sf_div_id = p_sf_div_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Division :' || sqlerrm;
    END;

    PROCEDURE hbg_sales_credit_sf_create (
        p_sales_force_number  IN   VARCHAR2,
        p_sales_force_name    IN   VARCHAR2,
        p_company             IN   VARCHAR2,
        p_edelweiss           IN   VARCHAR2,
        p_external_checkbox   IN   VARCHAR2,
        p_notes               IN   VARCHAR2,
        p_entered_by          IN   VARCHAR2,
        p_updated_by          IN   VARCHAR2,
        p_start_date          IN   VARCHAR2,
        p_end_date            IN   VARCHAR2,
        p_status              IN   VARCHAR2,
        p_return_status       OUT  VARCHAR2,
        p_sales_force_id      OUT  NUMBER
    ) IS
        l_sf_cnt NUMBER := 0;
    BEGIN
        IF ( p_sales_force_number IS NULL OR p_sales_force_name IS NULL ) THEN
            p_return_status := 'Sales Force Number and Sales Force Name feilds cannot be blank';
        ELSE
            BEGIN
                SELECT
                    COUNT(*)
                INTO l_sf_cnt
                FROM
                    xxhbg_sales_force_maintenance_tbl
                WHERE
                    upper(sales_force_number) = upper(p_sales_force_number);

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

            IF l_sf_cnt > 0 THEN
                p_return_status := ' Sales force Number '
                                   || p_sales_force_number
                                   || ' already exists please create unique sales force number';
            ELSE
                INSERT INTO xxhbg_sales_force_maintenance_tbl (
                    sales_force_number,
                    sales_force_name,
                    company,
                    edelweiss,
                    external_checkbox,
                    notes,
                    entered_by,
                    entered_date,
                    updated_by,
                    updated_date,
                    start_date,
                    end_date,
                    status
                ) VALUES (
                    p_sales_force_number,
                    p_sales_force_name,
                    p_company,
                    p_edelweiss,
                    p_external_checkbox,
                    p_notes,
                    p_entered_by,
                    sysdate,
                    p_updated_by,
                    sysdate,
                    to_date(p_start_date, 'YYYY-MM-DD'),
                    to_date(p_end_date, 'YYYY-MM-DD'),
                    p_status
                );

                p_return_status := 'SUCCESS';
            END IF;

            COMMIT;
            
           -- p_sales_force_id := xxhbg_sales_force_maintenance_tbl_seq.currval;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while Creating sales force  :' || sqlerrm;
    END;

    PROCEDURE hbg_sales_credit_sf_update (
        p_sales_force_id      IN   NUMBER,
        p_sales_force_number  IN   VARCHAR2,
        p_sales_force_name    IN   VARCHAR2,
        p_company             IN   VARCHAR2,
        p_edelweiss           IN   VARCHAR2,
        p_external_checkbox   IN   VARCHAR2,
        p_notes               IN   VARCHAR2,
        p_entered_by          IN   VARCHAR2,
        p_updated_by          IN   VARCHAR2,
        p_start_date          IN   VARCHAR2,
        p_end_date            IN   VARCHAR2,
        p_status              IN   VARCHAR2,
        p_return_status       OUT  VARCHAR2
    ) AS
    BEGIN
        IF p_sales_force_id IS NOT NULL THEN
            UPDATE xxhbg_sales_force_maintenance_tbl
            SET
                sales_force_number = p_sales_force_number,
                sales_force_name = p_sales_force_name,
                company = p_company,
                edelweiss = p_edelweiss,
                external_checkbox = p_external_checkbox,
                notes = p_notes,
                entered_by = p_entered_by,
                updated_by = p_updated_by,
                updated_date = sysdate,
                start_date = to_date(p_start_date, 'YYYY-MM-DD'),
                end_date = to_date(p_end_date, 'YYYY-MM-DD'),
                status = p_status
            WHERE
                sales_force_id = p_sales_force_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while Updating sales force  :' || sqlerrm;
    END hbg_sales_credit_sf_update;

    PROCEDURE hbg_sales_credit_territory_create (
        p_territory_number     IN   VARCHAR2,
        p_territory_name       IN   VARCHAR2,
        p_external_checkbox    IN   VARCHAR2,
        p_email                IN   VARCHAR2,
        p_edelweiss            IN   VARCHAR2,
        p_wholesale_commision  IN   NUMBER,
        p_retail_commision     IN   NUMBER,
        p_notes                IN   VARCHAR2,
        p_entered_by           IN   VARCHAR2,
        p_updated_by           IN   VARCHAR2,
        p_start_date           IN   VARCHAR2,
        p_end_date             IN   VARCHAR2,
        p_status               IN   VARCHAR2,
        p_sf_div_id            IN   NUMBER,
        p_sales_force_id       IN   NUMBER,
        p_return_status        OUT  VARCHAR2
    ) IS
        l_tr_cnt NUMBER := 0;
    BEGIN
        IF ( p_territory_number IS NULL OR p_territory_name IS NULL ) THEN
            p_return_status := 'Territory Number and Territory Name feilds cannot be blank';
        ELSE
            BEGIN
                SELECT
                    COUNT(*)
                INTO l_tr_cnt
                FROM
                    xxhbg_sales_force_territory_tbl
                WHERE
                        upper(territory_number) = upper(p_territory_number)
                    AND sf_div_id = p_sf_div_id;

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

            IF l_tr_cnt > 0 THEN
                p_return_status := ' Territory Number '
                                   || p_territory_number
                                   || ' already exists please create unique territory number';
            ELSE
                INSERT INTO xxhbg_sales_force_territory_tbl (
                    territory_number,
                    territory_name,
                    external_checkbox,
                    email,
                    edelweiss,
                    wholesale_commision,
                    retail_commision,
                    notes,
                    entered_by,
                    entered_date,
                    updated_by,
                    updated_date,
                    start_date,
                    end_date,
                    status,
                    sf_div_id,
                    sales_force_id
                ) VALUES (
                    p_territory_number,
                    p_territory_name,
                    p_external_checkbox,
                    p_email,
                    p_edelweiss,
                    p_wholesale_commision,
                    p_retail_commision,
                    p_notes,
                    p_entered_by,
                    sysdate,
                    p_updated_by,
                    sysdate,
                    to_date(p_start_date, 'YYYY-MM-DD'),
                    to_date(p_end_date, 'YYYY-MM-DD'),
                    p_status,
                    p_sf_div_id,
                    p_sales_force_id
                );

                p_return_status := 'SUCCESS';
            END IF;

            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while Creating Territory  :' || sqlerrm;
    END hbg_sales_credit_territory_create;

    PROCEDURE hbg_sales_credit_territory_update (
        p_sf_territory_id      IN   NUMBER,
        p_territory_number     IN   VARCHAR2,
        p_territory_name       IN   VARCHAR2,
        p_external_checkbox    IN   VARCHAR2,
        p_email                IN   VARCHAR2,
        p_edelweiss            IN   VARCHAR2,
        p_wholesale_commision  IN   NUMBER,
        p_retail_commision     IN   NUMBER,
        p_notes                IN   VARCHAR2,
        p_entered_by           IN   VARCHAR2,
        p_updated_by           IN   VARCHAR2,
        p_start_date           IN   VARCHAR2,
        p_end_date             IN   VARCHAR2,
        p_status               IN   VARCHAR2,
        p_sf_div_id            IN   NUMBER,
        p_sales_force_id       IN   NUMBER,
        p_return_status        OUT  VARCHAR2
    ) AS
    BEGIN
        IF p_sf_territory_id IS NOT NULL THEN
            UPDATE xxhbg_sales_force_territory_tbl
            SET
                territory_number = p_territory_number,
                territory_name = p_territory_name,
                external_checkbox = p_external_checkbox,
                email = p_email,
                edelweiss = p_edelweiss,
                wholesale_commision = p_wholesale_commision,
                retail_commision = p_retail_commision,
                notes = p_notes,
                entered_by = p_entered_by,
                updated_by = p_updated_by,
                updated_date = sysdate,
                start_date = to_date(p_start_date, 'YYYY-MM-DD'),
                end_date = to_date(p_end_date, 'YYYY-MM-DD'),
                status = p_status,
                sf_div_id = p_sf_div_id,
                sales_force_id = p_sales_force_id
            WHERE
                sf_territory_id = p_sf_territory_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Territory  :' || sqlerrm;
    END;

    PROCEDURE hbg_sales_credit_dist_channel_create (
        p_distribution_channel         IN   VARCHAR2,
        p_dist_channel_description     IN   VARCHAR2,
        p_owner                        IN   VARCHAR2,
        p_owner_description            IN   VARCHAR2,
        p_reporting_group              IN   VARCHAR2,
        p_reporting_group_description  IN   VARCHAR2,
        p_entered_by                   IN   VARCHAR2,
        p_updated_by                   IN   VARCHAR2,
        p_start_date                   IN   VARCHAR2,
        p_end_date                     IN   VARCHAR2,
        p_return_status                OUT  VARCHAR2
    ) IS
        l_dc_cnt NUMBER := 0;
    BEGIN
        IF ( p_distribution_channel IS NULL ) THEN
            p_return_status := ' Distribution Channel feilds cannot be blank';
        ELSE
            BEGIN
                SELECT
                    COUNT(*)
                INTO l_dc_cnt
                FROM
                    xxhbg_distrubution_channel_tbl
                WHERE
                    distribution_channel = p_distribution_channel;

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

            IF l_dc_cnt > 0 THEN
                p_return_status := ' Distribution channel '
                                   || p_distribution_channel
                                   || ' already exists please create unique distribution channel ';
            ELSE
                INSERT INTO xxhbg_distrubution_channel_tbl (
                    distribution_channel,
                    dist_channel_description,
                    owner,
                    owner_description,
                    reporting_group,
                    reporting_group_description,
                    entered_by,
                    entered_date,
                    updated_by,
                    updated_date,
                    start_date,
                    end_date
                ) VALUES (
                    p_distribution_channel,
                    p_dist_channel_description,
                    p_owner,
                    p_owner_description,
                    p_reporting_group,
                    p_reporting_group_description,
                    p_entered_by,
                    sysdate,
                    p_updated_by,
                    sysdate,
                    to_date(p_start_date, 'YYYY-MM-DD'),
                    to_date(p_end_date, 'YYYY-MM-DD')
                );

                COMMIT;
                p_return_status := 'SUCCESS';
            END IF;

        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while Creating Distribution channel   :' || sqlerrm;
    END;

    PROCEDURE hbg_sales_credit_dist_channel_update (
        p_dist_channel_id              IN   NUMBER,
        p_distribution_channel         IN   VARCHAR2,
        p_dist_channel_description     IN   VARCHAR2,
        p_owner                        IN   VARCHAR2,
        p_owner_description            IN   VARCHAR2,
        p_reporting_group              IN   VARCHAR2,
        p_reporting_group_description  IN   VARCHAR2,
        p_entered_by                   IN   VARCHAR2,
        p_updated_by                   IN   VARCHAR2,
        p_start_date                   IN   VARCHAR2,
        p_end_date                     IN   VARCHAR2,
        p_return_status                OUT  VARCHAR2
    ) IS
    BEGIN
        IF p_dist_channel_id IS NOT NULL THEN
            UPDATE xxhbg_distrubution_channel_tbl
            SET
                distribution_channel = p_distribution_channel,
                dist_channel_description = p_dist_channel_description,
                owner = p_owner,
                owner_description = p_owner_description,
                reporting_group = p_reporting_group,
                reporting_group_description = p_reporting_group_description,
                entered_by = p_entered_by,
                updated_by = p_updated_by,
                updated_date = sysdate,
                start_date = to_date(p_start_date, 'yyyy-mm-dd'),
                end_date = to_date(p_end_date, 'yyyy-mm-dd')
            WHERE
                dist_channel_id = p_dist_channel_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Distribution channel   :' || sqlerrm;
    END;

    PROCEDURE hbg_sales_rep_create (
        p_sales_rep_number               IN   VARCHAR2,
        p_sales_rep_name                 IN   VARCHAR2,
        p_external_sales_rep_identifier  IN   NUMBER,
        p_address                        IN   VARCHAR2,
        p_city                           IN   VARCHAR2,
        p_state                          IN   VARCHAR2,
        p_postal_code                    IN   VARCHAR2,
        p_country                        IN   VARCHAR2,
        p_phone_number                   IN   VARCHAR2,
        p_email                          IN   VARCHAR2,
        p_company                        IN   VARCHAR2,
        p_company_description            IN   VARCHAR2,
        p_external_checkbox              IN   VARCHAR2,
        p_wholesale_commision            IN   NUMBER,
        p_retail_commision               IN   NUMBER,
        p_edelweiss                      IN   VARCHAR2,
        p_notes                          IN   VARCHAR2,
        p_entered_by                     IN   VARCHAR2,
        p_updated_by                     IN   VARCHAR2,
        p_start_date                     IN   VARCHAR2,
        p_end_date                       IN   VARCHAR2,
        p_status                         IN   VARCHAR2,
        p_sf_territory_id                IN   NUMBER,
        p_sales_force_id                 IN   NUMBER,
        p_division_id                    IN   NUMBER,
        p_return_status                  OUT  VARCHAR2
    ) AS
        l_sr_cnt NUMBER := 0;
    BEGIN
        IF ( p_sales_rep_number IS NULL OR p_sales_rep_name IS NULL ) THEN
            p_return_status := 'Sales rep number and Sales rep number  feilds cannot be blank';
        ELSE
            BEGIN
                SELECT
                    COUNT(*)
                INTO l_sr_cnt
                FROM
                    xxhbg_sales_force_sales_rep_tbl
                WHERE
                        sales_rep_number = p_sales_rep_number
                    AND sf_territory_id = p_sf_territory_id
                    AND sales_force_id = p_sales_force_id
                    AND sf_div_id = p_division_id;

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

            IF l_sr_cnt > 0 THEN
                p_return_status := ' Sales rep '
                                   || p_sales_rep_number
                                   || ' already exists please create unique Sales rep ';
            ELSE
                INSERT INTO xxhbg_sales_force_sales_rep_tbl (
                    sales_rep_number,
                    sales_rep_name,
                    external_sales_rep_identifier,
                    address,
                    city,
                    state,
                    postal_code,
                    country,
                    phone_number,
                    email,
                    company,
                    company_description,
                    external_checkbox,
                    wholesale_commision,
                    retail_commision,
                    edelweiss,
                    notes,
                    entered_by,
                    entered_date,
                    updated_by,
                    updated_date,
                    start_date,
                    end_date,
                    status,
                    sf_territory_id,
                    sales_force_id,
                    sf_div_id
                ) VALUES (
                    p_sales_rep_number,
                    p_sales_rep_name,
                    p_external_sales_rep_identifier,
                    p_address,
                    p_city,
                    p_state,
                    p_postal_code,
                    p_country,
                    p_phone_number,
                    p_email,
                    p_company,
                    p_company_description,
                    p_external_checkbox,
                    p_wholesale_commision,
                    p_retail_commision,
                    p_edelweiss,
                    p_notes,
                    p_entered_by,
                    sysdate,
                    p_updated_by,
                    sysdate,
                    to_date(p_start_date, 'YYYY-MM-DD'),
                    to_date(p_end_date, 'YYYY-MM-DD'),
                    p_status,
                    p_sf_territory_id,
                    p_sales_force_id,
                    p_division_id
                );

                p_return_status := 'SUCCESS';
                COMMIT;
            END IF;

        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating sales rep  :' || sqlerrm;
    END;

    PROCEDURE hbg_sales_rep_update (
        p_sf_sales_rep_id                IN   NUMBER,
        p_sales_rep_number               IN   VARCHAR2,
        p_sales_rep_name                 IN   VARCHAR2,
        p_external_sales_rep_identifier  IN   NUMBER,
        p_address                        IN   VARCHAR2,
        p_city                           IN   VARCHAR2,
        p_state                          IN   VARCHAR2,
        p_postal_code                    IN   VARCHAR2,
        p_country                        IN   VARCHAR2,
        p_phone_number                   IN   VARCHAR2,
        p_email                          IN   VARCHAR2,
        p_company                        IN   VARCHAR2,
        p_company_description            IN   VARCHAR2,
        p_external_checkbox              IN   VARCHAR2,
        p_wholesale_commision            IN   NUMBER,
        p_retail_commision               IN   NUMBER,
        p_edelweiss                      IN   VARCHAR2,
        p_notes                          IN   VARCHAR2,
        p_entered_by                     IN   VARCHAR2,
        p_updated_by                     IN   VARCHAR2,
        p_start_date                     IN   VARCHAR2,
        p_end_date                       IN   VARCHAR2,
        p_status                         IN   VARCHAR2,
        p_sf_territory_id                IN   NUMBER,
        p_sales_force_id                 IN   NUMBER,
        p_division_id                    IN   NUMBER,
        p_return_status                  OUT  VARCHAR2
    ) AS
    BEGIN
        IF p_sf_sales_rep_id IS NOT NULL THEN
            UPDATE xxhbg_sales_force_sales_rep_tbl
            SET
                sales_rep_number = p_sales_rep_number,
                sales_rep_name = p_sales_rep_name,
                external_sales_rep_identifier = p_external_sales_rep_identifier,
                address = p_address,
                city = p_city,
                state = p_state,
                postal_code = p_postal_code,
                country = p_country,
                phone_number = p_phone_number,
                email = p_email,
                company = p_company,
                company_description = p_company_description,
                external_checkbox = p_external_checkbox,
                wholesale_commision = p_wholesale_commision,
                retail_commision = p_retail_commision,
                edelweiss = p_edelweiss,
                notes = p_notes,
                entered_by = p_entered_by,
                updated_by = p_updated_by,
                updated_date = sysdate,
                start_date = to_date(p_start_date, 'YYYY-MM-DD'),
                end_date = to_date(p_end_date, 'YYYY-MM-DD'),
                status = p_status,
                sf_territory_id = p_sf_territory_id,
                sales_force_id = p_sales_force_id,
                sf_div_id = p_division_id
            WHERE
                sf_sales_rep_id = p_sf_sales_rep_id;

            p_return_status := 'SUCCESS';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating sales rep  :' || sqlerrm;
    END;

    PROCEDURE hbg_sales_mapping_create (
        p_isbn                         IN   VARCHAR2,
        p_sales_force                  IN   VARCHAR2,
        p_sales_force_name             IN   VARCHAR2,
        p_owner                        IN   VARCHAR2,
        p_owner_description            IN   VARCHAR2,
        p_reporting_group              IN   VARCHAR2,
        p_reporting_group_description  IN   VARCHAR2,
        p_category_1                   IN   VARCHAR2,
        p_category_1_description       IN   VARCHAR2,
        p_category_2                   IN   VARCHAR2,
        p_category_2_description       IN   VARCHAR2,
        p_format                       IN   VARCHAR2,
        p_format_description           IN   VARCHAR2,
        p_sub_format                   IN   VARCHAR2,
        p_sub_format_description       IN   VARCHAR2,
        p_bisac                        IN   VARCHAR2,
        p_bisac_description            IN   VARCHAR2,
        p_account_type                 IN   VARCHAR2,
        p_account_type_description     IN   VARCHAR2,
        p_priority                     IN   NUMBER,
        p_notes                        IN   VARCHAR2,
        p_entered_by                   IN   VARCHAR2,
        p_updated_by                   IN   VARCHAR2,
        p_start_date                   IN   VARCHAR2,
        p_end_date                     IN   VARCHAR2,
        p_status                       IN   VARCHAR2,
        p_sales_force_id               IN   NUMBER,
        p_sf_acct_type_id              IN   NUMBER,
        p_return_status                OUT  VARCHAR2
    ) IS
    BEGIN
        IF ( p_sales_force IS NULL OR p_sales_force_name IS NULL ) THEN
            p_return_status := 'sales force and sales force name  feilds cannot be blank';
        ELSE
            INSERT INTO xxhbg_sales_force_mapping_tbl (
                isbn,
                sales_force,
                sales_force_name,
                owner,
                owner_description,
                reporting_group,
                reporting_group_description,
                category_1,
                category_1_description,
                category_2,
                category_2_description,
                format,
                format_description,
                sub_format,
                sub_format_description,
                bisac,
                bisac_description,
                account_type,
                account_type_description,
                priority,
                notes,
                entered_by,
                entered_date,
                updated_by,
                updated_date,
                start_date,
                end_date,
                status,
                sales_force_id,
                sf_acct_type_id
            ) VALUES (
                p_isbn,
                p_sales_force,
                p_sales_force_name,
                p_owner,
                p_owner_description,
                p_reporting_group,
                p_reporting_group_description,
                p_category_1,
                p_category_1_description,
                p_category_2,
                p_category_2_description,
                p_format,
                p_format_description,
                p_sub_format,
                p_sub_format_description,
                p_bisac,
                p_bisac_description,
                p_account_type,
                p_account_type_description,
                p_priority,
                p_notes,
                p_entered_by,
                sysdate,
                p_updated_by,
                sysdate,
                to_date(p_start_date, 'YYYY-MM-DD'),
                to_date(p_end_date, 'YYYY-MM-DD'),
                p_status,
                p_sales_force_id,
                p_sf_acct_type_id
            );

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating sales force mapping  :' || sqlerrm;
    END;

    PROCEDURE hbg_sales_teritory_create (
        p_territory_number     IN   VARCHAR2,
        p_territory_name       IN   VARCHAR2,
        p_external_checkbox    IN   VARCHAR2,
        p_email                IN   VARCHAR2,
        p_edelweiss            IN   VARCHAR2,
        p_wholesale_commision  IN   NUMBER,
        p_retail_commision     IN   NUMBER,
        p_notes                IN   VARCHAR2,
        p_entered_by           IN   VARCHAR2,
        p_updated_by           IN   VARCHAR2,
        p_updated_date         IN   DATE,
        p_start_date           IN   VARCHAR2,
        p_end_date             IN   VARCHAR2,
        p_status               IN   VARCHAR2,
        p_sf_div_id            IN   NUMBER,
        p_return_status        OUT  VARCHAR2
    ) IS
    BEGIN
        IF ( p_territory_number IS NULL OR p_territory_name IS NULL ) THEN
            p_return_status := 'Territory number and territory name  feilds cannot be blank';
        ELSE
            INSERT INTO xxhbg_sales_force_territory_tbl (
                territory_number,
                territory_name,
                external_checkbox,
                email,
                edelweiss,
                wholesale_commision,
                retail_commision,
                notes,
                entered_by,
                entered_date,
                updated_by,
                updated_date,
                start_date,
                end_date,
                status,
                sf_div_id
            ) VALUES (
                p_territory_number,
                p_territory_name,
                p_external_checkbox,
                p_email,
                p_edelweiss,
                p_wholesale_commision,
                p_retail_commision,
                p_notes,
                p_entered_by,
                sysdate,
                p_updated_by,
                sysdate,
                p_start_date,
                p_end_date,
                p_status,
                p_sf_div_id
            );

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating sales Territory  :' || sqlerrm;
    END;

    PROCEDURE hbg_sales_distribution_channel_create (
        p_distribution_channel         IN   VARCHAR2,
        p_dist_channel_description     IN   VARCHAR2,
        p_owner                        IN   VARCHAR2,
        p_owner_description            IN   VARCHAR2,
        p_reporting_group              IN   NUMBER,
        p_reporting_group_description  IN   VARCHAR2,
        p_entered_by                   IN   VARCHAR2,
        p_updated_by                   IN   VARCHAR2,
        p_updated_date                 IN   DATE,
        p_start_date                   IN   VARCHAR2,
        p_end_date                     IN   VARCHAR2,
        p_return_status                OUT  VARCHAR2
    ) IS
    BEGIN
        IF ( p_distribution_channel IS NULL ) THEN
            p_return_status := 'Distribution Channel  feild cannot be blank';
        ELSE
            INSERT INTO xxhbg_distrubution_channel_tbl (
                distribution_channel,
                dist_channel_description,
                owner,
                owner_description,
                reporting_group,
                reporting_group_description,
                entered_by,
                entered_date,
                updated_by,
                updated_date,
                start_date,
                end_date
            ) VALUES (
                p_distribution_channel,
                p_dist_channel_description,
                p_owner,
                p_owner_description,
                p_reporting_group,
                p_reporting_group_description,
                p_entered_by,
                sysdate,
                p_updated_by,
                sysdate,
                to_date(p_start_date, 'YYYY-MM-DD'),
                to_date(p_end_date, 'YYYY-MM-DD')
            );

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating Sales Distribution Channel  :' || sqlerrm;
    END;

    PROCEDURE hbg_sales_assign_distribution_create (
        p_account_number            IN   VARCHAR2,
        p_account_name              IN   VARCHAR2,
        p_sales_force_number        IN   VARCHAR2,
        p_sales_force_name          IN   VARCHAR2,
        p_owner                     IN   VARCHAR2,
        p_reporting_group           IN   VARCHAR2,
        p_category_1                IN   VARCHAR2,
        p_category_2                IN   VARCHAR2,
        p_bisac                     IN   VARCHAR2,
        p_bisac_description         IN   VARCHAR2,
        p_distribution_channel      IN   VARCHAR2,
        p_dist_channel_description  IN   VARCHAR2,
        p_notes                     IN   VARCHAR2,
        p_entered_by                IN   VARCHAR2,
        p_updated_by                IN   VARCHAR2,
        p_start_date                IN   VARCHAR2,
        p_end_date                  IN   VARCHAR2,
        p_dist_channel_id           IN   NUMBER,
        p_return_status             OUT  VARCHAR2
    ) IS
    BEGIN
        IF ( p_account_number IS NULL OR p_account_name IS NULL ) THEN
            p_return_status := 'Account number and Account name  feild cannot be blank';
        ELSE
            INSERT INTO xxhbg_assign_distrubution_channel_tbl (
                account_number,
                account_name,
                sales_force_number,
                sales_force_name,
                owner,
                reporting_group,
                category_1,
                category_2,
                bisac,
                bisac_description,
                distribution_channel,
                dist_channel_description,
                notes,
                entered_by,
                entered_date,
                updated_by,
                updated_date,
                start_date,
                end_date,
                dist_channel_id
            ) VALUES (
                p_account_number,
                p_account_name,
                p_sales_force_number,
                p_sales_force_name,
                p_owner,
                p_reporting_group,
                p_category_1,
                p_category_2,
                p_bisac,
                p_bisac_description,
                p_distribution_channel,
                p_dist_channel_description,
                p_notes,
                p_entered_by,
                sysdate,
                p_updated_by,
                sysdate,
                to_date(p_start_date, 'YYYY-MM-DD'),
                to_date(p_end_date, 'YYYY-MM-DD'),
                p_dist_channel_id
            );

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating Assign Distrubution Channel :' || sqlerrm;
    END;

    PROCEDURE hbg_sales_mapping_update (
        p_sf_mapping_id                IN   NUMBER,
        p_isbn                         IN   VARCHAR2,
        p_sales_force                  IN   VARCHAR2,
        p_sales_force_name             IN   VARCHAR2,
        p_owner                        IN   VARCHAR2,
        p_owner_description            IN   VARCHAR2,
        p_reporting_group              IN   VARCHAR2,
        p_reporting_group_description  IN   VARCHAR2,
        p_category_1                   IN   VARCHAR2,
        p_category_1_description       IN   VARCHAR2,
        p_category_2                   IN   VARCHAR2,
        p_category_2_description       IN   VARCHAR2,
        p_format                       IN   VARCHAR2,
        p_format_description           IN   VARCHAR2,
        p_sub_format                   IN   VARCHAR2,
        p_sub_format_description       IN   VARCHAR2,
        p_bisac                        IN   VARCHAR2,
        p_bisac_description            IN   VARCHAR2,
        p_account_type                 IN   VARCHAR2,
        p_account_type_description     IN   VARCHAR2,
        p_priority                     IN   NUMBER,
        p_notes                        IN   VARCHAR2,
        p_entered_by                   IN   VARCHAR2,
        p_updated_by                   IN   VARCHAR2,
        p_start_date                   IN   VARCHAR2,
        p_end_date                     IN   VARCHAR2,
        p_status                       IN   VARCHAR2,
        p_sales_force_id               IN   NUMBER,
        p_sf_acct_type_id              IN   NUMBER,
        p_return_status                OUT  VARCHAR2
    ) AS
    BEGIN
        IF p_sf_mapping_id IS NOT NULL THEN
            UPDATE xxhbg_sales_force_mapping_tbl
            SET
                sf_mapping_id = p_sf_mapping_id,
                isbn = p_isbn,
                sales_force = p_sales_force,
                sales_force_name = p_sales_force_name,
                owner = p_owner,
                owner_description = p_owner_description,
                reporting_group = p_reporting_group,
                reporting_group_description = p_reporting_group_description,
                category_1 = p_category_1,
                category_1_description = p_category_1_description,
                category_2 = p_category_2,
                category_2_description = p_category_2_description,
                format = p_format,
                format_description = p_format_description,
                sub_format = p_sub_format,
                sub_format_description = p_sub_format_description,
                bisac = p_bisac,
                bisac_description = p_bisac_description,
                account_type = p_account_type,
                account_type_description = p_account_type_description,
                priority = p_priority,
                notes = p_notes,
                entered_by = p_entered_by,
                updated_by = p_updated_by,
                updated_date = sysdate,
                start_date = to_date(p_start_date, 'YYYY-MM-DD'),
                end_date = to_date(p_end_date, 'YYYY-MM-DD'),
                status = p_status,
                sales_force_id = p_sales_force_id,
                sf_acct_type_id = p_sf_acct_type_id
            WHERE
                sf_mapping_id = p_sf_mapping_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating sales force mapping :' || sqlerrm;
    END;

    PROCEDURE hbg_sales_assign_distribution_update (
        p_dist_chnl_assign_id       IN   NUMBER,
        p_account_number            IN   VARCHAR2,
        p_account_name              IN   VARCHAR2,
        p_sales_force_number        IN   VARCHAR2,
        p_sales_force_name          IN   VARCHAR2,
        p_owner                     IN   VARCHAR2,
        p_reporting_group           IN   VARCHAR2,
        p_category_1                IN   VARCHAR2,
        p_category_2                IN   VARCHAR2,
        p_bisac                     IN   VARCHAR2,
        p_bisac_description         IN   VARCHAR2,
        p_distribution_channel      IN   VARCHAR2,
        p_dist_channel_description  IN   VARCHAR2,
        p_notes                     IN   VARCHAR2,
        p_entered_by                IN   VARCHAR2,
        p_updated_by                IN   VARCHAR2,
        p_start_date                IN   VARCHAR2,
        p_end_date                  IN   VARCHAR2,
        p_dist_channel_id           IN   NUMBER,
        p_return_status             OUT  VARCHAR2
    ) AS
    BEGIN
        IF p_dist_chnl_assign_id IS NOT NULL THEN
            UPDATE xxhbg_assign_distrubution_channel_tbl
            SET
                account_number = p_account_number,
                account_name = p_account_name,
                sales_force_number = p_sales_force_number,
                sales_force_name = p_sales_force_name,
                owner = p_owner,
                reporting_group = p_reporting_group,
                category_1 = p_category_1,
                category_2 = p_category_2,
                bisac = p_bisac,
                bisac_description = p_bisac_description,
                distribution_channel = p_distribution_channel,
                dist_channel_description = p_dist_channel_description,
                notes = p_notes,
                entered_by = p_entered_by,
                updated_by = p_updated_by,
                updated_date = sysdate,
                start_date = to_date(p_start_date, 'YYYY-MM-DD'),
                end_date = to_date(p_end_date, 'YYYY-MM-DD'),
                dist_channel_id = p_dist_channel_id
            WHERE
                dist_chnl_assign_id = p_dist_chnl_assign_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating sales force mapping :' || sqlerrm;
    END;

    PROCEDURE hbg_sales_force_create (
        p_sales_force_id           IN   NUMBER,
        p_om_destination_account   IN   NUMBER,
        p_om_sales_force_code      IN   NUMBER,
        p_om_division              IN   NUMBER,
        p_om_territory             IN   NUMBER,
        p_om_sales_rep             IN   NUMBER,
        p_om_distribution_channel  IN   VARCHAR2,
        p_ar_sales_force_code      IN   NUMBER,
        p_ar_division              IN   NUMBER,
        p_ar_territory             IN   NUMBER,
        p_ar_sales_rep             IN   NUMBER,
        p_ar_distribution_channel  IN   VARCHAR2,
        p_created_by               IN   VARCHAR2,
        p_created_date             IN   DATE,
        p_last_updated_by          IN   VARCHAR2,
        p_last_updated_date        IN   DATE,
        p_return_status            OUT  VARCHAR2
    ) IS
    BEGIN
        IF ( p_om_sales_force_code IS NULL ) THEN
            p_return_status := 'Om Sales Force Code feild cannot be blank';
        ELSE
            INSERT INTO xxhbg_sales_force_tbl (
                sales_force_id,
                om_destination_account,
                om_sales_force_code,
                om_division,
                om_territory,
                om_sales_rep,
                om_distribution_channel,
                ar_sales_force_code,
                ar_division,
                ar_territory,
                ar_sales_rep,
                ar_distribution_channel,
                created_by,
                created_date,
                last_updated_by,
                last_updated_date
            ) VALUES (
                p_sales_force_id,
                p_om_destination_account,
                p_om_sales_force_code,
                p_om_division,
                p_om_territory,
                p_om_sales_rep,
                p_om_distribution_channel,
                p_ar_sales_force_code,
                p_ar_division,
                p_ar_territory,
                p_ar_sales_rep,
                p_ar_distribution_channel,
                p_created_by,
                sysdate,
                p_last_updated_by,
                sysdate
            );

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating om sales force code :' || sqlerrm;
    END;

    PROCEDURE hbg_sales_force_assign_create (
        p_owner                        IN   VARCHAR2,
        p_owner_description            IN   VARCHAR2,
        p_reporting_group              IN   VARCHAR2,
        p_reporting_group_description  IN   VARCHAR2,
        p_category_1                   IN   VARCHAR2,
        p_category_1_description       IN   VARCHAR2,
        p_category_2                   IN   VARCHAR2,
        p_category_2_description       IN   VARCHAR2,
        p_format                       IN   VARCHAR2,
        p_format_description           IN   VARCHAR2,
        p_sub_format                   IN   VARCHAR2,
        p_sub_format_description       IN   VARCHAR2,
        p_bisac                        IN   VARCHAR2,
        p_bisac_description            IN   VARCHAR2,
        p_customer_org_number          IN   NUMBER,
        p_organization_name            IN   VARCHAR2,
        p_customer_account_number      IN   VARCHAR2,
        p_account_name                 IN   VARCHAR2,
        p_account_type                 IN   VARCHAR2,
        p_bill_to_                     IN   VARCHAR2,
        p_state_province               IN   VARCHAR2,
        p_bill_to_country              IN   VARCHAR2,
        p_alt_sales_country            IN   VARCHAR2,
        p_ship_to_number               IN   VARCHAR2,
        p_ship_to_name                 IN   VARCHAR2,
        p_ship_to_state                IN   VARCHAR2,
        p_ship_to_country              IN   VARCHAR2,
        p_final_destination_country    IN   VARCHAR2,
        p_sales_force                  IN   VARCHAR2,
        p_sales_force_name             IN   VARCHAR2,
        p_division                     IN   VARCHAR2,
        p_division_name                IN   VARCHAR2,
        p_territory                    IN   VARCHAR2,
        p_territory_name               IN   VARCHAR2,
        p_sales_rep                    IN   VARCHAR2,
        p_sales_rep_name               IN   VARCHAR2,
        p_override                     IN   VARCHAR2,
        p_account_override_start_date  IN   VARCHAR2,
        p_account_override_end_date    IN   VARCHAR2,
        p_notes                        IN   VARCHAR2,
        p_entered_by                   IN   VARCHAR2,
        p_updated_by                   IN   VARCHAR2,
        p_start_date                   IN   VARCHAR2,
        p_end_date                     IN   VARCHAR2,
        p_status                       IN   VARCHAR2,
        p_sales_force_id               IN   NUMBER,
        p_return_status                OUT  VARCHAR2
    ) IS
        l_sf_cnt NUMBER;
    BEGIN
        l_sf_cnt := 0;
        IF ( p_sales_force_id IS NULL ) THEN
            p_return_status := 'Sales Force Id field cannot be blank';
        ELSE
--            BEGIN
--                SELECT
--                    COUNT(*)
--                INTO l_sf_cnt
--                FROM
--                    xxhbg_sales_force_assign_tbl a
--                WHERE
--                    a.sales_force = p_sales_force;
--
--            EXCEPTION
--                WHEN no_data_found THEN
--                    NULL;
--            END;

--            IF l_sf_cnt > 0 THEN
--                p_return_status := 'This Sales Force : '
--                                   || p_sales_force_name
--                                   || '  already exists.Please Select another Sales force';
--            ELSE
            INSERT INTO xxhbg_sales_force_assign_tbl (
                owner,
                owner_description,
                reporting_group,
                reporting_group_description,
                category_1,
                category_1_description,
                category_2,
                category_2_description,
                format,
                format_description,
                sub_format,
                sub_format_description,
                bisac,
                bisac_description,
                customer_org_number,
                organization_name,
                customer_account_number,
                account_name,
                account_type,
                bill_to_,
                state_province,
                bill_to_country,
                alt_sales_country,
                ship_to_number,
                ship_to_name,
                ship_to_state,
                ship_to_country,
                final_destination_country,
                sales_force,
                sales_force_name,
                division,
                division_name,
                territory,
                territory_name,
                sales_rep,
                sales_rep_name,
                override,
                account_override_start_date,
                account_override_end_date,
                notes,
                entered_by,
                entered_date,
                updated_by,
                updated_date,
                start_date,
                end_date,
                status,
                sales_force_id
            ) VALUES (
                p_owner,
                p_owner_description,
                p_reporting_group,
                p_reporting_group_description,
                p_category_1,
                p_category_1_description,
                p_category_2,
                p_category_2_description,
                p_format,
                p_format_description,
                p_sub_format,
                p_sub_format_description,
                p_bisac,
                p_bisac_description,
                p_customer_org_number,
                p_organization_name,
                p_customer_account_number,
                p_account_name,
                p_account_type,
                p_bill_to_,
                p_state_province,
                p_bill_to_country,
                p_alt_sales_country,
                p_ship_to_number,
                p_ship_to_name,
                p_ship_to_state,
                p_ship_to_country,
                p_final_destination_country,
                p_sales_force,
                p_sales_force_name,
                p_division,
                p_division_name,
                p_territory,
                p_territory_name,
                p_sales_rep,
                p_sales_rep_name,
                p_override,
                to_date(p_account_override_start_date, 'YYYY-MM-DD'),
                to_date(p_account_override_end_date, 'YYYY-MM-DD'),
                p_notes,
                p_entered_by,
                sysdate,
                p_updated_by,
                sysdate,
                to_date(p_start_date, 'YYYY-MM-DD'),
                to_date(p_end_date, 'YYYY-MM-DD'),
                p_status,
                p_sales_force_id
            );

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;

       --- END IF;

    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unhandled exception while assign sales force' || sqlerrm;
    END;

    PROCEDURE hbg_sales_force_assign_update (
        p_sf_assign_id                 IN   NUMBER,
        p_owner                        IN   VARCHAR2,
        p_owner_description            IN   VARCHAR2,
        p_reporting_group              IN   VARCHAR2,
        p_reporting_group_description  IN   VARCHAR2,
        p_category_1                   IN   VARCHAR2,
        p_category_1_description       IN   VARCHAR2,
        p_category_2                   IN   VARCHAR2,
        p_category_2_description       IN   VARCHAR2,
        p_format                       IN   VARCHAR2,
        p_format_description           IN   VARCHAR2,
        p_sub_format                   IN   VARCHAR2,
        p_sub_format_description       IN   VARCHAR2,
        p_bisac                        IN   VARCHAR2,
        p_bisac_description            IN   VARCHAR2,
        p_customer_org_number          IN   NUMBER,
        p_organization_name            IN   VARCHAR2,
        p_customer_account_number      IN   VARCHAR2,
        p_account_name                 IN   VARCHAR2,
        p_account_type                 IN   VARCHAR2,
        p_bill_to_                     IN   VARCHAR2,
        p_state_province               IN   VARCHAR2,
        p_bill_to_country              IN   VARCHAR2,
        p_alt_sales_country            IN   VARCHAR2,
        p_ship_to_number               IN   VARCHAR2,
        p_ship_to_name                 IN   VARCHAR2,
        p_ship_to_state                IN   VARCHAR2,
        p_ship_to_country              IN   VARCHAR2,
        p_final_destination_country    IN   VARCHAR2,
        p_sales_force                  IN   VARCHAR2,
        p_sales_force_name             IN   VARCHAR2,
        p_division                     IN   VARCHAR2,
        p_division_name                IN   VARCHAR2,
        p_territory                    IN   VARCHAR2,
        p_territory_name               IN   VARCHAR2,
        p_sales_rep                    IN   VARCHAR2,
        p_sales_rep_name               IN   VARCHAR2,
        p_override                     IN   VARCHAR2,
        p_account_override_start_date  IN   VARCHAR2,
        p_account_override_end_date    IN   VARCHAR2,
        p_notes                        IN   VARCHAR2,
        p_entered_by                   IN   VARCHAR2,
        p_updated_by                   IN   VARCHAR2,
        p_start_date                   IN   VARCHAR2,
        p_end_date                     IN   VARCHAR2,
        p_status                       IN   VARCHAR2,
        p_sales_force_id               IN   NUMBER,
        p_return_status                OUT  VARCHAR2
    ) AS
    BEGIN
        IF p_sf_assign_id IS NOT NULL THEN
            UPDATE xxhbg_sales_force_assign_tbl
            SET
                sf_assign_id = p_sf_assign_id,
                owner = p_owner,
                owner_description = p_owner_description,
                reporting_group = p_reporting_group,
                reporting_group_description = p_reporting_group_description,
                category_1 = p_category_1,
                category_1_description = p_category_1_description,
                category_2 = p_category_2,
                category_2_description = p_category_2_description,
                format = p_format,
                format_description = p_format_description,
                sub_format = p_sub_format,
                sub_format_description = p_sub_format_description,
                bisac = p_bisac,
                bisac_description = p_bisac_description,
                customer_org_number = p_customer_org_number,
                organization_name = p_organization_name,
                customer_account_number = p_customer_account_number,
                account_name = p_account_name,
                account_type = p_account_type,
                bill_to_ = p_bill_to_,
                state_province = p_state_province,
                bill_to_country = p_bill_to_country,
                alt_sales_country = p_alt_sales_country,
                ship_to_number = p_ship_to_number,
                ship_to_name = p_ship_to_name,
                ship_to_state = p_ship_to_state,
                ship_to_country = p_ship_to_country,
                final_destination_country = p_final_destination_country,
                sales_force = p_sales_force,
                sales_force_name = p_sales_force_name,
                division = p_division,
                division_name = p_division_name,
                territory = p_territory,
                territory_name = p_territory_name,
                sales_rep = p_sales_rep,
                sales_rep_name = p_sales_rep_name,
                override = p_override,
                account_override_start_date = to_date(p_account_override_start_date, 'YYYY-MM-DD'),
                account_override_end_date = to_date(p_account_override_end_date, 'YYYY-MM-DD'),
                notes = p_notes,
                entered_by = p_entered_by,
                entered_date = sysdate,
                updated_by = p_updated_by,
                updated_date = sysdate,
                start_date = to_date(p_start_date, 'YYYY-MM-DD'),
                end_date = to_date(p_end_date, 'YYYY-MM-DD'),
                status = p_status,
                sales_force_id = p_sales_force_id
            WHERE
                sf_assign_id = p_sf_assign_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Division :' || sqlerrm;
    END;

    PROCEDURE assign_account_type_to_sales_force_create (
        p_sales_force        IN   VARCHAR2,
        p_sales_force_name   IN   VARCHAR2,
        p_sf_owner           IN   VARCHAR2,
        p_owner_name         IN   VARCHAR2,
        p_account_type       IN   VARCHAR2,
        p_account_type_name  IN   VARCHAR2,
        p_notes              IN   VARCHAR2,
        p_entered_by         IN   VARCHAR2,
        p_updated_by         IN   VARCHAR2,
        p_start_date         IN   VARCHAR2,
        p_end_date           IN   VARCHAR2,
        p_status             IN   VARCHAR2,
        p_return_status      OUT  VARCHAR2
    ) IS
    BEGIN
        IF ( p_sf_owner IS NULL OR p_sales_force_name IS NULL ) THEN
            p_return_status := 'Owner or Sales force number field cannot be blank';
        ELSE
            INSERT INTO xxhbg_assign_account_type_to_sales_force_tbl (
                sales_force,
                sales_force_name,
                sf_owner,
                owner_name,
                account_type,
                account_type_name,
                notes,
                entered_by,
                entered_date,
                updated_by,
                updated_date,
                start_date,
                end_date,
                status
            ) VALUES (
                p_sales_force,
                p_sales_force_name,
                p_sf_owner,
                p_owner_name,
                p_account_type,
                p_account_type_name,
                p_notes,
                p_entered_by,
                sysdate,
                p_updated_by,
                sysdate,
                to_date(p_start_date, 'YYYY-MM-DD'),
                to_date(p_end_date, 'YYYY-MM-DD'),
                p_status
            );

            p_return_status := 'SUCCESS';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating Assign Account Type :' || sqlerrm;
    END;

    PROCEDURE assign_account_type_to_sales_force_update (
        p_sf_account_id      IN   NUMBER,
        p_sales_force        IN   VARCHAR2,
        p_sales_force_name   IN   VARCHAR2,
        p_sf_owner           IN   VARCHAR2,
        p_owner_name         IN   VARCHAR2,
        p_account_type       IN   VARCHAR2,
        p_account_type_name  IN   VARCHAR2,
        p_notes              IN   VARCHAR2,
        p_entered_by         IN   VARCHAR2,
        p_updated_by         IN   VARCHAR2,
        p_start_date         IN   VARCHAR2,
        p_end_date           IN   VARCHAR2,
        p_status             IN   VARCHAR2,
        p_return_status      OUT  VARCHAR2
    ) AS
    BEGIN
        IF p_sf_account_id IS NOT NULL THEN
            UPDATE xxhbg_assign_account_type_to_sales_force_tbl
            SET
                sales_force = p_sales_force,
                sales_force_name = p_sales_force_name,
                sf_owner = p_sf_owner,
                owner_name = p_owner_name,
                account_type = p_account_type,
                account_type_name = p_account_type_name,
                notes = p_notes,
                entered_by = p_entered_by,
                entered_date = sysdate,
                updated_by = p_updated_by,
                updated_date = sysdate,
                start_date = to_date(p_start_date, 'YYYY-MM-DD'),
                end_date = to_date(p_end_date, 'YYYY-MM-DD'),
                status = p_status
            WHERE
                sf_account_id = p_sf_account_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Assign Account Type :' || sqlerrm;
    END;

    PROCEDURE default_distribution_channel_create (
        p_organization_number        IN   NUMBER,
        p_organization_name          IN   VARCHAR2,
        p_account_number             IN   VARCHAR2,
        p_account_name               IN   VARCHAR2,
        p_account_type               IN   VARCHAR2,
        p_description                IN   VARCHAR2,
        p_bill_to_country            IN   VARCHAR2,
        p_bill_to_state              IN   VARCHAR2,
        p_ship_to_country            IN   VARCHAR2,
        p_ship_to_state              IN   VARCHAR2,
        p_final_destination_country  IN   VARCHAR2,
        p_sales_force                IN   VARCHAR2,
        p_sales_force_name           IN   VARCHAR2,
        p_division                   IN   VARCHAR2,
        p_division_name              IN   VARCHAR2,
        p_territory                  IN   VARCHAR2,
        p_territory_name             IN   VARCHAR2,
        p_sales_rep                  IN   VARCHAR2,
        p_sales_rep_name             IN   VARCHAR2,
        p_distribution_channel       IN   VARCHAR2,
        p_notes                      IN   VARCHAR2,
        p_entered_by                 IN   VARCHAR2,
        p_updated_by                 IN   VARCHAR2,
        p_start_date                 IN   VARCHAR2,
        p_end_date                   IN   VARCHAR2,
        p_status                     IN   VARCHAR2,
        p_return_status              OUT  VARCHAR2
    ) IS
    BEGIN
        IF ( p_sales_force IS NULL OR p_distribution_channel IS NULL ) THEN
            p_return_status := ' Sales force and Distribution Channel fields cannot be blank';
        ELSE
            INSERT INTO xxhbg_default_distribution_channel_tbl (
                organization_number,
                organization_name,
                account_number,
                account_name,
                account_type,
                description,
                bill_to_country,
                bill_to_state,
                ship_to_country,
                ship_to_state,
                final_destination_country,
                sales_force,
                sales_force_name,
                division,
                division_name,
                territory,
                territory_name,
                sales_rep,
                sales_rep_name,
                distribution_channel,
                notes,
                entered_by,
                entered_date,
                updated_by,
                updated_date,
                start_date,
                end_date,
                status
            ) VALUES (
                p_organization_number,            
                p_organization_name,
                p_account_number,
                p_account_name,
                p_account_type,
                p_description,
                p_bill_to_country,
                p_bill_to_state,
                p_ship_to_country,
                p_ship_to_state,
                p_final_destination_country,
                p_sales_force,
                p_sales_force_name,
                p_division,
                p_division_name,
                p_territory,
                p_territory_name,
                p_sales_rep,
                p_sales_rep_name,
                p_distribution_channel,
                p_notes,
                p_entered_by,
                sysdate,
                p_updated_by,
                sysdate,
                to_date(p_start_date, 'YYYY-MM-DD'),
                to_date(p_end_date, 'YYYY-MM-DD'),
                p_status
            );

            p_return_status := 'SUCCESS';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating default distribution chanal :' || sqlerrm;
    END;

    PROCEDURE default_distribution_channel_update (
        p_df_distribution_id         IN   NUMBER,
         p_organization_number        IN   NUMBER,
        p_organization_name          IN   VARCHAR2,
        p_account_number             IN   VARCHAR2,
        p_account_name               IN   VARCHAR2,
        p_account_type               IN   VARCHAR2,
        p_description                IN   VARCHAR2,
        p_bill_to_country            IN   VARCHAR2,
        p_bill_to_state              IN   VARCHAR2,
        p_ship_to_country            IN   VARCHAR2,
        p_ship_to_state              IN   VARCHAR2,
        p_final_destination_country  IN   VARCHAR2,
        p_sales_force                IN   VARCHAR2,
        p_sales_force_name           IN   VARCHAR2,
        p_division                   IN   VARCHAR2,
        p_division_name              IN   VARCHAR2,
        p_territory                  IN   VARCHAR2,
        p_territory_name             IN   VARCHAR2,
        p_sales_rep                  IN   VARCHAR2,
        p_sales_rep_name             IN   VARCHAR2,
        p_distribution_channel       IN   VARCHAR2,
        p_notes                      IN   VARCHAR2,
        p_entered_by                 IN   VARCHAR2,
        p_updated_by                 IN   VARCHAR2,
        p_start_date                 IN   VARCHAR2,
        p_end_date                   IN   VARCHAR2,
        p_status                     IN   VARCHAR2,
        p_return_status              OUT  VARCHAR2
    ) AS
    BEGIN
        IF p_df_distribution_id IS NOT NULL THEN
            UPDATE xxhbg_default_distribution_channel_tbl
            SET
                organization_number = p_organization_number,                     
                organization_name = p_organization_name,
                account_number = p_account_number,
                account_name = p_account_name,
                account_type = p_account_type,
                description = p_description,
                bill_to_country = p_bill_to_country,
                bill_to_state = p_bill_to_state,
                ship_to_country = p_ship_to_country,
                ship_to_state = p_ship_to_state,
                final_destination_country = p_final_destination_country,
                sales_force = p_sales_force,
                sales_force_name = p_sales_force_name,
                division = p_division,
                division_name = p_division_name,
                territory = p_territory,
                territory_name = p_territory_name,
                sales_rep = p_sales_rep,
                sales_rep_name = p_sales_rep_name,
                distribution_channel = p_distribution_channel,
                notes = p_notes,
                entered_by = p_entered_by,
                entered_date = sysdate,
                updated_by = p_updated_by,
                updated_date = sysdate,
                start_date = to_date(p_start_date, 'YYYY-MM-DD'),
                end_date = to_date(p_end_date, 'YYYY-MM-DD'),
                status = p_status
            WHERE
                df_distribution_id = p_df_distribution_id;

            p_return_status := 'SUCCESS';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating default distribution chanal :' || sqlerrm;
    END;

    PROCEDURE unassigned_sales_force_create (
        p_type                         IN   VARCHAR2,
        p_organization_number        IN   NUMBER,
        p_organization_name          IN   VARCHAR2,
        p_account_number               IN   VARCHAR2,
        p_account_name                 IN   VARCHAR2,
        p_account_type                 IN   VARCHAR2,
        p_description                  IN   VARCHAR2,
        p_account_prefix               IN   VARCHAR2,
        p_owner                        IN   VARCHAR2,
        p_owner_description            IN   VARCHAR2,
        p_reporting_group              IN   VARCHAR2,
        p_reporting_group_description  IN   VARCHAR2,
        p_bill_to_country              IN   VARCHAR2,
        p_bill_to_state                IN   VARCHAR2,
        p_ship_to_country              IN   VARCHAR2,
        p_ship_to_state                IN   VARCHAR2,
        p_final_destination_country    IN   VARCHAR2,
        p_sales_force_number           IN   VARCHAR2,
        p_sales_force_name             IN   VARCHAR2,
        p_division                     IN   VARCHAR2,
        p_division_name                IN   VARCHAR2,
        p_territory                    IN   VARCHAR2,
        p_territory_name               IN   VARCHAR2,
        p_sales_rep                    IN   VARCHAR2,
        p_sales_rep_name               IN   VARCHAR2,
        p_notes                        IN   VARCHAR2,
        p_entered_by                   IN   VARCHAR2,
        p_updated_by                   IN   VARCHAR2,
        p_updated_date                 IN   DATE,
        p_start_date                   IN   VARCHAR2,
        p_end_date                     IN   VARCHAR2,
        p_status                       IN   VARCHAR2,
        p_sf_assign_id                 IN   NUMBER,
        p_sales_force_id               IN   NUMBER,
        p_return_status                OUT  VARCHAR2
    ) IS
    BEGIN
        IF ( p_type IS NULL OR p_sales_force_number IS NULL OR p_division IS NULL OR p_territory IS NULL ) THEN
            p_return_status := ' Type,Sales force,Division,Territory fields cannot be blank';
        ELSE
            INSERT INTO xxhbg_unassigned_sales_force_tbl (
                type,
                organization_number,
                organization_name,
                account_number,
                account_name,
                account_type,
                description,
                account_prefix,
                owner,
                owner_description,
                reporting_group,
                reporting_group_description,
                bill_to_country,
                bill_to_state,
                ship_to_country,
                ship_to_state,
                final_destination_country,
                sales_force_number,
                sales_force_name,
                division,
                division_name,
                territory,
                territory_name,
                sales_rep,
                sales_rep_name,
                notes,
                entered_by,
                entered_date,
                updated_by,
                updated_date,
                start_date,
                end_date,
                status,
                sf_assign_id,
                sales_force_id
            ) VALUES (
                p_type,
                p_organization_number,
                p_organization_name,
                p_account_number,
                p_account_name,
                p_account_type,
                p_description,
                p_account_prefix,
                p_owner,
                p_owner_description,
                p_reporting_group,
                p_reporting_group_description,
                p_bill_to_country,
                p_bill_to_state,
                p_ship_to_country,
                p_ship_to_state,
                p_final_destination_country,
                p_sales_force_number,
                p_sales_force_name,
                p_division,
                p_division_name,
                p_territory,
                p_territory_name,
                p_sales_rep,
                p_sales_rep_name,
                p_notes,
                p_entered_by,
                sysdate,
                p_updated_by,
                p_updated_date,
                to_date(p_start_date, 'YYYY-MM-DD'),
                to_date(p_end_date, 'YYYY-MM-DD'),
                p_status,
                p_sf_assign_id,
                p_sales_force_id
            );

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while Unassigned Sales Force Update:' || sqlerrm;
    END;

    PROCEDURE unassigned_sales_force_update (
        p_sf_unassigned_id             IN   NUMBER,
        p_type                         IN   VARCHAR2,
        p_organization_number          IN   NUMBER,
        p_organization_name            IN   VARCHAR2,
        p_account_number               IN   VARCHAR2,
        p_account_name                 IN   VARCHAR2,
        p_account_type                 IN   VARCHAR2,
        p_description                  IN   VARCHAR2,
        p_account_prefix               IN   VARCHAR2,
        p_owner                        IN   VARCHAR2,
        p_owner_description            IN   VARCHAR2,
        p_reporting_group              IN   VARCHAR2,
        p_reporting_group_description  IN   VARCHAR2,
        p_bill_to_country              IN   VARCHAR2,
        p_bill_to_state                IN   VARCHAR2,
        p_ship_to_country              IN   VARCHAR2,
        p_ship_to_state                IN   VARCHAR2,
        p_final_destination_country    IN   VARCHAR2,
        p_sales_force_number           IN   VARCHAR2,
        p_sales_force_name             IN   VARCHAR2,
        p_division                     IN   VARCHAR2,
        p_division_name                IN   VARCHAR2,
        p_territory                    IN   VARCHAR2,
        p_territory_name               IN   VARCHAR2,
        p_sales_rep                    IN   VARCHAR2,
        p_sales_rep_name               IN   VARCHAR2,
        p_notes                        IN   VARCHAR2,
        p_entered_by                   IN   VARCHAR2,
        p_updated_by                   IN   VARCHAR2,
        p_updated_date                 IN   DATE,
        p_start_date                   IN   VARCHAR2,
        p_end_date                     IN   VARCHAR2,
        p_status                       IN   VARCHAR2,
        p_sf_assign_id                 IN   NUMBER,
        p_sales_force_id               IN   NUMBER,
        p_return_status                OUT  VARCHAR2
    ) AS
    BEGIN
        IF p_sf_unassigned_id IS NOT NULL THEN
            UPDATE xxhbg_unassigned_sales_force_tbl
            SET
                type = p_type,
                organization_number = p_organization_number,
                organization_name = p_organization_name,
                account_number = p_account_number,
                account_name = p_account_name,
                account_type = p_account_type,
                description = p_description,
                account_prefix = p_account_prefix,
                owner = p_owner,
                owner_description = p_owner_description,
                reporting_group = p_reporting_group,
                reporting_group_description = p_reporting_group_description,
                bill_to_country = p_bill_to_country,
                bill_to_state = p_bill_to_state,
                ship_to_country = p_ship_to_country,
                ship_to_state = p_ship_to_state,
                final_destination_country = p_final_destination_country,
                sales_force_number = p_sales_force_number,
                sales_force_name = p_sales_force_name,
                division = p_division,
                division_name = p_division_name,
                territory = p_territory,
                territory_name = p_territory_name,
                sales_rep = p_sales_rep,
                sales_rep_name = p_sales_rep_name,
                notes = p_notes,
                entered_by = p_entered_by,
                updated_by = p_updated_by,
                updated_date = sysdate,
                start_date = to_date(p_start_date, 'YYYY-MM-DD'),
                end_date = to_date(p_end_date, 'YYYY-MM-DD'),
                status = p_status,
                sf_assign_id = p_sf_assign_id,
                sales_force_id = p_sales_force_id
            WHERE
                sf_unassigned_id = p_sf_unassigned_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Division :' || sqlerrm;
    END;

    PROCEDURE distribution_maintenance_create (
        p_owner                        IN   VARCHAR2,
        p_owner_description            IN   VARCHAR2,
        p_reporting_group              IN   VARCHAR2,
        p_creation_date                IN   DATE,
        p_created_by                   IN   VARCHAR2,
        p_last_updated_by              IN   VARCHAR2,
        p_last_update_date             IN   DATE,
        p_start_date                   IN   VARCHAR2,
        p_end_date                     IN   VARCHAR2,
        p_dist_channel_id              IN   NUMBER,
        p_reporting_group_description  IN   VARCHAR2,
        p_return_status                OUT  VARCHAR2
    ) IS
        l_dc_cnt NUMBER := 0;
    BEGIN
        IF ( p_owner IS NULL ) THEN
            p_return_status := ' Owner field cannot be blank';
        ELSE
            BEGIN
                SELECT
                    COUNT(*)
                INTO l_dc_cnt
                FROM
                    hbg_distribution_maintenance_tbl
                WHERE
                        upper(owner) = upper(p_owner)
                    AND upper(reporting_group) = upper(p_reporting_group)
                    AND dist_channel_id = p_dist_channel_id;

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

            IF l_dc_cnt > 0 THEN
                p_return_status := ' The owner '
                                   || p_owner
                                   || ' and reporting group'
                                   || p_reporting_group
                                   || '  combination                                   
                                    already exists please choose different combination ';
            ELSE
                INSERT INTO hbg_distribution_maintenance_tbl (
                    owner,
                    owner_description,
                    reporting_group,
                    creation_date,
                    created_by,
                    last_updated_by,
                    last_update_date,
                    start_date,
                    end_date,
                    dist_channel_id,
                    reporting_group_description
                ) VALUES (
                    p_owner,
                    p_owner_description,
                    p_reporting_group,
                    sysdate,
                    p_created_by,
                    p_last_updated_by,
                    sysdate,
                    to_date(p_start_date, 'YYYY-MM-DD'),
                    to_date(p_end_date, 'YYYY-MM-DD'),
                    p_dist_channel_id,
                    p_reporting_group_description
                );

                COMMIT;
                p_return_status := 'SUCCESS';
            END IF;

        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating distribution maintenance:' || sqlerrm;
    END;

    PROCEDURE distribution_maintenance_update (
        p_dist_mainten_stg_id          IN   NUMBER,
        p_owner                        IN   VARCHAR2,
        p_owner_description            IN   VARCHAR2,
        p_reporting_group              IN   VARCHAR2,
        p_creation_date                IN   DATE,
        p_created_by                   IN   VARCHAR2,
        p_last_updated_by              IN   VARCHAR2,
        p_last_update_date             IN   DATE,
        p_start_date                   IN   VARCHAR2,
        p_end_date                     IN   VARCHAR2,
        p_dist_channel_id              IN   NUMBER,
        p_reporting_group_description  IN   VARCHAR2,
        p_return_status                OUT  VARCHAR2
    ) AS
    BEGIN
        IF p_dist_mainten_stg_id IS NOT NULL THEN
            UPDATE hbg_distribution_maintenance_tbl
            SET
                dist_mainten_stg_id = p_dist_mainten_stg_id,
                owner = p_owner,
                owner_description = p_owner_description,
                reporting_group = p_reporting_group,
                creation_date = sysdate,
                created_by = p_created_by,
                last_updated_by = p_last_updated_by,
                last_update_date = sysdate,
                start_date = to_date(p_start_date, 'YYYY-MM-DD'),
                end_date = to_date(p_end_date, 'YYYY-MM-DD'),
                dist_channel_id = p_dist_channel_id,
                reporting_group_description = p_reporting_group_description
            WHERE
                dist_mainten_stg_id = p_dist_mainten_stg_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating division maintenance :' || sqlerrm;
    END;

    PROCEDURE sales_force_validation (
        p_source_line_id             IN   VARCHAR2,
        p_batch_id                   IN   VARCHAR2,
        return_status                OUT  VARCHAR2,
        p_so_mapping_val_type_array  OUT  hbg_so_mapping_val_type_array
    ) IS

        CURSOR c_get_override IS
        SELECT
            *
        FROM
            (
                SELECT
                    a.*,
                    DENSE_RANK()
                    OVER(PARTITION BY a.source_order_id, a.source_line_id
                         ORDER BY a.precedence_level
                    ) rank
                FROM
                    (
                        SELECT
                            dha.source_order_id,
                            dha.source_order_system,
                            dha.source_order_system
                            || ':'
                            || dha.source_order_id source_key,
                            dla.source_line_id,
                            dha.order_number,
                            hsfmt.sf_assign_id,
                            hsfmt.sales_force,
                            hsfmt.division,
                            hsfmt.territory,
                            hsfmt.sales_rep,
                            xsfplt.precedence_level,
                            dfla.fulfill_line_id
                        FROM
                            doo_headers_all                 dha,
                            doo_lines_all                   dla,
                            doo_fulfill_lines_all           dfla,
                            doo_headers_eff_b               dheb,
                            egp_system_items_b              esib,
                            ego_item_eff_b                  eieb,
                            ego_item_eff_b                  eieb_bisac,
                            inv_org_parameters              iop,
                            inv_org_parameters              iop_bisac,
                            xxhbg_sales_force_assign_tbl    hsfmt,
                            fnd_common_lookups              fcl_reportinggroup,
                            fnd_common_lookups              fcl_category1,
                            fnd_common_lookups              fcl_category2,
                            xxhbg_sales_force_prec_lev_tbl  xsfplt,
                            doo_fulfill_lines_eff_b         dfleb,
                            doo_fulfill_lines_eff_b         dfleb_sfcode,
                            hz_cust_accounts                hca,
                            hz_party_sites                  hps
                        WHERE
                                1 = 1
                            AND dla.source_line_id = nvl(p_source_line_id, dla.source_line_id)
                            AND dha.last_update_date >= sysdate -2
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
                            AND not exists
                            (select 1 from doo_fulfill_lines_all where header_id = dha.header_id
                            and status_code = 'CANCEL_PENDING')
                            AND dfla.bill_to_customer_id = hca.cust_account_id
                            AND dfla.ship_to_party_site_id = hps.party_site_id
                            AND p_batch_id IS NULL
                            AND dha.header_id = dheb.header_id (+)
                            AND dheb.context_code (+) = 'General'
                            AND nvl(dheb.attribute_char1, hca.account_number) = hsfmt.CUSTOMER_ACCOUNT_NUMBER
                            AND nvl(hps.party_site_number, '#NULL') = nvl(hsfmt.ship_to_number, nvl(hps.party_site_number, '#NULL'))
                            AND dla.inventory_item_id = esib.inventory_item_id
                            AND dla.inventory_organization_id = esib.organization_id
                            AND esib.inventory_item_id = eieb.inventory_item_id (+)
                            AND eieb.organization_id = iop.organization_id (+)
                            AND iop.organization_code (+) = 'ITEM_MASTER'
                            AND eieb.context_code (+) = 'Family Code'
                            AND esib.inventory_item_id = eieb_bisac.inventory_item_id (+)
                            AND eieb_bisac.organization_id = iop_bisac.organization_id (+)
                            AND iop_bisac.organization_code (+) = 'ITEM_MASTER'
                            AND eieb_bisac.context_code (+) = 'General BISAC'
                            AND hsfmt.reporting_group = fcl_reportinggroup.lookup_code (+)
                            AND fcl_reportinggroup.lookup_type (+) = 'HBG_REPORTING_GROUP'
                            AND hsfmt.category_1 = fcl_category1.lookup_code (+)
                            AND fcl_category1.lookup_type (+) = 'HBG_CATEGORY_1'
                            AND hsfmt.category_2 = fcl_category2.lookup_code (+)
                            AND fcl_category2.lookup_type (+) = 'HBG_CATEGORY_2'
                            AND hsfmt.override = 'Yes'
                            AND nvl(eieb.attribute_char1, '#NULL') = nvl(nvl(hsfmt.owner, eieb.attribute_char1), '#NULL')
                            AND nvl(eieb.attribute_char2, '#NULL') = nvl(nvl(fcl_reportinggroup.description, eieb.attribute_char2),
                            '#NULL')
                            AND nvl(eieb.attribute_char3, '#NULL') = nvl(nvl(fcl_category1.description, eieb.attribute_char3), '#NULL')
                            AND nvl(eieb.attribute_char4, '#NULL') = nvl(nvl(fcl_category2.description, eieb.attribute_char4), '#NULL')
                            AND nvl(eieb.attribute_char7, '#NULL') = nvl(nvl(hsfmt.format, eieb.attribute_char7), '#NULL')
                            AND nvl(eieb.attribute_char8, '#NULL') = nvl(nvl(hsfmt.sub_format, eieb.attribute_char8), '#NULL')
                            AND nvl(eieb_bisac.attribute_char1, '#NULL') = nvl(nvl(hsfmt.bisac, eieb_bisac.attribute_char1), '#NULL')
                            AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
                            AND dfleb.context_code (+) = 'Pricing'
                            AND nvl(dfleb.attribute_char1, '#NULL') = nvl(nvl(hsfmt.account_type, dfleb.attribute_char1), '#NULL')
                            AND dfla.fulfill_line_id = dfleb_sfcode.fulfill_line_id (+)
                            AND dfleb_sfcode.context_code (+) = 'Sales Force Code'
                            AND nvl(dfleb_sfcode.attribute_char6, 'N') = 'N'
                            AND CASE
                                    WHEN hsfmt.owner IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.owner
                            AND CASE
                                    WHEN hsfmt.reporting_group IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.reporting_group
                            AND CASE
                                    WHEN hsfmt.category_1 IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.category_1
                            AND CASE
                                    WHEN hsfmt.category_2 IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.category_2
                            AND CASE
                                    WHEN hsfmt.format IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.format
                            AND CASE
                                    WHEN hsfmt.sub_format IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.sub_format
                            AND CASE
                                    WHEN hsfmt.bisac IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.bisac
                            AND CASE
                                    WHEN hsfmt.account_type IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.account_type
                    ) a
            )
        WHERE
            rank = 1
        UNION
        SELECT
            *
        FROM
            (
                SELECT
                    a.*,
                    DENSE_RANK()
                    OVER(PARTITION BY a.source_order_id, a.source_line_id
                         ORDER BY a.precedence_level
                    ) rank
                FROM
                    (
                        SELECT
                            dha.source_order_id,
                            dha.source_order_system,
                            dla.source_line_id,
                            dha.source_order_system
                            || ':'
                            || dha.source_order_id source_key,
                            dha.order_number,
                            hsfmt.sf_assign_id,
                            hsfmt.sales_force,
                            hsfmt.division,
                            hsfmt.territory,
                            hsfmt.sales_rep,
                            xsfplt.precedence_level,
                            dfla.fulfill_line_id
                        FROM
                            doo_headers_all                 dha,
                            doo_lines_all                   dla,
                            doo_fulfill_lines_all           dfla,
                            doo_headers_eff_b               dheb,
                            egp_system_items_b              esib,
                            ego_item_eff_b                  eieb,
                            ego_item_eff_b                  eieb_bisac,
                            inv_org_parameters              iop,
                            inv_org_parameters              iop_bisac,
                            xxhbg_sales_force_assign_tbl    hsfmt,
                            fnd_common_lookups              fcl_reportinggroup,
                            fnd_common_lookups              fcl_category1,
                            fnd_common_lookups              fcl_category2,
                            xxhbg_sales_force_prec_lev_tbl  xsfplt,
                            doo_fulfill_lines_eff_b         dfleb,
                            doo_fulfill_lines_eff_b         dfleb_sfcode,
                            doo_headers_eff_b               dheb_batch,
                            hz_cust_accounts                hca,
                            hz_party_sites                  hps
                        WHERE
                                1 = 1
                            AND dla.source_line_id = nvl(p_source_line_id, dla.source_line_id)
                            AND dha.last_update_date >= sysdate -2
                            AND dha.header_id = dla.header_id
                            AND dla.line_id = dfla.line_id
                            AND dha.status_code IN ( 'DOO_DRAFT' )
                            AND dfla.status_code IN ( 'CREATED', 'NOT_STARTED' )
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
                            AND not exists
                            (select 1 from doo_fulfill_lines_all where header_id = dha.header_id
                            and status_code = 'CANCEL_PENDING')
                            AND dfla.bill_to_customer_id = hca.cust_account_id
                            AND dfla.ship_to_party_site_id = hps.party_site_id
                            AND dha.header_id = dheb_batch.header_id (+)
                            AND dheb_batch.context_code (+) = 'EDI General'
                            AND dheb_batch.attribute_char18 = p_batch_id
                            AND dha.header_id = dheb.header_id (+)
                            AND dheb.context_code (+) = 'General'
                            AND nvl(dheb.attribute_char1, hca.account_number) = hsfmt.CUSTOMER_ACCOUNT_NUMBER
                            AND nvl(hps.party_site_number, '#NULL') = nvl(hsfmt.ship_to_number, nvl(hps.party_site_number, '#NULL'))
                            AND dla.inventory_item_id = esib.inventory_item_id
                            AND dla.inventory_organization_id = esib.organization_id
                            AND esib.inventory_item_id = eieb.inventory_item_id (+)
                            AND eieb.organization_id = iop.organization_id (+)
                            AND iop.organization_code (+) = 'ITEM_MASTER'
                            AND eieb.context_code (+) = 'Family Code'
                            AND esib.inventory_item_id = eieb_bisac.inventory_item_id (+)
                            AND eieb_bisac.organization_id = iop_bisac.organization_id (+)
                            AND iop_bisac.organization_code (+) = 'ITEM_MASTER'
                            AND eieb_bisac.context_code (+) = 'General BISAC'
                            AND hsfmt.reporting_group = fcl_reportinggroup.lookup_code (+)
                            AND fcl_reportinggroup.lookup_type (+) = 'HBG_REPORTING_GROUP'
                            AND hsfmt.category_1 = fcl_category1.lookup_code (+)
                            AND fcl_category1.lookup_type (+) = 'HBG_CATEGORY_1'
                            AND hsfmt.category_2 = fcl_category2.lookup_code (+)
                            AND fcl_category2.lookup_type (+) = 'HBG_CATEGORY_2'
                            AND hsfmt.override = 'Yes'
                            AND nvl(eieb.attribute_char1, '#NULL') = nvl(nvl(hsfmt.owner, eieb.attribute_char1), '#NULL')
                            AND nvl(eieb.attribute_char2, '#NULL') = nvl(nvl(fcl_reportinggroup.description, eieb.attribute_char2),
                            '#NULL')
                            AND nvl(eieb.attribute_char3, '#NULL') = nvl(nvl(fcl_category1.description, eieb.attribute_char3), '#NULL')
                            AND nvl(eieb.attribute_char4, '#NULL') = nvl(nvl(fcl_category2.description, eieb.attribute_char4), '#NULL')
                            AND nvl(eieb.attribute_char7, '#NULL') = nvl(nvl(hsfmt.format, eieb.attribute_char7), '#NULL')
                            AND nvl(eieb.attribute_char8, '#NULL') = nvl(nvl(hsfmt.sub_format, eieb.attribute_char8), '#NULL')
                            AND nvl(eieb_bisac.attribute_char1, '#NULL') = nvl(nvl(hsfmt.bisac, eieb_bisac.attribute_char1), '#NULL')
                            AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
                            AND dfleb.context_code (+) = 'Pricing'
                            AND nvl(dfleb.attribute_char1, '#NULL') = nvl(nvl(hsfmt.account_type, dfleb.attribute_char1), '#NULL')
                            AND dfla.fulfill_line_id = dfleb_sfcode.fulfill_line_id (+)
                            AND dfleb_sfcode.context_code (+) = 'Sales Force Code'
                            AND nvl(dfleb_sfcode.attribute_char6, 'N') = 'N'
                            AND CASE
                                    WHEN hsfmt.owner IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.owner
                            AND CASE
                                    WHEN hsfmt.reporting_group IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.reporting_group
                            AND CASE
                                    WHEN hsfmt.category_1 IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.category_1
                            AND CASE
                                    WHEN hsfmt.category_2 IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.category_2
                            AND CASE
                                    WHEN hsfmt.format IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.format
                            AND CASE
                                    WHEN hsfmt.sub_format IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.sub_format
                            AND CASE
                                    WHEN hsfmt.bisac IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.bisac
                            AND CASE
                                    WHEN hsfmt.account_type IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.account_type
                    ) a
            )
        WHERE
            rank = 1;

        CURSOR c_get_sf_mapping IS
        SELECT
            *
        FROM
            (
                SELECT
                    a.*,
                    DENSE_RANK()
                    OVER(PARTITION BY a.source_order_id, a.source_line_id
                         ORDER BY a.priority,
                                  a.precedence_level
                    ) rank
                FROM
                    (
                        SELECT
                            dha.source_order_id,
                            dha.source_order_system,
                            dla.source_line_id,
                            dha.source_order_system
                            || ':'
                            || dha.source_order_id source_key,
                            dha.order_number,
                            hsfmt.priority,
                            hsfmt.sales_force,
                            hsfat.division,
                            hsfat.territory,
                            hsfat.sales_rep,
                            xsfplt.precedence_level,
                            dfla.fulfill_line_id
                        FROM
                            doo_headers_all                 dha,
                            doo_lines_all                   dla,
                            doo_fulfill_lines_all           dfla,
                            doo_headers_eff_b               dheb,
                            egp_system_items_b              esib,
                            ego_item_eff_b                  eieb,
                            ego_item_eff_b                  eieb_bisac,
                            inv_org_parameters              iop,
                            inv_org_parameters              iop_bisac,
                            xxhbg_sales_force_mapping_tbl   hsfmt,
                            xxhbg_sales_force_assign_tbl    hsfat,
                            fnd_common_lookups              fcl_reportinggroup,
                            fnd_common_lookups              fcl_category1,
                            fnd_common_lookups              fcl_category2,
                            xxhbg_sales_force_prec_lev_tbl  xsfplt,
                            doo_fulfill_lines_eff_b         dfleb,
                            doo_fulfill_lines_eff_b         dfleb_sfcode,
                            hz_cust_accounts                hca,
                            hz_party_sites                  hps
                        WHERE
                                1 = 1
                            AND dla.source_line_id = nvl(p_source_line_id, dla.source_line_id)
                            AND dha.last_update_date >= sysdate -2
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
                            AND not exists
                            (select 1 from doo_fulfill_lines_all where header_id = dha.header_id
                            and status_code = 'CANCEL_PENDING')
                            AND dfla.bill_to_customer_id = hca.cust_account_id
                            AND dfla.ship_to_party_site_id = hps.party_site_id
                            AND dha.header_id = dheb.header_id (+)
                            AND dheb.context_code (+) = 'General'
                            AND p_batch_id IS NULL
                            AND nvl(dheb.attribute_char1, hca.account_number) = hsfat.CUSTOMER_ACCOUNT_NUMBER
                            AND nvl(hps.party_site_number, '#NULL') = nvl(hsfat.ship_to_number, nvl(hps.party_site_number, '#NULL'))
                            AND dla.inventory_item_id = esib.inventory_item_id
                            AND dla.inventory_organization_id = esib.organization_id
                            AND esib.inventory_item_id = eieb.inventory_item_id (+)
                            AND eieb.organization_id = iop.organization_id (+)
                            AND iop.organization_code (+) = 'ITEM_MASTER'
                            AND eieb.context_code (+) = 'Family Code'
                            AND esib.inventory_item_id = eieb_bisac.inventory_item_id (+)
                            AND eieb_bisac.organization_id = iop_bisac.organization_id (+)
                            AND iop_bisac.organization_code (+) = 'ITEM_MASTER'
                            AND eieb_bisac.context_code (+) = 'General BISAC'
                            AND hsfmt.reporting_group = fcl_reportinggroup.lookup_code (+)
                            AND fcl_reportinggroup.lookup_type (+) = 'HBG_REPORTING_GROUP'
                            AND hsfmt.category_1 = fcl_category1.lookup_code (+)
                            AND fcl_category1.lookup_type (+) = 'HBG_CATEGORY_1'
                            AND hsfmt.category_2 = fcl_category2.lookup_code (+)
                            AND fcl_category2.lookup_type (+) = 'HBG_CATEGORY_2'
--                    AND hsfmt.override = 'Yes'
                            AND nvl(eieb.attribute_char1, '#NULL') = nvl(nvl(hsfmt.owner, eieb.attribute_char1), '#NULL')
                            AND nvl(eieb.attribute_char2, '#NULL') = nvl(nvl(fcl_reportinggroup.description, eieb.attribute_char2),
                            '#NULL')
                            AND nvl(eieb.attribute_char3, '#NULL') = nvl(nvl(fcl_category1.description, eieb.attribute_char3), '#NULL')
                            AND nvl(eieb.attribute_char4, '#NULL') = nvl(nvl(fcl_category2.description, eieb.attribute_char4), '#NULL')
                            AND nvl(eieb.attribute_char7, '#NULL') = nvl(nvl(hsfmt.format, eieb.attribute_char7), '#NULL')
                            AND nvl(eieb.attribute_char8, '#NULL') = nvl(nvl(hsfmt.sub_format, eieb.attribute_char8), '#NULL')
                            AND nvl(eieb_bisac.attribute_char1, '#NULL') = nvl(nvl(hsfmt.bisac, eieb_bisac.attribute_char1), '#NULL')
                            AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
                            AND dfleb.context_code (+) = 'Pricing'
                            AND nvl(dfleb.attribute_char1, '#NULL') = nvl(nvl(hsfmt.account_type, dfleb.attribute_char1), '#NULL')
                            AND dfla.fulfill_line_id = dfleb_sfcode.fulfill_line_id (+)
                            AND dfleb_sfcode.context_code (+) = 'Sales Force Code'
                            AND nvl(dfleb_sfcode.attribute_char6, 'N') = 'N'
                            AND nvl(dla.sf_mapping, '#NULL') <> 'Override'
                            AND hsfmt.sales_force = hsfat.sales_force
                            AND CASE
                                    WHEN hsfmt.owner IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.owner
                            AND CASE
                                    WHEN hsfmt.reporting_group IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.reporting_group
                            AND CASE
                                    WHEN hsfmt.category_1 IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.category_1
                            AND CASE
                                    WHEN hsfmt.category_2 IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.category_2
                            AND CASE
                                    WHEN hsfmt.format IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.format
                            AND CASE
                                    WHEN hsfmt.sub_format IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.sub_format
                            AND CASE
                                    WHEN hsfmt.bisac IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.bisac
                            AND CASE
                                    WHEN hsfmt.account_type IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.account_type
                    ) a
            )
        WHERE
            rank = 1
        UNION
        SELECT
            *
        FROM
            (
                SELECT
                    a.*,
                    DENSE_RANK()
                    OVER(PARTITION BY a.source_order_id, a.source_line_id
                         ORDER BY a.priority,
                                  a.precedence_level
                    ) rank
                FROM
                    (
                        SELECT
                            dha.source_order_id,
                            dha.source_order_system,
                            dla.source_line_id,
                            dha.source_order_system
                            || ':'
                            || dha.source_order_id source_key,
                            dha.order_number,
                            hsfmt.priority,
                            hsfmt.sales_force,
                            hsfat.division,
                            hsfat.territory,
                            hsfat.sales_rep,
                            xsfplt.precedence_level,
                            dfla.fulfill_line_id
                        FROM
                            doo_headers_all                 dha,
                            doo_lines_all                   dla,
                            doo_fulfill_lines_all           dfla,
                            doo_headers_eff_b               dheb,
                            egp_system_items_b              esib,
                            ego_item_eff_b                  eieb,
                            ego_item_eff_b                  eieb_bisac,
                            inv_org_parameters              iop,
                            inv_org_parameters              iop_bisac,
                            xxhbg_sales_force_mapping_tbl   hsfmt,
                            xxhbg_sales_force_assign_tbl    hsfat,
                            fnd_common_lookups              fcl_reportinggroup,
                            fnd_common_lookups              fcl_category1,
                            fnd_common_lookups              fcl_category2,
                            xxhbg_sales_force_prec_lev_tbl  xsfplt,
                            doo_fulfill_lines_eff_b         dfleb,
                            doo_fulfill_lines_eff_b         dfleb_sfcode,
                            hz_cust_accounts                hca,
                            hz_party_sites                  hps,
                            doo_headers_eff_b               dheb_batch
                        WHERE
                                1 = 1
                            AND dla.source_line_id = nvl(p_source_line_id, dla.source_line_id)
                            AND dha.last_update_date >= sysdate -2
                            AND dha.header_id = dla.header_id
                            AND dla.line_id = dfla.line_id
                            AND dha.status_code IN ( 'DOO_DRAFT' )
                            AND dfla.status_code IN ( 'CREATED', 'NOT_STARTED' )
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
                            AND not exists
                            (select 1 from doo_fulfill_lines_all where header_id = dha.header_id
                            and status_code = 'CANCEL_PENDING')
                            AND dfla.bill_to_customer_id = hca.cust_account_id
                            AND dfla.ship_to_party_site_id = hps.party_site_id
                            AND dha.header_id = dheb.header_id (+)
                            AND dheb.context_code (+) = 'General'
                            AND dha.header_id = dheb_batch.header_id (+)
                            AND dheb_batch.context_code (+) = 'EDI General'
                            AND dheb_batch.attribute_char18 = p_batch_id
                            AND nvl(dheb.attribute_char1, hca.account_number) = hsfat.CUSTOMER_ACCOUNT_NUMBER
                            AND nvl(hps.party_site_number, '#NULL') = nvl(hsfat.ship_to_number, nvl(hps.party_site_number, '#NULL'))
                            AND dla.inventory_item_id = esib.inventory_item_id
                            AND dla.inventory_organization_id = esib.organization_id
                            AND esib.inventory_item_id = eieb.inventory_item_id (+)
                            AND eieb.organization_id = iop.organization_id (+)
                            AND iop.organization_code (+) = 'ITEM_MASTER'
                            AND eieb.context_code (+) = 'Family Code'
                            AND esib.inventory_item_id = eieb_bisac.inventory_item_id (+)
                            AND eieb_bisac.organization_id = iop_bisac.organization_id (+)
                            AND iop_bisac.organization_code (+) = 'ITEM_MASTER'
                            AND eieb_bisac.context_code (+) = 'General BISAC'
                            AND hsfmt.reporting_group = fcl_reportinggroup.lookup_code (+)
                            AND fcl_reportinggroup.lookup_type (+) = 'HBG_REPORTING_GROUP'
                            AND hsfmt.category_1 = fcl_category1.lookup_code (+)
                            AND fcl_category1.lookup_type (+) = 'HBG_CATEGORY_1'
                            AND hsfmt.category_2 = fcl_category2.lookup_code (+)
                            AND fcl_category2.lookup_type (+) = 'HBG_CATEGORY_2'
--                    AND hsfmt.override = 'Yes'
                            AND nvl(eieb.attribute_char1, '#NULL') = nvl(nvl(hsfmt.owner, eieb.attribute_char1), '#NULL')
                            AND nvl(eieb.attribute_char2, '#NULL') = nvl(nvl(fcl_reportinggroup.description, eieb.attribute_char2),
                            '#NULL')
                            AND nvl(eieb.attribute_char3, '#NULL') = nvl(nvl(fcl_category1.description, eieb.attribute_char3), '#NULL')
                            AND nvl(eieb.attribute_char4, '#NULL') = nvl(nvl(fcl_category2.description, eieb.attribute_char4), '#NULL')
                            AND nvl(eieb.attribute_char7, '#NULL') = nvl(nvl(hsfmt.format, eieb.attribute_char7), '#NULL')
                            AND nvl(eieb.attribute_char8, '#NULL') = nvl(nvl(hsfmt.sub_format, eieb.attribute_char8), '#NULL')
                            AND nvl(eieb_bisac.attribute_char1, '#NULL') = nvl(nvl(hsfmt.bisac, eieb_bisac.attribute_char1), '#NULL')
                            AND dfla.fulfill_line_id = dfleb.fulfill_line_id (+)
                            AND dfleb.context_code (+) = 'Pricing'
                            AND nvl(dfleb.attribute_char1, '#NULL') = nvl(nvl(hsfmt.account_type, dfleb.attribute_char1), '#NULL')
                            AND dfla.fulfill_line_id = dfleb_sfcode.fulfill_line_id (+)
                            AND dfleb_sfcode.context_code (+) = 'Sales Force Code'
                            AND nvl(dfleb_sfcode.attribute_char6, 'N') = 'N'
                            AND nvl(dla.sf_mapping, '#NULL') <> 'Override'
                            AND hsfmt.sales_force = hsfat.sales_force
                            AND CASE
                                    WHEN hsfmt.owner IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.owner
                            AND CASE
                                    WHEN hsfmt.reporting_group IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.reporting_group
                            AND CASE
                                    WHEN hsfmt.category_1 IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.category_1
                            AND CASE
                                    WHEN hsfmt.category_2 IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.category_2
                            AND CASE
                                    WHEN hsfmt.format IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.format
                            AND CASE
                                    WHEN hsfmt.sub_format IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.sub_format
                            AND CASE
                                    WHEN hsfmt.bisac IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.bisac
                            AND CASE
                                    WHEN hsfmt.account_type IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xsfplt.account_type
                    ) a
            )
        WHERE
            rank = 1;

        l_return_status            VARCHAR2(255);
        loop_index                 NUMBER := 1;
        v_hbg_so_mapping_val_type  hbg_so_mapping_val_type_array := hbg_so_mapping_val_type_array();
    BEGIN
        l_return_status := 'SUCCESS';
        FOR c_get_override_lines IN c_get_override LOOP
            v_hbg_so_mapping_val_type.extend;
            v_hbg_so_mapping_val_type(loop_index) := hbg_so_mapping_val_type(c_get_override_lines.source_order_system, c_get_override_lines.
            source_order_id,
                                                                            c_get_override_lines.source_line_id,
                                                                            c_get_override_lines.source_key,
                                                                            c_get_override_lines.sales_force,
                                                                            c_get_override_lines.division,
                                                                            c_get_override_lines.territory,
                                                                            c_get_override_lines.sales_rep,
                                                                            NULL,
                                                                            c_get_override_lines.order_number,
                                                                            c_get_override_lines.fulfill_line_id);

            loop_index := loop_index + 1;
            UPDATE doo_lines_all
            SET
                sf_mapping = 'Override'
            WHERE
                source_line_id = c_get_override_lines.source_line_id;

            COMMIT;
        END LOOP;

        FOR c_get_sf_mapping_lines IN c_get_sf_mapping LOOP
            v_hbg_so_mapping_val_type.extend;
            v_hbg_so_mapping_val_type(loop_index) := hbg_so_mapping_val_type(c_get_sf_mapping_lines.source_order_system, c_get_sf_mapping_lines.
            source_order_id,
                                                                            c_get_sf_mapping_lines.source_line_id,
                                                                            c_get_sf_mapping_lines.source_key,
                                                                            c_get_sf_mapping_lines.sales_force,
                                                                            c_get_sf_mapping_lines.division,
                                                                            c_get_sf_mapping_lines.territory,
                                                                            c_get_sf_mapping_lines.sales_rep,
                                                                            NULL,
                                                                            c_get_sf_mapping_lines.order_number,
                                                                            c_get_sf_mapping_lines.fulfill_line_id);

            loop_index := loop_index + 1;
        END LOOP;

        return_status := l_return_status;
        p_so_mapping_val_type_array := v_hbg_so_mapping_val_type;
    EXCEPTION
        WHEN OTHERS THEN
            l_return_status := 'FAILURE';
            return_status := l_return_status;
            p_so_mapping_val_type_array := v_hbg_so_mapping_val_type;
    END;

    PROCEDURE unassigndefault_sales_force_create (
        p_account_number IN VARCHAR2
    ) IS

        CURSOR c1 IS
        SELECT
            account_number,
            account_name
        FROM
            hz_cust_accounts hca
        WHERE
                1 = 1
            AND hca.account_number = nvl(p_account_number, hca.account_number)
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    xxhbg_sales_force_assign_tbl
                WHERE
                    customer_account_number = hca.account_number
            );

    BEGIN
        FOR c1_rec IN c1 LOOP
            INSERT INTO xxhbg_sales_force_assign_tbl (
                customer_org_number,
                account_type,
                owner,
                owner_description,
                reporting_group,
                reporting_group_description,
                bill_to_country,
                state_province,
                ship_to_country,
                ship_to_state,
                sales_force,
                sales_force_name,
                division,
                division_name,
                territory,
                territory_name,
                sales_rep,
                sales_rep_name,
                start_date,
                end_date,
                status,
                sales_force_id,
                customer_account_number,
                account_name,
                entered_by,
                entered_date,
                override
            )
                SELECT
                    organization_number,
                    account_type,
                    owner,
                    owner_description,
                    reporting_group,
                    reporting_group_description,
                    bill_to_country,
                    bill_to_state,
                    ship_to_country,
                    ship_to_state,
                    sales_force_number,
                    sales_force_name,
                    division,
                    division_name,
                    territory,
                    territory_name,
                    sales_rep,
                    sales_rep_name,
                    start_date,
                    end_date,
                    status,
                    sales_force_id,
                    account_number,
                    account_name,
                    entered_by,
                    entered_date,
                    CASE
                        WHEN owner IS NOT NULL
                             OR reporting_group IS NOT NULL THEN
                            'Yes'
                        ELSE
                            'No'
                    END
                FROM
                    xxhbg_unassigned_sales_force_tbl
                WHERE
                        1 = 1
                    AND account_number = c1_rec.account_number
                UNION
                SELECT
                    organization_number,
                    account_type,
                    owner,
                    owner_description,
                    reporting_group,
                    reporting_group_description,
                    bill_to_country,
                    bill_to_state,
                    ship_to_country,
                    ship_to_state,
                    sales_force_number,
                    sales_force_name,
                    division,
                    division_name,
                    territory,
                    territory_name,
                    sales_rep,
                    sales_rep_name,
                    start_date,
                    end_date,
                    status,
                    sales_force_id,
                    c1_rec.account_number,
                    c1_rec.account_name,
                    entered_by,
                    entered_date,
                    CASE
                        WHEN owner IS NOT NULL
                             OR reporting_group IS NOT NULL THEN
                            'Yes'
                        ELSE
                            'No'
                    END
                FROM
                    xxhbg_unassigned_sales_force_tbl
                WHERE
                        1 = 1
                    AND upper(type) = 'DEFAULT'
                    AND NOT EXISTS (
                        SELECT
                            1
                        FROM
                            xxhbg_unassigned_sales_force_tbl
                        WHERE
                            account_number = c1_rec.account_number
                    );

        END LOOP;
    END unassigndefault_sales_force_create;

    PROCEDURE assigndefault_dist_channel_create (
        p_account_number  IN   VARCHAR2,
        p_status          OUT  VARCHAR2
    ) IS

        CURSOR c1 IS
        SELECT
            account_number,
            account_name,
            (
                SELECT
                    party_number
                FROM
                    hz_parties
                WHERE
                    party_id = hca.party_id
            ) org_num
        FROM
            hz_cust_accounts hca
        WHERE
                1 = 1
            AND hca.account_number = nvl(p_account_number, hca.account_number)
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    xxhbg_assign_distrubution_channel_tbl
                WHERE
                    account_number = hca.account_number
            );

    BEGIN
        FOR c1_rec IN c1 LOOP
            INSERT INTO xxhbg_assign_distrubution_channel_tbl (
                account_number,
                account_name,
                sales_force_number,
                sales_force_name,
                owner,
                reporting_group,
                category_1,
                category_2,
                bisac,
                bisac_description,
                distribution_channel,
                dist_channel_description,
                notes,
                entered_by,
                entered_date,
                updated_by,
                updated_date,
                start_date,
                end_date
                --,dist_channel_id
            )
                SELECT
                    c1_rec.account_number,
                    c1_rec.account_name,
                    sales_force,
                    sales_force_name,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    distribution_channel,
                    NULL,
                    notes,
                    entered_by,
                    sysdate,
                    updated_by,
                    sysdate,
                    start_date,
                    end_date
                  --  ,df_distribution_id
                FROM
                    xxhbg_default_distribution_channel_tbl
                WHERE
                        1 = 1
                    AND to_char(organization_number) = to_char(c1_rec.org_num);

            COMMIT;
        END LOOP;

        p_status := 'SUCCESS';
    EXCEPTION
        WHEN OTHERS THEN
            p_status := 'Unhandled exception while inserting date' || sqlerrm;
    END assigndefault_dist_channel_create;

    PROCEDURE dist_channel_validation (
        p_source_line_id             IN   VARCHAR2,
        p_batch_id                   IN   VARCHAR2,
        return_status                OUT  VARCHAR2,
        p_so_mapping_val_type_array  OUT  hbg_so_mapping_val_type_array
    ) IS

        CURSOR c_get_dist_channel IS
        SELECT
            *
        FROM
            (
                SELECT
                    a.*,
                    DENSE_RANK()
                    OVER(PARTITION BY a.source_order_id, a.source_line_id
                         ORDER BY a.precedence_level
                    ) rank
                FROM
                    (
                        SELECT DISTINCT
                            dha.source_order_id,
                            dha.source_order_system,
                            dla.source_line_id,
                            dha.source_order_system
                            || ':'
                            || dha.source_order_id source_key,
                            dha.order_number,
                            dfla.fulfill_line_id,
                            xdcplt.precedence_level,
                            xadct.distribution_channel
                        FROM
                            xxhbg_dist_channel_prec_lev_tbl        xdcplt,
                            xxhbg_assign_distrubution_channel_tbl  xadct,
                            ego_item_eff_b                         eieb_bisac,
                            ego_item_eff_b                         eieb,
                            hz_cust_accounts                       hca,
                            doo_fulfill_lines_eff_b                dfleb_dist,
                            doo_fulfill_lines_eff_b                dfleb_sfcode,
                            doo_fulfill_lines_all                  dfla,
                            doo_lines_all                          dla,
                            doo_headers_all                        dha
                        WHERE
                                1 = 1
                            AND p_batch_id IS NULL
                            AND dla.source_line_id = nvl(p_source_line_id, dla.source_line_id)
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
                            AND dfla.fulfill_line_id = dfleb_sfcode.fulfill_line_id
                            AND dfleb_sfcode.context_code = 'Sales Force Code'
                            AND dfla.fulfill_line_id = dfleb_dist.fulfill_line_id (+)
                            AND dfleb_dist.context_code (+) = 'Distribution Channel Code'
                            AND nvl(dfleb_dist.attribute_char2, 'N') = 'N'
                            AND dfla.bill_to_customer_id = hca.cust_account_id
                            AND dfla.inventory_item_id = eieb.inventory_item_id (+)
                            AND dfla.inventory_organization_id = eieb.organization_id (+)
                            AND eieb.context_code (+) = 'Family Code'
                            AND dfla.inventory_item_id = eieb_bisac.inventory_item_id (+)
                            AND dfla.inventory_organization_id = eieb_bisac.organization_id (+)
                            AND eieb_bisac.context_code (+) = 'General BISAC'
                            AND nvl(hca.account_number, '#NULL') = nvl(nvl(xadct.account_number, hca.account_number), '#NULL')
                            AND nvl(eieb.attribute_char1, '#NULL') = nvl(nvl(xadct.owner, eieb.attribute_char1), '#NULL')
                            AND nvl(eieb.attribute_char2, '#NULL') = nvl(nvl(xadct.reporting_group, eieb.attribute_char2), '#NULL')
                            AND nvl(eieb.attribute_char3, '#NULL') = nvl(nvl(xadct.category_1, eieb.attribute_char3), '#NULL')
                            AND nvl(eieb.attribute_char4, '#NULL') = nvl(nvl(xadct.category_2, eieb.attribute_char4), '#NULL')
                            AND nvl(eieb_bisac.attribute_char1, '#NULL') = nvl(nvl(xadct.bisac, eieb_bisac.attribute_char1), '#NULL')
                            AND CASE
                                    WHEN xadct.owner IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xdcplt.owner
                            AND CASE
                                    WHEN xadct.reporting_group IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xdcplt.reporting_group
                            AND CASE
                                    WHEN xadct.category_1 IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xdcplt.category_1
                            AND CASE
                                    WHEN xadct.category_2 IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xdcplt.category_2
                            AND CASE
                                    WHEN xadct.bisac IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xdcplt.bisac
                    ) a
            )
        WHERE
            rank = 1
        UNION
        SELECT
            *
        FROM
            (
                SELECT
                    a.*,
                    DENSE_RANK()
                    OVER(PARTITION BY a.source_order_id, a.source_line_id
                         ORDER BY a.precedence_level
                    ) rank
                FROM
                    (
                        SELECT DISTINCT
                            dha.source_order_id,
                            dha.source_order_system,
                            dla.source_line_id,
                            dha.source_order_system
                            || ':'
                            || dha.source_order_id source_key,
                            dha.order_number,
                            dfla.fulfill_line_id,
                            xdcplt.precedence_level,
                            xadct.distribution_channel
                        FROM
                            xxhbg_dist_channel_prec_lev_tbl        xdcplt,
                            xxhbg_assign_distrubution_channel_tbl  xadct,
                            ego_item_eff_b                         eieb_bisac,
                            ego_item_eff_b                         eieb,
                            hz_cust_accounts                       hca,
                            doo_fulfill_lines_eff_b                dfleb_dist,
                            doo_fulfill_lines_eff_b                dfleb_sfcode,
                            doo_fulfill_lines_all                  dfla,
                            doo_lines_all                          dla,
                            doo_headers_eff_b                      dheb_batch,
                            doo_headers_all                        dha
                        WHERE
                                1 = 1
                            AND dha.header_id = dheb_batch.header_id (+)
                            AND dheb_batch.context_code (+) = 'EDI General'
                            AND dheb_batch.attribute_char18 = p_batch_id
                            AND dla.source_line_id = nvl(p_source_line_id, dla.source_line_id)
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
                            AND dfla.fulfill_line_id = dfleb_sfcode.fulfill_line_id
                            AND dfleb_sfcode.context_code = 'Sales Force Code'
                            AND dfla.fulfill_line_id = dfleb_dist.fulfill_line_id (+)
                            AND dfleb_dist.context_code (+) = 'Distribution Channel Code'
                            AND nvl(dfleb_dist.attribute_char2, 'N') = 'N'
                            AND dfla.bill_to_customer_id = hca.cust_account_id
                            AND dfla.inventory_item_id = eieb.inventory_item_id (+)
                            AND dfla.inventory_organization_id = eieb.organization_id (+)
                            AND eieb.context_code (+) = 'Family Code'
                            AND dfla.inventory_item_id = eieb_bisac.inventory_item_id (+)
                            AND dfla.inventory_organization_id = eieb_bisac.organization_id (+)
                            AND eieb_bisac.context_code (+) = 'General BISAC'
                            AND nvl(hca.account_number, '#NULL') = nvl(nvl(xadct.account_number, hca.account_number), '#NULL')
                            AND nvl(eieb.attribute_char1, '#NULL') = nvl(nvl(xadct.owner, eieb.attribute_char1), '#NULL')
                            AND nvl(eieb.attribute_char2, '#NULL') = nvl(nvl(xadct.reporting_group, eieb.attribute_char2), '#NULL')
                            AND nvl(eieb.attribute_char3, '#NULL') = nvl(nvl(xadct.category_1, eieb.attribute_char3), '#NULL')
                            AND nvl(eieb.attribute_char4, '#NULL') = nvl(nvl(xadct.category_2, eieb.attribute_char4), '#NULL')
                            AND nvl(eieb_bisac.attribute_char1, '#NULL') = nvl(nvl(xadct.bisac, eieb_bisac.attribute_char1), '#NULL')
                            AND CASE
                                    WHEN xadct.owner IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xdcplt.owner
                            AND CASE
                                    WHEN xadct.reporting_group IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xdcplt.reporting_group
                            AND CASE
                                    WHEN xadct.category_1 IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xdcplt.category_1
                            AND CASE
                                    WHEN xadct.category_2 IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xdcplt.category_2
                            AND CASE
                                    WHEN xadct.bisac IS NULL THEN
                                        0
                                    ELSE
                                        1
                                END = xdcplt.bisac
                    ) a
            )
        WHERE
            rank = 1;

        l_return_status            VARCHAR2(255);
        loop_index                 NUMBER := 1;
        v_hbg_so_mapping_val_type  hbg_so_mapping_val_type_array := hbg_so_mapping_val_type_array();
    BEGIN
        l_return_status := 'SUCCESS';
        FOR c_get_dist_channel_lines IN c_get_dist_channel LOOP
            v_hbg_so_mapping_val_type.extend;
            v_hbg_so_mapping_val_type(loop_index) := hbg_so_mapping_val_type(c_get_dist_channel_lines.source_order_system, c_get_dist_channel_lines.
            source_order_id,
                                                                            c_get_dist_channel_lines.source_line_id,
                                                                            c_get_dist_channel_lines.source_key,
                                                                            c_get_dist_channel_lines.distribution_channel,
                                                                            NULL,
                                                                            NULL,
                                                                            NULL,
                                                                            NULL,
                                                                            c_get_dist_channel_lines.order_number,
                                                                            c_get_dist_channel_lines.fulfill_line_id);

            loop_index := loop_index + 1;
        END LOOP;

        return_status := l_return_status;
        p_so_mapping_val_type_array := v_hbg_so_mapping_val_type;
    EXCEPTION
        WHEN OTHERS THEN
            l_return_status := 'FAILURE';
            return_status := l_return_status;
            p_so_mapping_val_type_array := v_hbg_so_mapping_val_type;
    END dist_channel_validation;

END hbg_sales_credit_pkg;

/
