--------------------------------------------------------
--  DDL for Procedure HBG_PIM_CONVERSION_P
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "HBG_INTEGRATION"."HBG_PIM_CONVERSION_P" (p_hbg_process_id  IN NUMBER) AS

    R_INSERT EXCEPTION;

    CURSOR C_PIM IS
    SELECT hpc.*
          ,(SELECT LISTAGG(hpp.edition_onix_name, ';')
              FROM hbg_pim_pem_stg hpp
             WHERE hpp.isbn13 = hpc.isbn) concat_edition
         ,(SELECT NVL(MAX(hdci.digital_content_flag), 'N')
             FROM hbg_digital_content_items hdci
            WHERE hdci.isbn = hpc.isbn) digital_content_flag
      FROM hbg_pim_conversion hpc
      WHERE ROWNUM <= 1000;
      --WHERE isbn IN ('9780151003082', '2000009116182', '9781455583560');

BEGIN

    EXECUTE IMMEDIATE 'TRUNCATE TABLE HBG_PIM_CPM_STG';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE HBG_PIM_PAM_STG';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE HBG_PIM_PBC_STG';

    FOR R_PIM IN C_PIM LOOP
        BEGIN

            BEGIN
                INSERT /*+  APPEND PARALLEL  */  
                  INTO HBG_PIM_CPM_STG 
                      (ISBN13
                     , LONG_TITLE
                     , AUTHOR_NAME
                     , OWNER_CODE
                     , REPORTING_GROUP_CODE
                     , PUBLISHER_CODE
                     , IMPRINT_CODE
                     , EXTERNAL_PUBLISHER_CODE
                     , EXTERNAL_IMPRINT_CODE
                     , FORMAT_CODE
                     , SUB_FORMAT_CODE
                     , EDITION
                     , SHORT_TITLE
                     , HBG_PROCESS_ID
                     , DIGITAL_CONTENT_FLAG) 
                VALUES 
                      (R_PIM.ISBN
                     , R_PIM.ITEM_DESCRIPTION
                     , R_PIM.AUTHOR_NAME
                     , R_PIM.OWNER
                     , R_PIM.REPORTING_GROUP
                     , R_PIM.CATEGORY_1
                     , R_PIM.CATEGORY_2
                     , R_PIM.EXTERNAL_PUBLISHER
                     , R_PIM.EXTERNAL_IMPRINT
                     , R_PIM.FORMAT
                     , R_PIM.SUBFORMAT
                     , R_PIM.CONCAT_EDITION
                     , R_PIM.SHORT_TITLE
                     , p_hbg_process_id
                     , R_PIM.DIGITAL_CONTENT_FLAG);
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('ERROR TRYING TO INSERT INTO HBG_PIM_CPM_STG TABLE, ERROR DETAILS: '||SQLERRM);
                    RAISE R_INSERT;
            END;

            BEGIN
                INSERT /*+  APPEND PARALLEL  */  
                  INTO HBG_PIM_PAM_STG 
                      (ISBN13
                     , PUBLICATION_DATE
                     , DISCOUNT_GROUP_CODE
                     , ASSTD_FORMAT_CODE
                     , ASSTD_SUB_FORMAT_CODE
                     , HBG_PROCESS_ID) 
                VALUES 
                      (R_PIM.ISBN
                     , R_PIM.PUBLICATION_DATE
                     , R_PIM.DISCOUNT_GROUP
                     , R_PIM.ASSOCIATED_FORMAT
                     , R_PIM.ASSOCIATED_SUBFORMAT
                     , p_hbg_process_id
                     );
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('ERROR TRYING TO INSERT INTO HBG_PIM_PAM_STG TABLE, ERROR DETAILS: '||SQLERRM);
                    RAISE R_INSERT;
            END;

            
            FOR r_bisac IN (SELECT R_PIM.BISAC1 BISAC
                                 , 1 SEQUENCE
                              FROM DUAL

                              UNION ALL

                            SELECT R_PIM.BISAC2 BISAC
                                 , 2 SEQUENCE
                              FROM DUAL

                              UNION ALL

                            SELECT R_PIM.BISAC3 BISAC
                                 , 3 SEQUENCE
                              FROM DUAL

                             ORDER BY 2) LOOP

                            IF R_BISAC.BISAC IS NOT NULL THEN
                                BEGIN
                                    INSERT /*+  APPEND PARALLEL  */  
                                      INTO HBG_PIM_PBC_STG 
                                          (ISBN13
                                         , GENBISAC_CODE
                                         , SPCBISAC_CODE
                                         , BISAC_SEQUENCE
                                         , HBG_PROCESS_ID) 
                                    VALUES 
                                          (R_PIM.ISBN
                                         --, SUBSTR(R_BISAC.BISAC,0, 3)
                                         , R_BISAC.BISAC
                                         , SUBSTR(R_BISAC.BISAC, 4)
                                         , R_BISAC.SEQUENCE
                                         , p_hbg_process_id);
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        DBMS_OUTPUT.PUT_LINE('ERROR TRYING TO INSERT INTO HBG_PIM_PBC_STG TABLE FOR THE COUNTER: '||R_BISAC.SEQUENCE||', ERROR DETAILS: '||SQLERRM);
                                        RAISE R_INSERT;
                                END;
                            END IF;
            END LOOP;

        COMMIT;
        EXCEPTION 
            WHEN R_INSERT THEN
                ROLLBACK;
                CONTINUE;
        END;
    END LOOP;

    COMMIT;

EXCEPTION 
    WHEN OTHERS THEN 
        DBMS_OUTPUT.PUT_LINE('ERROR DETAILS: '||SQLERRM);
        ROLLBACK;
        RAISE;
END HBG_PIM_CONVERSION_P;

/
