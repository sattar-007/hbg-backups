--------------------------------------------------------
--  DDL for Package Body HBG_CX_ITEMS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."HBG_CX_ITEMS_PKG" IS
  /*************************************************************************
  *
  * Description:   HBG Cx Items integration
  *
  * Modifications:
  *
  * DATE         AUTHOR           	DESCRIPTION
  * ----------   -----------      	------------------------------------------
  * 03/10/2022   Mariana Teixeira   INITIAL VERSION
  * 07/28/2022   Mariana Teixeira   Products Bulk Import/ Error Handling 
  * 08/15/2022   Mariana Teixeira   inactive old NYPs / 60,61 to HUK2324 / 5 retries get access token
  * 08/17/2022   Mariana Teixeira   Client Gifting Draft
  * 09/06/2022   Mariana Teixeira   Data Model Change
  * 09/22/2022   Mariana Teixeira   1C changes
  ************************************************************************/

  --/*************************************************************************
  -- Global Variables 
  --*************************************************************************/

   -- g_directory    VARCHAR2(50) := 'HBG_JSON_IMPORT';
    --g_content_name VARCHAR2(15) := 'content.json';
    --g_instance_id NUMBER;
    --g_auth := 

  --/*************************************************************************
  -- Isbn validation Procedure  
  --*************************************************************************/

    PROCEDURE isbn_validation ( p_instance_id IN NUMBER,
                                errbuf        OUT VARCHAR2,
                                retcode       OUT VARCHAR2
    ) AS


    BEGIN
        errbuf := NULL;
        retcode := 0;
        --VALIDATE OWNER
        UPDATE HBG_CX_ITEMS_EXTRACT item SET STATUS = 'SKIPPED', CX_ACTIVE = 'false', COMMENTS = 'SKIPPED: Owner code ['
                                  || item.owner_code
                                  || '] not valid;'
        WHERE item.owner_code NOT IN (   'HB', 'CB', 'HU', 'OB', 'MS',
                                        'AB', 'PP', 'DP',
                                        'QS', 'KP', 'LP', 'YP' ) 
        AND INSTANCEID = p_instance_id
        --AND NOT EXISTS (SELECT 1 FROM HBG_CX_ITEMS_PRODUCTS_SKUS cx WHERE cx.sku_id = item.isbn)
        ;
        COMMIT;
        --VALIDATE PUBLICATION DATE
        UPDATE HBG_CX_ITEMS_EXTRACT item SET STATUS = 'SKIPPED', CX_ACTIVE = 'false', COMMENTS = COMMENTS || 'SKIPPED: Null Publication Date;'
        WHERE item.publication_date IS NULL  
        AND INSTANCEID = p_instance_id
        --AND NOT EXISTS (SELECT 1 FROM HBG_CX_ITEMS_PRODUCTS_SKUS cx WHERE cx.sku_id = item.isbn)
        ;
        COMMIT;
        --VALIDATE FORMAT
        UPDATE HBG_CX_ITEMS_EXTRACT item SET STATUS = 'SKIPPED', CX_ACTIVE = 'false', COMMENTS = COMMENTS || 'SKIPPED: Invalid Format ['
                                  || item.format
                                  || '];'
                WHERE item.format_code IN ( 
                                            '25', -- CD-ROM Interactive
                                            '26', -- Online Services
                                            '30', -- CDROM Software
                                            '31', -- Shirts - Tee / Sweat
                                            '34', -- Foam Back Print (Poster)
                                            '38', -- Electronic Book
                                            '48', -- Miscellaneous Titles
                                            '49', -- Postage / Costing
                                            '50', -- Advance Reading Copy / Galleys
                                            '52', -- Boxed Set
                                            '55', -- Video - VHS
                                            '56', -- Video - DVD
                                            '57', -- Displays / Prepacks / Set
                                            '58', -- Dummy #
                                            '59', -- Assortment
                                            '66', -- Book "Other Format"
                                            '70', -- Instruments
                                            '77', -- Co-Publication / Special Royalty
                                            '79', -- Voice-controlled
                                            '81', -- Promotional Item - Non Distributed
                                            '82', -- Promotional Item - Distributed
                                            '83', -- Promo posters
                                            '84', -- Catalog - ISBN
                                            '85', -- Assorted Pallet Returns
                                            '86', -- Whse Use Only - ISBN
                                            '87', -- Music
                                            '88', -- Material / Non-Book Item
                                            '90', -- Digital Content
                                            '91', -- PT internal use only
                                            '92' -- Boxed Set - Non Saleable Component                                                                              
                ) 
                AND INSTANCEID = p_instance_id
                --AND NOT EXISTS (SELECT 1 FROM HBG_CX_ITEMS_PRODUCTS_SKUS cx WHERE cx.sku_id = item.isbn)
                ;
              COMMIT;  
        --VALIDATE SUBFORMAT
        UPDATE HBG_CX_ITEMS_EXTRACT item SET STATUS = 'SKIPPED', CX_ACTIVE = 'false', COMMENTS = COMMENTS || 'SKIPPED: Invalid Sub Format ['
                                  || item.sub_format
                                  || '];'
                WHERE item.sub_format_code IN (  '32', --Downloadable (Audio)
                                                 '33', --Downloadable (Audio Library)
                                                 '37', --Playaway (Audio)
                                                 '38'  --Playaway (Audio Library
                     ) 
                AND INSTANCEID = p_instance_id
                --AND NOT EXISTS (SELECT 1 FROM HBG_CX_ITEMS_PRODUCTS_SKUS cx WHERE cx.sku_id = item.isbn)
                ;
            COMMIT;    
        --VALIDATE PUB STATUS
        UPDATE HBG_CX_ITEMS_EXTRACT item SET STATUS = 'SKIPPED', CX_ACTIVE = 'false', COMMENTS = COMMENTS || 'SKIPPED: Invalid Publication Status Code ['
                                  || item.pub_status
                                  || '];'
                WHERE item.pub_status IN ( 'NOP', 'PC', 'OP', 'OSI', 'OSF' )
                AND INSTANCEID = p_instance_id
                --AND NOT EXISTS (SELECT 1 FROM HBG_CX_ITEMS_PRODUCTS_SKUS cx WHERE cx.sku_id = item.isbn)
                ;
        COMMIT;
         UPDATE HBG_CX_ITEMS_EXTRACT item SET STATUS = 'NEW', COMMENTS = NULL
         WHERE STATUS = 'SKIPPED'
         AND INSTANCEID = p_instance_id
         AND EXISTS (SELECT 1 FROM HBG_CX_ITEMS_PRODUCTS_SKUS cx WHERE cx.sku_id = item.isbn);
         COMMIT;

         UPDATE HBG_CX_ITEMS_EXTRACT item SET CX_ACTIVE = 'false'
         WHERE CX_ACTIVE IS NULL
         and pub_status = 'NYP'
         and to_date(item.publication_date,'YYYY-MM-DD') < trunc(sysdate)
         AND INSTANCEID = p_instance_id;
         COMMIT; 
         
         UPDATE HBG_CX_ITEMS_EXTRACT item SET CX_ACTIVE = 'false'
         WHERE CX_ACTIVE IS NULL
         and HIDE_FROM_ONIX = 'Y'
         AND INSTANCEID = p_instance_id;
         COMMIT; 
         
         UPDATE HBG_CX_ITEMS_EXTRACT item SET CX_ACTIVE = 'false'
         WHERE CX_ACTIVE IS NULL
         and CUSTOMER_SPECIFIC_CODE IS NOT NULL
         AND INSTANCEID = p_instance_id;
         COMMIT; 

         UPDATE HBG_CX_ITEMS_EXTRACT item SET CX_ACTIVE = 'true'
         WHERE CX_ACTIVE IS NULL
         AND INSTANCEID = p_instance_id;
         COMMIT;    
         UPDATE hbg_cx_items_price_extract price
            SET
                comments = 'SKIPPED: SKU has invalid values - check Item Extract for more information',
                status = 'SKIPPED'
            WHERE
                    instanceid = p_instance_id
                AND EXISTS (SELECT 1 FROM HBG_CX_ITEMS_EXTRACT item WHERE item.isbn = price.item_code and item.status = 'SKIPPED');
        COMMIT;
        UPDATE hbg_cx_items_inventory_extract inv
            SET
                comments = 'SKIPPED: SKU has invalid values - check Item Extract for more information',
                status = 'SKIPPED'
            WHERE
                    instanceid = p_instance_id
                AND EXISTS (SELECT 1 FROM HBG_CX_ITEMS_EXTRACT item WHERE item.isbn = inv.isbn and item.status = 'SKIPPED');
        COMMIT;
        UPDATE hbg_cx_items_cntb_extract cntb
            SET
                status = 'SKIPPED',
                comments = 'SKIPPED: SKU has invalid values - check Item Extract for more information'
            WHERE
                instanceid = p_instance_id
                AND EXISTS (SELECT 1 FROM HBG_CX_ITEMS_EXTRACT item WHERE item.isbn = cntb.isbn and item.status = 'SKIPPED');
        COMMIT;

        UPDATE hbg_cx_items_bisac_extract bisac
            SET
                status = 'SKIPPED',
                comments = 'SKIPPED: SKU has invalid values - check Item Extract for more information'
            WHERE
                instanceid = p_instance_id
                AND EXISTS (SELECT 1 FROM HBG_CX_ITEMS_EXTRACT item WHERE item.isbn = bisac.isbn and (item.status = 'SKIPPED' or item.owner_code not in ('CB', 'AB', 'QS')));
        COMMIT;



    EXCEPTION
        WHEN OTHERS THEN
        errbuf := sqlerrm;
        retcode := 1;
    END isbn_validation;


  --/*************************************************************************
  -- Import Skus Procedure  
  --*************************************************************************/

    PROCEDURE import_skus (
        p_instance_id IN NUMBER,
        p_user_token  IN VARCHAR2,
        errbuf        OUT VARCHAR2,
        retcode       OUT VARCHAR2
    ) AS

        l_errbuf        VARCHAR2(150);
        l_retcode       VARCHAR2(1);

    --Authentication Token 
        l_access_token  VARCHAR2(4000);

    --api variables
        l_skus_request      CLOB;
        l_response_clob     CLOB;
        l_sku_id            VARCHAR2(30);
        l_sku_csv_file      utl_file.file_type;
        l_sku_filename      VARCHAR2(50) := 'ProductsV2.json';
        l_file_token        varchar2(100);
        l_validation_clob   CLOB;
        l_validation_blob   BLOB;
        l_import_total      NUMBER;
        l_import_flag       VARCHAR2(5);
        l_file_b64          CLOB;
        l_file_blob         BLOB;
        l_comments          hbg_cx_items_extract.comments%TYPE;
        l_status            hbg_cx_items_extract.status%TYPE;
        l_cntb_comments     hbg_cx_items_cntb_extract.comments%TYPE;
        l_cntb_status       hbg_cx_items_cntb_extract.status%TYPE;
        l_error_code        VARCHAR2(30);
        l_err_message       VARCHAR2(4000);
        l_offset            INT := 1;
        l_process_flag      NUMBER;
        l_call_api          NUMBER;
        l_inventory         NUMBER;
        l_active            VARCHAR2(5);
        token_exception     EXCEPTION;
        l_author_list       VARCHAR2(4000);
        l_update_check      VARCHAR2(30);
        l_isbn              VARCHAR2(30);
        l_rws_sku           VARCHAR2(30);
        l_count             NUMBER;
        l_count_offset      NUMBER := 0;
        l_author_exception  NUMBER;
        l_import_progress   VARCHAR2(20);
        l_session_sleep     NUMBER;
        l_error_count       NUMBER;
        l_first_rec         NUMBER := 0;
        l_process_id          VARCHAR2(100);
        l_failure_count       NUMBER;
        l_json_report_clob    CLOB;
        l_failed_records_clob CLOB;
    --exception
        failed_import EXCEPTION;
    BEGIN
        errbuf := NULL;
        retcode := 0;
    --Create Skus Json file

    select count(1) into l_count from hbg_cx_items_extract where instanceid = p_instance_id;
    --skus loop
    l_sku_csv_file := utl_file.fopen(g_directory, l_sku_filename, 'W', 32767);
    utl_file.put_line(l_sku_csv_file,'{"product": [');
    --update hbg_cx_items_execution_tracker set request = '{"product": [' where instanceid = p_instance_id;
        FOR rws IN (
            SELECT
                item.work_isbn,                 
                item.isbn                      AS sku_id,               
                item.title                     AS displayname,
                item.CX_ACTIVE                 AS active,
                item.CUSTOMER_SPECIFIC_CODE,
                item.CUSTOMER_SPECIFIC_DESC,
                'true'                         AS discountable,
                upper(item.format)             AS book_type,
                item.book_description          AS long_desc,
                CASE
                    WHEN item.primary_flag = 'Y' THEN
                        'true'
                    ELSE
                        'false'
                END                            primary,
                TRIM(item.by_line)             author_name,
                item.imprint                   imprint,
                --'blabla' pub_date,
                case when item.publication_date is not null then item.publication_date || 'T12:00:00.000Z' 
                else null end as pub_date,
                item.publisher                 publisher,
                item.series                    series,
                item.series_number             series_num,
                item.sub_format                sub_prod,
                item.sub_title                 sub_title,
                item.pub_status                pub_status,
                item.owner_code                owner_code,
                item.format_code               format_code,
                item.sub_format_code           sub_format_code,
                item.owner                     owner,
                item.reporting_group_code_desc reporting_group,
                item.external_imprint,
                item.edition,
                CASE
                    WHEN cx.sku_id IS NOT NULL THEN
                        'true'
                    ELSE
                        'false'
                END                            AS update_flag
            FROM
                hbg_cx_items_extract       item,
                hbg_cx_items_products_skus cx
            WHERE
                    item.instanceid = p_instance_id
                AND item.isbn = cx.sku_id (+)
                and item.status <> 'SKIPPED'
            ORDER BY
                item.work_isbn,
                item.isbn
        ) LOOP
            l_rws_sku := rws.sku_id;
            l_author_exception := 0;
            --dbms_output.put_line(l_rws_sku);
            BEGIN
                SELECT DISTINCT
                    CASE
                        WHEN is_active_cnt = 0 THEN
                            NULL
                        WHEN cntb.isbn IS NULL THEN
                            cx.author_list
                        ELSE
                            cntb.author_list
                    END AS author_list,
                    item.isbn
                INTO
                    l_author_list,
                    l_isbn
                FROM
                    (
                        SELECT
                            isbn,
                            SUM(is_active) AS is_active_cnt
                        FROM
                            hbg_cx_items_cntb_extract
                        WHERE
                                instanceid = p_instance_id
                            AND isbn = l_rws_sku
                        GROUP BY
                            isbn
                    )                          act,
                    (
                        SELECT
                            LISTAGG((replace(display_name,',','')
                                     || ','
                                     || role_desc), '|') WITHIN GROUP(
                            ORDER BY
                                contributor_sequence
                            )
                            OVER(PARTITION BY isbn) AS author_list,
                            isbn
                        FROM
                            hbg_cx_items_cntb_extract
                        WHERE
                                instanceid = p_instance_id
                            AND isbn = l_rws_sku
                            AND is_active = 1
                    )                          cntb,
                    hbg_cx_items_products_skus cx,
                    hbg_cx_items_extract       item
                WHERE
                        item.isbn = cntb.isbn (+)
                    AND item.isbn = cx.sku_id (+)
                    AND item.isbn = l_rws_sku
                    AND item.isbn = act.isbn (+)
                    AND item.instanceid = p_instance_id;

            EXCEPTION
                WHEN no_data_found THEN
                    l_author_list := NULL;
                WHEN OTHERS THEN
                    --dbms_output.put_line(sqlerrm);
                    l_comments := 'ERROR: Failed to fetch author information for isbn ' || l_rws_sku ||' - ' || sqlerrm ;
                    l_status := 'ERROR';
                    l_cntb_status := 'ERROR';
                    l_cntb_comments := 'ERROR: Failed to fetch author information for isbn ' || l_rws_sku ||' - ' || sqlerrm ;
                    l_author_exception := 1;
                    UPDATE hbg_cx_items_cntb_extract
                    SET
                        status = l_cntb_status,
                        comments = l_cntb_comments
                    WHERE
                            isbn = rws.sku_id
                        AND instanceid = p_instance_id;

                    UPDATE hbg_cx_items_extract
                    SET
                        comments = l_comments,
                        status = l_status
                    WHERE
                            instanceid = p_instance_id
                        AND isbn = rws.sku_id;

                    COMMIT;
            END;

            IF l_author_exception = 0 THEN
            BEGIN
                SELECT
                    item.isbn
                INTO l_isbn
                FROM
                    hbg_cx_items_extract       item,
                    hbg_cx_items_products_skus cx,
                    (
                        SELECT DISTINCT
                            CASE
                                WHEN is_active_cnt = 0 THEN
                                    NULL
                                ELSE
                                    cntb.author_list
                            END       AS author_list,
                            item.isbn AS isbn
                        FROM
                            (
                                SELECT
                                    isbn,
                                    SUM(is_active) AS is_active_cnt
                                FROM
                                    hbg_cx_items_cntb_extract
                                WHERE
                                        instanceid = p_instance_id
                                    AND isbn = l_rws_sku
                                GROUP BY
                                    isbn
                            )                    act,
                            (
                                SELECT
                                    LISTAGG((replace(display_name,',', '')
                                             || ','
                                             || role_desc), '|') WITHIN GROUP(
                                    ORDER BY
                                        contributor_sequence
                                    )
                                    OVER(PARTITION BY isbn) AS author_list,
                                    isbn
                                FROM
                                    hbg_cx_items_cntb_extract
                                WHERE
                                        instanceid = p_instance_id
                                    AND is_active = 1
                                    AND isbn = l_rws_sku
                            )                    cntb,
                            hbg_cx_items_extract item
                        WHERE
                                item.isbn = cntb.isbn (+)
                            AND item.isbn = act.isbn
                            AND item.instanceid = p_instance_id
                    )                          cntb
                WHERE
                        item.isbn = cx.sku_id
                    AND item.isbn = cntb.isbn (+)
                    AND item.isbn = l_rws_sku
                    AND item.instanceid = p_instance_id
                    AND ( cx.display_name = item.title
                          OR ( cx.display_name IS NULL
                               AND item.title IS NULL ) )
                    AND ( cx.active = item.cx_active 
                            or ( cx.active IS NULL
                               AND item.cx_active IS NULL ) ) 
                    AND ( cx.author_name = TRIM(item.by_line)
                          OR ( cx.author_name IS NULL
                               AND item.by_line IS NULL ) )
                    AND ( cx.imprint = item.imprint
                          OR ( cx.imprint IS NULL
                               AND item.imprint IS NULL ) )
                    AND ( cx.publisher = item.publisher
                          OR ( cx.publisher IS NULL
                               AND item.publisher IS NULL ) )
                    AND ( cx.publication_date = item.publication_date
                          OR ( cx.publication_date IS NULL
                               AND item.publication_date IS NULL ) )
                    AND ( cx.series = item.series
                          OR ( cx.series IS NULL
                               AND item.series IS NULL ) )
                    AND ( cx.series_number = item.series_number
                          OR ( cx.series_number IS NULL
                               AND item.series_number IS NULL ) )
                    AND ( cx.sub_product = item.sub_format
                          OR ( cx.sub_product IS NULL
                               AND item.sub_format IS NULL ) )
                    AND ( cx.sub_title = item.sub_title
                          OR ( cx.sub_title IS NULL
                               AND item.sub_title IS NULL ) )
                    AND cx.owner = item.owner
                    AND cx.reporting_group = item.reporting_group_code_desc
                    AND ( dbms_lob.compare(cx.long_description, item.book_description) = '0'
                          OR ( cx.long_description IS NULL
                               AND item.book_description IS NULL ) )
                    AND ( cx.author_list = cntb.author_list
                          OR ( cx.author_list IS NULL
                               AND cntb.author_list IS NULL )
                          OR cntb.isbn IS NULL )
                    AND ( item.external_imprint = cx.external_imprint
                          OR ( item.external_imprint IS NULL
                               AND cx.external_imprint IS NULL ) )
                    AND ( item.edition = cx.edition
                          OR ( item.edition IS NULL
                               AND cx.edition IS NULL ) )
                    AND ( item.pub_status = cx.pub_status
                          OR ( item.pub_status IS NULL
                               AND cx.pub_status IS NULL ) )
                    AND ( upper(item.format) = cx.format
                          OR ( item.format IS NULL
                               AND cx.format IS NULL ) )
                    AND ( item.work_isbn = cx.parentid
                          OR ( item.work_isbn IS NULL
                               AND cx.parentid IS NULL ) )
                    AND ( item.CUSTOMER_SPECIFIC_CODE = cx.CUSTOMER_SPECIFIC_CODE
                          OR ( item.CUSTOMER_SPECIFIC_CODE IS NULL
                               AND cx.CUSTOMER_SPECIFIC_CODE IS NULL ) )
                    AND ( item.CUSTOMER_SPECIFIC_DESC = cx.CUSTOMER_SPECIFIC_DESC
                          OR ( item.CUSTOMER_SPECIFIC_DESC IS NULL
                               AND cx.CUSTOMER_SPECIFIC_DESC IS NULL ) );

            EXCEPTION
                WHEN no_data_found THEN
                    l_isbn := NULL;
                WHEN OTHERS THEN
                    errbuf := 'ERROR: Failed to validate mirror table data';
                    RAISE failed_import;
            END;

            IF l_isbn IS NULL THEN
                l_process_flag := 1;
                l_call_api := 1;       
                IF l_process_flag = 1 THEN 

                IF l_first_rec > 0 THEN
                    l_skus_request := ',{"id" : "'
                                      || rws.sku_id
                                      || '","displayName": "'
                                      || REPLACE(rws.displayname,'"','\"')
                                      || '","type": "'
                                      ||'Hachette_Book'
                                      || '","active" : '
                                      ||'true'
                                      || ',"description" : "'
                                      || REPLACE(rws.sub_title,'"','\"')
                                      || '","excludeFromSitemap": false'
                                      || ',"listPrices": {"giftingPrice": 0.0,"canadianPriceGroup": 0.0,"giftingPriceCAD": 0.0,"defaultPriceGroup": 0.0}'
                                      || ', "childSKUs": [{"id" : "'
                                      || rws.sku_id
                                      || '","displayName": "'
                                      || REPLACE(rws.displayname,'"','\"')
                                      || '","active" : '
                                      || rws.active
                                      || ',"x_publicationStatus": "'
                                      || rws.pub_status
                                      || '","x_externalImprint": "'
                                      || REPLACE(rws.external_imprint,'"','\"')
                                      || '","x_edition" : "'
                                      || REPLACE(rws.edition,'"','\"')
                                      || '","discountable" : '
                                      || 'true'
                                      || ',"x_authorList" : "'
                                      || REPLACE(l_author_list,'"','\"')
                                      || '","x_authorname" : "'
                                      || REPLACE(rws.author_name,'"','\"')
                                      || '","x_bookType" : "'
                                      || REPLACE(rws.book_type,'"','\"')
                                      || '","x_imprint" : "'
                                      || REPLACE(rws.imprint,'"','\"')
                                      || '","x_longDescription" : "'
                                      || REPLACE(rws.long_desc,'"','\"')
                                      || '","x_owner" : "'
                                      || REPLACE(rws.owner,'"','\"')
                                      || '","x_reportingGroup" : "'
                                      || REPLACE(rws.reporting_group,'"','\"')
                                      || '","x_primaryProduct" :'
                                      || rws.primary
                                      || ',"x_publicationDate" : "'
                                      || rws.pub_date
                                      ||'","x_publisher" : "'
                                      || REPLACE(rws.publisher,'"','\"')
                                      ||'","x_series" : "'
                                      || REPLACE(rws.series,'"','\"')
                                      ||'","x_seriesNumber" : "'
                                      || REPLACE(rws.series_num,'"','\"')
                                      ||'","x_subproduct" : "'
                                      || REPLACE(rws.sub_prod,'"','\"')
                                      ||'","x_subtitlebook" : "'
                                      || REPLACE(rws.sub_title,'"','\"')
                                      ||'","x_customerSpecificCode" : "'
                                      || REPLACE(rws.CUSTOMER_SPECIFIC_CODE,'"','\"')
                                      ||'","x_customerSpecificDescription" : "'
                                      || REPLACE(rws.CUSTOMER_SPECIFIC_DESC,'"','\"')
                                      ||'"}]}';
                    ELSE 
                        l_skus_request := '{"id" : "'
                                      || rws.sku_id
                                      || '","displayName": "'
                                      || REPLACE(rws.displayname,'"','\"')
                                      || '","type": "'
                                      ||'Hachette_Book'
                                      || '","active" : '
                                      ||'true'
                                      || ',"description" : "'
                                      || REPLACE(rws.sub_title,'"','\"')
                                      || '","excludeFromSitemap": false'
                                      || ',"listPrices": {"giftingPrice": 0.0,"canadianPriceGroup": 0.0,"giftingPriceCAD": 0.0,"defaultPriceGroup": 0.0}'
                                      || ', "childSKUs": [{"id" : "'
                                      || rws.sku_id
                                      || '","displayName": "'
                                      || REPLACE(rws.displayname,'"','\"')
                                      || '","active" : '
                                      || rws.active
                                      || ',"x_publicationStatus": "'
                                      || rws.pub_status
                                      || '","x_externalImprint": "'
                                      || REPLACE(rws.external_imprint,'"','\"')
                                      || '","x_edition" : "'
                                      || REPLACE(rws.edition,'"','\"')
                                      || '","discountable" : '
                                      || 'true'
                                      || ',"x_authorList" : "'
                                      || REPLACE(l_author_list,'"','\"')
                                      || '","x_authorname" : "'
                                      || REPLACE(rws.author_name,'"','\"')
                                      || '","x_bookType" : "'
                                      || REPLACE(rws.book_type,'"','\"')
                                      || '","x_imprint" : "'
                                      || REPLACE(rws.imprint,'"','\"')
                                      || '","x_longDescription" : "'
                                      || REPLACE(rws.long_desc,'"','\"')
                                      || '","x_owner" : "'
                                      || REPLACE(rws.owner,'"','\"')
                                      || '","x_reportingGroup" : "'
                                      || REPLACE(rws.reporting_group,'"','\"')
                                      || '","x_primaryProduct" :'
                                      || rws.primary
                                      || ',"x_publicationDate" : "'
                                      || rws.pub_date
                                      ||'","x_publisher" : "'
                                      || REPLACE(rws.publisher,'"','\"')
                                      ||'","x_series" : "'
                                      || REPLACE(rws.series,'"','\"')
                                      ||'","x_seriesNumber" : "'
                                      || REPLACE(rws.series_num,'"','\"')
                                      ||'","x_subproduct" : "'
                                      || REPLACE(rws.sub_prod,'"','\"')
                                      ||'","x_subtitlebook" : "'
                                      || REPLACE(rws.sub_title,'"','\"')
                                      ||'","x_customerSpecificCode" : "'
                                      || REPLACE(rws.CUSTOMER_SPECIFIC_CODE,'"','\"')
                                      ||'","x_customerSpecificDescription" : "'
                                      || REPLACE(rws.CUSTOMER_SPECIFIC_DESC,'"','\"')
                                      ||'"}]}';
                        l_first_rec := 1;
                        END IF;

                /* BEGIN  
                    dbms_output.put_line('Print CLOB 1 - importSkus');    
                    loop  
                    exit when l_offset > dbms_lob.getlength(l_skus_request);  
                    dbms_output.put_line( dbms_lob.substr( l_skus_request, 255, l_offset ) );  
                    l_offset := l_offset + 255;  
                    end loop;  
                END;*/
                        INSERT INTO hbg_cx_items_validation_rpt
                                    (   
                                        PRODUCT_ID,
                                        SKU_ID,
                                        DISPLAY_NAME,
                                        ACTIVE, 
                                        PUB_STATUS, 
                                        EXTERNAL_IMPRINT, 
                                        EDITION, 
                                        AUTHOR_LIST, 
                                        AUTHOR_NAME,
                                        BOOK_TYPE,
                                        IMPRINT, 
                                        LONG_DESCRIPTION, 
                                        OWNER, 
                                        REPORTING_GROUP,
                                        PRIMARY_PRODUCT,
                                        PUBLICATION_DATE,
                                        PUBLISHER,
                                        SERIES,
                                        SERIES_NUMBER,
                                        SUB_PRODUCT,
                                        SUB_TITLE,
                                        CUSTOMER_SPECIFIC_CODE,
                                        CUSTOMER_SPECIFIC_DESC,
                                        INSTANCEID
                                    )
                        VALUES
                                    (   rws.work_isbn,
                                        rws.sku_id,
                                        rws.displayname,
                                        rws.active,
                                        rws.pub_status,
                                        rws.external_imprint,
                                        rws.edition,
                                        l_author_list,
                                        rws.author_name,
                                        rws.book_type,
                                        rws.imprint,
                                        rws.long_desc,
                                        rws.owner,
                                        rws.reporting_group,
                                        rws.primary,
                                        rws.pub_date,
                                        rws.publisher,
                                        rws.series,
                                        rws.series_num,
                                        rws.sub_prod,
                                        rws.sub_title,
                                        rws.CUSTOMER_SPECIFIC_CODE,
                                        rws.CUSTOMER_SPECIFIC_DESC,
                                        p_instance_id);
                        commit;

                 --update hbg_cx_items_execution_tracker set request = request || l_skus_request where instanceid = p_instance_id;           

                     --dbms_output.put_line('WRITE IN FILE');
                      --dbms_output.put_line(DBMS_LOB.GETLENGTH(l_skus_request));
                    utl_file.put_line(l_sku_csv_file,l_skus_request);
                    --dbms_output.put_line('END WRITE IN FILE');
                END IF;
                END IF;
                END IF;
                end loop;
        utl_file.put_line(l_sku_csv_file,']}'); 
        --update hbg_cx_items_execution_tracker set request = request || ']}' where instanceid = p_instance_id; 
        utl_file.fclose(l_sku_csv_file);   
        IF l_call_api = 1 THEN

            l_file_blob := file_to_blob(l_sku_filename);
            IF l_file_blob IS NULL THEN
                errbuf := 'Failed convert SKU file to blob';
                RAISE failed_import;
            END IF;

        -----TEST FILES SCRIPT------
           -- teste := utl_file.fopen(g_directory, l_collections_filename, 'R');
            /*read_teste := NULL;
            LOOP
                BEGIN
                    utl_file.get_line(teste, teste_row);
                    read_teste := read_teste || to_clob(teste_row);
               --dbms_output.put_line(read_teste);
                EXCEPTION
                    WHEN no_data_found THEN
                        EXIT;
                END;
            END LOOP;  */


            --insert into hbg_cx_items_execution_tracker (request) values (l_file_b64);
            --get cx api access token
            l_access_token := get_api_access_token;
            IF l_access_token IS NULL THEN
                errbuf := 'Failed to get access token';
                RAISE failed_import;
            END IF;
             l_file_token := start_file_upload_api(l_access_token, l_file_blob, l_sku_filename);
            IF l_file_token IS NULL THEN
                errbuf := 'Failed to upload the file to CX';
                RAISE failed_import;
            END IF;
            dbms_output.put_line('l_process_id=' || l_file_token);


             l_process_id := execute_bulk_import_api(l_access_token, 'ProductsV2');
            IF l_process_id IS NULL THEN
                errbuf := 'Failed to execute the import process';
                RAISE failed_import;
            END IF;

            dbms_output.put_line('l_process_id=' || l_process_id);
            get_import_process_api(p_user_token => l_access_token, p_process_id => l_process_id, l_json_report_clob => l_json_report_clob,
            l_failed_records_clob => l_failed_records_clob, l_failure_count => l_failure_count,
                                  errbuf => l_errbuf, retcode => l_retcode);  

            IF l_retcode = 1 THEN
                errbuf := 'Failed to retrieve products/skus import process information - ' || l_errbuf;
                RAISE failed_import;
            END IF;

            --l_import_total := import_assets_ui(l_access_token,l_file_token);
            IF l_failure_count > 0 THEN
                retcode := 2;

           INSERT INTO hbg_cx_items_json_report
                    ( SELECT
                        json.comments,
                        ROWNUM        AS row_number,
                        p_instance_id AS instanceid
                    FROM
                            JSON_TABLE ( l_json_report_clob, '$.failureExceptions[*]'
                                COLUMNS (
                                    comments VARCHAR2 ( 2000 ) PATH '$.localizedMessage'
                                )
                            )
                        AS json
                    );

                INSERT INTO hbg_cx_items_failed_rec
                    ( SELECT
                        json.product_id,
                        ROWNUM        AS line_number,
                        p_instance_id AS instanceid
                    FROM
                            JSON_TABLE ( l_failed_records_clob, '$.product[*]'
                                COLUMNS (
                                    product_id VARCHAR2 ( 100 ) PATH '$.id'
                                )
                            )
                        json
                    );

                COMMIT;
                retcode := 2;
        --dbms_output.put_line('insert to table');
                BEGIN 

                    UPDATE hbg_cx_items_extract item
                    SET STATUS = STATUS || 'ERROR_SKU',
                        comments = comments || (
                            SELECT DISTINCT
                                'ERROR_SKU - '
                                || json.comments
                            FROM
                                hbg_cx_items_failed_rec  failed_records,
                                hbg_cx_items_json_report json
                            WHERE
                                    json.line_number = failed_records.line_number
                                AND failed_records.product_id = item.isbn
                                AND failed_records.instanceid = p_instance_id
                                AND json.instanceid = p_instance_id
                        )
                    WHERE
                            instanceid = p_instance_id
                        AND status <> 'SKIPPED';

                    COMMIT;

                    UPDATE hbg_cx_items_cntb_extract cntb
                    SET STATUS = 'ERROR',
                        comments = 'ERROR: Failed to import SKU - check Item Extract for more information'
                    WHERE
                            instanceid = p_instance_id
                        AND status <> 'SKIPPED'
                        AND ISBN IN (SELECT product_id FROM hbg_cx_items_failed_rec WHERE instanceid  = p_instance_id);

                    COMMIT;

                     EXCEPTION
                    WHEN OTHERS THEN
                        errbuf := 'Failed to update items extract table with error details - ' || sqlerrm;
                        retcode := 1;
                    END;

                    END IF;

                --dbms_output.put_line('create in mirror table');
                --UPDATE MIRROR TABLE
                begin 
                    DELETE FROM hbg_cx_items_validation_rpt stg
                    WHERE EXISTS (SELECT json.PRODUCT_ID FROM hbg_cx_items_failed_rec json WHERE json.product_id = stg.sku_id)
                    AND INSTANCEID = p_instance_id;
                    commit;

                    UPDATE (SELECT
                        rpt.active rpt_active ,
                        rpt.display_name rpt_display_name,
                        rpt.long_description rpt_long_description,
                        rpt.author_name rpt_author_name,
                        rpt.imprint rpt_imprint,
                        rpt.publisher rpt_publisher,
                        substr(rpt.publication_date,1,10) rpt_publication_date ,
                        rpt.series rpt_series,
                        rpt.series_number rpt_series_number,
                        rpt.sub_product rpt_sub_product,
                        rpt.sub_title rpt_sub_title,
                        rpt.owner rpt_owner,
                        rpt.reporting_group rpt_reporting_group,
                        rpt.primary_product rpt_primary_product,
                        rpt.author_list rpt_author_list,
                        rpt.edition rpt_edition,
                        rpt.external_imprint rpt_external_imprint,
                        rpt.pub_status rpt_pub_status,
                        rpt.book_type rpt_book_type,
                        rpt.CUSTOMER_SPECIFIC_CODE rpt_cust_code,
                        rpt.CUSTOMER_SPECIFIC_DESC rpt_cust_desc,
                        sysdate,
                        cx.active cx_active,
                        cx.display_name cx_display_name,
                        cx.long_description cx_long_description,
                        cx.author_name cx_author_name, 
                        cx.imprint cx_imprint,
                        cx.publisher cx_publisher,
                        cx.publication_date cx_publication_date,
                        cx.series cx_series,
                        cx.series_number cx_series_number,
                        cx.sub_product cx_sub_product,
                        cx.sub_title cx_sub_title,
                        cx.owner cx_owner,
                        cx.reporting_group cx_reporting_group,
                        cx.primary_flag cx_primary_flag,
                        cx.edition cx_edition,
                        cx.external_imprint cx_external_imprint,
                        cx.author_list cx_author_list,
                        cx.format cx_format,
                        cx.pub_status cx_pub_status,
                        cx.CUSTOMER_SPECIFIC_CODE cx_cust_code,
                        cx.CUSTOMER_SPECIFIC_DESC cx_cust_desc,
                        cx.last_update_date cx_last_update_date
                    FROM
                        hbg_cx_items_validation_rpt rpt,
                        hbg_cx_items_products_skus  cx
                    WHERE
                        cx.sku_id = rpt.sku_id 
                        and instanceid = p_instance_id) 

                        set cx_active  = rpt_active,
                        cx_display_name = rpt_display_name,
                        cx_long_description = rpt_long_description,
                        cx_author_name = rpt_author_name,
                        cx_imprint = rpt_imprint,
                        cx_publisher = rpt_publisher,
                        cx_publication_date = rpt_publication_date,
                        cx_series = rpt_series,
                        cx_series_number = rpt_series_number,
                        cx_sub_product = rpt_sub_product,
                        cx_sub_title = rpt_sub_title,
                        cx_owner = rpt_owner,
                        cx_reporting_group = rpt_reporting_group,
                        cx_primary_flag = rpt_primary_product,
                        cx_edition = rpt_edition,
                        cx_external_imprint = rpt_external_imprint,
                        cx_author_list = rpt_author_list,
                        cx_format = rpt_book_type,
                        cx_pub_status = rpt_pub_status,
                        cx_cust_code = rpt_cust_code,
                        cx_cust_desc = rpt_cust_desc,
                        cx_last_update_date = sysdate;

                    COMMIT;
                EXCEPTION
                    WHEN OTHERS THEN
            --dbms_output.put_line('failed to update mirror table');
                        errbuf := 'Failed to update CX mirror table';
                        retcode := 1;
                END;
                                BEGIN
                                    INSERT INTO hbg_cx_items_products_skus (
                                        sku_id,
                                        active,
                                        display_name,
                                        long_description,
                                        author_name,
                                        imprint,
                                        publisher,
                                        publication_date,
                                        series,
                                        series_number,
                                        sub_product,
                                        sub_title,
                                        owner,
                                        reporting_group,
                                        primary_flag,
                                        author_list,
                                        edition,
                                        external_imprint,
                                        pub_status,
                                        format,
                                        CUSTOMER_SPECIFIC_CODE,
                                        CUSTOMER_SPECIFIC_DESC,
                                        creation_date,
                                        last_update_date
                                    ) 

                                    SELECT 
                                           rpt.sku_id,
                                           rpt.active,
                                           rpt.DISPLAY_NAME,
                                           rpt.long_Description,
                                           rpt.author_name,
                                           rpt.imprint,
                                           rpt.publisher,
                                           substr(rpt.publication_date,1,10),
                                           rpt.series,
                                           rpt.series_number,
                                           rpt.sub_product,
                                           rpt.sub_title,
                                           rpt.owner,
                                           rpt.reporting_group,
                                           rpt.primary_Product,
                                           rpt.author_List,
                                           rpt.edition,
                                           rpt.external_Imprint,
                                           rpt.pub_Status,
                                           rpt.book_Type,
                                           rpt.CUSTOMER_SPECIFIC_CODE,
                                           rpt.CUSTOMER_SPECIFIC_DESC,
                                           sysdate,
                                           sysdate
                                           from hbg_cx_items_validation_rpt rpt
                                           where
                                           rpt.sku_id not in (select sku_id from hbg_cx_items_products_skus)
                                           AND rpt.instanceid = p_instance_id;

                                    COMMIT;
                                EXCEPTION
                                    WHEN OTHERS THEN
                            --dbms_output.put_line('failed to update mirror table');
                                        errbuf := 'Failed to update CX mirror table';
                                        retcode := 1;
                                END;
                --dbms_output.put_line('update in mirror table');

                EXECUTE IMMEDIATE 'TRUNCATE TABLE HBG_CX_ITEMS_FAILED_REC';
                EXECUTE IMMEDIATE 'TRUNCATE TABLE HBG_CX_ITEMS_JSON_REPORT';
                --DELETE FROM hbg_cx_items_validation_rpt;
                --COMMIT;
            END IF;

        UTL_FILE.FREMOVE (g_directory,l_sku_filename);

      --UPDATE EXTRACT TABLE
        BEGIN
            UPDATE hbg_cx_items_extract
            SET
                comments = 'SKU_PROCESSED;',
                status = 'SKU_PROCESSED;'
            WHERE
                    instanceid = p_instance_id
                AND ( status NOT LIKE '%SKU%'
                      AND status NOT LIKE '%SKIPPED%' );

             UPDATE hbg_cx_items_cntb_extract
            SET
                comments = NULL,
                status = 'SUCCESS'
            WHERE
                    instanceid = p_instance_id
                AND status = 'NEW';

            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                errbuf := 'Failed to update skus extract table status';
                retcode := 1;
        END;

        IF retcode = 2 THEN
            errbuf := 'Failed to import some skus';
        END IF;

    EXCEPTION
        WHEN failed_import THEN
            --dbms_output.put_line('FAILED IMPORT' || errbuf);
            retcode := 1;
            UPDATE hbg_cx_items_extract
            SET
                comments = comments
                           || 'ERROR_SKU: '
                           || errbuf
                           || ';',
                status = status || 'ERROR_SKU;'
            WHERE
                ( status NOT LIKE '%SKU%'
                  AND status NOT LIKE '%SKIPPED%' )
                AND instanceid = p_instance_id;

            COMMIT;
        WHEN OTHERS THEN
            errbuf := sqlerrm;
            UPDATE hbg_cx_items_extract
            SET
                comments = comments
                           || 'ERROR_SKU: '
                           || errbuf
                           || ';',
                status = status || 'ERROR_SKU;'
            WHERE
                ( status NOT LIKE '%SKU%'
                  AND status NOT LIKE '%SKIPPED%' )
                AND instanceid = p_instance_id;

            COMMIT;
            --dbms_output.put_line('sqlerrm=' || sqlerrm);
            retcode := 1;
    END import_skus;

  --/*************************************************************************
  -- Import Related Items Procedure 
  --*************************************************************************/

  PROCEDURE import_related_items (
        p_instance_id IN NUMBER,
        p_user_token  IN VARCHAR2,
        errbuf        OUT VARCHAR2,
        retcode       OUT VARCHAR2
    ) AS

        l_errbuf        VARCHAR2(150);
        l_retcode       VARCHAR2(1);

    --Authentication Token 
        l_access_token  VARCHAR2(4000);

    --api variables
        l_items_request     CLOB;
        l_response_clob     CLOB;
        l_item_file         utl_file.file_type;
        l_item_filename     VARCHAR2(50) := 'ProductsV2.json';
        l_product_id        VARCHAR2(50) := 'first_rec';
        l_items_blob        BLOB;
        l_file_token          VARCHAR2(100);
        l_process_id          VARCHAR2(100);
        l_file_blob         BLOB;
        l_first_rec         NUMBER := 0;
        l_first_item        NUMBER := 0;
        l_first_related     NUMBER := 0;
        l_json_report_clob    CLOB;
        l_failed_records_clob CLOB;
        l_failure_count       NUMBER;
    --exception
        failed_import EXCEPTION;
    BEGIN
        errbuf := NULL;
        retcode := 0;
    --Create Skus Json file

        --skus loop
        l_item_file := utl_file.fopen(g_directory, l_item_filename, 'W', 32767);
        utl_file.put_line(l_item_file,'{"product": [');
        update hbg_cx_items_execution_tracker set request = '{"product": [' where instanceid = p_instance_id;
        commit;
        DELETE FROM HBG_CX_ITEMS_VALIDATION_RPT rpt where sku_id in 
        (select rpt.sku_id from HBG_CX_ITEMS_VALIDATION_RPT rpt, hbg_cx_items_products_skus cx
        where rpt.sku_id = cx.sku_id and rpt.product_id = cx.parentid);
        commit;

        FOR rws IN (
                SELECT distinct rpt1.SKU_ID, rpt1.product_id, rpt2.sku_id as related_item
                    FROM 
                    HBG_CX_ITEMS_VALIDATION_RPT rpt1,
                    HBG_CX_ITEMS_VALIDATION_RPT rpt2
                    where rpt1.product_id = rpt2.product_id
                    and rpt1.sku_id <> rpt2.sku_id

                    union

                SELECT distinct cx1.SKU_ID, cx1.PARENTID, cx2.sku_id as related_item
                    FROM 
                    HBG_CX_ITEMS_PRODUCTS_SKUS cx1,
                    HBG_CX_ITEMS_PRODUCTS_SKUS cx2
                    where cx1.parentid = cx2.parentid
                    and cx1.sku_id <> cx2.sku_id
                    and cx1.parentid in (SELECT PRODUCT_ID FROM HBG_CX_ITEMS_VALIDATION_RPT)
                    AND cx1.sku_id not in (SELECT SKU_ID FROM HBG_CX_ITEMS_VALIDATION_RPT )
                    AND cx2.sku_id not in (SELECT SKU_ID FROM HBG_CX_ITEMS_VALIDATION_RPT )

                    UNION

                    select rpt.sku_id, rpt.product_id, cx.sku_id as related_item
                    from HBG_CX_ITEMS_VALIDATION_RPT rpt,
                        HBG_CX_ITEMS_PRODUCTS_SKUS cx
                        where rpt.product_id = cx.parentid

                    union 

                    select cx.sku_id, cx.parentid, rpt.sku_id as related_item
                    from HBG_CX_ITEMS_VALIDATION_RPT rpt,
                        HBG_CX_ITEMS_PRODUCTS_SKUS cx
                        where rpt.product_id = cx.parentid

                    union 

                    select cx1.sku_id, cx1.parentid, 
                    case when cx2.sku_id in (select sku_id from HBG_CX_ITEMS_VALIDATION_RPT ) then null else cx2.sku_id end as related_item
                    from HBG_CX_ITEMS_PRODUCTS_SKUS cx1,
                        HBG_CX_ITEMS_PRODUCTS_SKUS cx2
                    where cx1.parentid = cx2.parentid 
                    and cx1.sku_id <> cx2.sku_id
                    and cx1.parentid in (select cx.parentid from HBG_CX_ITEMS_PRODUCTS_SKUS cx,
                    HBG_CX_ITEMS_VALIDATION_RPT rpt where cx.sku_id = rpt.sku_id and cx.parentid <> rpt.product_id)
                    and cx1.sku_id not in (select sku_id from HBG_CX_ITEMS_VALIDATION_RPT )

                    UNION

                    SELECT SKU_ID, PRODUCT_ID, NULL
                    FROM HBG_CX_ITEMS_VALIDATION_RPT
                    WHERE PRODUCT_ID NOT IN (select parentid from HBG_CX_ITEMS_PRODUCTS_SKUS)
                    order by sku_id, RELATED_ITEM

            )

        LOOP

            if rws.sku_id <> l_product_id THEN
                IF l_first_rec > 0 THEN
                    utl_file.put_line(l_item_file, ']}');
                    update hbg_cx_items_execution_tracker set request = request || ']}' where instanceid = p_instance_id;
                    commit;
                ELSE 
                    l_first_rec := 1;
                END IF;
               l_product_id := rws.sku_id;

               if l_first_item > 0 then
                    utl_file.put_line(l_item_file, ',{"id" : "' || rws.sku_id ||'","relatedProducts" : [');
                    update hbg_cx_items_execution_tracker set request = request || ',{"id" : "' || rws.sku_id ||'","relatedProducts" : [' where instanceid = p_instance_id;
                    commit;
                else    
                    utl_file.put_line(l_item_file, '{ "id": "' || rws.sku_id ||'","relatedProducts" : [');
                    update hbg_cx_items_execution_tracker set request = request || '{"id" : "' || rws.sku_id ||'","relatedProducts" : [' where instanceid = p_instance_id;
                    commit;

                    l_first_item :=1;    
                end if;
               l_first_related := 0;
            end if;
             if l_first_related > 0 then
                    if rws.related_item is not null then
                        utl_file.put_line(l_item_file, ',{"id": "'|| rws.related_item ||'"}');
                        update hbg_cx_items_execution_tracker set request = request || ',{"id": "'|| rws.related_item ||'"}' where instanceid = p_instance_id;
                        commit;
                    end if;
                else
                    if rws.related_item is not null then
                        utl_file.put_line(l_item_file, '{"id": "'|| rws.related_item ||'"}');
                        update hbg_cx_items_execution_tracker set request = request || '{"id": "'|| rws.related_item ||'"}' where instanceid = p_instance_id;
                        commit;
                    end if;
                    l_first_related := 1;
                end if;    
        END LOOP;
        utl_file.put_line(l_item_file, ']}]}');
        update hbg_cx_items_execution_tracker set request = request || ']}]}' where instanceid = p_instance_id;
        utl_file.fclose(l_item_file);
        --get blob from files
        l_items_blob := file_to_blob(l_item_filename);
        IF l_items_blob IS NULL THEN
            errbuf := 'Failed to convert collections file to blob';
            RAISE failed_import;
        END IF;
         --get cx api access token
        l_access_token := get_api_access_token;
        IF l_access_token IS NULL THEN
            errbuf := 'Failed to get access token';
            RAISE failed_import;
        END IF;

        l_file_token := start_file_upload_api(l_access_token, l_items_blob, l_item_filename);
        IF l_file_token IS NULL THEN
            errbuf := 'Failed to upload the file to CX';
            RAISE failed_import;
        END IF;
        dbms_output.put_line('l_process_id=' || l_file_token);

         l_process_id := execute_bulk_import_api(l_access_token, 'ProductsV2');
            IF l_process_id IS NULL THEN
                errbuf := 'Failed to execute the import process';
                RAISE failed_import;
            END IF;

        dbms_output.put_line('l_process_id=' || l_process_id);
            get_import_process_api(p_user_token => l_access_token, p_process_id => l_process_id, l_json_report_clob => l_json_report_clob,
            l_failed_records_clob => l_failed_records_clob, l_failure_count => l_failure_count,
                                  errbuf => l_errbuf, retcode => l_retcode);  
        IF l_failure_count > 0 THEN
                retcode := 2;

                INSERT INTO hbg_cx_items_json_report
                    ( SELECT
                        json.comments,
                        ROWNUM        AS row_number,
                        p_instance_id AS instanceid
                    FROM
                            JSON_TABLE ( l_json_report_clob, '$.failureExceptions[*]'
                                COLUMNS (
                                    comments VARCHAR2 ( 2000 ) PATH '$.localizedMessage'
                                )
                            )
                        AS json
                    );

                INSERT INTO hbg_cx_items_failed_rec
                    ( SELECT
                        json.product_id,
                        ROWNUM        AS line_number,
                        p_instance_id AS instanceid
                    FROM
                            JSON_TABLE ( l_failed_records_clob, '$.product[*]'
                                COLUMNS (
                                    product_id VARCHAR2 ( 100 ) PATH '$.id'
                                )
                            )
                        json
                    );

                COMMIT;
                retcode := 2;
                BEGIN
                    UPDATE hbg_cx_items_extract item
                    SET STATUS = STATUS || 'ERROR_RELATED_ITEMS',
                        comments = comments || (
                            SELECT DISTINCT
                                'ERROR_RELATED_ITEMS - '
                                || json.comments
                            FROM
                                hbg_cx_items_failed_rec  failed_records,
                                hbg_cx_items_json_report json
                            WHERE
                                    json.line_number = failed_records.line_number
                                AND failed_records.product_id = item.isbn
                                AND failed_records.instanceid = p_instance_id
                                AND json.instanceid = p_instance_id
                        )
                    WHERE
                            instanceid = p_instance_id
                        AND status <> 'SKIPPED';
                        COMMIT;
                     EXCEPTION
                    WHEN OTHERS THEN
                        errbuf := 'Failed to update item extract table with related items error details - ' || sqlerrm;
                        retcode := 1;
                    END;
                END IF;
                begin
                 DELETE FROM HBG_CX_ITEMS_VALIDATION_RPT rpt
                    WHERE EXISTS (SELECT json.PRODUCT_ID FROM hbg_cx_items_failed_rec json WHERE json.product_id = rpt.sku_id);
                    commit;

                UPDATE HBG_CX_ITEMS_PRODUCTS_SKUS cx SET PARENTID = (SELECT PRODUCT_ID 
                                                                        FROM HBG_CX_ITEMS_VALIDATION_RPT rpt 
                                                                        WHERE rpt.sku_id = cx.sku_id )
                where exists (SELECT SKU_ID FROM HBG_CX_ITEMS_VALIDATION_RPT rpt WHERE rpt.sku_id = cx.sku_id);
                COMMIT;
                EXCEPTION
                    WHEN OTHERS THEN
                        errbuf := 'Failed to update related items mirror table - ' || sqlerrm;
                        retcode := 1;
                    END;   

                 --UPDATE EXTRACT TABLE
            BEGIN
                UPDATE hbg_cx_items_extract
                SET
                    comments = COMMENTS || NULL,
                    status = status || 'RELATED_ITEMS_PROCESSED;'
                WHERE
                    instanceid = p_instance_id
                    AND ( status NOT LIKE '%ERROR_RELATED_ITEMS%'
                      AND status NOT LIKE '%SKIPPED%' );

                COMMIT;
            EXCEPTION
                WHEN OTHERS THEN
                    errbuf := 'Failed to update related items extract table status - ' || sqlerrm;
                    retcode := 1;
            END;

            EXECUTE IMMEDIATE 'TRUNCATE TABLE HBG_CX_ITEMS_VALIDATION_RPT';
        IF retcode = 2 THEN
            errbuf := 'Failed to import related items';
        END IF;
    EXCEPTION
        WHEN failed_import THEN
            retcode := 1;
            UPDATE hbg_cx_items_extract
            SET
                comments = comments
                           || 'ERROR_RELATED_ITEMS: '
                           || errbuf
                           || ';',
                status = status || 'ERROR_RELATED_ITEMS;'
            WHERE
                status NOT LIKE '%RELATED_ITEMS%'
                AND instanceid = p_instance_id;

            COMMIT;
        WHEN OTHERS THEN
            errbuf := sqlerrm;
            retcode := 1;
            UPDATE hbg_cx_items_extract
            SET
                comments = comments
                           || 'ERROR_RELATED_ITEMS: '
                           || errbuf
                           || ';',
                status = status || 'ERROR_RELATED_ITEMS;'
            WHERE
                ( status NOT LIKE '%RELATED_ITEMS%'
                      AND status NOT LIKE '%SKIPPED%' )
                AND instanceid = p_instance_id;

            COMMIT;

    end import_related_items;
    --/*************************************************************************
  -- Import Price Procedure 
  --*************************************************************************/

    PROCEDURE import_prices (
        p_instance_id IN NUMBER,
        p_user_token  IN VARCHAR2,
        errbuf        OUT VARCHAR2,
        retcode       OUT VARCHAR2
    ) AS

        l_errbuf              VARCHAR2(500);
        l_retcode             NUMBER;

    --Authentication Token 
        l_access_token        VARCHAR2(5000);

    --Create price File
        l_prices_json_file    utl_file.file_type;
        l_prices_filename     VARCHAR2(50) := 'Prices.json';
        l_prices_blob         BLOB;

    --api variables
        l_price_request       VARCHAR2(4000);
        l_response_clob       CLOB;
        countrws              VARCHAR2(5) := 'true';
        mytime                TIMESTAMP;
        l_offset              INT := 1;
        l_file_token          VARCHAR2(100);
        l_process_id          VARCHAR2(100);
        l_json_report_clob    CLOB;
        l_failed_records_clob CLOB;
        l_failure_count       NUMBER;
        l_count               NUMBER;
        l_error_count         NUMBER;

    --exception
        failed_import EXCEPTION;
       -----TEST FILES VARIABLES-------
        teste                 utl_file.file_type;
        read_teste            CLOB;
        blob_test             BLOB;
        teste_row             VARCHAR2(4000);
    BEGIN
        --dbms_output.put_line(mytime);
        mytime := systimestamp;
        errbuf := NULL;
        retcode := 0;
    /*UPDATE hbg_cx_items_price_extract 
        SET STATUS = 'SKIPPED' 
        WHERE   item_code NOT IN (SELECT SKU_ID FROM HBG_CX_ITEMS_PRODUCTS_SKUS)
            AND INSTANCEID = p_instance_id;
    COMMIT;*/
        SELECT
            COUNT(item_code)
        INTO l_count
        FROM
            hbg_cx_items_price_extract
        WHERE
                status = 'NEW'
            AND instanceid = p_instance_id;

        IF l_count > 0 THEN
        --Create Skus Json file
            l_prices_json_file := utl_file.fopen(g_directory, l_prices_filename, 'W');
        --skus loop
            FOR rws IN (
                SELECT DISTINCT
                    item_code                                                                 AS sku_id,
                    nvl(rtrim(to_char(round(price.usd_msrp, 2), 'FM999999999990.99'), '.'), 0) AS usd_price,
                    nvl(rtrim(to_char(round(price.cad_msrp, 2), 'FM999999999990.99'), '.'), 0) AS cad_price,
                    nvl(rtrim(to_char(round(price.usd_msrp * dis.discount, 2), 'FM999999999990.99'), '.'), 0) AS usd_discount_price,
                    nvl(rtrim(to_char(round(price.cad_msrp * dis.discount, 2), 'FM999999999990.99'), '.'), 0) AS cad_discount_price
                FROM
                    hbg_cx_items_price_report price,
                    hbg_cx_items_report item,
                    hbg_cx_items_discounts dis
                WHERE
                        price.status = 'NEW'
                        and price.item_code = item.isbn (+)
                        and item.reporting_group_code = dis.reporting_group_code (+)
                        and item.owner_code = dis.owner_code (+)
                    AND price.instanceid = p_instance_id
                    and item.instanceid (+) = p_instance_id
                ORDER BY
                    sku_id
            ) LOOP
            --dbms_output.put_line(rws.sku_id);
                IF countrws = 'true' THEN
                    l_price_request := '{"price" : [{"productId" : "'
                                       || rws.sku_id
                                       || '","skuId" : "'
                                       || rws.sku_id
                                       || '","priceListId" : "giftingPrice_listPrices","listPrice" : '
                                       || rws.usd_price
                                       || ',"pricingScheme":"listPrice"},{"productId" : "'
                                       || rws.sku_id
                                       || '","skuId" : "'
                                       || rws.sku_id
                                       || '","priceListId" : "listPrices","listPrice" : '
                                       || rws.usd_price
                                       || ',"pricingScheme":"listPrice"},{"productId" : "'
                                       || rws.sku_id
                                       || '","skuId" : "'
                                       || rws.sku_id
                                       || '","priceListId" :  "canadianPriceGroup_listPrices","listPrice" : '
                                       || rws.cad_price
                                       || ',"pricingScheme":"listPrice"},{"productId" : "'
                                       || rws.sku_id
                                       || '","skuId" : "'
                                       || rws.sku_id
                                       || '","priceListId" : "giftingPriceCAD_listPrices","listPrice" : '
                                       || rws.cad_price
                                       || ',"pricingScheme":"listPrice"},{"productId" : "'
                                       || rws.sku_id
                                       || '","skuId" : "'
                                       || rws.sku_id
                                       || '","priceListId" : "employeePriceCAD_listPrices","listPrice" : '
                                       || rws.cad_price
                                       || ',"pricingScheme":"listPrice"},{"productId" : "'
                                       || rws.sku_id
                                       || '","skuId" : "'
                                       || rws.sku_id
                                       || '","priceListId" : "giftingPriceCAD_salePrices","listPrice" : '
                                       || rws.cad_discount_price
                                       || ',"pricingScheme":"listPrice"},{"productId" : "'
                                       || rws.sku_id
                                       || '","skuId" : "'
                                       || rws.sku_id
                                       || '","priceListId" : "employeePriceUSD_listPrices","listPrice" : '
                                       || rws.usd_price
                                       || ',"pricingScheme":"listPrice"},{"productId" : "'
                                       || rws.sku_id
                                       || '","skuId" : "'
                                       || rws.sku_id
                                       || '","priceListId" : "employeePriceUSD_salePrices","listPrice" : '
                                       || rws.usd_discount_price
                                       || ',"pricingScheme":"listPrice"}';

                    countrws := 1;
                --dbms_output.put_line(' countRWS := 0');
                    utl_file.put_line(l_prices_json_file, l_price_request);
                ELSE
                    l_price_request := ',{"productId" : "'
                                       || rws.sku_id
                                       || '","skuId" : "'
                                       || rws.sku_id
                                       || '","priceListId" : "giftingPrice_listPrices","listPrice" : '
                                       || rws.usd_price
                                       || ',"pricingScheme":"listPrice"},{"productId" : "'
                                       || rws.sku_id
                                       || '","skuId" : "'
                                       || rws.sku_id
                                       || '","priceListId" : "listPrices","listPrice" : '
                                       || rws.usd_price
                                       || ',"pricingScheme":"listPrice"},{"productId" : "'
                                       || rws.sku_id
                                       || '","skuId" : "'
                                       || rws.sku_id
                                       || '","priceListId" :  "canadianPriceGroup_listPrices","listPrice" : '
                                       || rws.cad_price
                                       || ',"pricingScheme":"listPrice"},{"productId" : "'
                                       || rws.sku_id
                                       || '","skuId" : "'
                                       || rws.sku_id
                                       || '","priceListId" : "giftingPriceCAD_listPrices","listPrice" : '
                                       || rws.cad_price
                                       || ',"pricingScheme":"listPrice"},{"productId" : "'
                                       || rws.sku_id
                                       || '","skuId" : "'
                                       || rws.sku_id
                                       || '","priceListId" : "employeePriceCAD_listPrices","listPrice" : '
                                       || rws.cad_price
                                       || ',"pricingScheme":"listPrice"},{"productId" : "'
                                       || rws.sku_id
                                       || '","skuId" : "'
                                       || rws.sku_id
                                       || '","priceListId" : "giftingPriceCAD_salePrices","listPrice" : '
                                       || rws.cad_discount_price
                                       || ',"pricingScheme":"listPrice"},{"productId" : "'
                                       || rws.sku_id
                                       || '","skuId" : "'
                                       || rws.sku_id
                                       || '","priceListId" : "employeePriceUSD_listPrices","listPrice" : '
                                       || rws.usd_price
                                       || ',"pricingScheme":"listPrice"},{"productId" : "'
                                       || rws.sku_id
                                       || '","skuId" : "'
                                       || rws.sku_id
                                       || '","priceListId" : "employeePriceUSD_salePrices","listPrice" : '
                                       || rws.usd_discount_price
                                       || ',"pricingScheme":"listPrice"}';

                    utl_file.put_line(l_prices_json_file, l_price_request);
                END IF;
            END LOOP;

            utl_file.put_line(l_prices_json_file, ']}');
            utl_file.fclose(l_prices_json_file);

            -----TEST FILES SCRIPT------
            teste := utl_file.fopen(g_directory, l_prices_filename, 'R');
            read_teste := NULL;
            LOOP
                BEGIN
                    utl_file.get_line(teste, teste_row);
                    read_teste := read_teste || to_clob(teste_row);
               --dbms_output.put_line(read_teste);
                EXCEPTION
                    WHEN no_data_found THEN
                        EXIT;
                END;
            END LOOP;

           /* UPDATE hbg_cx_items_execution_tracker
            SET
                request = read_teste
            WHERE
                instanceid = p_instance_id;

            COMMIT;*/
             --get blob from files
            l_prices_blob := file_to_blob(l_prices_filename);
            IF l_prices_blob IS NULL THEN
                errbuf := 'Failed to convert price file to blob';
                RAISE failed_import;
            END IF;

            --get cx api access token
            l_access_token := get_api_access_token;
            IF l_access_token IS NULL THEN
                errbuf := 'Failed to get access token';
                RAISE failed_import;
            END IF;
            --dbms_output.put_line('access_token=' || l_access_token);

             -- upload the file to cx
            l_file_token := start_file_upload_api(l_access_token, l_prices_blob, l_prices_filename);
            IF l_file_token IS NULL THEN
                errbuf := 'Failed to upload the file to CX';
                RAISE failed_import;
            END IF;
            --dbms_output.put_line('file_token=' || l_file_token);

           -- execute bulk import 
            l_process_id := execute_bulk_import_api(l_access_token, 'Prices');
            IF l_process_id IS NULL THEN
                errbuf := 'Failed to execute the import process';
                RAISE failed_import;
            END IF;
            get_import_process_api(p_user_token => l_access_token, p_process_id => l_process_id, l_json_report_clob => l_json_report_clob,
            l_failed_records_clob => l_failed_records_clob, l_failure_count => l_failure_count,
                                  errbuf => l_errbuf, retcode => l_retcode);

          /* UPDATE HBG_CX_ITEMS_EXECUTION_TRACKER
           SET REQUEST = read_teste
           WHERE INSTANCEID = p_instance_id;*/
            IF l_retcode = 1 THEN
                errbuf := 'Failed to retrieve price import process information - ' || l_errbuf ;
                RAISE failed_import;
            END IF;
            IF l_failure_count > 0 THEN
                retcode := 2;

           /* FOR rws IN (SELECT
                                json.skuId, json.priceListId, rownum as line_number
                               FROM
                                JSON_TABLE ( l_failed_records_clob, '$.price[*]'
                                COLUMNS(
                                    skuId       VARCHAR2(100)   PATH '$.skuId',
                                    priceListId VARCHAR2(100)   PATH '$.priceListId'
                                        ))json
                                        order by json.skuId)
            LOOP
                dbms_output.put_line('skuId = ' || rws.skuId || ' priceListId = ' || rws.priceListId ||  ' line_number = ' || rws.line_number);
            END LOOP;

           /* FOR rws IN (SELECT distinct 'ERROR - ' || LISTAGG(priceListId || ' - ' || a.comments, ';') over(partition by skuId) as comments, skuId
            from ( SELECT json.comments, failed_records.skuId, failed_records.priceListId FROM
                        (SELECT
                                json.skuId, json.priceListId, rownum as line_number
                               FROM
                                JSON_TABLE ( l_failed_records_clob, '$.price[*]'
                                COLUMNS(
                                    skuId       VARCHAR2(100)   PATH '$.skuId',
                                    priceListId VARCHAR2(100)   PATH '$.priceListId'
                                        ))json)failed_records,
                                  (SELECT
                                        json.comments, rownum as row_number
                                       FROM
                                        JSON_TABLE ( l_json_report_clob, '$.failureExceptions[*]'
                                        COLUMNS(
                                            comments VARCHAR2 ( 2000 ) PATH '$.localizedMessage'
                                        )
                                        )as json
                                        )json
                                    where json.row_number = failed_records.line_number
                                    )a, hbg_cx_items_price_extract price
                                    where price.item_code = skuId
                                    and price.instanceid = p_instance_id)
            LOOP
                dbms_output.put_line('comments = ' || rws.comments || ' skuId = ' || rws.skuId );
            END LOOP;*/
                INSERT INTO hbg_cx_items_price_json_report
                    ( SELECT
                        json.comments,
                        ROWNUM        AS row_number,
                        p_instance_id AS instanceid
                    FROM
                            JSON_TABLE ( l_json_report_clob, '$.failureExceptions[*]'
                                COLUMNS (
                                    comments VARCHAR2 ( 2000 ) PATH '$.localizedMessage'
                                )
                            )
                        AS json
                    );

                INSERT INTO hbg_cx_items_price_failed_rec
                    ( SELECT
                        json.skuid,
                        json.pricelistid,
                        ROWNUM        AS line_number,
                        p_instance_id AS instanceid
                    FROM
                            JSON_TABLE ( l_failed_records_clob, '$.price[*]'
                                COLUMNS (
                                    skuid VARCHAR2 ( 100 ) PATH '$.skuId',
                                    pricelistid VARCHAR2 ( 100 ) PATH '$.priceListId'
                                )
                            )
                        json
                    );

                COMMIT;
                retcode := 2;
                BEGIN
                    UPDATE hbg_cx_items_price_extract price
                    SET
                        comments = (
                            SELECT DISTINCT
                                'ERROR - '
                                || LISTAGG(failed_records.price_list_id
                                           || ' - '
                                           || json.comments, ';')
                                   OVER(PARTITION BY sku_id)
                            FROM
                                hbg_cx_items_price_failed_rec  failed_records,
                                hbg_cx_items_price_json_report json
                            WHERE
                                    json.line_number = failed_records.line_number
                                AND sku_id = price.item_code
                                AND failed_records.instanceid = p_instance_id
                                AND json.instanceid = p_instance_id
                        )
                    WHERE
                            instanceid = p_instance_id
                        AND status = 'NEW';

                    COMMIT;
                    UPDATE hbg_cx_items_price_extract price
                    SET
                        status = 'ERROR'
                    WHERE
                        comments IS NOT NULL
                        and status <> 'SKIPPED'
                        AND instanceid = p_instance_id;

                    DELETE FROM hbg_cx_items_price_failed_rec
                    WHERE
                        instanceid = p_instance_id;

                    DELETE FROM hbg_cx_items_price_json_report
                    WHERE
                        instanceid = p_instance_id;

                    COMMIT;
                EXCEPTION
                    WHEN OTHERS THEN
                        errbuf := 'Failed to update price extract table status - ' || sqlerrm;
                        retcode := 1;
                END;

            END IF;
                --dbms_output.put_line('update tables');
            BEGIN
                UPDATE hbg_cx_items_price_extract
                SET
                    status = 'SUCCESS'
                WHERE
                        status = 'NEW'
                    AND instanceid = p_instance_id;

                IF retcode = 2 THEN
                    errbuf := 'Failed to import some price data';
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    errbuf := 'Failed to update price extract table status';
                    retcode := 1;
            END;

        END IF;

    --dbms_output.put_line(systimestamp);
    --dbms_output.put_line(systimestamp - mytime );
    --end loop
   /* IF retcode = 1 THEN
        errbuf := 'Failed to import some price data';
    end if;*/
    EXCEPTION
        WHEN failed_import THEN
            retcode := 1;
            UPDATE hbg_cx_items_price_extract
            SET
                status = 'ERROR',
                comments = errbuf
            WHERE
                    status = 'NEW'
                AND instanceid = p_instance_id;

        WHEN OTHERS THEN
            errbuf := sqlerrm;
            retcode := 1;
            UPDATE hbg_cx_items_price_extract
            SET
                status = 'ERROR',
                comments = errbuf
            WHERE
                    status = 'NEW'
                AND instanceid = p_instance_id;

    END import_prices;

  --/*************************************************************************
  -- Import Collections Procedure  
  --*************************************************************************/

     PROCEDURE import_collections (
        p_instance_id IN NUMBER,
        p_user_token  IN VARCHAR2,
        errbuf        OUT VARCHAR2,
        retcode       OUT VARCHAR2
    ) AS

        l_errbuf              VARCHAR2(150);
        l_retcode             VARCHAR2(1);

    --Authentication Token 
        l_access_token        VARCHAR2(5000);

    --api variables
        l_collections_request VARCHAR2(4000);
        l_response_clob       CLOB;
        l_collection_id       VARCHAR2(30);
        l_comments            hbg_cx_items_extract.comments%TYPE;
        l_status              hbg_cx_items_extract.status%TYPE;
        l_error_code          VARCHAR2(30);
        l_err_message         VARCHAR2(4000);
        l_product_id          VARCHAR2(50) := 'first_rec';
        token_exception EXCEPTION;
        l_products_json       VARCHAR2(4000);

    --Create price File
        l_collections_json_file    utl_file.file_type;
        l_collections_filename     VARCHAR2(50) := 'ProductsV2.json';
        l_collections_blob         BLOB;
        l_col_count                NUMBER;
        l_prd_count                NUMBER;
        l_offset              INT := 1;
        l_file_token          VARCHAR2(100);
        l_process_id          VARCHAR2(100);
        l_json_report_clob    CLOB;
        l_failed_records_clob CLOB;
        l_failure_count       NUMBER;
        l_count               NUMBER;
        l_error_count         NUMBER;
        l_exists           NUMBER;
        l_create_col           VARCHAR2(5);
        l_first_rec         NUMBER := 0;
        l_new_flag          varchar2(5);
    --exception
        failed_import EXCEPTION;
    -----TEST FILES VARIABLES-------
        teste                 utl_file.file_type;
        read_teste            CLOB;
        blob_test             BLOB;
        teste_row             VARCHAR2(4000);
    BEGIN
        errbuf := NULL;
        retcode := 0;

     --get cx api access token
        l_access_token := get_api_access_token;
        IF l_access_token IS NULL THEN
            errbuf := 'Failed to get access token';
            RAISE failed_import;
        END IF;
        l_collections_json_file := utl_file.fopen(g_directory, l_collections_filename, 'W');
        utl_file.put_line(l_collections_json_file, '{"product": [');
        --update hbg_cx_items_execution_tracker set request = request || '{"product": [' where instanceid = p_instance_id;
                --commit;
       --dbms_output.put_line('access_token=' || l_access_token);
       l_prd_count := 0;

       BEGIN
        dbms_output.put_line('begin delete inactive collections');
           DELETE FROM HBG_CX_ITEMS_CATEGORIES cx WHERE product_id in 
            (SELECT ISBN 
                FROM     
                        HBG_CX_ITEMS_BISAC_EXTRACT bisac
                WHERE   
                        bisac.IS_ACTIVE = 0
                    AND bisac.instanceid = p_instance_id);
        dbms_output.put_line('end delete inactive collections');
            EXECUTE IMMEDIATE 'TRUNCATE TABLE HBG_CX_ITEMS_CATEGORIES_STG';
        dbms_output.put_line('truncate stg collections');
        EXCEPTION WHEN OTHERS THEN
            errbuf := 'Failed to validate active genres - ' || sqlerrm;
            RAISE failed_import;
        END;
    --collections loop
        FOR prd IN (
            SELECT DISTINCT
                item.isbn AS product_id,
                'allGifting'   AS category_id,
                CASE
                    WHEN col.product_id IS NULL THEN
                        'true'
                    ELSE
                        'false'
                END            AS new_flag
            FROM
                hbg_cx_items_extract    item,
                hbg_cx_items_categories col
            WHERE
                            --item.status = 'NEW'
                    item.instanceid = p_instance_id
                AND pub_status NOT IN ( 'NOP', 'PC', 'OP', 'OSI', 'OSF' )
                AND owner_code IN ( 'HB', 'CB', 'HU', 'OB', 'MS',
                                    'AB', 'PP', 'DP',
                                    'QS', 'KP', 'LP', 'YP' )
                AND publication_date IS NOT NULL
                --AND PUBLICATION_DATE <> '2050-01-01'
                AND format_code NOT IN ( 
                                            '25', -- CD-ROM Interactive
                                            '26', -- Online Services
                                            '30', -- CDROM Software
                                            '31', -- Shirts - Tee / Sweat
                                            '34', -- Foam Back Print (Poster)
                                            '38', -- Electronic Book
                                            '48', -- Miscellaneous Titles
                                            '49', -- Postage / Costing
                                            '50', -- Advance Reading Copy / Galleys
                                            '52', -- Boxed Set
                                            '55', -- Video - VHS
                                            '56', -- Video - DVD
                                            '57', -- Displays / Prepacks / Set
                                            '58', -- Dummy #
                                            '59', -- Assortment
                                            '66', -- Book "Other Format"
                                            '70', -- Instruments
                                            '77', -- Co-Publication / Special Royalty
                                            '79', -- Voice-controlled
                                            '81', -- Promotional Item - Non Distributed
                                            '82', -- Promotional Item - Distributed
                                            '83', -- Promo posters
                                            '84', -- Catalog - ISBN
                                            '85', -- Assorted Pallet Returns
                                            '86', -- Whse Use Only - ISBN
                                            '87', -- Music
                                            '88', -- Material / Non-Book Item
                                            '90', -- Digital Content
                                            '91', -- PT internal use only
                                            '92' -- Boxed Set - Non Saleable Component
                                          )
                AND ( sub_format_code NOT IN ( '32', --Downloadable (Audio)
                 '33', --Downloadable (Audio Library)
                 '37', --Playaway (Audio)
                 '38'  --Playaway (Audio Library)
                 )
                      OR sub_format_code IS NULL )
                AND col.product_id (+) = item.isbn
                AND col.category_id (+) = 'allGifting'
                AND ( ( item.owner_code = 'HU'
                        AND item.reporting_group_code <> 23
                        AND item.reporting_group_code <> 24
                        AND item.reporting_group_code <> 60 
                        AND item.reporting_group_code <> 61)
                      OR ( item.owner_code <> 'HU' ) )
            UNION ALL
            SELECT DISTINCT
                item.isbn AS product_id,
                'hbgGifting'   AS category_id,
                CASE
                    WHEN col.product_id IS NULL THEN
                        'true'
                    ELSE
                        'false'
                END            AS new_flag
            FROM
                hbg_cx_items_extract    item,
                hbg_cx_items_categories col
            WHERE
                            --item.status = 'NEW'
                    item.instanceid = p_instance_id
                AND pub_status NOT IN ( 'NOP', 'PC', 'OP', 'OSI', 'OSF' )
                --AND OWNER_CODE IN ('HB','CB','HU','OB','MS','AB','PP','GM','DP','HL','QS','KP','LP','YP')
                AND publication_date IS NOT NULL
                --AND PUBLICATION_DATE <> '2050-01-01'
                AND format_code NOT IN ( 
                                            '25', -- CD-ROM Interactive
                                            '26', -- Online Services
                                            '30', -- CDROM Software
                                            '31', -- Shirts - Tee / Sweat
                                            '34', -- Foam Back Print (Poster)
                                            '38', -- Electronic Book
                                            '48', -- Miscellaneous Titles
                                            '49', -- Postage / Costing
                                            '50', -- Advance Reading Copy / Galleys
                                            '52', -- Boxed Set
                                            '55', -- Video - VHS
                                            '56', -- Video - DVD
                                            '57', -- Displays / Prepacks / Set
                                            '58', -- Dummy #
                                            '59', -- Assortment
                                            '66', -- Book "Other Format"
                                            '70', -- Instruments
                                            '77', -- Co-Publication / Special Royalty
                                            '79', -- Voice-controlled
                                            '81', -- Promotional Item - Non Distributed
                                            '82', -- Promotional Item - Distributed
                                            '83', -- Promo posters
                                            '84', -- Catalog - ISBN
                                            '85', -- Assorted Pallet Returns
                                            '86', -- Whse Use Only - ISBN
                                            '87', -- Music
                                            '88', -- Material / Non-Book Item
                                            '90', -- Digital Content
                                            '91', -- PT internal use only
                                            '92' -- Boxed Set - Non Saleable Component
                                          )
                AND ( sub_format_code NOT IN ( '32', --Downloadable (Audio)
                 '33', --Downloadable (Audio Library)
                 '37', --Playaway (Audio)
                 '38'  --Playaway (Audio Library)
                 )
                      OR sub_format_code IS NULL )
                AND col.product_id (+)  = item.isbn
                AND col.category_id (+) = 'hbgGifting'
                AND item.owner_code = 'HB'
            UNION ALL
            SELECT DISTINCT
                item.isbn AS product_id,
                'HUK2324'      AS category_id,
                CASE
                    WHEN col.product_id IS NULL THEN
                        'true'
                    ELSE
                        'false'
                END            AS new_flag
            FROM
                hbg_cx_items_extract    item,
                hbg_cx_items_categories col
            WHERE
                            --item.status = 'NEW'
                    item.instanceid = p_instance_id
                AND pub_status NOT IN ( 'NOP', 'PC', 'OP', 'OSI', 'OSF' )
                --AND OWNER_CODE IN ('HB','CB','HU','OB','MS','AB','PP','GM','DP','HL','QS','KP','LP','YP')
                AND publication_date IS NOT NULL
                --AND PUBLICATION_DATE <> '2050-01-01'
                AND format_code NOT IN (
                                            '25', -- CD-ROM Interactive
                                            '26', -- Online Services
                                            '30', -- CDROM Software
                                            '31', -- Shirts - Tee / Sweat
                                            '34', -- Foam Back Print (Poster)
                                            '38', -- Electronic Book
                                            '48', -- Miscellaneous Titles
                                            '49', -- Postage / Costing
                                            '50', -- Advance Reading Copy / Galleys
                                            '52', -- Boxed Set
                                            '55', -- Video - VHS
                                            '56', -- Video - DVD
                                            '57', -- Displays / Prepacks / Set
                                            '58', -- Dummy #
                                            '59', -- Assortment
                                            '66', -- Book "Other Format"
                                            '70', -- Instruments
                                            '77', -- Co-Publication / Special Royalty
                                            '79', -- Voice-controlled
                                            '81', -- Promotional Item - Non Distributed
                                            '82', -- Promotional Item - Distributed
                                            '83', -- Promo posters
                                            '84', -- Catalog - ISBN
                                            '85', -- Assorted Pallet Returns
                                            '86', -- Whse Use Only - ISBN
                                            '87', -- Music
                                            '88', -- Material / Non-Book Item
                                            '90', -- Digital Content
                                            '91', -- PT internal use only
                                            '92' -- Boxed Set - Non Saleable Component
                                          )
                AND ( sub_format_code NOT IN ( '32', --Downloadable (Audio)
                 '33', --Downloadable (Audio Library)
                 '37', --Playaway (Audio)
                 '38'  --Playaway (Audio Library)
                 )
                      OR sub_format_code IS NULL )
                AND col.product_id (+) = item.isbn
                AND col.category_id (+) = 'HUK2324'
                AND item.owner_code = 'HU'
                AND item.reporting_group_code IN ( 23, 24, 60, 61 )

            UNION ALL
            SELECT DISTINCT
                item.isbn              AS product_id,
                item.OWNER_CODE || '_' || bisac.genbisac_code  AS category_id,
                CASE
                    WHEN col.product_id IS NULL THEN
                        'true'
                    ELSE
                        'false'
                END  


     from   hbg_cx_items_bisac_extract bisac,
            hbg_cx_items_extract item,
            hbg_cx_items_categories col

        where bisac.isbn = item.isbn
                and item.instanceid = p_instance_id
                and bisac.instanceid = p_instance_id
                AND col.product_id (+) = item.isbn
                AND col.category_id (+) = item.OWNER_CODE || '_' || bisac.genbisac_code
        and item.PUB_STATUS NOT IN ('NOP','PC','OP','OSI','OSF')
                AND item.OWNER_CODE IN ('CB','AB','QS')
                AND item.PUBLICATION_DATE IS NOT NULL
                AND item.FORMAT_CODE NOT IN (

                                            '25', -- CD-ROM Interactive
                                            '26', -- Online Services
                                            '30', -- CDROM Software
                                            '31', -- Shirts - Tee / Sweat
                                            '34', -- Foam Back Print (Poster)
                                            '38', -- Electronic Book
                                            '48', -- Miscellaneous Titles
                                            '49', -- Postage / Costing
                                            '50', -- Advance Reading Copy / Galleys
                                            '52', -- Boxed Set
                                            '55', -- Video - VHS
                                            '56', -- Video - DVD
                                            '57', -- Displays / Prepacks / Set
                                            '58', -- Dummy #
                                            '59', -- Assortment
                                            '66', -- Book "Other Format"
                                            '70', -- Instruments
                                            '77', -- Co-Publication / Special Royalty
                                            '79', -- Voice-controlled
                                            '81', -- Promotional Item - Non Distributed
                                            '82', -- Promotional Item - Distributed
                                            '83', -- Promo posters
                                            '84', -- Catalog - ISBN
                                            '85', -- Assorted Pallet Returns
                                            '86', -- Whse Use Only - ISBN
                                            '87', -- Music
                                            '88', -- Material / Non-Book Item
                                            '90', -- Digital Content
                                            '91', -- PT internal use only
                                            '92' -- Boxed Set - Non Saleable Component

                           )
                AND  (SUB_FORMAT_CODE NOT IN (
                     '32', --Downloadable (Audio)
                     '33', --Downloadable (Audio Library)
                     '37', --Playaway (Audio)
                     '38'  --Playaway (Audio Library)
                     ) OR SUB_FORMAT_CODE IS NULL)

        UNION ALL
            SELECT DISTINCT
                item.isbn              AS product_id,
                'employee' || '_' || bisac.genbisac_code  AS category_id,
                CASE
                    WHEN col.product_id IS NULL THEN
                        'true'
                    ELSE
                        'false'
                END  


     from   hbg_cx_items_bisac_extract bisac,
            hbg_cx_items_extract item,
            hbg_cx_items_categories col,
            hbg_cx_items_discounts dis

        where bisac.isbn = item.isbn
                and item.instanceid = p_instance_id
                and bisac.instanceid = p_instance_id
                AND col.product_id (+) = item.isbn
                AND col.category_id (+) = 'employee' || '_' || bisac.genbisac_code
        and item.PUB_STATUS NOT IN ('NOP','PC','OP','OSI','OSF')
                AND item.OWNER_CODE = dis.OWNER_CODE
                and ((item.pub_status = 'NYP' and item.publication_date <= to_char(sysdate + 90,'YYYY-MM-DD'))
                    OR item.pub_status <> 'NYP')
                AND item.reporting_group_code = dis.reporting_group_code
                AND item.PUBLICATION_DATE IS NOT NULL
                AND item.FORMAT_CODE NOT IN (

                                            '25', -- CD-ROM Interactive
                                            '26', -- Online Services
                                            '30', -- CDROM Software
                                            '31', -- Shirts - Tee / Sweat
                                            '34', -- Foam Back Print (Poster)
                                            '38', -- Electronic Book
                                            '48', -- Miscellaneous Titles
                                            '49', -- Postage / Costing
                                            '50', -- Advance Reading Copy / Galleys
                                            '52', -- Boxed Set
                                            '55', -- Video - VHS
                                            '56', -- Video - DVD
                                            '57', -- Displays / Prepacks / Set
                                            '58', -- Dummy #
                                            '59', -- Assortment
                                            '66', -- Book "Other Format"
                                            '70', -- Instruments
                                            '77', -- Co-Publication / Special Royalty
                                            '79', -- Voice-controlled
                                            '81', -- Promotional Item - Non Distributed
                                            '82', -- Promotional Item - Distributed
                                            '83', -- Promo posters
                                            '84', -- Catalog - ISBN
                                            '85', -- Assorted Pallet Returns
                                            '86', -- Whse Use Only - ISBN
                                            '87', -- Music
                                            '88', -- Material / Non-Book Item
                                            '90', -- Digital Content
                                            '91', -- PT internal use only
                                            '92' -- Boxed Set - Non Saleable Component

                           )
                AND  (SUB_FORMAT_CODE NOT IN (
                     '32', --Downloadable (Audio)
                     '33', --Downloadable (Audio Library)
                     '37', --Playaway (Audio)
                     '38'  --Playaway (Audio Library)
                     ) OR SUB_FORMAT_CODE IS NULL)
                order by product_id
    ) LOOP

        if prd.product_id <> l_product_id THEN
            IF l_first_rec > 0 THEN
                utl_file.put_line(l_collections_json_file, ']}');
                --update hbg_cx_items_execution_tracker set request = request || ']}' where instanceid = p_instance_id;
                --commit;
            ELSE 
                l_first_rec := 1;
            END IF;
           l_product_id := prd.product_id;
            if l_prd_count > 0 then
                utl_file.put_line(l_collections_json_file, ',{ "id": "'|| l_product_id ||'","parentCategories": [');
                --update hbg_cx_items_execution_tracker set request = request || ',{ "id": "'|| l_product_id ||'","parentCategories": [' where instanceid = p_instance_id;
                --commit;
            else    
                utl_file.put_line(l_collections_json_file, '{ "id": "'|| l_product_id ||'","parentCategories": [');
                --update hbg_cx_items_execution_tracker set request = request || '{ "id": "'|| l_product_id ||'","parentCategories": [' where instanceid = p_instance_id;
                --commit;
                l_prd_count :=1;    
            end if;
        l_col_count := 0;
        END IF;

        SELECT COUNT(1) INTO l_exists
            FROM HBG_CX_ITEMS_COLLECTIONS
            WHERE COLLECTION_ID = prd.category_id;

            IF l_exists = 0 THEN
                l_create_col := create_collections(substr(prd.category_id,1,2),substr(prd.category_id,4,3),p_instance_id);
            END IF;

        if l_col_count > 0 then
                utl_file.put_line(l_collections_json_file, ',{"id": "'|| prd.category_id ||'"}');
                 --update hbg_cx_items_execution_tracker set request = request || '{"id": "'|| prd.category_id ||'"}'  where instanceid = p_instance_id;
                 --commit;
            else
                utl_file.put_line(l_collections_json_file, '{"id": "'|| prd.category_id ||'"}');
                l_col_count := 1;
                --update hbg_cx_items_execution_tracker set request = request || ',{"id": "'|| prd.category_id ||'"}'  where instanceid = p_instance_id;
            end if;    
            insert into hbg_cx_items_categories_stg (product_id, category_id, instanceid) values (l_product_id, prd.category_id, p_instance_id );
            --update hbg_cx_items_execution_tracker set request = request || l_products_json;
            --commit;
        end loop;
            utl_file.put_line(l_collections_json_file, ']}]}');
            --update hbg_cx_items_execution_tracker set request = request || ']}]}'  where instanceid = p_instance_id;
            --commit;
            utl_file.fclose(l_collections_json_file);
                    -----TEST FILES SCRIPT------
            teste := utl_file.fopen(g_directory, l_collections_filename, 'R');
            /*read_teste := NULL;
            LOOP
                BEGIN
                    utl_file.get_line(teste, teste_row);
                    read_teste := read_teste || to_clob(teste_row);
               --dbms_output.put_line(read_teste);
                EXCEPTION
                    WHEN no_data_found THEN
                        EXIT;
                END;
            END LOOP;  */
             --get blob from files
             dbms_output.put_line('file_to_blob');
            l_collections_blob := file_to_blob(l_collections_filename);
            IF l_collections_blob IS NULL THEN
                errbuf := 'Failed to convert collections file to blob';
                RAISE failed_import;
            END IF;
            dbms_output.put_line('ACCESS TOKEN INIT');
            --get cx api access token
            l_access_token := get_api_access_token;
            IF l_access_token IS NULL THEN
                errbuf := 'Failed to get access token';
                RAISE failed_import;
            END IF;
            dbms_output.put_line('access_token=' || l_access_token);

             -- upload the file to cx
            l_file_token := start_file_upload_api(l_access_token, l_collections_blob, l_collections_filename);
            IF l_file_token IS NULL THEN
                errbuf := 'Failed to upload the file to CX';
                RAISE failed_import;
            END IF;
            dbms_output.put_line('l_process_id=' || l_file_token);

           -- execute bulk import 
            l_process_id := execute_bulk_import_api(l_access_token, 'ProductsV2');
            IF l_process_id IS NULL THEN
                errbuf := 'Failed to execute the import process';
                RAISE failed_import;
            END IF;
            dbms_output.put_line('l_process_id=' || l_process_id);
            get_import_process_api(p_user_token => l_access_token, p_process_id => l_process_id, l_json_report_clob => l_json_report_clob,
            l_failed_records_clob => l_failed_records_clob, l_failure_count => l_failure_count,
                                  errbuf => l_errbuf, retcode => l_retcode);  

             IF l_retcode = 1 THEN
                errbuf := 'Failed to retrieve collections import process information - ' || l_errbuf;
                RAISE failed_import;
            END IF;
            IF l_failure_count > 0 THEN
                retcode := 2;

                INSERT INTO hbg_cx_items_col_json_report
                    ( SELECT
                        json.comments,
                        ROWNUM        AS row_number,
                        p_instance_id AS instanceid
                    FROM
                            JSON_TABLE ( l_json_report_clob, '$.failureExceptions[*]'
                                COLUMNS (
                                    comments VARCHAR2 ( 2000 ) PATH '$.localizedMessage'
                                )
                            )
                        AS json
                    );

                INSERT INTO hbg_cx_items_col_failed_rec
                    ( SELECT
                        json.product_id,
                        ROWNUM        AS line_number,
                        p_instance_id AS instanceid
                    FROM
                            JSON_TABLE ( l_failed_records_clob, '$.product[*]'
                                COLUMNS (
                                    product_id VARCHAR2 ( 100 ) PATH '$.id'
                                )
                            )
                        json
                    );

                COMMIT;
                retcode := 2;
                BEGIN
                    UPDATE hbg_cx_items_extract item
                    SET STATUS = STATUS || 'ERROR_COLLECTIONS',
                        comments = comments || (
                            SELECT DISTINCT
                                'ERROR_COLLECTIONS - '
                                || json.comments
                            FROM
                                hbg_cx_items_col_failed_rec  failed_records,
                                hbg_cx_items_col_json_report json
                            WHERE
                                    json.line_number = failed_records.line_number
                                AND failed_records.product_id = item.isbn
                                AND failed_records.instanceid = p_instance_id
                                AND json.instanceid = p_instance_id
                        )
                    WHERE
                            instanceid = p_instance_id
                        AND status <> 'SKIPPED';

                    COMMIT;

                    UPDATE hbg_cx_items_bisac_extract bisac
                    SET
                        status = 'ERROR',
                        COMMENTS = (SELECT DISTINCT
                                'ERROR - '
                                || json.comments
                            FROM
                                hbg_cx_items_col_failed_rec  failed_records,
                                hbg_cx_items_col_json_report json,
                                hbg_cx_items_extract item
                            WHERE
                                    json.line_number = failed_records.line_number
                                AND failed_records.product_id = bisac.isbn
                                AND failed_records.instanceid = p_instance_id
                                and bisac.instanceid = p_instance_id
                                AND json.instanceid = p_instance_id
                        )
                    WHERE
                            status = 'NEW'
                        AND instanceid = p_instance_id;
                    EXCEPTION
                    WHEN OTHERS THEN
                        errbuf := 'Failed to update collection extract table with error details - ' || sqlerrm;
                        retcode := 1;
                    END;
                END IF;
                begin
                    DELETE FROM HBG_CX_ITEMS_CATEGORIES_STG stg
                    WHERE EXISTS (SELECT json.PRODUCT_ID FROM hbg_cx_items_col_failed_rec json WHERE json.product_id = stg.product_id);
                    commit;

                    DELETE FROM HBG_CX_ITEMS_CATEGORIES cx 
                    WHERE cx.product_id IN (SELECT stg.PRODUCT_ID from HBG_CX_ITEMS_CATEGORIES_STG stg where instanceid = p_instance_id);
                    commit; 

                    INSERT INTO HBG_CX_ITEMS_CATEGORIES cx
                    SELECT PRODUCT_ID, CATEGORY_ID, SYSDATE, SYSDATE 
                    FROM HBG_CX_ITEMS_CATEGORIES_STG stg
                    where instanceid = p_instance_id;

                    /*DELETE FROM hbg_cx_items_col_failed_rec
                    WHERE
                        instanceid = p_instance_id;

                    DELETE FROM hbg_cx_items_col_json_report
                    WHERE
                        instanceid = p_instance_id;*/

                    COMMIT;
            EXCEPTION
                    WHEN OTHERS THEN
                        errbuf := 'Failed to update collection mirror table - ' || sqlerrm;
                        retcode := 1;
                    END;   
       -- dbms_output.put_line('COLLECTIONS LOOP');
    --dbms_output.put_line('l_status = '|| l_status);
    --dbms_output.put_line('l_comments = '|| l_comments);
    --dbms_output.put_line('rws.product_id = '|| rws.product_id);
            --UPDATE EXTRACT TABLE
            BEGIN
                UPDATE hbg_cx_items_extract
                SET
                    comments = COMMENTS || NULL,
                    status = status || 'COLLECTIONS_PROCESSED'
                WHERE
                    instanceid = p_instance_id
                    AND ( status NOT LIKE '%ERROR_COLLECTIONS%'
                      AND status NOT LIKE '%SKIPPED%' );

                UPDATE hbg_cx_items_bisac_extract
                SET
                    comments = NULL,
                    status = 'SUCCESS'
                WHERE
                    instanceid = p_instance_id
                    AND status = 'NEW';

                COMMIT;
            EXCEPTION
                WHEN OTHERS THEN
                    errbuf := 'Failed to update collections extract table status - ' || sqlerrm;
                    retcode := 1;
            END;
        IF retcode = 2 THEN
            errbuf := 'Failed to import some products to collections';
        END IF;
    EXCEPTION
        WHEN failed_import THEN
            retcode := 1;
            UPDATE hbg_cx_items_extract
            SET
                comments = comments
                           || 'ERROR_COLLECTIONS: '
                           || errbuf
                           || ';',
                status = status || 'ERROR_COLLECTIONS;'
            WHERE
                status NOT LIKE '%COLLECTION%'
                AND instanceid = p_instance_id;

            COMMIT;
        WHEN OTHERS THEN
            errbuf := sqlerrm;
            retcode := 1;
            UPDATE hbg_cx_items_extract
            SET
                comments = comments
                           || 'ERROR_COLLECTIONS: '
                           || errbuf
                           || ';',
                status = status || 'ERROR_COLLECTIONS;'
            WHERE
                ( status NOT LIKE '%COLLECTIONS%'
                      AND status NOT LIKE '%SKIPPED%' )
                AND instanceid = p_instance_id;

            UPDATE hbg_cx_items_BISAC_extract
            SET
                comments = 'ERROR: '
                           || errbuf
                           || ';',
                status = 'ERROR'
            WHERE
                status = 'NEW'
                AND instanceid = p_instance_id;


            COMMIT;
    END import_collections;
  --/*************************************************************************
  -- Import Inventory Procedure  
  --*************************************************************************/    

    PROCEDURE import_inventory (
        p_instance_id IN NUMBER,
        p_user_token  IN VARCHAR2,
        errbuf        OUT VARCHAR2,
        retcode       OUT VARCHAR2
    ) AS

        l_errbuf              VARCHAR2(150);
        l_retcode             VARCHAR2(1);

    --Authentication Token 
        l_access_token        VARCHAR2(4000);

    --Create Skus File
        l_inventory_json_file utl_file.file_type;
        l_inventory_filename  VARCHAR2(50) := 'Inventory.json';
        l_inventory_blob      BLOB;

    --api variables
        l_inventory_request   VARCHAR2(300);
        l_file_token          VARCHAR2(100);
        l_process_id          VARCHAR2(100);
        token_exception EXCEPTION;
        countrws              NUMBER := 0;
        l_json_report_clob    CLOB;
        l_failed_records_clob CLOB;
        l_inventory_clob      CLOB;
        l_failure_count       NUMBER;
        l_count               NUMBER;
        l_stock_type          VARCHAR2(50);
        l_stock_refresh       VARCHAR2(50);
        l_quantity            NUMBER;
    --exception
        failed_import EXCEPTION;

    -----TEST FILES VARIABLES-------
        teste                 utl_file.file_type;
        read_teste            CLOB;
        blob_test             BLOB;
        teste_row             VARCHAR2(4000);
    BEGIN
        errbuf := NULL;
        retcode := 0;
        /*UPDATE hbg_cx_items_inventory_extract 
        SET STATUS = 'SKIPPED' 
        WHERE   isbn NOT IN (SELECT SKU_ID FROM HBG_CX_ITEMS_PRODUCTS_SKUS)
            AND INSTANCEID = p_instance_id;
        COMMIT;*/
        SELECT
            COUNT(isbn)
        INTO l_count
        FROM
            hbg_cx_items_inventory_extract
        WHERE
                status = 'NEW'
            AND instanceid = p_instance_id;

        IF l_count > 0 THEN
        --Create inventory json file
            l_inventory_json_file := utl_file.fopen(g_directory, l_inventory_filename, 'W');
        --inventory loop
            FOR rws IN (
                SELECT DISTINCT
                    inv.isbn                      AS sku_id,
                    case when inv.useable_inventory < 0 then 0
                    else nvl(inv.useable_inventory, 0) end AS stock,
                    cx.pub_status
                FROM
                    hbg_cx_items_inventory_extract inv,
                    hbg_cx_items_products_skus     cx
                WHERE
                        inv.status = 'NEW'
                    AND inv.instanceid = p_instance_id
                    AND inv.isbn = cx.sku_id (+)
                ORDER BY
                    sku_id
            ) LOOP
                l_quantity := rws.stock;
                IF rws.pub_status = 'NYP' THEN
                    l_stock_type := 'preorderLevel';
                    l_stock_refresh := 'stockLevel';
                    IF rws.stock = 0 THEN
                        l_quantity := 1000;
                    END IF;
                ELSE
                    l_stock_type := 'stockLevel';
                    l_stock_refresh := 'preorderLevel';
                END IF;

                IF countrws = 0 THEN
                    l_inventory_request := '{"inventory" : [{"skuNumber" : "'
                                           || rws.sku_id
                                           || '","'
                                           || l_stock_type
                                           || '" : '
                                           || l_quantity
                                           || ',"'
                                           || l_stock_refresh
                                           || '" : 0}';

                    countrws := 1;
                ELSE
                    l_inventory_request := ',{"skuNumber" : "'
                                           || rws.sku_id
                                           || '","'
                                           || l_stock_type
                                           || '" : '
                                           || l_quantity
                                           || ',"'
                                           || l_stock_refresh
                                           || '" : 0}';
                END IF;

                l_inventory_clob := l_inventory_clob || l_inventory_request;
                utl_file.put_line(l_inventory_json_file, l_inventory_request);
            END LOOP;

            utl_file.put_line(l_inventory_json_file, ']}');
            utl_file.fclose(l_inventory_json_file);

        -----TEST FILES SCRIPT------
            teste := utl_file.fopen(g_directory, l_inventory_filename, 'R');
            LOOP
                BEGIN
                    utl_file.get_line(teste, teste_row);
                    read_teste := read_teste || to_clob(teste_row);
           --dbms_output.put_line(read_teste);
                EXCEPTION
                    WHEN no_data_found THEN
                        EXIT;
                END;
            END LOOP;
       --get blob from files
            l_inventory_blob := file_to_blob(l_inventory_filename);
            IF l_inventory_blob IS NULL THEN
                errbuf := 'Failed to convert inventory file to blob';
                RAISE failed_import;
            END IF;

            --get cx api access token
            l_access_token := get_api_access_token;
            IF l_access_token IS NULL THEN
                errbuf := 'Failed to get access token';
                RAISE failed_import;
            END IF;
            --dbms_output.put_line('access_token=' || l_access_token);

             -- upload the file to cx
            l_file_token := start_file_upload_api(l_access_token, l_inventory_blob, l_inventory_filename);
            IF l_file_token IS NULL THEN
                errbuf := 'Failed to upload the file to CX';
                RAISE failed_import;
            END IF;
            --dbms_output.put_line('file_token=' || l_file_token);

           -- execute bulk import 
            l_process_id := execute_bulk_import_api(l_access_token, 'Inventory');
            IF l_process_id IS NULL THEN
                errbuf := 'Failed to execute the import process';
                RAISE failed_import;
            END IF;
            --dbms_output.put_line('bulk_token=' || l_process_id);
            get_import_process_api(p_user_token => l_access_token, p_process_id => l_process_id, l_json_report_clob => l_json_report_clob,
            l_failed_records_clob => l_failed_records_clob, l_failure_count => l_failure_count,
                                  errbuf => l_errbuf, retcode => l_retcode);

            --dbms_output.put_line('out of get process');
            /*UPDATE hbg_cx_items_execution_tracker
            SET
                request = read_teste
            WHERE
                instanceid = p_instance_id;*/

            IF retcode = 1 THEN
                errbuf := 'Failed to retrieve inventory import process information - ' || l_errbuf;
                RAISE failed_import;
            END IF;
            IF l_failure_count > 0 THEN
                retcode := 2;
                INSERT INTO hbg_cx_items_inv_failed_rec
                    SELECT
                        json.skuid,
                        ROWNUM AS line_number,
                        p_instance_id
                    FROM
                            JSON_TABLE ( l_failed_records_clob, '$.inventory[*]'
                                COLUMNS (
                                    skuid VARCHAR2 ( 100 ) PATH '$.skuNumber'
                                )
                            )
                        json;

                COMMIT;
                INSERT INTO hbg_cx_items_inv_json_report
                    SELECT
                        json.comments,
                        ROWNUM AS row_number,
                        p_instance_id
                    FROM
                            JSON_TABLE ( l_json_report_clob, '$.failureExceptions[*]'
                                COLUMNS (
                                    comments VARCHAR2 ( 4000 ) PATH '$.localizedMessage'
                                )
                            )
                        json;

                COMMIT;
                BEGIN
                    UPDATE hbg_cx_items_inventory_extract inv
                    SET
                        comments = (
                            SELECT
                                'ERROR - ' || json.comments
                            FROM
                                hbg_cx_items_inv_failed_rec  failed_records,
                                hbg_cx_items_inv_json_report json
                            WHERE
                                    json.line_number = failed_records.line_number
                                AND sku_id = inv.isbn
                                AND failed_records.instanceid = p_instance_id
                                AND json.instanceid = p_instance_id
                        )
                    WHERE
                            instanceid = p_instance_id
                        AND status = 'NEW';

                    COMMIT;
                    UPDATE hbg_cx_items_inventory_extract price
                    SET
                        status = 'ERROR'
                    WHERE
                        comments IS NOT NULL
                        AND status <> 'SKIPPED'
                        AND instanceid = p_instance_id;

                    DELETE FROM hbg_cx_items_inv_failed_rec
                    WHERE
                        instanceid = p_instance_id;

                    DELETE FROM hbg_cx_items_inv_json_report
                    WHERE
                        instanceid = p_instance_id;

                    COMMIT;
                EXCEPTION
                    WHEN OTHERS THEN
                        errbuf := 'Failed to update inventory extract table status - ' || sqlerrm;
                        retcode := 1;
                END;

            END IF;
                --dbms_output.put_line('update tables');
            BEGIN
                UPDATE hbg_cx_items_inventory_extract
                SET
                    status = 'SUCCESS'
                WHERE
                        status = 'NEW'
                    AND instanceid = p_instance_id;

                COMMIT;
            EXCEPTION
                WHEN OTHERS THEN
                    errbuf := 'Failed to update inventory extract table status';
                    retcode := 1;
            END;
        --end loop
            IF retcode = 2 THEN
                errbuf := 'Failed to import some inventory data';
            END IF;
        END IF;

    EXCEPTION
        WHEN failed_import THEN
            retcode := 1;
            UPDATE hbg_cx_items_inventory_extract
            SET
                status = 'ERROR',
                comments = errbuf
            WHERE
                    status = 'NEW'
                AND instanceid = p_instance_id;

            COMMIT;
        WHEN OTHERS THEN
            errbuf := sqlerrm;
            retcode := 1;
            UPDATE hbg_cx_items_inventory_extract
            SET
                status = 'ERROR',
                comments = errbuf
            WHERE
                    status = 'NEW'
                AND instanceid = p_instance_id;

            COMMIT;
    END import_inventory;

  --/*************************************************************************
  -- MAIN Procedure  
  --*************************************************************************/

    PROCEDURE main (
        p_instanceid IN NUMBER,
        p_auth       IN VARCHAR2 DEFAULT NULL,
        p_url        IN VARCHAR2
    ) AS

        l_errbuf     VARCHAR2(3000);
        l_retcode    VARCHAR2(1);
        l_tracker    hbg_cx_items_integration_tracker%rowtype;
        x_report     VARCHAR2(5);
        errbuf       VARCHAR2(4000);
        retcode      NUMBER;
        my_time      DATE;
        countrows    NUMBER;
        countcol     NUMBER;
        clear_status VARCHAR2(5);
        validation_exception EXCEPTION;
        token_exception      EXCEPTION;
    BEGIN
        errbuf := NULL;
        retcode := 0;
        g_auth := p_auth;
        g_instance_id := p_instanceid;
        g_url := p_url;
        l_tracker.instanceid := p_instanceid;
        l_tracker.job_status := 'RUNNING';
        l_tracker.errbuf := NULL;
        l_tracker.retcode := NULL;
        l_tracker.report_file := NULL;
        l_tracker.creation_date := sysdate;

        UPDATE hbg_cx_items_integration_tracker
        SET
            row = l_tracker
        WHERE
            instanceid = p_instanceid;

        COMMIT;

        INSERT INTO hbg_cx_items_execution_tracker (
            instanceid,
            creation_date
        ) VALUES (
            p_instanceid,
            sysdate
        );
        --CALL VALIDATE SKU PROCEDURE
        dbms_output.put_line('item validation');
        isbn_validation(p_instanceid, l_errbuf, l_retcode);
        IF l_retcode = 1 THEN
            errbuf := 'Failed to validate isbns - ' || l_errbuf;
            RAISE validation_exception;
        END IF;

        my_time := systimestamp;

        --CALL IMPORT SKU PROCEDURE
        import_skus(p_instanceid, p_auth, l_errbuf, l_retcode);
        IF l_retcode > 0 THEN
            errbuf := errbuf
                      || 'Skus : '
                      || l_errbuf
                      || '
            ';
            IF retcode != 1 THEN
                retcode := l_retcode;
            END IF;
            if l_errbuf = 'Failed to get access token' then
                errbuf := 'Failed to get access token';
                raise token_exception;
            end if;
            l_errbuf := NULL;       
        END IF;


        SELECT
            COUNT(DISTINCT isbn)
        INTO countrows
        FROM
            hbg_cx_items_extract
        WHERE
            instanceid = p_instanceid;

        UPDATE hbg_cx_items_execution_tracker
        SET
            sku_exec = ( systimestamp - my_time ),
            sku_rec = countrows
        WHERE
            instanceid = p_instanceid;

        COMMIT;

         my_time := systimestamp;
         --CALL IMPORT SKU PROCEDURE
        import_related_items(p_instanceid, p_auth, l_errbuf, l_retcode);
        IF l_retcode > 0 THEN
            errbuf := errbuf
                      || 'Skus : '
                      || l_errbuf
                      || '
            ';
            IF retcode != 1 THEN
                retcode := l_retcode;
            END IF;
            if l_errbuf = 'Failed to get access token' then
                errbuf := 'Failed to get access token';
                raise token_exception;
            end if;
            l_errbuf := NULL;       
        END IF;

        UPDATE hbg_cx_items_execution_tracker
        SET
            product_exec = ( systimestamp - my_time ),
            product_rec = countrows
        WHERE
            instanceid = p_instanceid;

        COMMIT;

        my_time := systimestamp;
        --CALL IMPORT COLLECTIONS PROCEDURE
        import_collections(p_instanceid, p_auth, l_errbuf, l_retcode);
        IF l_retcode > 0 THEN
            errbuf := errbuf
                      || 'Collections : '
                      || l_errbuf
                      || '
            ';
            IF retcode != 1 THEN
                retcode := l_retcode;
            END IF;
            if l_errbuf = 'Failed to get access token' then
                errbuf := 'Failed to get access token';
                raise token_exception;
            end if;
            l_errbuf := NULL;
        END IF;

        SELECT
            COUNT(DISTINCT isbn)
        INTO countrows
        FROM
            (
                SELECT DISTINCT
                    isbn,
                    reporting_group_code
                FROM
                    hbg_cx_items_extract
                WHERE
                    instanceid = p_instanceid
            );

        SELECT
            COUNT(DISTINCT isbn)
        INTO countcol
        FROM
            (
                SELECT DISTINCT
                    isbn,
                    genbisac_code
                FROM
                    hbg_cx_items_bisac_extract
                WHERE
                    instanceid = p_instanceid
            );

        UPDATE hbg_cx_items_execution_tracker
        SET
            col_exec = ( systimestamp - my_time ),
            col_rec = ( countrows + countcol )
        WHERE
            instanceid = p_instanceid;

        COMMIT;
        UPDATE hbg_cx_items_extract
        SET
            status = 'ERROR'
        WHERE
            status LIKE '%ERROR%'
            AND instanceid = p_instanceid;

        COMMIT;
        UPDATE hbg_cx_items_extract
        SET
            status = 'SUCCESS',
            comments = NULL
        WHERE
            ( status <> 'ERROR'
              AND status NOT LIKE '%SKIPPED%' )
            AND instanceid = p_instanceid;

        COMMIT;

        my_time := systimestamp;
        --CALL IMPORT PRICES PROCEDURE
        import_prices(p_instanceid, p_auth, l_errbuf, l_retcode);
        IF l_retcode > 0 THEN
            errbuf := errbuf
                      || 'Prices : '
                      || l_errbuf
                      || '
            ';
            IF retcode != 1 THEN
                retcode := l_retcode;
            END IF;
            if l_errbuf = 'Failed to get access token' then
                errbuf := 'Failed to get access token';
                raise token_exception;
            end if;
            l_errbuf := NULL;
        END IF;

        SELECT
            COUNT(DISTINCT item_code)
        INTO countrows
        FROM
            hbg_cx_items_price_extract
        WHERE
            instanceid = p_instanceid;

        UPDATE hbg_cx_items_execution_tracker
        SET
            price_exec = ( systimestamp - my_time ),
            price_rec = countrows
        WHERE
            instanceid = p_instanceid;

        COMMIT;

        --CALL IMPORT INVENTORY PROCEDURE
        my_time := systimestamp;
        import_inventory(p_instanceid, p_auth, l_errbuf, l_retcode);
        IF l_retcode > 0 THEN
            errbuf := errbuf
                      || 'Inventory : '
                      || l_errbuf
                      || '
            ';
            IF retcode != 1 THEN
                retcode := l_retcode;
            END IF;
            if l_errbuf = 'Failed to get access token' then
                errbuf := 'Failed to get access token';
                raise token_exception;
            end if;
            l_errbuf := NULL;
        END IF;

        SELECT
            COUNT(DISTINCT isbn)
        INTO countrows
        FROM
            hbg_cx_items_inventory_extract
        WHERE
            instanceid = p_instanceid;

        UPDATE hbg_cx_items_execution_tracker
        SET
            inv_exec = ( systimestamp - my_time ),
            inv_rec = countrows
        WHERE
            instanceid = p_instanceid;

        COMMIT;
        my_time := systimestamp;

        --CALL GENERATE REPORTS FUNCTION
        x_report := generatereports(p_instanceid);
        IF x_report IS NULL THEN
            errbuf := errbuf || 'Report Error : Failed to generate report status
            ';
            retcode := 1;
        END IF;
        UPDATE hbg_cx_items_execution_tracker
        SET
            report_exec = ( systimestamp - my_time )
        WHERE
            instanceid = p_instanceid;

        COMMIT;
        clear_status := clearstagetables(p_instanceid);
        l_tracker.instanceid := p_instanceid;
        l_tracker.job_status := 'COMPLETED';
        l_tracker.errbuf := errbuf;
        l_tracker.retcode := retcode;
        l_tracker.report_file := x_report;
        UPDATE hbg_cx_items_integration_tracker
        SET
            row = l_tracker
        WHERE
            instanceid = p_instanceid;

    EXCEPTION
        WHEN OTHERS THEN
            errbuf := errbuf
                      || 'Proc Error : '
                      || sqlerrm;
            retcode := 1;
            l_tracker.instanceid := p_instanceid;
            l_tracker.job_status := 'ERROR';
            l_tracker.errbuf := errbuf;
            l_tracker.retcode := retcode;
            l_tracker.report_file := NULL;
            UPDATE hbg_cx_items_integration_tracker
            SET
                row = l_tracker
            WHERE
                instanceid = p_instanceid;

            COMMIT;
    END main;

  --/*************************************************************************
  -- Generate MAIN Procedure JOB  
  --*************************************************************************/
    PROCEDURE call_main_job (
        p_instanceid IN NUMBER,
        p_auth       IN VARCHAR2,
        p_url        IN VARCHAR2,
        errbuf       OUT VARCHAR2,
        retcode      OUT VARCHAR2,
        job_status   OUT VARCHAR2,
        job_name     OUT VARCHAR2
    ) AS
        l_errbuf  VARCHAR2(3000);
        l_retcode VARCHAR2(1);
        l_tracker hbg_cx_items_integration_tracker%rowtype;
        l_sysdate DATE;
    BEGIN
        errbuf := NULL;
        retcode := 0;
        job_name := 'IMPORT_CX_ITEMS_JOB_' || p_instanceid;
        dbms_scheduler.create_job(job_name => 'import_cx_items_job_' || p_instanceid, job_type => 'PLSQL_BLOCK', job_action => 'BEGIN
                                        HBG_CX_ITEMS_PKG.MAIN('
                                                                                                                               || p_instanceid
                                                                                                                               || ','''
                                                                                                                               || p_auth
                                                                                                                               || ''','''
                                                                                                                               || p_url
                                                                                                                               || ''');
                                    END;', enabled => true, auto_drop => true,
                                 comments => 'HBG CX Items instance ' || p_instanceid);

        l_tracker.instanceid := p_instanceid;
        l_tracker.job_status := 'SUBMITTED';
        l_tracker.errbuf := NULL;
        l_tracker.retcode := NULL;
        l_tracker.report_file := NULL;
        SELECT SYSDATE INTO l_sysdate FROM DUAL;
        l_tracker.CREATION_DATE := l_sysdate;
        INSERT INTO hbg_cx_items_integration_tracker VALUES l_tracker;

        COMMIT;
        job_status := l_tracker.job_status;
    EXCEPTION
        WHEN OTHERS THEN
            errbuf := sqlerrm;
            retcode := 1;
            job_status := 'ERROR';
    END call_main_job;

    FUNCTION get_api_access_token RETURN VARCHAR2 AS

        x_access_token      VARCHAR2(4000);
        l_url               VARCHAR2(200) := g_url || '/ccadmin/v1/login?grant_type=client_credentials';
        l_auth              VARCHAR2(2000) := 'Bearer ' || g_auth;
        l_tkn_response_clob CLOB;
        l_retry             NUMBER;
        l_offset            number := 1;
    BEGIN
        l_retry := 0;
        x_access_token := NULL;
        --dbms_output.put_line('get access token = start' );
        --dbms_output.put_line('get access token = request sent');

        WHILE x_access_token IS NULL AND l_retry < 6 LOOP

        apex_web_service.g_request_headers.delete();
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/x-www-form-urlencoded';
        apex_web_service.g_request_headers(2).name := 'Authorization';
        apex_web_service.g_request_headers(2).value := l_auth;
        --dbms_output.put_line('get access token = headers');
       BEGIN
        l_tkn_response_clob := apex_web_service.make_rest_request(p_url => l_url, p_http_method => 'POST', p_wallet_path => 'file:////u01/app/wallet/https_wallet');
       /* dbms_output.put_line('get access token RETRY = ' || l_retry || ' timestamp : ' || systimestamp);
        l_offset := 1;
         BEGIN  
                    dbms_output.put_line('Print CLOB 1 - ACCESS TOKEN');    
                    loop  
                    exit when l_offset > dbms_lob.getlength(l_tkn_response_clob);  
                    dbms_output.put_line( dbms_lob.substr( l_tkn_response_clob, 255, l_offset ) );  
                    l_offset := l_offset + 255;  
                    end loop;  
                END;*/

            SELECT
                tk.access_token
            INTO x_access_token
            FROM
                    JSON_TABLE ( l_tkn_response_clob
                        COLUMNS
                            access_token VARCHAR2 ( 4000 ) PATH '$.access_token'
                    )
                tk;


            IF x_access_token IS NULL THEN
                l_retry := l_retry + 1;
                dbms_session.sleep(2*l_retry*60);
            END IF;


        EXCEPTION WHEN OTHERS THEN
            x_access_token := NULL;
            l_retry := l_retry + 1;
            dbms_session.sleep(2*l_retry*60);
        END;

        END LOOP;

        RETURN ( x_access_token );
    EXCEPTION
        WHEN OTHERS THEN
         --dbms_output.put_line('get access token = ' || sqlerrm);
            RETURN NULL;
    END get_api_access_token;

    FUNCTION file_to_blob (
        p_filename VARCHAR2
    ) RETURN BLOB AS

        x_blob_file BLOB;
        --l_file      utl_file.file_type;
        l_file      BFILE := bfilename(g_directory, p_filename);
        l_blob      BLOB;
        src_offset  NUMBER := 1;
        dst_offset  NUMBER := 1;
        src_osin    NUMBER;
        dst_osin    NUMBER;
        --bytes_rd    NUMBER;
        bytes_wt    NUMBER;
       -- l_read      VARCHAR2(32000) := '';
        --l_row       VARCHAR2(32000);
    BEGIN
        dbms_lob.createtemporary(l_blob, false, 2);
        --dbms_output.put_line('open bfile ' ) ;
        dbms_lob.fileopen(l_file, dbms_lob.file_readonly);
        --dbms_output.put_line('open blob' ) ;
        dbms_lob.open(l_blob, dbms_lob.lob_readwrite);
        src_osin := src_offset;
        dst_osin := dst_offset;
        --dbms_output.put_line('load blob' ) ;
        dbms_lob.loadblobfromfile(l_blob, l_file, dbms_lob.lobmaxsize, src_offset, dst_offset);
        dbms_lob.close(l_blob);
        dbms_lob.filecloseall();
        --bytes_rd := src_offset - src_osin;
       -- --dbms_output.put_line(' Number of bytes read from the BFILE ' || bytes_rd ) ;
  /* Use the dst_offset returned to calculate the actual amount written to the 
BLOB */
        --bytes_wt := dst_offset - dst_osin;
        --DBMS_LOB.ERASE(l_blob,bytes_wt);
       -- --dbms_output.put_line(' Number of bytes written to the BLOB ' || bytes_wt ) ;
       -- l_file := utl_file.fopen(g_directory, p_filename, 'R');
       /* IF utl_file.is_open(l_file) THEN
            LOOP
                BEGIN
                    utl_file.get_raw(l_file, l_row);
                    l_read := l_read || l_row;
                EXCEPTION
                    WHEN no_data_found THEN
                        EXIT;
                END;
            END LOOP;

        END IF;
        l_blob := to_blob(l_read);*/
        RETURN l_blob;
    EXCEPTION
        WHEN OTHERS THEN
           --dbms_output.put_line('file_TO_BLOB=' || sqlerrm);
            RETURN NULL;
    END file_to_blob;

    FUNCTION execute_import_api (
        p_uri          VARCHAR2,
        p_user_token   VARCHAR2,
        p_request_json CLOB,
        p_id           VARCHAR2 DEFAULT NULL
    ) RETURN CLOB AS

        x_process_id    VARCHAR2(500);
        l_url           VARCHAR2(200) := g_url
                               || '/ccadmin/v1/'
                               || p_uri;
        l_auth          VARCHAR2(5000) := 'Bearer ' || p_user_token;
        l_response_clob CLOB;
       -- l_request_json  VARCHAR(100);
        l_request_clob  CLOB;
        l_offset        INT := 1;
        l_method        VARCHAR2(10);
    BEGIN
        IF p_id IS NOT NULL THEN
            l_method := 'PUT';
            l_url := l_url
                     || '/'
                     || p_id;
        ELSIF p_uri = 'prices' THEN
            l_method := 'PUT';
        ELSE
            l_method := 'POST';
        END IF;

        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';
        apex_web_service.g_request_headers(2).name := 'Authorization';
        apex_web_service.g_request_headers(2).value := l_auth;
        apex_web_service.g_request_headers(3).name := 'X-CCAsset-Language';
        apex_web_service.g_request_headers(3).value := 'en';
        l_request_clob := to_clob(p_request_json);
        l_response_clob := apex_web_service.make_rest_request(p_url => l_url, p_http_method => l_method, p_body => l_request_clob, p_wallet_path =>
        'file:////u01/app/wallet/https_wallet');
        /*BEGIN  
            dbms_output.put_line('Print CLOB - execute_import_api');
            loop  
            exit when l_offset > dbms_lob.getlength(l_response_clob);  
            dbms_output.put_line( dbms_lob.substr( l_response_clob, 255, l_offset ) );  
            l_offset := l_offset + 255;  
            end loop;
        END;*/
        RETURN ( l_response_clob );
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END execute_import_api;

    FUNCTION check_inventory_stock_level (
        p_user_token VARCHAR2,
        p_id         VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER AS

        l_stock_level   NUMBER;
        l_url           VARCHAR2(200) := g_url
                               || '/ccadmin/v1/inventories/'
                               || p_id;
        l_auth          VARCHAR2(5000) := 'Bearer ' || p_user_token;
        l_response_clob CLOB;
    BEGIN
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';
        apex_web_service.g_request_headers(2).name := 'Authorization';
        apex_web_service.g_request_headers(2).value := l_auth;
        apex_web_service.g_request_headers(3).name := 'X-CCAsset-Language';
        apex_web_service.g_request_headers(3).value := 'en';
        l_response_clob := apex_web_service.make_rest_request(p_url => l_url, p_http_method => 'GET', p_wallet_path => 'file:////u01/app/wallet/https_wallet');

        IF l_response_clob IS NULL THEN
            l_stock_level := NULL;
        ELSE
            SELECT
                json.stock_level
            INTO l_stock_level
            FROM
                    JSON_TABLE ( l_response_clob
                        COLUMNS
                            stock_level NUMBER PATH '$.stockLevel'
                    )
                json;

        END IF;

        RETURN ( l_stock_level );
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END check_inventory_stock_level;

    FUNCTION clob2blob (
        aclob CLOB
    ) RETURN BLOB IS
        result BLOB;
        o1     INTEGER;
        o2     INTEGER;
        c      INTEGER;
        w      INTEGER;
    BEGIN
        o1 := 1;
        o2 := 1;
        c := 0;
        w := 0;
        dbms_lob.createtemporary(result, true);
        dbms_lob.converttoblob(result, aclob, length(aclob), o1, o2,
                              0, c, w);

        RETURN ( result );
    END clob2blob;

    FUNCTION generatereports (
        p_instance_id NUMBER
    ) RETURN VARCHAR2 AS

        x_zip_reports             BLOB;
        l_products_report         utl_file.file_type;
        l_products_report_name    VARCHAR2(100) := 'ItemExtract_Report.csv';
        l_products_blob           BLOB;
        l_collections_report      utl_file.file_type;
        l_collections_report_name VARCHAR2(100) := 'ItemBISACExtract_Report.csv';
        l_collections_blob        BLOB;
        l_authors_report          utl_file.file_type;
        l_authors_report_name     VARCHAR2(100) := 'ItemCntbExtract_Report.csv';
        l_authors_blob            BLOB;
        l_price_report            utl_file.file_type;
        l_price_report_name       VARCHAR2(100) := 'ItemPriceExtract_Report.csv';
        l_price_blob              BLOB;
        l_inv_report              utl_file.file_type;
        l_inv_report_name         VARCHAR2(100) := 'ItemInventoryExtract_Report.csv';
        l_inv_blob                BLOB;
        I_USER VARCHAR2(200);
        I_HOST VARCHAR2(200);
        I_PORT NUMBER;
        I_TRUST_SERVER BOOLEAN;
        l_report_flag VARCHAR2(5);
    BEGIN
        I_USER := 'peloton_integrations';
        I_HOST := '147.154.19.246';
        I_PORT := 5011;
        I_TRUST_SERVER := TRUE;
        ----------------ITEM EXTRACT REPORT ----------------------------------------------
        --dbms_output.put_line('begin');
        l_products_report := utl_file.fopen(g_directory, l_products_report_name, 'W', 32767);
        --dbms_output.put_line('open item extract');
        FOR l_header IN (
            SELECT
                column_name
            FROM
                user_tab_columns
            WHERE
                    table_name = 'HBG_CX_ITEMS_EXTRACT'
                AND column_id <= 32
            ORDER BY
                column_id
        ) LOOP
            utl_file.put(l_products_report, l_header.column_name || '|');
        END LOOP;

        utl_file.put(l_products_report, 'HIDE_FROM_ONIX|HIDE_FROM_ONIX|CUSTOMER_SPECIFIC_DESC|STATUS|ERROR_TEXT|OIC_PARENT_ID');
        utl_file.new_line(l_products_report);
        FOR l_rec IN (
            SELECT
                *
            FROM
                hbg_cx_items_extract
            WHERE
                instanceid = p_instance_id
        ) LOOP
            utl_file.put_line(l_products_report, l_rec.isbn
                                                 || '|'
                                                 || l_rec.isbn10
                                                 || '|'
                                                 || l_rec.work_isbn
                                                 || '|'
                                                 || l_rec.work_title
                                                 || '|'
                                                 || l_rec.work_sub_title
                                                 || '|'
                                                 || l_rec.owner_code
                                                 || '|'
                                                 || l_rec.owner
                                                 || '|'
                                                 || l_rec.reporting_group_code
                                                 || '|'
                                                 || l_rec.reporting_group_code_desc
                                                 || '|'
                                                 || l_rec.publisher_code
                                                 || '|'
                                                 || l_rec.publisher
                                                 || '|'
                                                 || l_rec.imprint_code
                                                 || '|'
                                                 || l_rec.imprint
                                                 || '|'
                                                 || l_rec.external_publisher_code
                                                 || '|'
                                                 || l_rec.external_publisher
                                                 || '|'
                                                 || l_rec.external_imprint_code
                                                 || '|'
                                                 || l_rec.external_imprint
                                                 || '|'
                                                 || l_rec.title
                                                 || '|'
                                                 || l_rec.sub_title
                                                 || '|'
                                                 || l_rec.edition
                                                 || '|'
                                                 || l_rec.pub_status
                                                 || '|'
                                                 || l_rec.media
                                                 || '|'
                                                 || l_rec.format_code
                                                 || '|'
                                                 || l_rec.format
                                                 || '|'
                                                 || l_rec.sub_format_code
                                                 || '|'
                                                 || l_rec.sub_format
                                                 || '|'
                                                 || l_rec.series
                                                 || '|'
                                                 || l_rec.series_number
                                                 || '|'
                                                 || l_rec.by_line
                                                 || '|'
                                                 || l_rec.publication_date
                                                 || '|'
                                                 || l_rec.keyword
                                                 || '|'
                                                 || l_rec.book_description
                                                 || '|'
                                                 || l_rec.HIDE_FROM_ONIX
                                                 || '|'
                                                 || l_rec.CUSTOMER_SPECIFIC_CODE
                                                 || '|'
                                                 || l_rec.CUSTOMER_SPECIFIC_DESC
                                                 || '|'
                                                 || l_rec.status
                                                 || '|'
                                                 || l_rec.comments
                                                 || '|'
                                                 || l_rec.instanceid);
        END LOOP;

        utl_file.fclose(l_products_report);
        l_products_blob := file_to_blob(l_products_report_name);
       ----dbms_output.put_line('item extract');
        apex_zip.add_file(p_zipped_blob => x_zip_reports, p_file_name => l_products_report_name, p_content => l_products_blob);
       ----dbms_output.put_line('add item extract');
        ---------------- ITEM BISAC REPORT --------------------------------------------
        l_collections_report := utl_file.fopen(g_directory, l_collections_report_name, 'W', 32767);
        FOR l_header IN (
            SELECT
                column_name
            FROM
                user_tab_columns
            WHERE
                    table_name = 'HBG_CX_ITEMS_BISAC_EXTRACT'
                AND column_id <= 6
            ORDER BY
                column_id
        ) LOOP
            utl_file.put(l_collections_report, l_header.column_name || '|');
        END LOOP;

        utl_file.put(l_collections_report, 'STATUS|ERROR_TEXT|OIC_PARENT_ID');
        utl_file.new_line(l_collections_report);
        FOR l_rec IN (
            SELECT
                *
            FROM
                hbg_cx_items_bisac_extract
            WHERE
                instanceid = p_instance_id
        ) LOOP
            utl_file.put_line(l_collections_report, l_rec.isbn
                                                    || '|'
                                                    || l_rec.bisac_sequence
                                                    || '|'
                                                    || l_rec.genbisac_code
                                                    || '|'
                                                    || l_rec.genbisac_name
                                                    || '|'
                                                    || l_rec.spcbisac_code
                                                    || '|'
                                                    || l_rec.spcbisac_name
                                                    || '|'
                                                    || l_rec.status
                                                    || '|'
                                                    || l_rec.comments
                                                    || '|'
                                                    || l_rec.instanceid);
        END LOOP;

        utl_file.fclose(l_collections_report);
        l_collections_blob := file_to_blob(l_collections_report_name);
       ----dbms_output.put_line('bisac extract');
        apex_zip.add_file(p_zipped_blob => x_zip_reports, p_file_name => l_collections_report_name, p_content => l_collections_blob);
       ----dbms_output.put_line('add bisac extract');

        ---------------- ITEM CNTB REPORT -----------------------------------------------
        l_authors_report := utl_file.fopen(g_directory, l_authors_report_name, 'W', 32767);
        FOR l_header IN (
            SELECT
                column_name
            FROM
                user_tab_columns
            WHERE
                    table_name = 'HBG_CX_ITEMS_CNTB_EXTRACT'
                AND column_id <= 11
            ORDER BY
                column_id
        ) LOOP
            utl_file.put(l_authors_report, l_header.column_name || '|');
        END LOOP;

        utl_file.put(l_authors_report, 'STATUS|ERROR_TEXT|OIC_PARENT_ID');
        utl_file.new_line(l_authors_report);
        FOR l_rec IN (
            SELECT
                *
            FROM
                hbg_cx_items_cntb_extract
            WHERE
                instanceid = p_instance_id
        ) LOOP
            utl_file.put_line(l_authors_report, l_rec.isbn
                                                || '|'
                                                || l_rec.contact_key
                                                || '|'
                                                || l_rec.role_code
                                                || '|'
                                                || l_rec.role_desc
                                                || '|'
                                                || l_rec.contributor_sequence
                                                || '|'
                                                || l_rec.first_name
                                                || '|'
                                                || l_rec.middle_name
                                                || '|'
                                                || l_rec.last_name
                                                || '|'
                                                || l_rec.display_name
                                                || '|'
                                                || l_rec.group_name
                                                || '|'
                                                || l_rec.contact_type
                                                || '|'
                                                || l_rec.status
                                                || '|'
                                                || l_rec.comments
                                                || '|'
                                                || l_rec.instanceid);
        END LOOP;

        utl_file.fclose(l_authors_report);
        l_authors_blob := file_to_blob(l_authors_report_name);
       ----dbms_output.put_line('cntb extract');
        apex_zip.add_file(p_zipped_blob => x_zip_reports, p_file_name => l_authors_report_name, p_content => l_authors_blob);
       ----dbms_output.put_line('add cntb extract');

        ---------------- ITEM PRICE REPORT -----------------------------------------------
        l_price_report := utl_file.fopen(g_directory, l_price_report_name, 'W', 32767);
        utl_file.put(l_price_report, 'ITEM_CODE|WORK_ISBN|USD_MSRP|CAD_MSRP|STATUS|ERROR_TEXT|OIC_PARENT_ID');
        utl_file.new_line(l_price_report);
        FOR l_rec IN (
            SELECT
                *
            FROM
                hbg_cx_items_price_extract
            WHERE
                instanceid = p_instance_id
        ) LOOP
            utl_file.put_line(l_price_report, l_rec.item_code
                                              || '|'
                                              || l_rec.work_isbn
                                              || '|'
                                              || l_rec.usd_msrp
                                              || '|'
                                              || l_rec.cad_msrp
                                              || '|'
                                              || l_rec.status
                                              || '|'
                                              || l_rec.comments
                                              || '|'
                                              || l_rec.instanceid);
        END LOOP;

        utl_file.fclose(l_price_report);
        l_price_blob := file_to_blob(l_price_report_name);
       ----dbms_output.put_line('price extract');
        apex_zip.add_file(p_zipped_blob => x_zip_reports, p_file_name => l_price_report_name, p_content => l_price_blob);
    ----dbms_output.put_line('add price extract');

        ---------------- ITEM INVENTORY REPORT -----------------------------------------------
        l_inv_report := utl_file.fopen(g_directory, l_inv_report_name, 'W', 32767);
        utl_file.put(l_inv_report, 'ISBN|USEABLE_INVENTORY|STATUS|ERROR_TEXT|OIC_PARENT_ID');
        utl_file.new_line(l_inv_report);
        FOR l_rec IN (
            SELECT
                *
            FROM
                hbg_cx_items_inventory_extract
            WHERE
                instanceid = p_instance_id
        ) LOOP
            utl_file.put_line(l_inv_report, l_rec.isbn
                                            || '|'
                                            || l_rec.useable_inventory
                                            || '|'
                                            || l_rec.status
                                            || '|'
                                            || l_rec.comments
                                            || '|'
                                            || l_rec.instanceid);
        END LOOP;

        utl_file.fclose(l_inv_report);
        l_inv_blob := file_to_blob(l_inv_report_name);
        ----dbms_output.put_line('inv extract');
        apex_zip.add_file(p_zipped_blob => x_zip_reports, p_file_name => l_inv_report_name, p_content => l_inv_blob);
        ----dbms_output.put_line('add inv extract');


       ----dbms_output.put_line('finish zip');    
        apex_zip.finish(p_zipped_blob => x_zip_reports);
        --update hbg_cx_items_execution_tracker set report_blob = x_zip_reports where instanceid = p_instance_id;
        BEGIN
         AS_SFTP_KEYMGMT.LOGIN(
            I_USER => I_USER,
            I_HOST => I_HOST,
            I_PORT => I_PORT,
            I_TRUST_SERVER => I_TRUST_SERVER
  );
        AS_SFTP.put_file('/OIC_IB/CX_Items/reports/HBG_CX_Products_' ||p_instance_id||'.zip' , x_zip_reports );
        l_report_flag := 'true';
        EXCEPTION WHEN OTHERS THEN
            l_report_flag := 'false';
            dbms_output.put_line(sqlerrm); 
        END;
        RETURN l_report_flag;

    EXCEPTION
        WHEN OTHERS THEN
               dbms_output.put_line(sqlerrm); 
            RETURN 'false';
    END;

    FUNCTION failedinvokeproc (
        p_instance_id NUMBER
    ) RETURN VARCHAR2 AS
        update_status VARCHAR2(5);
        clear_status varchar2(5);
    BEGIN
        UPDATE hbg_cx_items_extract
        SET
            status = 'PROC_ERROR'
        WHERE
                instanceid = p_instance_id
            AND status = 'NEW';

        UPDATE hbg_cx_items_bisac_extract
        SET
            status = 'PROC_ERROR'
        WHERE
                instanceid = p_instance_id
            AND status = 'NEW';

        UPDATE hbg_cx_items_cntb_extract
        SET
            status = 'PROC_ERROR'
        WHERE
                instanceid = p_instance_id
            AND status = 'NEW';

        UPDATE hbg_cx_items_inventory_extract
        SET
            status = 'PROC_ERROR'
        WHERE
                instanceid = p_instance_id
            AND status = 'NEW';

        UPDATE hbg_cx_items_price_extract
        SET
            status = 'PROC_ERROR'
        WHERE
                instanceid = p_instance_id
            AND status = 'NEW';
        COMMIT;
        clear_status := clearstagetables(p_instance_id);
        update_status := 'true';
        RETURN update_status;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'false';
    END;

    FUNCTION deletefaileditems (
        p_instance_id NUMBER
    ) RETURN VARCHAR2 AS
        delete_status VARCHAR2(5);
    BEGIN
        DELETE FROM hbg_cx_items_extract
        WHERE
            instanceid = p_instance_id;
       /* DELETE FROM HBG_CX_ITEMS_BISAC_EXTRACT
        WHERE INSTANCEID = p_instance_id;
        DELETE FROM HBG_CX_ITEMS_CNTB_EXTRACT
        WHERE INSTANCEID = p_instance_id;*/
        COMMIT;
        RETURN delete_status;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'false';
    END deletefaileditems;

    PROCEDURE publishchanges (
        p_auth  IN VARCHAR2,
        errbuf  OUT VARCHAR2,
        retcode OUT VARCHAR2
    ) AS

        l_errbuf           VARCHAR2(300);
        l_retcode          VARCHAR2(1);
        l_access_token     VARCHAR2(5000) := 'Bearer ';
        publishexception EXCEPTION;
        l_url              VARCHAR2(500) := g_url || '/ccadmin/v1/publish';
        l_response_clob    CLOB;
        l_get_publish_clob CLOB;
        l_startpublish     VARCHAR2(5);
        l_publishrunning   VARCHAR2(5) := 'true';
        l_statuspublish    VARCHAR2(500);
        l_offset           INT := 1;
    BEGIN
        errbuf := NULL;
        retcode := 0;
        g_auth := p_auth;
        l_access_token := l_access_token || get_api_access_token;
        IF l_access_token IS NULL THEN
            l_errbuf := 'Failed to get access token';
            RAISE publishexception;
        END IF;
   ----dbms_output.put_line('access token');
        apex_web_service.g_request_headers(1).name := 'Authorization';
        apex_web_service.g_request_headers(1).value := l_access_token;
        apex_web_service.g_request_headers(2).name := 'X-CCAsset-Language';
        apex_web_service.g_request_headers(2).value := 'en';
        l_response_clob := apex_web_service.make_rest_request(p_url => l_url, p_http_method => 'POST', p_wallet_path => 'file:////u01/app/wallet/https_wallet');
   /* --dbms_output.put_line('post publish');
     --dbms_output.put_line('Print CLOB');    
        loop  
        exit when l_offset > dbms_lob.getlength(l_response_clob);  
        --dbms_output.put_line( dbms_lob.substr( l_response_clob, 255, l_offset ) );  
        l_offset := l_offset + 255;  
        end loop;  */
        SELECT
            json.publish,
            json.status
        INTO
            l_startpublish,
            l_statuspublish
        FROM
                JSON_TABLE ( l_response_clob
                    COLUMNS
                        publish VARCHAR2 ( 5 ) PATH '$.publishRunning',
                        status VARCHAR2 ( 500 ) PATH '$.statusMessage'
                )
            json;
      --  --dbms_output.put_line('check post publish status');
        IF l_startpublish != 'true' THEN
            l_errbuf := 'Failed to initiate publish process - ' || l_statuspublish;
            RAISE publishexception;
        END IF;
  ----dbms_output.put_line('after check post publish status');

        WHILE l_publishrunning != 'false' LOOP
            apex_web_service.g_request_headers(1).name := 'Authorization';
            apex_web_service.g_request_headers(1).value := l_access_token;
            apex_web_service.g_request_headers(2).name := 'X-CCAsset-Language';
            apex_web_service.g_request_headers(2).value := 'en';
            l_get_publish_clob := apex_web_service.make_rest_request(p_url => l_url, p_http_method => 'GET', p_wallet_path => 'file:////u01/app/wallet/https_wallet');

            SELECT
                json.publish
            INTO l_publishrunning
            FROM
                    JSON_TABLE ( l_get_publish_clob
                        COLUMNS
                            publish VARCHAR2 ( 500 ) PATH '$.publishRunning'
                    )
                json;

            dbms_session.sleep(30);
        END LOOP;

    EXCEPTION
        WHEN publishexception THEN
            retcode := 1;
            errbuf := l_errbuf;
        WHEN OTHERS THEN
            retcode := 1;
            errbuf := sqlerrm;
    END publishchanges;

    FUNCTION execute_bulk_import_api (
        p_user_token VARCHAR2,
        p_operation  VARCHAR2
    ) RETURN VARCHAR2 AS

        x_process_id    VARCHAR2(500);
        l_url           VARCHAR2(200) := g_url || '/ccadmin/v1/importProcess/';
        l_auth          VARCHAR2(4000) := 'Bearer ' || p_user_token;
        l_response_clob CLOB;
       -- l_request_json  VARCHAR(100);
        l_request_clob  CLOB;
        l_offset        INT := 1;
    BEGIN
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';
        apex_web_service.g_request_headers(2).name := 'Authorization';
        apex_web_service.g_request_headers(2).value := l_auth;
        apex_web_service.g_request_headers(3).name := 'X-CCAsset-Language';
        apex_web_service.g_request_headers(3).value := 'en';
        --l_request_json := '{"fileName":"'||p_file_name||'"}';
        l_request_clob := to_clob('{ "fileName": "'
                                  || p_operation
                                  || '.json","mode" : "standalone", "id" : "'
                                  || p_operation
                                  || '","format" : "json","params": {"update" : true}}');

        l_response_clob := apex_web_service.make_rest_request(p_url => l_url, p_http_method => 'POST', p_body => l_request_clob, p_wallet_path =>
        'file:////u01/app/wallet/https_wallet');

       /*BEGIN  
            dbms_output.put_line('Print CLOB - execute_bulk_import_api');
            loop  
            exit when l_offset > dbms_lob.getlength(l_response_clob);  
            dbms_output.put_line( dbms_lob.substr( l_response_clob, 255, l_offset ) );  
            l_offset := l_offset + 255;  
            end loop;  
        END;*/

        SELECT
            tk.process_id
        INTO x_process_id
        FROM
                JSON_TABLE ( l_response_clob
                    COLUMNS
                        process_id VARCHAR2 ( 500 ) PATH '$.processId'
                )
            tk;

        RETURN ( x_process_id );
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END execute_bulk_import_api;

    FUNCTION start_file_upload_api (
        p_user_token VARCHAR2,
        p_file_blob  BLOB,
        p_file_name  VARCHAR2
    ) RETURN VARCHAR2 AS

        x_file_token    VARCHAR2(5000);
        l_url           VARCHAR2(100) := g_url || '/ccadmin/v1/files';
        l_auth          VARCHAR2(4000) := 'Bearer ' || p_user_token;
        l_response_clob CLOB;
        l_multipart     apex_web_service.t_multipart_parts;
        l_request_blob  BLOB;
    BEGIN
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/x-www-form-urlencoded';
        apex_web_service.g_request_headers(2).name := 'Authorization';
        apex_web_service.g_request_headers(2).value := l_auth;
        apex_web_service.g_request_headers(3).name := 'X-CCAsset-Language';
        apex_web_service.g_request_headers(3).value := 'en';
        apex_web_service.append_to_multipart(p_multipart => l_multipart, p_name => 'fileUpload', p_content_type => 'application/octet-stream',
        p_body_blob => p_file_blob);
        --dbms_output.put_line('FILE');
        apex_web_service.append_to_multipart(p_multipart => l_multipart, p_name => 'filename', p_content_type => 'text/plain', p_body =>
        p_file_name);
        --dbms_output.put_line('FILENAME');
        apex_web_service.append_to_multipart(p_multipart => l_multipart, p_name => 'uploadType', p_content_type => 'text/plain', p_body =>
        'bulkImport');
        --dbms_output.put_line('UPLOADTYPE');
        l_request_blob := apex_web_service.generate_request_body(p_multipart => l_multipart);
        --dbms_output.put_line('GENERATE BODY');
        l_response_clob := apex_web_service.make_rest_request(p_url => l_url, p_http_method => 'POST', p_body_blob => l_request_blob,
        p_wallet_path => 'file:////u01/app/wallet/https_wallet');

        SELECT
            tk.token
        INTO x_file_token
        FROM
                JSON_TABLE ( l_response_clob
                    COLUMNS
                        token VARCHAR2 ( 4000 ) PATH '$.token'
                )
            tk;

        RETURN ( x_file_token );
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(sqlerrm);
            RETURN NULL;
    END start_file_upload_api;

    PROCEDURE get_import_process_api (
        p_user_token          IN VARCHAR2,
        p_process_id          IN VARCHAR2,
        l_json_report_clob    OUT CLOB,
        l_failed_records_clob OUT CLOB,
        l_failure_count       OUT NUMBER,
        errbuf                OUT VARCHAR2,
        retcode               OUT NUMBER
    ) AS

        l_url                 VARCHAR2(500) := g_url
                               || '/ccadmin/v1/importProcess/'
                               || p_process_id;
        l_auth                VARCHAR2(5000) := 'Bearer ' || p_user_token;
        l_response_clob       CLOB;
        l_completed           VARCHAR2(5) := 'false';
        l_json_report_link    VARCHAR2(500);
        l_failed_records_link VARCHAR2(500);
        l_failed_records_blob BLOB;
        l_access_token        VARCHAR2(4000);
    BEGIN
        errbuf := NULL;
        retcode := 0;
        apex_web_service.g_request_headers(1).name := 'Authorization';
        apex_web_service.g_request_headers(1).value := l_auth;
        apex_web_service.g_request_headers(2).name := 'X-CCAsset-Language';
        apex_web_service.g_request_headers(2).value := 'en';
        WHILE ( l_completed != 'true' ) LOOP
            dbms_session.sleep(30);
            l_response_clob := apex_web_service.make_rest_request(p_url => l_url, p_http_method => 'GET', p_wallet_path => 'file:////u01/app/wallet/https_wallet');

            SELECT
                tk.completed
            INTO l_completed
            FROM
                    JSON_TABLE ( l_response_clob
                        COLUMNS
                            completed VARCHAR2 ( 500 ) PATH '$.completed'
                    )
                tk;

            IF l_completed IS NULL THEN
                l_access_token := get_api_access_token;
                l_auth := 'Bearer ' || l_access_token;
                apex_web_service.g_request_headers(1).name := 'Authorization';
                apex_web_service.g_request_headers(1).value := l_auth;
                apex_web_service.g_request_headers(2).name := 'X-CCAsset-Language';
                apex_web_service.g_request_headers(2).value := 'en';
                l_response_clob := apex_web_service.make_rest_request(p_url => l_url, p_http_method => 'GET', p_wallet_path => 'file:////u01/app/wallet/https_wallet');

                SELECT
                    tk.completed
                INTO l_completed
                FROM
                        JSON_TABLE ( l_response_clob
                            COLUMNS
                                completed VARCHAR2 ( 500 ) PATH '$.completed'
                        )
                    tk;

            END IF;

        END LOOP;

        --dbms_output.put_line('completed: ' || l_completed);
        FOR l_rec IN (
            SELECT
                tk.rel,
                tk.href
            FROM
                    JSON_TABLE ( l_response_clob, '$.links[*]'
                        COLUMNS
                            rel VARCHAR2 ( 50 ) PATH '$.rel',
                            href VARCHAR2 ( 500 ) PATH '$.href'
                    )
                tk
        ) LOOP
            IF l_rec.rel = 'meta' THEN
                l_json_report_link := l_rec.href;
            END IF;
            IF l_rec.rel = 'failedRecordsFile' THEN
                l_failed_records_link := l_rec.href;
            END IF;
        END LOOP;

        apex_web_service.g_request_headers(1).name := 'Authorization';
        apex_web_service.g_request_headers(1).value := l_auth;
        l_json_report_clob := apex_web_service.make_rest_request(p_url => l_json_report_link, p_http_method => 'GET', p_wallet_path =>
        'file:////u01/app/wallet/https_wallet');

        SELECT
            json.failure_count
        INTO l_failure_count
        FROM
                JSON_TABLE ( l_json_report_clob
                    COLUMNS (
                        failure_count NUMBER PATH '$.failureCount'
                    )
                )
            AS json;

        IF l_failure_count > 0 THEN
            apex_web_service.g_request_headers(1).name := 'Authorization';
            apex_web_service.g_request_headers(1).value := l_auth;
            l_failed_records_clob := apex_web_service.make_rest_request(p_url => l_failed_records_link, p_http_method => 'GET', p_wallet_path =>
            'file:////u01/app/wallet/https_wallet');

        ELSE
            l_failed_records_clob := NULL;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            --dbms_output.put_line('sqlerrm: ' || sqlerrm);
            errbuf := sqlerrm;
            retcode := 1;
    END get_import_process_api;

    FUNCTION clearstagetables (
        p_instance_id NUMBER
    ) RETURN VARCHAR2 AS
        clear_status VARCHAR2(5);
    BEGIN
        INSERT INTO hbg_cx_items_report
            SELECT
                *
            FROM
                hbg_cx_items_extract
            WHERE
                instanceid = p_instance_id;

        DELETE FROM hbg_cx_items_extract
        WHERE
            instanceid = p_instance_id;

        INSERT INTO hbg_cx_items_cntb_report
            SELECT
                *
            FROM
                hbg_cx_items_cntb_extract
            WHERE
                instanceid = p_instance_id;

        DELETE FROM hbg_cx_items_cntb_extract
        WHERE
            instanceid = p_instance_id;

        INSERT INTO hbg_cx_items_price_report
            SELECT
                *
            FROM
                hbg_cx_items_price_extract
            WHERE
                instanceid = p_instance_id;

        DELETE FROM hbg_cx_items_price_extract
        WHERE
            instanceid = p_instance_id;

        INSERT INTO hbg_cx_items_inventory_report
            SELECT
                *
            FROM
                hbg_cx_items_inventory_extract
            WHERE
                instanceid = p_instance_id;

        DELETE FROM hbg_cx_items_inventory_extract
        WHERE
            instanceid = p_instance_id;

         INSERT INTO hbg_cx_items_bisac_report
            SELECT
                *
            FROM
                hbg_cx_items_bisac_extract
            WHERE
                instanceid = p_instance_id;

        DELETE FROM hbg_cx_items_bisac_extract
        WHERE
            instanceid = p_instance_id;

        clear_status := 'true';
        RETURN clear_status;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'false';
    END;

     FUNCTION file_to_base64 (
        p_filename VARCHAR2
    ) RETURN CLOB AS

        x_clob_file CLOB;
        l_file      utl_file.file_type;
        l_row RAW(32767);
        l_clob CLOB;
        l_amount NUMBER := 32767;
        l_offset NUMBER := 1;
        --l_raw_value long raw;

    BEGIN
        l_file := utl_file.fopen(g_directory, p_filename, 'R', 32767);
        dbms_lob.createtemporary(x_clob_file, false, 2);
        dbms_lob.open(x_clob_file, dbms_lob.lob_readwrite);
        LOOP
                BEGIN
                    utl_file.get_raw(l_file, l_row, 32767);

                    DBMS_LOB.WRITE (x_clob_file,l_amount,l_offset,UTL_ENCODE.base64_encode(l_row));
                    l_offset := l_offset + l_amount;
                EXCEPTION
                    WHEN no_data_found THEN
                        EXIT;
                END;
            END LOOP;
        utl_file.fclose(l_file);
        dbms_lob.close(x_clob_file);
        dbms_lob.filecloseall();
        RETURN x_clob_file;
    EXCEPTION
        WHEN OTHERS THEN
           --dbms_output.put_line('file_TO_B64=' || sqlerrm);
            RETURN NULL;
    END file_to_base64;

    PROCEDURE upload_from_ui_api (
        p_user_token IN VARCHAR2,
        p_file_clob  IN CLOB,
        p_file_name  IN VARCHAR2,
        x_file_token OUT VARCHAR2,
        errbuf       OUT VARCHAR2,
        retcode      OUT NUMBER
    )  AS

        l_url           VARCHAR2(100) := g_url || '/ccadminui/v1/asset/uploadFromUI';
        l_auth          VARCHAR2(4000) := 'Bearer ' || p_user_token;
        l_request_clob  CLOB;
        l_response_clob CLOB;
        l_offset NUMBER := 1;
    BEGIN
        errbuf := NULL;
        retcode := 1;
        apex_web_service.g_request_headers.delete();
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/json';
        apex_web_service.g_request_headers(2).name := 'Authorization';
        apex_web_service.g_request_headers(2).value := l_auth;
        l_request_clob := to_clob('{"file": "') || p_file_clob || to_clob('","filename" : "' || p_file_name || '"}');
        l_response_clob := apex_web_service.make_rest_request(p_url => l_url, p_http_method => 'POST', p_body => l_request_clob,
        p_wallet_path => 'file:////u01/app/wallet/https_wallet');
       /* BEGIN  
            dbms_output.put_line('Print CLOB - upload_from_ui_api');    
            loop  
            exit when l_offset > dbms_lob.getlength(l_response_clob);  
            dbms_output.put_line( dbms_lob.substr( l_response_clob, 255, l_offset ) );  
            l_offset := l_offset + 255;  
            end loop;
        END;*/
        SELECT
            tk.token,
            tk.message
        INTO x_file_token,
             errbuf
        FROM
                JSON_TABLE ( l_response_clob
                    COLUMNS
                        token VARCHAR2 ( 4000 ) PATH '$.token',
                        message VARCHAR2(1000)  PATH '$.message'
                )
            tk;

    EXCEPTION
        WHEN OTHERS THEN
            --dbms_output.put_line(sqlerrm);
             x_file_token :=  NULL;
             errbuf := sqlerrm;
             retcode := 1;
    END upload_from_ui_api;

    FUNCTION validate_file_from_ui (
        p_user_token VARCHAR2,
        p_token varchar2
    ) RETURN CLOB AS

        l_url           VARCHAR2(500) := g_url || '/ccadminui/v1/asset/validationReport/' || p_token;
        l_auth          VARCHAR2(4000) := 'Bearer ' || p_user_token;
        l_response_clob CLOB;
        l_offset number :=1;

    BEGIN
        apex_web_service.g_request_headers.delete();
        apex_web_service.g_request_headers(1).name := 'Authorization';
        apex_web_service.g_request_headers(1).value := l_auth;
        l_response_clob := apex_web_service.make_rest_request(p_url => l_url, p_http_method => 'GET',
        p_wallet_path => 'file:////u01/app/wallet/https_wallet');
       /* BEGIN  
            dbms_output.put_line('Print CLOB - validate_file_from_ui');    
            loop  
            exit when l_offset > dbms_lob.getlength(l_response_clob);  
            dbms_output.put_line( dbms_lob.substr( l_response_clob, 255, l_offset ) );  
            l_offset := l_offset + 255;  
            end loop;  
        END;*/
        RETURN ( l_response_clob );
    EXCEPTION
        WHEN OTHERS THEN
            --dbms_output.put_line(sqlerrm);
            RETURN NULL;
    END validate_file_from_ui;

    PROCEDURE import_assets_ui (
        p_user_token IN VARCHAR2,
        p_token IN VARCHAR2,
        x_total OUT NUMBER,
        retcode OUT NUMBER,
        errbuf OUT VARCHAR2
    )  AS

        x_file_token    VARCHAR2(500);
        l_url           VARCHAR2(100) := g_url || '/ccadminui/v1/asset/import';
        l_auth          VARCHAR2(4000) := 'Bearer ' || p_user_token;
        l_request_clob  CLOB;
        l_response_clob CLOB;
        l_offset NUMBER := 1;
        l_http_error VARCHAR2(300);
        l_import_progress VARCHAR2(20);
        l_access_token VARCHAR2(4000);
        l_sleep NUMBER;

    BEGIN
        retcode := 0;
        errbuf := NULL;
        BEGIN
           apex_web_service.g_request_headers.delete();
           apex_web_service.g_request_headers(1).name := 'Content-Type';
           apex_web_service.g_request_headers(1).value := 'application/json';
           apex_web_service.g_request_headers(2).name := 'Authorization';
           apex_web_service.g_request_headers(2).value := l_auth;
           l_request_clob := to_clob('{"token": "') || p_token || to_clob('","useCatalogHeaderForCreatingNewItems" : "true"}');
           l_response_clob := apex_web_service.make_rest_request(p_url => l_url, p_http_method => 'POST', p_body => l_request_clob,
           p_wallet_path => 'file:////u01/app/wallet/https_wallet');
           /* BEGIN  
               dbms_output.put_line('Print CLOB - import_assets_ui');    
               loop  
               exit when l_offset > dbms_lob.getlength(l_response_clob);  
               dbms_output.put_line( dbms_lob.substr( l_response_clob, 255, l_offset ) );  
               l_offset := l_offset + 255;  
               end loop;
           END;*/
           SELECT
               json.total,
               json.message
           INTO x_total,
           errbuf
           FROM
                   JSON_TABLE ( l_response_clob
                       COLUMNS
                           total number PATH '$.total',
                           message varchar2(1000) PATH '$.message'
                   )
               json;
                update hbg_cx_items_execution_tracker set request =  request || l_response_clob where instanceid = g_instance_id;
                l_sleep := 1;
                l_import_progress := 'true';
                WHILE l_import_progress = 'true'
                LOOP
                    dbms_session.sleep(l_sleep);
                    l_access_token := get_api_access_token;
                    l_import_progress := get_ui_import_status(l_access_token);
                l_sleep := 300;
                END LOOP;
                x_total := 1;

        EXCEPTION WHEN OTHERS THEN
            select  utl_http.get_detailed_sqlerrm into l_http_error from dual;
            --IF l_http_error = 'ORA-29276: transfer timeout' THEN
                l_url := g_url || '/ccadminui/v1/asset/importStatus';
                apex_web_service.g_request_headers.delete();
                l_import_progress := 'true';
                WHILE l_import_progress = 'true'
                LOOP
                    dbms_session.sleep(300);
                    l_access_token := get_api_access_token;
                    l_import_progress := get_ui_import_status(l_access_token);
                END LOOP;
                x_total := 1;
           /* ELSE
                retcode := 1;
                errbuf := l_http_error;
                x_total := NULL;
            END IF;*/
        END;
    EXCEPTION
        WHEN OTHERS THEN
            --dbms_output.put_line(sqlerrm);
            retcode := 1;
            select  utl_http.get_detailed_sqlerrm into errbuf from dual;
            --errbuf := sqlerrm;
            x_total := NULL;

    END import_assets_ui;

    FUNCTION get_ui_import_status (
        p_user_token VARCHAR2
    ) RETURN varchar2 AS

        x_import_flag    VARCHAR2(100);
        l_url           VARCHAR2(100) := g_url || '/ccadminui/v1/asset/importStatus';
        l_auth          VARCHAR2(4000) := 'Bearer ' || p_user_token;
        l_response_clob CLOB;
        l_offset NUMBER := 1;

    BEGIN
        apex_web_service.g_request_headers.delete();
        apex_web_service.g_request_headers(1).name := 'Authorization';
        apex_web_service.g_request_headers(1).value := l_auth;
        l_response_clob := apex_web_service.make_rest_request(p_url => l_url, p_http_method => 'GET',
        p_wallet_path => 'file:////u01/app/wallet/https_wallet');
        /* BEGIN  
                    dbms_output.put_line('Print CLOB 1 - importSkus');    
                    loop  
                    exit when l_offset > dbms_lob.getlength(l_response_clob);  
                    dbms_output.put_line( dbms_lob.substr( l_response_clob, 255, l_offset ) );  
                    l_offset := l_offset + 255;  
                    end loop;  
                END;*/
        SELECT
            json.import_flag
        INTO x_import_flag
        FROM
                JSON_TABLE ( l_response_clob
                    COLUMNS
                        import_flag VARCHAR2 ( 100 ) PATH '$.importInProgressStatus'
                )
            json;
        dbms_output.put_line(x_import_flag);  
        RETURN ( x_import_flag );
    EXCEPTION
        WHEN OTHERS THEN
            --dbms_output.put_line(sqlerrm);
            RETURN NULL;
    END get_ui_import_status;


     FUNCTION create_collections (
        owner_code VARCHAR2,
        genre_code VARCHAR2,
        p_instance_id NUMBER
    ) RETURN varchar2 AS

        x_import_flag    VARCHAR2(100);
        l_url           VARCHAR2(100) := g_url || '/ccadmin/v1/collections';
        l_auth          VARCHAR2(4000);
        l_response_clob CLOB;
        l_offset NUMBER := 1;
        l_genre_name    varchar2(200);
        l_access_token VARCHAR2(4000);
        l_request_clob clob;
        l_error_code VARCHAR2(30);
        l_err_message VARCHAR2(4000);
    BEGIN
        SELECT DISTINCT 
            GENBISAC_NAME 
            INTO l_genre_name
            FROM HBG_CX_ITEMS_BISAC_EXTRACT 
            WHERE 
                GENBISAC_CODE = genre_code
                AND INSTANCEID = p_instance_id;

        l_request_clob := to_clob('{"parentCategoryId":"'|| owner_code || '_GENRES","properties":{"displayName":"' || l_genre_name 
        ||'","id" : "'||owner_code||'_'||genre_code||'"}}');

        l_access_token := get_api_access_token;
        l_auth := 'Bearer ' || l_access_token;

        apex_web_service.g_request_headers.delete();
        apex_web_service.g_request_headers(1).name := 'Authorization';
        apex_web_service.g_request_headers(1).value := l_auth;
        apex_web_service.g_request_headers(2).name := 'X-CCAsset-Language';
        apex_web_service.g_request_headers(2).value := 'en';
        apex_web_service.g_request_headers(3).name := 'Content-Type';
        apex_web_service.g_request_headers(3).value := 'application/json';

        l_response_clob := apex_web_service.make_rest_request(p_url => l_url, p_http_method => 'POST', p_body => l_request_clob,
        p_wallet_path => 'file:////u01/app/wallet/https_wallet');

        begin
            SELECT
                json.error_code,
                json.message
            INTO l_error_code,
                l_err_message
            FROM
                    JSON_TABLE ( l_response_clob
                        COLUMNS
                            error_code VARCHAR2(30) PATH '$.errorCode',
                            message VARCHAR2 (4000) PATH '$.message'
                    )
                json;
            EXCEPTION WHEN OTHERS THEN
                x_import_flag := 'true';
            END;

            IF l_error_code IS NULL THEN
                x_import_flag := 'true';
            ELSE 
                x_import_flag := 'false';
            END IF;

            IF x_import_flag = 'true' then
                INSERT INTO HBG_CX_ITEMS_COLLECTIONS (COLLECTION_ID, DISPLAY_NAME, IS_ACTIVE, CREATION_DATE, LAST_UPDATE_DATE)
                    VALUES (owner_code||'_'||genre_code, l_genre_name,'true',SYSDATE,SYSDATE);
                COMMIT;
            END IF;

        /* BEGIN  
                    dbms_output.put_line('Print CLOB 1 - importSkus');    
                    loop  
                    exit when l_offset > dbms_lob.getlength(l_response_clob);  
                    dbms_output.put_line( dbms_lob.substr( l_response_clob, 255, l_offset ) );  
                    l_offset := l_offset + 255;  
                    end loop;  
                END;*/

        RETURN ( 'true' );
    EXCEPTION
        WHEN OTHERS THEN
            --dbms_output.put_line(sqlerrm);
            RETURN 'false';
    END create_collections;


END hbg_cx_items_pkg;

/
