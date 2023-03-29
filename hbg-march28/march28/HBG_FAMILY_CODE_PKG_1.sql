--------------------------------------------------------
--  DDL for Package Body HBG_FAMILY_CODE_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."HBG_FAMILY_CODE_PKG" IS

    PROCEDURE hbg_family_code_owner_create (
        p_owner_code        IN VARCHAR2,
        p_owner_name        IN VARCHAR2,
        p_owner_abbr        IN VARCHAR2,
        p_status            IN VARCHAR2,
        p_start_date        IN DATE,
        p_end_date          IN DATE,
        p_in_pubtracker_ind IN VARCHAR2,
        p_distributee_ind   IN VARCHAR2,
        p_creation_date     IN DATE,
        p_created_by        IN VARCHAR2,
        p_last_updated_date IN DATE,
        p_last_updated_by   IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    ) IS
        l_ow_cnt NUMBER := 0;
    BEGIN
        IF ( p_owner_code IS NULL OR p_owner_name IS NULL ) THEN
            p_return_status := 'Owner code and Owner name field cannot be blank';
        ELSE
            BEGIN
                SELECT
                    COUNT(*)
                INTO l_ow_cnt
                FROM
                    xxhbg_family_code_owner
                WHERE
                    owner_code = p_owner_code;

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

            IF l_ow_cnt > 0 THEN
                p_return_status := ' Owner code '
                                   || p_owner_code
                                   || ' already exists please create unique Owner code';
            ELSE
                INSERT INTO xxhbg_family_code_owner (
                    owner_code,
                    owner_name,
                    owner_abbr,
                    status,
                    start_date,
                    end_date,
                    in_pubtracker_ind,
                    distributee_ind,             
                    creation_date,
                    created_by,
                    last_updated_date,
                    last_updated_by
                ) VALUES (
                    p_owner_code,
                    p_owner_name,
                    p_owner_abbr,
                    p_status,
                    p_start_date,
                    p_end_date,
                    p_in_pubtracker_ind,
                    p_distributee_ind,          
                    sysdate,
                    p_created_by,
                    sysdate,
                    p_last_updated_by
                );

                p_return_status := 'SUCCESS';
            END IF;

        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'error occured due to ' || sqlerrm;
    END;

    PROCEDURE hbg_family_code_owner_update (
        p_owner_id          IN NUMBER,
        p_owner_code        IN VARCHAR2,
        p_owner_name        IN VARCHAR2,
        p_owner_abbr        IN VARCHAR2,
        p_start_date        IN DATE,
        p_end_date          IN DATE,
        p_status            IN VARCHAR2,
        p_in_pubtracker_ind IN VARCHAR2,
        p_distributee_ind   IN VARCHAR2,
        p_creation_date     IN DATE,
        p_created_by        IN VARCHAR2,
        p_last_updated_date IN DATE,
        p_last_updated_by   IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    ) AS
    BEGIN
        IF p_owner_id IS NOT NULL THEN
            UPDATE xxhbg_family_code_owner
            SET
                owner_id = p_owner_id,
                owner_code = p_owner_code,
                owner_name = p_owner_name,
                owner_abbr = p_owner_abbr,
                status = p_status,
                start_date = p_start_date,
                end_date = p_end_date,
                in_pubtracker_ind = p_in_pubtracker_ind,
                distributee_ind = p_distributee_ind,
                last_updated_date = sysdate,
                last_updated_by = p_last_updated_by
            WHERE
                owner_id = p_owner_id;

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Division :' || sqlerrm;
    END;

    PROCEDURE hbg_family_code_reporting_group_create (
        p_reporting_grp_code IN VARCHAR2,
        p_reporting_grp_name IN VARCHAR2,
        p_reporting_grp_abbr IN VARCHAR2,
        p_created_by         IN VARCHAR2,
        p_last_updated_by    IN VARCHAR2,
        p_owner_id           IN NUMBER,
        p_status             IN VARCHAR2,
        p_start_date         IN DATE,
        p_end_date           IN DATE,
        p_return_status      OUT VARCHAR2
    ) IS
        l_rpg_cnt NUMBER := 0;
    BEGIN
        IF ( p_reporting_grp_code IS NULL OR p_reporting_grp_name IS NULL ) THEN
            p_return_status := ' Reporting Group Code and  Reporting Group Name field cannot be blank';
        ELSE
            BEGIN
                SELECT
                    COUNT(*)
                INTO l_rpg_cnt
                FROM
                    xxhbg_family_code_reporting_group
                WHERE
                    reporting_grp_code = p_reporting_grp_code;

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

            IF l_rpg_cnt > 0 THEN
                p_return_status := ' Reporting Group Code '
                                   || p_reporting_grp_code
                                   || ' already exists please create unique Reporting Group Code';
            ELSE
                INSERT INTO xxhbg_family_code_reporting_group (
                    reporting_group_id,
                    reporting_grp_code,
                    reporting_grp_name,
                    reporting_grp_abbr,
                    creation_date,
                    created_by,
                    last_updated_date,
                    last_updated_by,
                    owner_id,
                    status,
                    start_date,
                    end_date
                ) VALUES (
                    hbg_fc_rpt_grp_id_seq.NEXTVAL,
                    p_reporting_grp_code,
                    p_reporting_grp_name,
                    p_reporting_grp_abbr,
                    sysdate,
                    p_created_by,
                    sysdate,
                    p_last_updated_by,
                    p_owner_id,
                    p_status,
                    p_start_date,
                    p_end_date
                );

                COMMIT;
                p_return_status := 'SUCCESS';
            END IF;

        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'error occured due to ' || sqlerrm;
    END;

    PROCEDURE hbg_family_code_reporting_group_update (
        p_reporting_group_id IN NUMBER,
        p_reporting_grp_code IN VARCHAR2,
        p_reporting_grp_name IN VARCHAR2,
        p_reporting_grp_abbr IN VARCHAR2,
        p_creation_date      IN DATE,
        p_created_by         IN VARCHAR2,
        p_last_updated_date  IN DATE,
        p_last_updated_by    IN VARCHAR2,
        p_owner_id           IN NUMBER,
        p_status             IN VARCHAR2,
        p_start_date         IN DATE,
        p_end_date           IN DATE,
        p_return_status      OUT VARCHAR2
    ) AS
    BEGIN
        IF p_reporting_group_id IS NOT NULL THEN
            UPDATE xxhbg_family_code_reporting_group
            SET
                reporting_group_id = p_reporting_group_id,
                reporting_grp_code = p_reporting_grp_code,
                reporting_grp_name = p_reporting_grp_name,
                reporting_grp_abbr = p_reporting_grp_abbr,            
                last_updated_date = sysdate,
                last_updated_by = p_last_updated_by,
                owner_id = p_owner_id,
                status = p_status,
                start_date = p_start_date,
                end_date = p_end_date
            WHERE
                reporting_group_id = p_reporting_group_id;

            p_return_status := 'SUCCESS';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Division :' || sqlerrm;
    END;

    PROCEDURE hbg_family_code_reporting_category1_create (
        p_category1_code         IN VARCHAR2,
        p_category1_name         IN VARCHAR2,
        p_category1_abbr         IN VARCHAR2,
        p_start_date             IN DATE,
        p_end_date               IN DATE,
        p_status                 IN VARCHAR2,
        p_returnable_grace_days  IN NUMBER,
        p_creation_date          IN DATE,
        p_created_by             IN VARCHAR2,
        p_last_updated_date      IN DATE,
        p_last_updated_by        IN VARCHAR2,
        p_reporting_group_id     IN NUMBER,
        p_pub_id                 IN NUMBER,
        p_company_code           IN VARCHAR2,
        p_osd_ind                IN VARCHAR2,
        p_partial_ship_ind       IN VARCHAR2,
        p_partial_ship_threshold IN NUMBER,
        p_return_status          OUT VARCHAR2
    ) IS
    BEGIN
        IF ( p_category1_code IS NULL OR p_category1_name IS NULL ) THEN
            p_return_status := ' Category1 code AND Category1 name field cannot be blank';
        ELSE
            INSERT INTO xxhbg_family_code_reporting_category1 (
                category1_code,
                category1_name,
                category1_abbr,
                start_date,
                end_date,
                status,
                returnable_grace_days,
                creation_date,
                created_by,
                last_updated_date,
                last_updated_by,
                reporting_group_id,
                pub_id,
                company_code,
                osd_ind,
                partial_ship_ind,
                partial_ship_threshold
            ) VALUES (
                p_category1_code,
                p_category1_name,
                p_category1_abbr,
                p_start_date,
                p_end_date,
                p_status,
                p_returnable_grace_days,
                sysdate,
                p_created_by,
                sysdate,
                p_last_updated_by,
                p_reporting_group_id,
                p_pub_id,
                p_company_code,
                p_osd_ind,
                p_partial_ship_ind,
                p_partial_ship_threshold
            );

            COMMIT;
            p_return_status := 'SUCCESS';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating category1 :' || sqlerrm;
    END;

    PROCEDURE hbg_family_code_reporting_category1_update (
        p_category1_id           IN NUMBER,
        p_category1_code         IN VARCHAR2,
        p_category1_name         IN VARCHAR2,
        p_category1_abbr         IN VARCHAR2,
        p_start_date             IN DATE,
        p_end_date               IN DATE,
        p_status                 IN VARCHAR2,
        p_returnable_grace_days  IN NUMBER,
        p_creation_date          IN DATE,
        p_created_by             IN VARCHAR2,
        p_last_updated_date      IN DATE,
        p_last_updated_by        IN VARCHAR2,
        p_reporting_group_id     IN NUMBER,
        p_pub_id                 IN NUMBER,
        p_company_code           IN VARCHAR2,
        p_osd_ind                IN VARCHAR2,
        p_partial_ship_ind       IN VARCHAR2,
        p_partial_ship_threshold IN NUMBER,
        p_return_status          OUT VARCHAR2
    ) AS
    BEGIN
        IF p_category1_id IS NOT NULL THEN
            UPDATE xxhbg_family_code_reporting_category1
            SET
                category1_id = p_category1_id,
                category1_code = p_category1_code,
                category1_name = p_category1_name,
                category1_abbr = p_category1_abbr,
                start_date = p_start_date,
                end_date = p_end_date,
                status = p_status,
                returnable_grace_days = p_returnable_grace_days,               
                last_updated_date = sysdate,
                last_updated_by = p_last_updated_by,
                reporting_group_id = p_reporting_group_id,
                pub_id = p_pub_id,
                company_code = p_company_code,
                osd_ind = p_osd_ind,
                partial_ship_ind = p_partial_ship_ind,
                partial_ship_threshold = p_partial_ship_threshold
            WHERE
                category1_id = p_category1_id;

            p_return_status := 'SUCCESS';
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating cat1egory :' || sqlerrm;
    END;

    PROCEDURE hbg_family_code_reporting_category2_create (
        p_category2_code    IN VARCHAR2,
        p_category2_name    IN VARCHAR2,
        p_category2_abbr    IN VARCHAR2,
        p_impr_id           IN  NUMBER,
        p_created_by      IN VARCHAR2,
        p_last_updated_by IN VARCHAR2,
        p_category1_id    IN NUMBER,
        p_start_date      IN DATE,
        p_end_date        IN DATE,
        p_status          IN VARCHAR2,
        p_return_status   OUT VARCHAR2
    ) IS
    BEGIN
        IF ( p_category2_code IS NULL OR p_category2_name IS NULL ) THEN
            p_return_status := ' category2_code AND category2_name field cannot be blank';
        ELSE
            INSERT INTO xxhbg_family_code_reporting_category2 (
                category2_code,
                category2_name,
                category2_abbr,
                impr_id,
                creation_date,
                created_by,
                last_updated_date,
                last_updated_by,
                category1_id,
                start_date,
                end_date,
                status
            ) VALUES (
                p_category2_code,
                p_category2_name,
                p_category2_abbr,
                p_impr_id,
                sysdate,
                p_created_by,
                sysdate,
                p_last_updated_by,
                p_category1_id,
                p_start_date,
                p_end_date,
                p_status
            );

            p_return_status := 'SUCCESS';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating cat1egory2 :' || sqlerrm;
            COMMIT;
    END;

    PROCEDURE hbg_family_code_reporting_category2_update (
        p_category2_id      IN NUMBER,
        p_category2_code    IN VARCHAR2,
        p_category2_name    IN VARCHAR2,
        p_category2_abbr    IN VARCHAR2,
        p_impr_id           IN  NUMBER,
        p_creation_date     IN DATE,
        p_created_by        IN VARCHAR2,
        p_last_updated_date IN DATE,
        p_last_updated_by   IN VARCHAR2,
        p_category1_id      IN NUMBER,
        p_start_date        IN DATE,
        p_end_date          IN DATE,
        p_status            IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    ) AS
    BEGIN
        IF p_category2_id IS NOT NULL THEN
            UPDATE xxhbg_family_code_reporting_category2
            SET
                category2_id = p_category2_id,
                category2_code = p_category2_code,
                category2_name = p_category2_name,
                category2_abbr = p_category2_abbr,
                impr_id       = p_impr_id,
                last_updated_date = sysdate,
                last_updated_by = p_last_updated_by,
                category1_id = p_category1_id,
                start_date = p_start_date,
                end_date = p_end_date,
                status = p_status
            WHERE
                category2_id = p_category2_id;

            p_return_status := 'SUCCESS';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Division :' || sqlerrm;
    END;

    PROCEDURE hbg_family_code_external_publisher_create (
        p_external_pub_code IN VARCHAR2,
        p_external_pub_name IN VARCHAR2,
        p_external_pub_abbr IN VARCHAR2,
        p_reporting_group_id IN VARCHAR2,
        p_created_date      IN DATE,
        p_created_by        IN VARCHAR2,
        p_last_updated_date IN DATE,
        p_last_updated_by   IN VARCHAR2,
        p_start_date        IN DATE,
        p_end_date          IN DATE,
        p_status            IN VARCHAR2,
        p_category1_id      IN NUMBER,
        p_return_status     OUT VARCHAR2
    ) IS
    BEGIN
        IF ( p_external_pub_code IS NULL OR p_external_pub_name IS NULL ) THEN
            p_return_status := ' External Publisher Code and External Publisher Name field cannot be blank';
        ELSE
            INSERT INTO xxhbg_family_code_external_publisher (
                external_pub_code,
                external_pub_name,
                external_pub_abbr,
                reporting_group_id,
                created_date,
                created_by,
                last_updated_date,
                last_updated_by,
                start_date,
                end_date,
                status,
                category1_id
            ) VALUES (
                p_external_pub_code,
                p_external_pub_name,
                p_external_pub_abbr,
                p_reporting_group_id,
                sysdate,
                p_created_by,
                sysdate,
                p_last_updated_by,
                p_start_date,
                p_end_date,
                p_status,
                p_category1_id
            );

            p_return_status := 'SUCCESS';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while creating External Publisher :' || sqlerrm;
    END;

    PROCEDURE hbg_family_code_external_publisher_update (
        p_pub_id            IN NUMBER,
        p_external_pub_code IN VARCHAR2,
        p_external_pub_name IN VARCHAR2,
        p_external_pub_abbr IN VARCHAR2,
        p_reporting_group_id IN VARCHAR2,
        p_created_date      IN DATE,
        p_created_by        IN VARCHAR2,
        p_last_updated_date IN DATE,
        p_last_updated_by   IN VARCHAR2,
        p_start_date        IN DATE,
        p_end_date          IN DATE,
        p_status            IN VARCHAR2,
        p_category1_id      IN NUMBER,
        p_return_status     OUT VARCHAR2
    ) AS
    BEGIN
        IF p_pub_id IS NOT NULL THEN
            UPDATE xxhbg_family_code_external_publisher
            SET
                pub_id = p_pub_id,
                external_pub_code = p_external_pub_code,
                external_pub_name = p_external_pub_name,
                external_pub_abbr = p_external_pub_abbr,
                reporting_group_id = p_reporting_group_id,
                last_updated_date = sysdate,
                last_updated_by = p_last_updated_by,
                start_date = p_start_date,
                end_date = p_end_date,
                status = p_status,
                category1_id = p_category1_id
            WHERE
                pub_id = p_pub_id;

            p_return_status := 'SUCCESS';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating External Publisher :' || sqlerrm;
    END;

    PROCEDURE hbg_family_code_external_imprint_create (
        p_external_imp_code IN VARCHAR2,
        p_external_imp_name IN VARCHAR2,
        p_external_imp_abbr IN VARCHAR2,
        p_reporting_group_id IN VARCHAR2,
        p_status            IN VARCHAR2,
        p_start_date        IN DATE,
        p_end_date          IN DATE,
        p_created_date      IN DATE,
        p_created_by        IN VARCHAR2,
        p_last_updated_date IN DATE,
        p_last_updated_by   IN VARCHAR2,
        p_category2_id      IN NUMBER,
        p_pub_id            IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    ) IS
    BEGIN
        IF ( p_external_imp_code IS NULL OR p_external_imp_name IS NULL ) THEN
            p_return_status := 'External Imprint Code and External Imprint Name field cannot be blank';
        ELSE
            INSERT INTO xxhbg_family_code_external_imprint (
                external_imp_code,
                external_imp_name,
                external_imp_abbr,
                reporting_group_id,
                status,
                start_date,
                end_date,
                created_date,
                created_by,
                last_updated_date,
                last_updated_by,
                category2_id,
                pub_id 
                ) VALUES (
                p_external_imp_code,
                p_external_imp_name,
                p_external_imp_abbr,
                p_reporting_group_id,
                p_status,
                p_start_date,
                p_end_date,
                sysdate,
                p_created_by,
                sysdate,
                p_last_updated_by,
                p_category2_id,
                p_pub_id
            );

            p_return_status := 'SUCCESS';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating External Imprint :' || sqlerrm;
    END;

    PROCEDURE hbg_family_code_external_imprint_update (
        p_impr_id           IN NUMBER,
        p_external_imp_code IN VARCHAR2,
        p_external_imp_name IN VARCHAR2,
        p_external_imp_abbr IN VARCHAR2,
        p_reporting_group_id IN VARCHAR2,
        p_status            IN VARCHAR2,
        p_start_date        IN DATE,
        p_end_date          IN DATE,
        p_created_date      IN DATE,
        p_created_by        IN VARCHAR2,
        p_last_updated_date IN DATE,
        p_last_updated_by   IN VARCHAR2,
        p_category2_id      IN NUMBER,
        p_pub_id            IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    ) AS
    BEGIN
        IF p_impr_id IS NOT NULL THEN
            UPDATE xxhbg_family_code_external_imprint
            SET
                external_imp_code = p_external_imp_code,
                external_imp_name = p_external_imp_name,
                external_imp_abbr = p_external_imp_abbr,
                reporting_group_id = p_reporting_group_id,
                status = p_status,
                start_date = p_start_date,
                end_date = p_end_date,
                last_updated_date = sysdate,
                last_updated_by = p_last_updated_by,
                category2_id = p_category2_id,
                pub_id = p_pub_id
            WHERE
                impr_id = p_impr_id;

            p_return_status := 'SUCCESS';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Division :' || sqlerrm;
    END;

    PROCEDURE hbg_family_code_format_create (
        p_format_code         IN VARCHAR2,
        p_format_name         IN VARCHAR2,
        p_format_abbr         IN VARCHAR2,
        p_status              IN VARCHAR2,
        p_ebook_ind           IN VARCHAR2,
        p_nonpub_item_ind     IN VARCHAR2,
        p_audio_ind           IN VARCHAR2,
        p_inc_sale_ind        IN VARCHAR2,
        p_cal_ind             IN VARCHAR2,
        p_commodity_code      IN VARCHAR2,
        p_require_sub_fmt_ind IN VARCHAR2,
        p_creation_date       IN DATE,
        p_created_by          IN VARCHAR2,
        p_last_updated_date   IN DATE,
        p_last_updated_by     IN VARCHAR2,
        p_return_status       OUT VARCHAR2
    ) IS
    BEGIN
        IF ( p_format_code IS NULL OR p_format_name IS NULL ) THEN
            p_return_status := ' Format code and Format name field cannot be blank';
        ELSE
            INSERT INTO xxhbg_familycode_format (
                format_code,
                format_name,
                format_abbr,
                status,
                ebook_ind,
                nonpub_item_ind,
                audio_ind,
                inc_sale_ind,
                cal_ind,
                commodity_code,
                require_sub_fmt_ind,
                creation_date,
                created_by,
                last_updated_date,
                last_updated_by
            ) VALUES (
                p_format_code,
                p_format_name,
                p_format_abbr,
                p_status,
                p_ebook_ind,
                p_nonpub_item_ind,
                p_audio_ind,
                p_inc_sale_ind,
                p_cal_ind,
                p_commodity_code,
                p_require_sub_fmt_ind,
            sysdate,
                p_created_by,
              sysdate,
                p_last_updated_by
            );

            p_return_status := 'SUCCESS';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while Creating Format :' || sqlerrm;
    END;

    PROCEDURE hbg_family_code_format_update (
        p_format_id           IN NUMBER,
        p_format_code         IN VARCHAR2,
        p_format_name         IN VARCHAR2,
        p_format_abbr         IN VARCHAR2,
        p_status              IN VARCHAR2,
        p_ebook_ind           IN VARCHAR2,
        p_nonpub_item_ind     IN VARCHAR2,
        p_audio_ind           IN VARCHAR2,
        p_inc_sale_ind        IN VARCHAR2,
        p_cal_ind             IN VARCHAR2,
        p_commodity_code      IN VARCHAR2,
        p_require_sub_fmt_ind IN VARCHAR2,
        p_creation_date       IN DATE,
        p_created_by          IN VARCHAR2,
        p_last_updated_date   IN DATE,
        p_last_updated_by     IN VARCHAR2,
        p_return_status       OUT VARCHAR2
    ) AS
    BEGIN
        IF p_format_id IS NOT NULL THEN
            UPDATE xxhbg_familycode_format
            SET
                format_id = p_format_id,
                format_code = p_format_code,
                format_name = p_format_name,
                format_abbr = p_format_abbr,
                status   = p_status,
                ebook_ind = p_ebook_ind,
                nonpub_item_ind = p_nonpub_item_ind,
                audio_ind = p_audio_ind,
                inc_sale_ind = p_inc_sale_ind,
                cal_ind = p_cal_ind,
                commodity_code = p_commodity_code,
                require_sub_fmt_ind = p_require_sub_fmt_ind,
                last_updated_date = sysdate,
                last_updated_by = p_last_updated_by
            WHERE
                format_id = p_format_id;

            p_return_status := 'SUCCESS';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Format :' || sqlerrm;
    END;

    PROCEDURE hbg_family_code_sub_format_create (
        p_sub_format_code   IN VARCHAR2,
        p_sub_format_name   IN VARCHAR2,
        p_sub_format_abbr   IN VARCHAR2,
        p_status              IN VARCHAR2,
        p_commodity_code    IN VARCHAR2,
        p_default_rpt_ind   IN VARCHAR2,
        p_created_date      IN DATE,
        p_created_by        IN VARCHAR2,
        p_last_updated_date IN DATE,
        p_last_updated_by   IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    ) IS
    BEGIN
        IF ( p_sub_format_code IS NULL OR p_sub_format_name IS NULL ) THEN
            p_return_status := ' Sub format code and Sub format name field cannot be blank';
        ELSE
            INSERT INTO xxhbg_family_code_sub_format (
                sub_format_code,
                sub_format_name,
                sub_format_abbr,
                status,
                commodity_code,
                default_rpt_ind,
                created_date,
                created_by,
                last_updated_date,
                last_updated_by
            ) VALUES (
                p_sub_format_code,
                p_sub_format_name,
                p_sub_format_abbr,
                p_status,
                p_commodity_code,
                p_default_rpt_ind,
                 sysdate,
                p_created_by,
                sysdate,
                p_last_updated_by
            );

            p_return_status := 'SUCCESS';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while Creating Sub Format :' || sqlerrm;
    END;

    PROCEDURE hbg_family_code_sub_format_update (
        p_sub_format_id     IN NUMBER,
        p_sub_format_code   IN VARCHAR2,
        p_sub_format_name   IN VARCHAR2,
        p_sub_format_abbr   IN VARCHAR2,
        p_status              IN VARCHAR2,
        p_commodity_code    IN VARCHAR2,
       p_default_rpt_ind   IN VARCHAR2,
        p_created_date      IN DATE,
        p_created_by        IN VARCHAR2,
        p_last_updated_date IN DATE,
        p_last_updated_by   IN VARCHAR2,
        p_return_status     OUT VARCHAR2
    ) AS
    BEGIN
        IF p_sub_format_id IS NOT NULL THEN
            UPDATE xxhbg_family_code_sub_format
            SET
                sub_format_id = p_sub_format_id,
                sub_format_code = p_sub_format_code,
                sub_format_name = p_sub_format_name,
                sub_format_abbr = p_sub_format_abbr,
                 status    =   p_status ,
                commodity_code = p_commodity_code,
                default_rpt_ind = p_default_rpt_ind,
                last_updated_date = sysdate,
                last_updated_by = p_last_updated_by
            WHERE
                sub_format_id = p_sub_format_id;

            p_return_status := 'SUCCESS';
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_return_status := 'Unkown error while updating Sub Format :' || sqlerrm;
    END;

END;

/
