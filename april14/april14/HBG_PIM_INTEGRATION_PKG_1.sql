--------------------------------------------------------
--  DDL for Package Body HBG_PIM_INTEGRATION_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."HBG_PIM_INTEGRATION_PKG" IS
   -- -----------------------------------------------------------------------------------------------------------------
   --  Package Body: HBG_PIM_INTEGRATION_PKG
   -- -----------------------------------------------------------------------------------------------------------------
   --
   --  Description: Package responsible for processing items data to be loaded into Oracle ERP Cloud (PIM) trough FBDI.
   --
   -- -----------------------------------------------------------------------------------------------------------------
   --  Change History
   -- -----------------------------------------------------------------------------------------------------------------
   --  Version  Date         Task Number            Author              Description of Change
   -- -----------------------------------------------------------------------------------------------------------------
   --     0.1   23-JAN-2023  Oracle Project Wave 3  Peloton Consulting  Initial Version
   -- -----------------------------------------------------------------------------------------------------------------

   -- -----------------------------------------------------------------------------------------------------------------
   --  PROCEDURE: log_p
   -- -----------------------------------------------------------------------------------------------------------------
   --
   --  Parameters: p_type - type of the log (e.g. ERROR, WARNING)
   --              p_text - text to be printed in the log file
   --
   --  Description: Procedure to save log messages
   --
   -- -----------------------------------------------------------------------------------------------------------------
   PROCEDURE log_p(p_type IN VARCHAR2
                  ,p_text IN VARCHAR2) IS
   BEGIN
      INSERT INTO hbg_pim_integration_logs
         (log_id
         ,log_date
         ,log_type
         ,log_message
         ,oic_instance_id
         ,hbg_process_id)
      VALUES
         (hbg_pim_integration_logs_seq.NEXTVAL
         ,CURRENT_DATE
         ,p_type
         ,p_text
         ,gv_oic_instance_id
         ,gv_hbg_process_id);
      --
      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         COMMIT;
         dbms_output.put_line('ERROR inserting record into HBG_PIM_INTEGRATION_LOGS - ' || SQLERRM);
   END log_p;

   -- -----------------------------------------------------------------------------------------------------------------
   --  PROCEDURE: get_hbg_process_status_p
   -- -----------------------------------------------------------------------------------------------------------------
   --
   --  Parameters: p_hbg_process_id - HBG Process ID
   --              p_status - output parameter - Process status
   --
   --  Description: it returns (p_status output parameter) the process status of the HBG process ID passed as input
   --               parameter.
   --               p_status = 0 - Success
   --                          1 - In Progress
   --                          2 - Warning (based on threshold value configured in HBG_PIM_PARAMETERS table)
   --                          3 - Error
   --
   -- -----------------------------------------------------------------------------------------------------------------
   PROCEDURE get_hbg_process_status_p(p_hbg_process_id IN NUMBER
                                     ,p_status         OUT VARCHAR2) IS

      lv_count_errors NUMBER := 0;
      lv_debug VARCHAR2(1000);
      lv_error_msg VARCHAR2(32000);
      lv_errors_threshold NUMBER;
      lv_status VARCHAR2(30);

   BEGIN
      gv_hbg_process_id := p_hbg_process_id;
      p_status := 'ERROR';

      lv_debug := 'CHECK_STATUS_UNTIL_STEP_4_FBDI_FILE_IS_CREATED_AND_UPLOADED_TO_FTP';
      BEGIN
         SELECT hic.status
           INTO lv_status
           FROM hbg_integration_control hic
          WHERE hic.hbg_process_id = gv_hbg_process_id
            AND hic.step_number = 0;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            lv_status := 'NOT STARTED';
         WHEN OTHERS THEN
            lv_error_msg := 'ERROR checking status until step 4 (FBDI file is created and uploaded to FTP). ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      IF lv_status IN ('WARNING', 'SUCCESS') THEN
         lv_debug := 'CHECK_STATUS_OF_CALLBACK_SUBPROCESS';
         BEGIN
            SELECT DECODE(hic.status
                         ,'NOT STARTED', 'IN PROGRESS'
                         ,hic.status) status
              INTO lv_status
              FROM hbg_integration_control hic
             WHERE hic.hbg_process_id = gv_hbg_process_id
               AND hic.step_number = 6;
         EXCEPTION
            WHEN OTHERS THEN
               lv_error_msg := 'ERROR checking status of callback subprocess. ' || SQLERRM;
               RAISE ge_custom_exception;
         END;
      END IF;

      IF lv_status IN ('WARNING', 'SUCCESS') THEN
         lv_debug := 'GET_ERRORS_THRESHOLD_PARAMETER';
         BEGIN
            SELECT hpip.param_number1
              INTO lv_errors_threshold
              FROM hbg_pim_int_parameters hpip
             WHERE hpip.parameter_name = 'ERRORS_THRESHOLD';
         EXCEPTION
            WHEN OTHERS THEN
               lv_error_msg := 'ERROR getting value of integration parameter [ERRORS_THRESHOLD]. ' ||
                               'It has been considered 100. ' || SQLERRM;
               lv_errors_threshold := 100;
         END;

         lv_debug := 'COUNT_ERRORS_IN_PROCESS_TABLE_HBG_PIM_CPM';
         BEGIN
            SELECT COUNT(1)
              INTO lv_count_errors
              FROM hbg_pim_cpm hpc
             WHERE hpc.hbg_process_id = gv_hbg_process_id
               AND hpc.status = 'ERROR';
         EXCEPTION
            WHEN OTHERS THEN
               lv_error_msg := 'ERROR counting errors in process table [HBG_PIM_CPM]. ' || SQLERRM;
               RAISE ge_custom_exception;
         END;

         lv_debug := 'APPLY_ERRORS_THRESHOLD_RULE';
         IF lv_count_errors > lv_errors_threshold THEN
            lv_status := 'ERROR';
         ELSIF lv_count_errors > 0 THEN
            lv_status := 'WARNING';
         END IF;
      END IF;

      p_status := lv_status;

   EXCEPTION
      WHEN ge_custom_exception THEN
         log_p('ERROR'
              ,'ERROR at the step [' || lv_debug || '] of the [GET_HBG_PROCESS_STATUS_P]. ' || lv_error_msg);
      WHEN OTHERS THEN
         log_p('ERROR'
              ,'GENERAL ERROR at the step [' || lv_debug || '] of the [GET_HBG_PROCESS_STATUS_P] - ' || dbms_utility.format_error_backtrace);
   END get_hbg_process_status_p;

   -- -----------------------------------------------------------------------------------------------------------------
   --  PROCEDURE: update_item_intf_eff_b_status
   -- -----------------------------------------------------------------------------------------------------------------
   --
   --  Parameters: p_hbg_process_id - HBG Process ID
   --              p_oic_instance_id - OIC Instance ID
   --              p_item_intf_eff_b_tb - Table of hbg_ego_item_intf_eff_b_status_rec
   --
   --  Description: procedure used to update status and error_text fields of table HBG_EGO_ITEM_INTF_EFF_B.
   --
   -- -----------------------------------------------------------------------------------------------------------------
   PROCEDURE update_item_intf_eff_b_status(p_hbg_process_id     IN NUMBER
                                          ,p_oic_instance_id    IN NUMBER
                                          ,p_item_intf_eff_b_tb IN gt_hbg_ego_item_intf_eff_b_status_tb) IS

      le_update_exception EXCEPTION;
      PRAGMA EXCEPTION_INIT(le_update_exception, -24381);

   BEGIN
      gv_hbg_process_id := p_hbg_process_id;
      gv_oic_instance_id := p_oic_instance_id;
      --
      BEGIN
         FORALL i IN 1 .. p_item_intf_eff_b_tb.COUNT SAVE EXCEPTIONS
            UPDATE hbg_ego_item_intf_eff_b
               SET status = p_item_intf_eff_b_tb(i).status
                  ,error_text = p_item_intf_eff_b_tb(i).error_text
             WHERE batch_id =p_item_intf_eff_b_tb(i).batch_id
               AND item_number = p_item_intf_eff_b_tb(i).item_number
               AND organization_code = p_item_intf_eff_b_tb(i).organization_code
               AND context_code = p_item_intf_eff_b_tb(i).context_code
               AND (attribute_char1 = p_item_intf_eff_b_tb(i).attribute_char1 OR attribute_char1 IS NULL)
               AND (attribute_char2 = p_item_intf_eff_b_tb(i).attribute_char2 OR attribute_char2 IS NULL)
               AND (attribute_char3 = p_item_intf_eff_b_tb(i).attribute_char3 OR attribute_char3 IS NULL)
               AND (attribute_number1 = p_item_intf_eff_b_tb(i).attribute_number1 OR attribute_number1 IS NULL)
               AND (attribute_number2 = p_item_intf_eff_b_tb(i).attribute_number2 OR attribute_number2 IS NULL)
               AND (attribute_number3 = p_item_intf_eff_b_tb(i).attribute_number3 OR attribute_number3 IS NULL);
         --
         COMMIT;
      EXCEPTION
         WHEN le_update_exception THEN
            --
            FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
               log_p('ERROR'
                    ,'ERROR updating records in HBG_EGO_ITEM_INTF_EFF_B - BATCH_ID ['
                     || p_item_intf_eff_b_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).batch_id || '] - '
                     || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
            END LOOP;
            --
            COMMIT;
            RAISE ge_custom_exception;
            --
         WHEN OTHERS THEN
            log_p('ERROR'
                 ,'GENERAL ERROR when updating records in [HBG_EGO_ITEM_INTF_EFF_B] - ' || SQLERRM);
            RAISE ge_custom_exception;
      END;

   EXCEPTION
      WHEN ge_custom_exception THEN
         RAISE;
      WHEN OTHERS THEN
         log_p('ERROR'
              ,'ERROR in [UPDATE_ITEM_INTF_EFF_B_STATUS]. ' || SQLERRM);
         RAISE;
   END update_item_intf_eff_b_status;

   -- -----------------------------------------------------------------------------------------------------------------
   --  PROCEDURE: update_fbdi_tables_status_to_error_p
   -- -----------------------------------------------------------------------------------------------------------------
   --
   --  Parameters: p_hbg_process_id - HBG Process ID
   --              p_oic_instance_id - OIC Instance ID
   --
   --  Description: procedure responsible for updating status and error message of FBDI tables records
   --
   -- -----------------------------------------------------------------------------------------------------------------
   PROCEDURE update_fbdi_tables_status_to_error_p(p_hbg_process_id  IN NUMBER
                                                 ,p_oic_instance_id IN NUMBER) IS

      lv_debug VARCHAR2(300);

   BEGIN
      gv_hbg_process_id := p_hbg_process_id;
      gv_oic_instance_id := p_oic_instance_id;

      lv_debug := 'UPDATE_HBG_EGP_SYSTEM_ITEMS_INTERFACE';
      UPDATE hbg_egp_system_items_interface
         SET status = 'ERROR'
            ,error_text = TRIM(error_text || ' Loading process completed with error.'
                               || 'Check logs for details.')
       WHERE batch_id = gv_hbg_process_id;
      --
      lv_debug := 'UPDATE_HBG_EGP_ITEM_CATEGORIES_INTERFACE';
      UPDATE hbg_egp_item_categories_interface
         SET status = 'ERROR'
            ,error_text = TRIM(error_text || ' Loading process completed with error.'
                               || 'Check logs for details.')
       WHERE batch_id = gv_hbg_process_id;
      --
      lv_debug := 'UPDATE_HBG_EGO_ITEM_INTF_EFF_B';
      UPDATE hbg_ego_item_intf_eff_b
         SET status = 'ERROR'
            ,error_text = TRIM(error_text || ' Loading process completed with error.'
                               || 'Check logs for details.')
       WHERE batch_id = gv_hbg_process_id;
      --
      COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
         COMMIT;
         log_p('ERROR'
              ,'ERROR at the step [' || lv_debug || '] of the [UPDATE_FBDI_TABLES_STATUS_TO_ERROR_P]. ' || SQLERRM);
         raise_application_error(-20001, 'ERROR occured in [HBG_PIM_INTEGRATION_PKG.UPDATE_FBDI_TABLES_STATUS_TO_ERROR_P]. '
                                         || 'Check logs for details.');
   END update_fbdi_tables_status_to_error_p;

   -- -----------------------------------------------------------------------------------------------------------------
   --  PROCEDURE: update_process_tables_status_to_error_p
   -- -----------------------------------------------------------------------------------------------------------------
   --
   --  Parameters: p_hbg_process_id - HBG Process ID
   --              p_oic_instance_id - OIC Instance ID
   --
   --  Description: procedure responsible for updating status and error message of process tables records
   --
   -- -----------------------------------------------------------------------------------------------------------------
   PROCEDURE update_process_tables_status_to_error_p(p_hbg_process_id  IN NUMBER
                                                    ,p_oic_instance_id IN NUMBER) IS

      lv_debug VARCHAR2(300);

   BEGIN
      gv_hbg_process_id := p_hbg_process_id;
      gv_oic_instance_id := p_oic_instance_id;

      lv_debug := 'UPDATE_HBG_PIM_CPM';
      UPDATE hbg_pim_cpm
         SET status = 'ERROR'
            ,error_text = TRIM(error_text || ' Loading process completed with error.'
                               || 'Check logs for details.')
       WHERE hbg_process_id = gv_hbg_process_id;
      --
      lv_debug := 'UPDATE_HBG_PIM_PAM';
      UPDATE hbg_pim_pam
         SET status = 'ERROR'
            ,error_text = TRIM(error_text || ' Loading process completed with error.'
                               || 'Check logs for details.')
       WHERE hbg_process_id = gv_hbg_process_id;
      --
      lv_debug := 'UPDATE_HBG_PIM_PAT';
      UPDATE hbg_pim_pat
         SET status = 'ERROR'
            ,error_text = TRIM(error_text || ' Loading process completed with error.'
                               || 'Check logs for details.')
       WHERE hbg_process_id = gv_hbg_process_id;
      --
      lv_debug := 'UPDATE_HBG_PIM_PBC';
      UPDATE hbg_pim_pbc
         SET status = 'ERROR'
            ,error_text = TRIM(error_text || ' Loading process completed with error.'
                               || 'Check logs for details.')
       WHERE hbg_process_id = gv_hbg_process_id;
      --
      lv_debug := 'UPDATE_HBG_PIM_PCA';
      UPDATE hbg_pim_pca
         SET status = 'ERROR'
            ,error_text = TRIM(error_text || ' Loading process completed with error.'
                               || 'Check logs for details.')
       WHERE hbg_process_id = gv_hbg_process_id;
      --
      lv_debug := 'UPDATE_HBG_PIM_PCC';
      UPDATE hbg_pim_pcc
         SET status = 'ERROR'
            ,error_text = TRIM(error_text || ' Loading process completed with error.'
                               || 'Check logs for details.')
       WHERE hbg_process_id = gv_hbg_process_id;
      --
      lv_debug := 'UPDATE_HBG_PIM_PEM';
      UPDATE hbg_pim_pem
         SET status = 'ERROR'
            ,error_text = TRIM(error_text || ' Loading process completed with error.'
                               || 'Check logs for details.')
       WHERE hbg_process_id = gv_hbg_process_id;
      --
      COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
         COMMIT;
         log_p('ERROR'
              ,'ERROR at the step [' || lv_debug || '] of the [UPDATE_FBDI_TABLES_STATUS_TO_ERROR_P]. ' || SQLERRM);
         raise_application_error(-20001, 'ERROR occured in [HBG_PIM_INTEGRATION_PKG.UPDATE_FBDI_TABLES_STATUS_TO_ERROR_P]. '
                                         || 'Check logs for details.');
   END update_process_tables_status_to_error_p;

   -- -----------------------------------------------------------------------------------------------------------------
   --  PROCEDURE: update_process_tables_p
   -- -----------------------------------------------------------------------------------------------------------------
   --
   --  Parameters: p_hbg_process_id - HBG Process ID
   --              p_oic_instance_id - OIC Instance ID
   --
   --  Description: procedure responsible for updating status and error message of process tables records
   --
   -- -----------------------------------------------------------------------------------------------------------------
   PROCEDURE update_process_tables_p(p_hbg_process_id  IN NUMBER
                                    ,p_oic_instance_id IN NUMBER) IS

      lv_debug VARCHAR2(300);
      lv_error_msg VARCHAR2(32000);
      lv_keep_data_in_fbdi_tables CHAR(1) := 'N';

   BEGIN
      gv_hbg_process_id := p_hbg_process_id;
      gv_oic_instance_id := p_oic_instance_id;

      -- HBG_PIM_PEM
      lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_PEM_FROM_HBG_EGO_ITEM_INTF_EFF_B';
      BEGIN
         MERGE INTO hbg_pim_pem hpp
         USING hbg_ego_item_intf_eff_b heiieb
         ON (heiieb.item_number = hpp.isbn13
             AND heiieb.batch_id = hpp.hbg_process_id
             AND heiieb.attribute_char1 = hpp.edition_code
             AND heiieb.attribute_number1 = hpp.sequence
             AND heiieb.organization_code = 'ITEM_MASTER'
             AND heiieb.context_code = 'Edition Information'
             AND hpp.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpp.status = CASE
                                   WHEN (hpp.status = 'SUCCESS' AND heiieb.status = 'ERROR')
                                     OR (hpp.status = 'ERROR' AND heiieb.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heiieb.status
                                END
                  ,hpp.error_text = TRIM(hpp.error_text || ' ' || DECODE(heiieb.status
                                                                        ,'ERROR', NVL(heiieb.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_PEM] from [' ||
                            'HBG_EGO_ITEM_INTF_EFF_B - Edition Information]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_PEM_FROM_HBG_EGP_ITEM_CATEGORIES_INTERFACE_HBG_Edition_1';
      BEGIN
         MERGE INTO hbg_pim_pem hpp
         USING hbg_egp_item_categories_interface heici
         ON (heici.item_number = hpp.isbn13
             AND heici.batch_id = hpp.hbg_process_id
             AND heici.organization_code = 'ITEM_MASTER'
             AND heici.category_set_name = 'HBG Edition 1'
             AND heici.category_code = 'ED1_' || TRIM(REPLACE(REPLACE(hpp.edition_code, CHR(10), ' '), CHR(13), ' '))
             AND hpp.sequence = 1
             AND hpp.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpp.status = CASE
                                   WHEN (hpp.status = 'SUCCESS' AND heici.status = 'ERROR')
                                     OR (hpp.status = 'ERROR' AND heici.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heici.status
                                END
                  ,hpp.error_text = TRIM(hpp.error_text || ' ' || DECODE(heici.status
                                                                        ,'ERROR', NVL(heici.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_PEM] from [' ||
                            'HBG_EGP_ITEM_CATEGORIES_INTERFACE - HBG Edition 1].' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'MERGE_ERROR_TEXT_INTO_HBG_PIM_PEM_FROM_HBG_EGP_ITEM_CATEGORIES_INTERFACE_HBG_Edition_2';
      BEGIN
         MERGE INTO hbg_pim_pem hpp
         USING hbg_egp_item_categories_interface heici
         ON (heici.item_number = hpp.isbn13
             AND heici.batch_id = hpp.hbg_process_id
             AND heici.organization_code = 'ITEM_MASTER'
             AND heici.category_set_name = 'HBG Edition 2'
             AND heici.category_code = 'ED2_' || TRIM(REPLACE(REPLACE(hpp.edition_code, CHR(10), ' '), CHR(13), ' '))
             AND hpp.sequence = 2
             AND hpp.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpp.status = CASE
                                   WHEN (hpp.status = 'SUCCESS' AND heici.status = 'ERROR')
                                     OR (hpp.status = 'ERROR' AND heici.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heici.status
                                END
                  ,hpp.error_text = TRIM(hpp.error_text || ' ' || DECODE(heici.status
                                                                        ,'ERROR', NVL(heici.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_PEM] from [' ||
                            'HBG_EGP_ITEM_CATEGORIES_INTERFACE - HBG Edition 2].' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      -- HBG_PIM_PAT
      lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_PAT';
      BEGIN
         MERGE INTO hbg_pim_pat hpp
         USING hbg_ego_item_intf_eff_b heiieb
         ON (heiieb.item_number = hpp.isbn13
             AND heiieb.batch_id = hpp.hbg_process_id
             AND heiieb.attribute_char1 = hpp.alternate_item_code
             AND heiieb.attribute_char2 = hpp.alternate_item_type
             AND heiieb.organization_code = 'ITEM_MASTER'
             AND heiieb.context_code = 'Alternate Item'
             AND hpp.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpp.status = CASE
                                   WHEN (hpp.status = 'SUCCESS' AND heiieb.status = 'ERROR')
                                     OR (hpp.status = 'ERROR' AND heiieb.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heiieb.status
                                END
                  ,hpp.error_text = TRIM(hpp.error_text || ' ' || DECODE(heiieb.status
                                                                        ,'ERROR', NVL(heiieb.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_PAT]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      -- HBG_PIM_PCA
      lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_PCA';
      BEGIN
         MERGE INTO hbg_pim_pca hpp
         USING hbg_ego_item_intf_eff_b heiieb
         ON (heiieb.item_number = hpp.isbn13
             AND heiieb.batch_id = hpp.hbg_process_id
             AND heiieb.attribute_char1 = hpp.role_code
             AND heiieb.attribute_number1 = hpp.cntb_sequence
             AND heiieb.organization_code = 'ITEM_MASTER'
             AND heiieb.context_code = 'Contributor'
             AND hpp.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpp.status = CASE
                                   WHEN (hpp.status = 'SUCCESS' AND heiieb.status = 'ERROR')
                                     OR (hpp.status = 'ERROR' AND heiieb.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heiieb.status
                                END
                  ,hpp.error_text = TRIM(hpp.error_text || ' ' || DECODE(heiieb.status
                                                                        ,'ERROR', NVL(heiieb.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_PCA]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      -- HBG_PIM_PBC
      lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_PBC_FROM_HBG_EGO_ITEM_INTF_EFF_B';
      BEGIN
         MERGE INTO hbg_pim_pbc hpp
         USING hbg_ego_item_intf_eff_b heiieb
         ON (heiieb.item_number = hpp.isbn13
             AND heiieb.batch_id = hpp.hbg_process_id
             --AND heiieb.attribute_char1 = TRIM(REPLACE(REPLACE(hpp.genbisac_code, CHR(10), ' '), CHR(13), ' '))
             AND heiieb.attribute_number2 = hpp.bisac_sequence
             AND heiieb.organization_code = 'ITEM_MASTER'
             AND heiieb.context_code = 'General BISAC'
             AND hpp.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpp.status = CASE
                                   WHEN (hpp.status = 'SUCCESS' AND heiieb.status = 'ERROR')
                                     OR (hpp.status = 'ERROR' AND heiieb.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heiieb.status
                                END
                  ,hpp.error_text = TRIM(hpp.error_text || ' ' || DECODE(heiieb.status
                                                                        ,'ERROR', NVL(heiieb.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_PBC] from [' ||
                            'HBG_EGO_ITEM_INTF_EFF_B]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_PBC_FROM_HBG_EGP_ITEM_CATEGORIES_INTERFACE_HBG_BISAC_1';
      BEGIN
         MERGE INTO hbg_pim_pbc hpp
         USING hbg_egp_item_categories_interface heici
         ON (heici.item_number = hpp.isbn13
             AND heici.batch_id = hpp.hbg_process_id
             AND heici.organization_code = 'ITEM_MASTER'
             AND heici.category_set_name = 'HBG BISAC 1'
             /*AND heici.category_code = 'BIS1_' || TRIM(REPLACE(REPLACE(TO_CHAR(hpp.genbisac_code) || TO_CHAR(hpp.spcbisac_code), CHR(10), ' ')
                                                              ,CHR(13), ' '))*/
             AND hpp.bisac_sequence = 1
             AND hpp.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpp.status = CASE
                                   WHEN (hpp.status = 'SUCCESS' AND heici.status = 'ERROR')
                                     OR (hpp.status = 'ERROR' AND heici.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heici.status
                                END
                  ,hpp.error_text = TRIM(hpp.error_text || ' ' || DECODE(heici.status
                                                                        ,'ERROR', NVL(heici.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_PBC] from [' ||
                            'HBG_EGP_ITEM_CATEGORIES_INTERFACE - HBG BISAC 1].' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_PBC_FROM_HBG_EGP_ITEM_CATEGORIES_INTERFACE_HBG_BISAC_2';
      BEGIN
         MERGE INTO hbg_pim_pbc hpp
         USING hbg_egp_item_categories_interface heici
         ON (heici.item_number = hpp.isbn13
             AND heici.batch_id = hpp.hbg_process_id
             AND heici.organization_code = 'ITEM_MASTER'
             AND heici.category_set_name = 'HBG BISAC 2'
             /*AND heici.category_code = 'BIS2_' || TRIM(REPLACE(REPLACE(TO_CHAR(hpp.genbisac_code) || TO_CHAR(hpp.spcbisac_code), CHR(10), ' ')
                                                              ,CHR(13), ' '))*/
             AND hpp.bisac_sequence = 2
             AND hpp.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpp.status = CASE
                                   WHEN (hpp.status = 'SUCCESS' AND heici.status = 'ERROR')
                                     OR (hpp.status = 'ERROR' AND heici.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heici.status
                                END
                  ,hpp.error_text = TRIM(hpp.error_text || ' ' || DECODE(heici.status
                                                                        ,'ERROR', NVL(heici.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_PBC] from [' ||
                            'HBG_EGP_ITEM_CATEGORIES_INTERFACE - HBG BISAC 2].' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_PBC_FROM_HBG_EGP_ITEM_CATEGORIES_INTERFACE_HBG_BISAC_3';
      BEGIN
         MERGE INTO hbg_pim_pbc hpp
         USING hbg_egp_item_categories_interface heici
         ON (heici.item_number = hpp.isbn13
             AND heici.batch_id = hpp.hbg_process_id
             AND heici.organization_code = 'ITEM_MASTER'
             AND heici.category_set_name = 'HBG BISAC 3'
             /*AND heici.category_code = 'BIS3_' || TRIM(REPLACE(REPLACE(TO_CHAR(hpp.genbisac_code) || TO_CHAR(hpp.spcbisac_code), CHR(10), ' ')
                                                              ,CHR(13), ' '))*/
             AND hpp.bisac_sequence = 3
             AND hpp.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpp.status = CASE
                                   WHEN (hpp.status = 'SUCCESS' AND heici.status = 'ERROR')
                                     OR (hpp.status = 'ERROR' AND heici.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heici.status
                                END
                  ,hpp.error_text = TRIM(hpp.error_text || ' ' || DECODE(heici.status
                                                                        ,'ERROR', NVL(heici.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_PBC] from [' ||
                            'HBG_EGP_ITEM_CATEGORIES_INTERFACE - HBG BISAC 3].' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      -- HBG_PIM_PAM
      lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_PAM_FROM_HBG_EGO_ITEM_INTF_EFF_B_BOM';
      BEGIN
         MERGE INTO hbg_pim_pam hpp
         USING hbg_ego_item_intf_eff_b heiieb
         ON (heiieb.item_number = hpp.isbn13
             AND heiieb.batch_id = hpp.hbg_process_id
             AND (heiieb.attribute_char1 = hpp.bom_type OR hpp.bom_type IS NULL)
             AND (heiieb.attribute_char2 = hpp.bom_boxed_set_ind OR hpp.bom_boxed_set_ind IS NULL)
             AND heiieb.organization_code = 'ITEM_MASTER'
             AND heiieb.context_code = 'BOM'
             AND hpp.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpp.status = CASE
                                   WHEN (hpp.status = 'SUCCESS' AND heiieb.status = 'ERROR')
                                     OR (hpp.status = 'ERROR' AND heiieb.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heiieb.status
                                END
                  ,hpp.error_text = TRIM(hpp.error_text || ' ' || DECODE(heiieb.status
                                                                        ,'ERROR', NVL(heiieb.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_PAM] from [' ||
                            'HBG_EGO_ITEM_INTF_EFF_B - BOM]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_PAM_FROM_HBG_EGO_ITEM_INTF_EFF_B_Carton';
      BEGIN
         MERGE INTO hbg_pim_pam hpp
         USING hbg_ego_item_intf_eff_b heiieb
         ON (heiieb.item_number = hpp.isbn13
             AND heiieb.batch_id = hpp.hbg_process_id
             AND (heiieb.attribute_number1 = hpp.current_carton_qty OR hpp.current_carton_qty IS NULL)
             AND (heiieb.attribute_number2 = hpp.carton_qty OR hpp.carton_qty IS NULL)
             AND (heiieb.attribute_number3 = hpp.carton_weight OR hpp.carton_weight IS NULL)
             AND (heiieb.attribute_number4 = hpp.carton_height OR hpp.carton_height IS NULL)
             AND (heiieb.attribute_number5 = hpp.carton_width OR hpp.carton_width IS NULL)
             AND (heiieb.attribute_number6 = hpp.carton_depth OR hpp.carton_depth IS NULL)
             AND heiieb.organization_code = 'ITEM_MASTER'
             AND heiieb.context_code = 'Carton'
             AND hpp.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpp.status = CASE
                                   WHEN (hpp.status = 'SUCCESS' AND heiieb.status = 'ERROR')
                                     OR (hpp.status = 'ERROR' AND heiieb.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heiieb.status
                                END
                  ,hpp.error_text = TRIM(hpp.error_text || ' ' || DECODE(heiieb.status
                                                                        ,'ERROR', NVL(heiieb.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_PAM] from [' ||
                            'HBG_EGO_ITEM_INTF_EFF_B - Carton]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_PAM_FROM_HBG_EGO_ITEM_INTF_EFF_B_Configuration';
      BEGIN
         MERGE INTO hbg_pim_pam hpp
         USING hbg_ego_item_intf_eff_b heiieb
         ON (heiieb.item_number = hpp.isbn13
             AND heiieb.batch_id = hpp.hbg_process_id
             AND (heiieb.attribute_char1 = hpp.trim_size OR hpp.trim_size IS NULL)
             AND (heiieb.attribute_number1 = hpp.audio_quantity OR hpp.audio_quantity IS NULL)
             AND (heiieb.attribute_number2 = hpp.running_time OR hpp.running_time IS NULL)
             AND (heiieb.attribute_number3 = hpp.carton_qty OR hpp.carton_qty IS NULL)
             AND (heiieb.attribute_number4 = hpp.pagecount OR hpp.pagecount IS NULL)
             AND heiieb.organization_code = 'ITEM_MASTER'
             AND heiieb.context_code = 'Configuration'
             AND hpp.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpp.status = CASE
                                   WHEN (hpp.status = 'SUCCESS' AND heiieb.status = 'ERROR')
                                     OR (hpp.status = 'ERROR' AND heiieb.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heiieb.status
                                END
                  ,hpp.error_text = TRIM(hpp.error_text || ' ' || DECODE(heiieb.status
                                                                        ,'ERROR', NVL(heiieb.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_PAM] from [' ||
                            'HBG_EGO_ITEM_INTF_EFF_B - Configuration]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_PAM_FROM_HBG_EGO_ITEM_INTF_EFF_B_Content';
      BEGIN
         MERGE INTO hbg_pim_pam hpp
         USING hbg_ego_item_intf_eff_b heiieb
         ON (heiieb.item_number = hpp.isbn13
             AND heiieb.batch_id = hpp.hbg_process_id
             AND (heiieb.attribute_char1 = hpp.product_content_type OR hpp.product_content_type IS NULL)
             AND (heiieb.attribute_number1 = hpp.epub_ver_no OR hpp.epub_ver_no IS NULL)
             AND heiieb.organization_code = 'ITEM_MASTER'
             AND heiieb.context_code = 'Content'
             AND hpp.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpp.status = CASE
                                   WHEN (hpp.status = 'SUCCESS' AND heiieb.status = 'ERROR')
                                     OR (hpp.status = 'ERROR' AND heiieb.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heiieb.status
                                END
                  ,hpp.error_text = TRIM(hpp.error_text || ' ' || DECODE(heiieb.status
                                                                        ,'ERROR', NVL(heiieb.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_PAM] from [' ||
                            'HBG_EGO_ITEM_INTF_EFF_B - Content]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_PAM_FROM_HBG_EGO_ITEM_INTF_EFF_B_Discount_Group';
      BEGIN
         MERGE INTO hbg_pim_pam hpp
         USING hbg_ego_item_intf_eff_b heiieb
         ON (heiieb.item_number = hpp.isbn13
             AND heiieb.batch_id = hpp.hbg_process_id
             AND heiieb.attribute_char1 = hpp.discount_group_code
             AND heiieb.organization_code = 'ITEM_MASTER'
             AND heiieb.context_code = 'Discount Group'
             AND hpp.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpp.status = CASE
                                   WHEN (hpp.status = 'SUCCESS' AND heiieb.status = 'ERROR')
                                     OR (hpp.status = 'ERROR' AND heiieb.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heiieb.status
                                END
                  ,hpp.error_text = TRIM(hpp.error_text || ' ' || DECODE(heiieb.status
                                                                        ,'ERROR', NVL(heiieb.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_PAM] from [' ||
                            'HBG_EGO_ITEM_INTF_EFF_B - Discount Group]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_PAM_FROM_HBG_EGO_ITEM_INTF_EFF_B_Estimated Release';
      BEGIN
         MERGE INTO hbg_pim_pam hpp
         USING hbg_ego_item_intf_eff_b heiieb
         ON (heiieb.item_number = hpp.isbn13
             AND heiieb.batch_id = hpp.hbg_process_id
             AND (heiieb.attribute_char1 = hpp.osd_indicator OR hpp.osd_indicator IS NULL)
             AND (heiieb.attribute_char2 = hpp.affidavit_laydown_flag OR hpp.affidavit_laydown_flag IS NULL)
             AND (heiieb.attribute_date1 = hpp.estimated_release_date OR hpp.estimated_release_date IS NULL)
             --AND (heiieb.attribute_date2 = hpp.on_sale_date OR hpp.on_sale_date IS NULL) -- it comes from CPM table
             AND (heiieb.attribute_date3 = hpp.release_date OR hpp.release_date IS NULL)
             AND heiieb.organization_code = 'ITEM_MASTER'
             AND heiieb.context_code = 'Estimated Release'
             AND hpp.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpp.status = CASE
                                   WHEN (hpp.status = 'SUCCESS' AND heiieb.status = 'ERROR')
                                     OR (hpp.status = 'ERROR' AND heiieb.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heiieb.status
                                END
                  ,hpp.error_text = TRIM(hpp.error_text || ' ' || DECODE(heiieb.status
                                                                        ,'ERROR', NVL(heiieb.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_PAM] from [' ||
                            'HBG_EGO_ITEM_INTF_EFF_B - Estimated Release]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      /*lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_PAM_FROM_HBG_EGO_ITEM_INTF_EFF_B_Family Code';
      BEGIN
         MERGE INTO hbg_pim_pam hpp
         USING hbg_ego_item_intf_eff_b heiieb
         ON (heiieb.item_number = hpp.isbn13
             AND heiieb.batch_id = hpp.hbg_process_id
             AND (heiieb.attribute_char1 = hpp.owner_code OR hpp.owner_code IS NULL)
             AND (heiieb.attribute_char2 = hpp.reporting_group_code OR hpp.reporting_group_code IS NULL)
             AND (heiieb.attribute_char3 = hpp.publisher_code OR hpp.publisher_code IS NULL)
             AND (heiieb.attribute_char4 = hpp.imprint_code OR hpp.imprint_code IS NULL)
             AND (heiieb.attribute_char5 = hpp.external_publisher_code OR hpp.external_publisher_code IS NULL)
             AND (heiieb.attribute_char6 = hpp.external_imprint_code OR hpp.external_imprint_code IS NULL)
             AND (heiieb.attribute_char7 = hpp.format_code OR hpp.format_code IS NULL)
             AND (heiieb.attribute_char8 = hpp.sub_format_code OR hpp.sub_format_code IS NULL)
             AND (heiieb.attribute_char9 = hpp.asstd_format_code OR hpp.asstd_format_code IS NULL)
             AND (heiieb.attribute_char10 = hpp.asstd_sub_format_code OR hpp.asstd_sub_format_code IS NULL)
             AND heiieb.organization_code = 'ITEM_MASTER'
             AND heiieb.context_code = 'Family Code'
             AND hpp.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpp.status = CASE
                                   WHEN (hpp.status = 'SUCCESS' AND heiieb.status = 'ERROR')
                                     OR (hpp.status = 'ERROR' AND heiieb.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heiieb.status
                                END
                  ,hpp.error_text = TRIM(hpp.error_text || ' ' || DECODE(heiieb.status
                                                                        ,'ERROR', NVL(heiieb.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_PAM] from [' ||
                            'HBG_EGO_ITEM_INTF_EFF_B - Family Code]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;*/

      lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_PAM_FROM_HBG_EGO_ITEM_INTF_EFF_B_General';
      BEGIN
         MERGE INTO hbg_pim_pam hpp
         USING hbg_ego_item_intf_eff_b heiieb
         ON (heiieb.item_number = hpp.isbn13
             AND heiieb.batch_id = hpp.hbg_process_id
             --AND (heiieb.attribute_char1 = hpp.product_profile_code OR hpp.product_profile_code IS NULL)
             AND (heiieb.attribute_char2 = hpp.audience_code OR hpp.audience_code IS NULL)
             AND (heiieb.attribute_char3 = hpp.language OR hpp.language IS NULL)
             --AND (heiieb.attribute_char4 = hpp.language2 OR hpp.language2 IS NULL)
             --AND (heiieb.attribute_char5 = hpp.medium OR hpp.medium IS NULL)
             --AND (heiieb.attribute_char6 = hpp.format_binding OR hpp.format_binding IS NULL)
             AND (heiieb.attribute_char7 = hpp.commodity_code OR hpp.commodity_code IS NULL)
             --AND (heiieb.attribute_char8 = hpp.price_on_book OR hpp.price_on_book IS NULL)
             AND (heiieb.attribute_char9 = hpp.age_group OR hpp.age_group IS NULL)
             AND (heiieb.attribute_char10 = hpp.customer_specific_code OR hpp.customer_specific_code IS NULL)
             --AND (heiieb.attribute_char11 = hpp.shrink_wrap OR hpp.shrink_wrap IS NULL)
             AND (heiieb.attribute_char12 = hpp.isbn_on_book OR hpp.isbn_on_book IS NULL)
             --AND (heiieb.attribute_char13 = hpp.short_author OR hpp.short_author IS NULL)
             AND (heiieb.attribute_number1 = hpp.age_from OR hpp.age_from IS NULL)
             AND (heiieb.attribute_number2 = hpp.age_to OR hpp.age_to IS NULL)
             --AND (heiieb.attribute_number3 = hpp.grade_from OR hpp.grade_from IS NULL)
             --AND (heiieb.attribute_number4 = hpp.grade_to OR hpp.grade_to IS NULL)
             AND (heiieb.attribute_date1 = hpp.publication_date OR hpp.publication_date IS NULL)
             AND heiieb.organization_code = 'ITEM_MASTER'
             AND heiieb.context_code = 'General'
             AND hpp.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpp.status = CASE
                                   WHEN (hpp.status = 'SUCCESS' AND heiieb.status = 'ERROR')
                                     OR (hpp.status = 'ERROR' AND heiieb.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heiieb.status
                                END
                  ,hpp.error_text = TRIM(hpp.error_text || ' ' || DECODE(heiieb.status
                                                                        ,'ERROR', NVL(heiieb.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_PAM] from [' ||
                            'HBG_EGO_ITEM_INTF_EFF_B - General]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      /*lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_PAM_FROM_HBG_EGO_ITEM_INTF_EFF_B_Hot Title Indicator';
      BEGIN
         MERGE INTO hbg_pim_cpm hpc
         USING hbg_ego_item_intf_eff_b heiieb
         ON (heiieb.item_number = hpc.isbn13
             AND heiieb.batch_id = hpc.hbg_process_id
             AND heiieb.attribute_char1 = hpc.hot_title_flag
             AND heiieb.organization_code = 'ITEM_MASTER'
             AND heiieb.context_code = 'Hot Title Indicator'
             AND hpc.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpc.status = CASE
                                   WHEN (hpc.status = 'SUCCESS' AND heiieb.status = 'ERROR')
                                     OR (hpc.status = 'ERROR' AND heiieb.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heiieb.status
                                END
                  ,hpc.error_text = TRIM(hpc.error_text || ' ' || DECODE(heiieb.status
                                                                        ,'ERROR', NVL(heiieb.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_CPM] from [' ||
                            'HBG_EGO_ITEM_INTF_EFF_B - Hot Title Indicator]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;*/

      lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_PAM_FROM_HBG_EGO_ITEM_INTF_EFF_B_Status and Release';
      BEGIN
         MERGE INTO hbg_pim_pam hpp
         USING hbg_ego_item_intf_eff_b heiieb
         ON (heiieb.item_number = hpp.isbn13
             AND heiieb.batch_id = hpp.hbg_process_id
             AND (heiieb.attribute_char1 = hpp.shipping_schedule OR hpp.shipping_schedule IS NULL)
             AND (heiieb.attribute_char2 = hpp.pod_status_override OR hpp.pod_status_override IS NULL)
             AND (heiieb.attribute_char3 = hpp.embargo_level OR hpp.embargo_level IS NULL)
             --AND (heiieb.attribute_char4 = hpp.sequestered_indicator OR hpp.sequestered_indicator IS NULL)
             --AND (heiieb.attribute_char5 = hpp.country_of_origin OR hpp.country_of_origin IS NULL)
             --AND (heiieb.attribute_char6 = hpp.non_standard_flag OR hpp.non_standard_flag IS NULL)
             AND (heiieb.attribute_char7 = hpp.out_of_stock_reason OR hpp.out_of_stock_reason IS NULL)
             AND (heiieb.attribute_char8 = hpp.ito_ind OR hpp.ito_ind IS NULL)
             --AND (heiieb.attribute_char9 = hpp.nyp_canceled_indicator OR hpp.nyp_canceled_indicator IS NULL)
             AND (heiieb.attribute_char10 = hpp.cancel_status_code OR hpp.cancel_status_code IS NULL)
             --AND (heiieb.attribute_char11 = hpp.rights_reverted_indicator OR hpp.rights_reverted_indicator IS NULL)
             AND (heiieb.attribute_date1 = hpp.return_deadline_date OR hpp.return_deadline_date IS NULL)
             AND (heiieb.attribute_date2 = hpp.reverted_no_sale_date OR hpp.reverted_no_sale_date IS NULL)
             AND (heiieb.attribute_date3 = hpp.out_of_stock_date OR hpp.out_of_stock_date IS NULL)
             AND (heiieb.attribute_date4 = hpp.print_on_demand_date OR hpp.print_on_demand_date IS NULL)
             AND (heiieb.attribute_date5 = hpp.first_release_date OR hpp.first_release_date IS NULL)
             AND (heiieb.attribute_date6 = hpp.first_billing_date OR hpp.first_billing_date IS NULL)
             AND (heiieb.attribute_date7 = hpp.first_ship_date OR hpp.first_ship_date IS NULL)
             AND (heiieb.attribute_date8 = hpp.pub_cancel_date OR hpp.pub_cancel_date IS NULL)
             AND (heiieb.attribute_date9 = hpp.rights_reverted_date OR hpp.rights_reverted_date IS NULL)
             AND (heiieb.attribute_date10 = hpp.out_of_print_date OR hpp.out_of_print_date IS NULL)
             AND heiieb.organization_code = 'ITEM_MASTER'
             AND heiieb.context_code = 'Status and Release'
             AND hpp.hbg_process_id = gv_hbg_process_id)
         WHEN MATCHED THEN
            UPDATE
               SET hpp.status = CASE
                                   WHEN (hpp.status = 'SUCCESS' AND heiieb.status = 'ERROR')
                                     OR (hpp.status = 'ERROR' AND heiieb.status = 'SUCCESS') THEN
                                      'WARNING'
                                   ELSE
                                      heiieb.status
                                END
                  ,hpp.error_text = TRIM(hpp.error_text || ' ' || DECODE(heiieb.status
                                                                        ,'ERROR', NVL(heiieb.error_text
                                                                                     ,'Please check error message in CPM table.')));
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_PAM] from [' ||
                            'HBG_EGO_ITEM_INTF_EFF_B - Status and Release]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'MERGE_STATUS_AND_ERROR_TEXT_INTO_HBG_PIM_CPM_FROM_HBG_EGP_SYSTEM_ITEMS_INTERFACE';
      BEGIN
         UPDATE hbg_pim_cpm hpc
            SET hpc.status = CASE
                                WHEN NVL(hpc.status, 'NULL') <> 'ERROR'
                                     AND
                                     ((EXISTS (SELECT 1
                                                 FROM hbg_egp_system_items_interface hesii
                                                WHERE hesii.item_number = hpc.isbn13
                                                  AND hesii.batch_id = hpc.hbg_process_id
                                                  AND hesii.status = 'SUCCESS')
                                       AND
                                       EXISTS (SELECT 1
                                                 FROM hbg_egp_system_items_interface hesii
                                                WHERE hesii.item_number = hpc.isbn13
                                                  AND hesii.batch_id = hpc.hbg_process_id
                                                  AND hesii.status = 'ERROR'))
                                      OR
                                      (EXISTS (SELECT 1
                                                 FROM hbg_egp_system_items_interface hesii
                                                WHERE hesii.item_number = hpc.isbn13
                                                  AND hesii.batch_id = hpc.hbg_process_id
                                                  AND hesii.status = 'SUCCESS')
                                       AND
                                       EXISTS (SELECT 1
                                                 FROM hbg_pim_pam hpp
                                                WHERE hpp.isbn13 = hpc.isbn13
                                                  AND hpp.status = 'ERROR'
                                                UNION
                                               SELECT 1
                                                 FROM hbg_pim_pbc hpp
                                                WHERE hpp.isbn13 = hpc.isbn13
                                                  AND hpp.status = 'ERROR'
                                                UNION
                                               SELECT 1
                                                 FROM hbg_pim_pca hpp
                                                WHERE hpp.isbn13 = hpc.isbn13
                                                  AND hpp.status = 'ERROR'
                                                UNION
                                               SELECT 1
                                                 FROM hbg_pim_pem hpp
                                                WHERE hpp.isbn13 = hpc.isbn13
                                                  AND hpp.status = 'ERROR'
                                                UNION
                                               SELECT 1
                                                 FROM hbg_pim_prm hpp
                                                WHERE hpp.isbn13 = hpc.isbn13
                                                  AND hpp.status = 'ERROR'
                                                UNION
                                               SELECT 1
                                                 FROM hbg_pim_pat hpp
                                                WHERE hpp.isbn13 = hpc.isbn13
                                                  AND hpp.status = 'ERROR'
                                                UNION
                                               SELECT 1
                                                 FROM hbg_pim_pcc hpp
                                                WHERE hpp.isbn13 = hpc.isbn13
                                                  AND hpp.status = 'ERROR'))
                                      OR
                                      (EXISTS (SELECT 1
                                                 FROM hbg_egp_system_items_interface hesii
                                                WHERE hesii.item_number = hpc.isbn13
                                                  AND hesii.batch_id = hpc.hbg_process_id
                                                  AND hesii.status = 'ERROR')
                                       AND
                                       EXISTS (SELECT 1
                                                 FROM hbg_pim_pam hpp
                                                WHERE hpp.isbn13 = hpc.isbn13
                                                  AND hpp.status = 'SUCCESS'
                                                UNION
                                               SELECT 1
                                                 FROM hbg_pim_pbc hpp
                                                WHERE hpp.isbn13 = hpc.isbn13
                                                  AND hpp.status = 'SUCCESS'
                                                UNION
                                               SELECT 1
                                                 FROM hbg_pim_pca hpp
                                                WHERE hpp.isbn13 = hpc.isbn13
                                                  AND hpp.status = 'SUCCESS'
                                                UNION
                                               SELECT 1
                                                 FROM hbg_pim_pem hpp
                                                WHERE hpp.isbn13 = hpc.isbn13
                                                  AND hpp.status = 'SUCCESS'
                                                UNION
                                               SELECT 1
                                                 FROM hbg_pim_prm hpp
                                                WHERE hpp.isbn13 = hpc.isbn13
                                                  AND hpp.status = 'SUCCESS'
                                                UNION
                                               SELECT 1
                                                 FROM hbg_pim_pat hpp
                                                WHERE hpp.isbn13 = hpc.isbn13
                                                  AND hpp.status = 'SUCCESS'
                                                UNION
                                               SELECT 1
                                                 FROM hbg_pim_pcc hpp
                                                WHERE hpp.isbn13 = hpc.isbn13
                                                  AND hpp.status = 'SUCCESS')))
                                    THEN 'WARNING'
                                --
                                WHEN NOT EXISTS (SELECT 1
                                                   FROM hbg_egp_system_items_interface hesii
                                                  WHERE hesii.item_number = hpc.isbn13
                                                    AND hesii.batch_id = hpc.hbg_process_id
                                                    AND hesii.status = 'SUCCESS')
                                THEN 'ERROR'
                                --
                                WHEN NOT EXISTS (SELECT 1
                                                   FROM hbg_egp_system_items_interface hesii
                                                  WHERE hesii.item_number = hpc.isbn13
                                                    AND hesii.batch_id = hpc.hbg_process_id
                                                    AND hesii.status = 'ERROR')
                                THEN 'SUCCESS'
                             END
               ,hpc.error_text = TRIM(hpc.error_text || ' ' ||
                                      (SELECT LISTAGG(DISTINCT hesii.error_text, ' ' ON OVERFLOW TRUNCATE '!!!') WITHIN GROUP (ORDER BY hesii.organization_code)
                                         FROM hbg_egp_system_items_interface hesii
                                        WHERE hesii.item_number = hpc.isbn13
                                          AND hesii.batch_id = hpc.hbg_process_id))
          WHERE hpc.hbg_process_id = gv_hbg_process_id;
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when merging STATUS and ERROR_TEXT into table [HBG_PIM_CPM] from [' ||
                            'HBG_EGP_SYSTEM_ITEMS_INTERFACE]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      -- Update status and error_text of child tables records that the corresponding CPM record is ERROR (sample scenario: ERROR due to some validation rule)
      lv_debug := 'UPDATE_STATUS_AND_ERROR_TEXT_OF_HBG_PIM_PAM_INVALID_RECORDS';
      BEGIN
         UPDATE hbg_pim_pam hpp
            SET hpp.status = 'ERROR'
               ,hpp.error_text = TRIM(hpp.error_text || ' Please check error message in CPM table.')
          WHERE hpp.hbg_process_id = gv_hbg_process_id
            AND hpp.status IS NULL
            AND EXISTS (SELECT 1
                          FROM hbg_pim_cpm hpc
                         WHERE hpc.isbn13 = hpp.isbn13
                           AND hpc.hbg_process_id = hpp.hbg_process_id
                           AND hpc.status = 'ERROR');
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when updating STATUS and ERROR_TEXT of table [HBG_PIM_PAM]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'UPDATE_STATUS_AND_ERROR_TEXT_OF_HBG_PIM_PAT_INVALID_RECORDS';
      BEGIN
         UPDATE hbg_pim_pat hpp
            SET hpp.status = 'ERROR'
               ,hpp.error_text = TRIM(hpp.error_text || ' Please check error message in CPM table.')
          WHERE hpp.hbg_process_id = gv_hbg_process_id
            AND hpp.status IS NULL
            AND EXISTS (SELECT 1
                          FROM hbg_pim_cpm hpc
                         WHERE hpc.isbn13 = hpp.isbn13
                           AND hpc.hbg_process_id = hpp.hbg_process_id
                           AND hpc.status = 'ERROR');
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when updating STATUS and ERROR_TEXT of table [HBG_PIM_PAT]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'UPDATE_STATUS_AND_ERROR_TEXT_OF_HBG_PIM_PBC_INVALID_RECORDS';
      BEGIN
         UPDATE hbg_pim_pbc hpp
            SET hpp.status = 'ERROR'
               ,hpp.error_text = TRIM(hpp.error_text || ' Please check error message in CPM table.')
          WHERE hpp.hbg_process_id = gv_hbg_process_id
            AND hpp.status IS NULL
            AND EXISTS (SELECT 1
                          FROM hbg_pim_cpm hpc
                         WHERE hpc.isbn13 = hpp.isbn13
                           AND hpc.hbg_process_id = hpp.hbg_process_id
                           AND hpc.status = 'ERROR');
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when updating STATUS and ERROR_TEXT of table [HBG_PIM_PBC]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'UPDATE_STATUS_AND_ERROR_TEXT_OF_HBG_PIM_PCA_INVALID_RECORDS';
      BEGIN
         UPDATE hbg_pim_pca hpp
            SET hpp.status = 'ERROR'
               ,hpp.error_text = TRIM(hpp.error_text || ' Please check error message in CPM table.')
          WHERE hpp.hbg_process_id = gv_hbg_process_id
            AND hpp.status IS NULL
            AND EXISTS (SELECT 1
                          FROM hbg_pim_cpm hpc
                         WHERE hpc.isbn13 = hpp.isbn13
                           AND hpc.hbg_process_id = hpp.hbg_process_id
                           AND hpc.status = 'ERROR');
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when updating STATUS and ERROR_TEXT of table [HBG_PIM_PCA]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'UPDATE_STATUS_AND_ERROR_TEXT_OF_HBG_PIM_PCC_INVALID_RECORDS';
      BEGIN
         UPDATE hbg_pim_pcc hpp
            SET hpp.status = 'ERROR'
               ,hpp.error_text = TRIM(hpp.error_text || ' Please check error message in CPM table.')
          WHERE hpp.hbg_process_id = gv_hbg_process_id
            AND hpp.status IS NULL
            AND EXISTS (SELECT 1
                          FROM hbg_pim_cpm hpc
                         WHERE hpc.isbn13 = hpp.isbn13
                           AND hpc.hbg_process_id = hpp.hbg_process_id
                           AND hpc.status = 'ERROR');
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when updating STATUS and ERROR_TEXT of table [HBG_PIM_PCC]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'UPDATE_STATUS_AND_ERROR_TEXT_OF_HBG_PIM_PEM_INVALID_RECORDS';
      BEGIN
         UPDATE hbg_pim_pem hpp
            SET hpp.status = 'ERROR'
               ,hpp.error_text = TRIM(hpp.error_text || ' Please check error message in CPM table.')
          WHERE hpp.hbg_process_id = gv_hbg_process_id
            AND hpp.status IS NULL
            AND EXISTS (SELECT 1
                          FROM hbg_pim_cpm hpc
                         WHERE hpc.isbn13 = hpp.isbn13
                           AND hpc.hbg_process_id = hpp.hbg_process_id
                           AND hpc.status = 'ERROR');
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when updating STATUS and ERROR_TEXT of table [HBG_PIM_PEM]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'UPDATE_STATUS_AND_ERROR_TEXT_OF_HBG_PIM_PRM_INVALID_RECORDS';
      BEGIN
         UPDATE hbg_pim_prm hpp
            SET hpp.status = 'ERROR'
               ,hpp.error_text = TRIM(hpp.error_text || ' Please check error message in CPM table.')
          WHERE hpp.hbg_process_id = gv_hbg_process_id
            AND hpp.status IS NULL
            AND EXISTS (SELECT 1
                          FROM hbg_pim_cpm hpc
                         WHERE hpc.isbn13 = hpp.isbn13
                           AND hpc.hbg_process_id = hpp.hbg_process_id
                           AND hpc.status = 'ERROR');
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when updating STATUS and ERROR_TEXT of table [HBG_PIM_PRM]. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      -- Get KEEP_DATA_IN_FBDI_TABLES integration parameter
      lv_debug := 'GET_KEEP_DATA_IN_FBDI_TABLES_INTEGRATION_PARAMETER';
      BEGIN
         SELECT hpip.param_char1
           INTO lv_keep_data_in_fbdi_tables
           FROM hbg_pim_int_parameters hpip
          WHERE hpip.parameter_name = 'KEEP_DATA_IN_FBDI_TABLES';
         --
      EXCEPTION
         WHEN OTHERS THEN
            log_p('ERROR'
                 ,'ERROR getting value of integration parameter  [KEEP_DATA_IN_FBDI_TABLES]. It was considered as [No]. ' || SQLERRM);
      END;

      IF lv_keep_data_in_fbdi_tables = 'N' THEN
         -- Clean FBDI tables
         BEGIN
            lv_debug := 'CLEAN_HBG_EGP_SYSTEM_ITEMS_INTERFACE';
            DELETE
              FROM HBG_EGP_SYSTEM_ITEMS_INTERFACE
             WHERE batch_id = gv_hbg_process_id;

            lv_debug := 'CLEAN_HBG_EGP_ITEM_REVISIONS_INTERFACE';
            DELETE
              FROM HBG_EGP_ITEM_REVISIONS_INTERFACE
             WHERE batch_id = gv_hbg_process_id;

            lv_debug := 'CLEAN_HBG_EGP_ITEM_CATEGORIES_INTERFACE';
            DELETE
              FROM HBG_EGP_ITEM_CATEGORIES_INTERFACE
             WHERE batch_id = gv_hbg_process_id;

            lv_debug := 'CLEAN_HBG_EGP_ITEM_RELATIONSHIPS_INTF';
            DELETE
              FROM HBG_EGP_ITEM_RELATIONSHIPS_INTF
             WHERE batch_id = gv_hbg_process_id;

            lv_debug := 'CLEAN_HBG_EGO_ITEM_ASSOCIATIONS_INTF';
            DELETE
              FROM HBG_EGO_ITEM_ASSOCIATIONS_INTF
             WHERE batch_id = gv_hbg_process_id;

            lv_debug := 'CLEAN_HBG_EGO_ITEM_INTF_EFF_B';
            DELETE
              FROM HBG_EGO_ITEM_INTF_EFF_B
             WHERE batch_id = gv_hbg_process_id;

            lv_debug := 'CLEAN_HBG_EGO_ITEM_INTF_EFF_TL';
            DELETE
              FROM HBG_EGO_ITEM_INTF_EFF_TL
             WHERE batch_id = gv_hbg_process_id;

            lv_debug := 'CLEAN_HBG_EGO_ITEM_REVISION_INTF_EFF_B';
            DELETE
              FROM HBG_EGO_ITEM_REVISION_INTF_EFF_B
             WHERE batch_id = gv_hbg_process_id;

            lv_debug := 'CLEAN_HBG_EGO_ITEM_REVISION_INTF_EFF_TL';
            DELETE
              FROM HBG_EGO_ITEM_REVISION_INTF_EFF_TL
             WHERE batch_id = gv_hbg_process_id;

            lv_debug := 'CLEAN_HBG_EGO_ITEM_SUPPLIER_INTF_EFF_B';
            DELETE
              FROM HBG_EGO_ITEM_SUPPLIER_INTF_EFF_B
             WHERE batch_id = gv_hbg_process_id;

            lv_debug := 'CLEAN_HBG_EGO_ITEM_SUPPLIER_INTF_EFF_TL';
            DELETE
              FROM HBG_EGO_ITEM_SUPPLIER_INTF_EFF_TL
             WHERE batch_id = gv_hbg_process_id;

            lv_debug := 'CLEAN_HBG_EGO_STYLE_VARIANT_ATTR_VS_INTF';
            DELETE
              FROM HBG_EGO_STYLE_VARIANT_ATTR_VS_INTF
             WHERE batch_id = gv_hbg_process_id;

            lv_debug := 'CLEAN_HBG_EGP_TRADING_PARTNER_ITEMS_INTF';
            DELETE
              FROM HBG_EGP_TRADING_PARTNER_ITEMS_INTF
             WHERE batch_id = gv_hbg_process_id;

            lv_debug := 'CLEAN_HBG_EGP_ITEM_ATTACHMENTS_INTF';
            DELETE
              FROM HBG_EGP_ITEM_ATTACHMENTS_INTF
             WHERE batch_id = gv_hbg_process_id;

            COMMIT;
         EXCEPTION
            WHEN OTHERS THEN
               ROLLBACK;
               log_p('ERROR'
                    ,'ERROR when cleaning FBDI tables at the step [' || lv_debug || ']. ' || SQLERRM);
         END;
      END IF;

      -- Update the status of the step 7 to SUCCESS
      lv_debug := 'UPDATE_STEP_7_TO_SUCCESS';
      BEGIN
         UPDATE hbg_integration_control
            SET status = 'SUCCESS'
               ,end_date = CURRENT_DATE
          WHERE hbg_process_id = gv_hbg_process_id
            AND step_number = 7;
      EXCEPTION
         WHEN OTHERS THEN
            log_p('ERROR'
                 ,'ERROR when updating control table at the step [' || lv_debug || ']. ' || SQLERRM);
      END;
      --
      COMMIT;

   EXCEPTION
      WHEN ge_custom_exception THEN
         log_p('ERROR'
              ,'ERROR at the step [' || lv_debug || '] of the [UPDATE_PROCESS_TABLES_P]. ' || lv_error_msg);
         --
         BEGIN
            UPDATE hbg_integration_control
               SET status = 'ERROR'
                  ,end_date = CURRENT_DATE
             WHERE hbg_process_id = gv_hbg_process_id
               AND step_number = 7;
         EXCEPTION
            WHEN OTHERS THEN
               log_p('ERROR'
                    ,'ERROR when updating status of step 7 to ERROR in control table [GE_CUSTOM_EXCEPTION]. '
                     || SQLERRM);
         END;
         --
         COMMIT;
         --
         raise_application_error(-20001, 'ERROR occured in [HBG_PIM_INTEGRATION_PKG.UPDATE_PROCESS_TABLES_P]. '
                                         || 'Check logs for details.');
      WHEN OTHERS THEN
         log_p('ERROR'
              ,'GENERAL ERROR at the step [' || lv_debug || '] of the program. ' || dbms_utility.format_error_backtrace);
         --
         BEGIN
            UPDATE hbg_integration_control
               SET status = 'ERROR'
                  ,end_date = CURRENT_DATE
             WHERE hbg_process_id = gv_hbg_process_id
               AND step_number = 7;
         EXCEPTION
            WHEN OTHERS THEN
               log_p('ERROR'
                    ,'ERROR when updating status of step 7 to ERROR in control table. ' || SQLERRM);
         END;
         --
         COMMIT;
         --
         raise_application_error(-20001, 'ERROR occured in [HBG_PIM_INTEGRATION_PKG.UPDATE_PROCESS_TABLES_P]. '
                                         || 'Check logs for details.');
   END update_process_tables_p;

   -- -----------------------------------------------------------------------------------------------------------------
   --  PROCEDURE: submit_update_process_tables_p
   -- -----------------------------------------------------------------------------------------------------------------
   --
   --  Parameters: p_hbg_process_id - HBG Process ID
   --              p_oic_instance_id - OIC Instance ID
   --
   --  Description: procedure responsible for creating a JOB to run the procedure [update_process_tables_p]
   --
   -- -----------------------------------------------------------------------------------------------------------------
   PROCEDURE submit_update_process_tables_p(p_hbg_process_id  IN NUMBER
                                           ,p_oic_instance_id IN NUMBER) IS

      lv_debug VARCHAR2(300);
      lv_error_msg VARCHAR2(2000);

   BEGIN
      gv_hbg_process_id := p_hbg_process_id;
      gv_oic_instance_id := p_oic_instance_id;
      
      lv_debug := 'UPDATE_STEP_7_IN_INTEGRATION_CONTROL_TABLE';
      BEGIN
         UPDATE hbg_integration_control
            SET status = 'IN PROGRESS'
               ,start_date = CURRENT_DATE
               ,oic_instance_id = gv_oic_instance_id
          WHERE hbg_process_id = gv_hbg_process_id
            AND step_number = 7;
      EXCEPTION
         WHEN OTHERS THEN
            lv_error_msg := 'ERROR when updating record in [HBG_INTEGRATION_CONTROL] at the step [' || lv_debug
                            || '] - ' || SQLERRM;
            RAISE ge_custom_exception;
      END;
      COMMIT;

      lv_debug := 'SUBMIT_JOB_TO_CALL_UPDATE_PROCESS_TABLES_P';
      --EXECUTE IMMEDIATE 'BEGIN HBG_PIM_INTEGRATION_PKG.UPDATE_PROCESS_TABLES_P(' || gv_hbg_process_id || '); END;';
      dbms_scheduler.create_job(job_name   => 'HBG_LOAD_ITEMS_INTO_ORACLE_PIM_CALLBACK_' || TO_CHAR(gv_hbg_process_id)
                               ,job_type   => 'PLSQL_BLOCK'
                               ,job_action => 'BEGIN
                                                  HBG_PIM_INTEGRATION_PKG.UPDATE_PROCESS_TABLES_P(' || gv_hbg_process_id
                                              || ',' || gv_oic_instance_id || '); END;'
                               ,enabled    => TRUE
                               ,auto_drop  => TRUE
                               ,comments   => 'HBG Load Items Information into Oracle PIM - CALLBACK - HBG Process ID = '
                                              || TO_CHAR(gv_hbg_process_id) || ' - OIC Instance ID = ' || TO_CHAR(gv_oic_instance_id)) ;
   EXCEPTION
      WHEN ge_custom_exception THEN
         log_p('ERROR'
              ,'ERROR at the step [' || lv_debug || '] of the [SUBMIT_UPDATE_PROCESS_TABLES_P]. ' || lv_error_msg);
         raise_application_error(-20001, 'ERROR occured in [HBG_PIM_INTEGRATION_PKG.SUBMIT_UPDATE_PROCESS_TABLES_P].'
                                         || ' Check logs for details.');
      WHEN OTHERS THEN
         log_p('ERROR'
              ,'ERROR at the step [' || lv_debug || '] of the [SUBMIT_UPDATE_PROCESS_TABLES_P]. ' || SQLERRM);
         RAISE;
   END submit_update_process_tables_p;

   -- -----------------------------------------------------------------------------------------------------------------
   --  FUNCTION: file_to_blob_f
   -- -----------------------------------------------------------------------------------------------------------------
   --
   --  Parameters: p_filename - name of the file to be read and returned as BLOB
   --
   --  Description: Function to convert a file in BLOB
   --
   -- -----------------------------------------------------------------------------------------------------------------
   FUNCTION file_to_blob_f(p_filename VARCHAR2) RETURN BLOB AS

      lv_debug VARCHAR2(300);
      lv_file BFILE := bfilename(gv_db_directory, p_filename);
      lv_blob BLOB;
      src_offset NUMBER := 1;
      dst_offset NUMBER := 1;

   BEGIN
      lv_debug := 'CREATE_TEMPORARY_BLOB';
      dbms_lob.createtemporary(lv_blob
                              ,FALSE
                              ,2);

      lv_debug := 'OPEN_FILE_IN_READ_ONLY_MODE';
      dbms_lob.fileopen(lv_file
                       ,dbms_lob.file_readonly);

      lv_debug := 'CHECK_FILE_SIZE';
      IF dbms_lob.getlength(lv_file) > 0 THEN
         lv_debug := 'OPEN_BLOB_IN_READ_WRITE_MODE';
         dbms_lob.open(lv_blob
                      ,dbms_lob.lob_readwrite);

         lv_debug := 'LOAD_BLOB_FROM_FILE';
         dbms_lob.loadblobfromfile(lv_blob
                                  ,lv_file
                                  --,dbms_lob.lobmaxsize
                                  ,dbms_lob.getlength(lv_file)
                                  ,src_offset
                                  ,dst_offset);
         lv_debug := 'CLOSE_BLOB';
         dbms_lob.close(lv_blob);
      END IF;

      lv_debug := 'CLOSE_FILE';
      dbms_lob.filecloseall();

      RETURN lv_blob;
   EXCEPTION
      WHEN OTHERS THEN
         log_p('ERROR'
              ,'ERROR at the step [' || lv_debug || '] while converting file [' || p_filename || '] in BLOB - ' || SQLERRM);
         RAISE;
   END file_to_blob_f;

   -- -----------------------------------------------------------------------------------------------------------------
   --  PROCEDURE: load_process_tables_p
   -- -----------------------------------------------------------------------------------------------------------------
   --
   --  Description: Procedure to load data from staging tables into process tables
   --
   -- -----------------------------------------------------------------------------------------------------------------
   PROCEDURE load_process_tables_p IS
      CURSOR c_hbg_pim_cpm_stg IS
         SELECT *
           FROM hbg_pim_cpm_stg hpcs
          WHERE hpcs.hbg_process_id = gv_hbg_process_id;

      CURSOR c_hbg_pim_pam_stg IS
         SELECT *
           FROM hbg_pim_pam_stg hpps
          WHERE hpps.hbg_process_id = gv_hbg_process_id;

      CURSOR c_hbg_pim_pat_stg IS
         SELECT *
           FROM hbg_pim_pat_stg hpps
          WHERE hpps.hbg_process_id = gv_hbg_process_id;

      CURSOR c_hbg_pim_pbc_stg IS
         SELECT *
           FROM hbg_pim_pbc_stg hpps
          WHERE hpps.hbg_process_id = gv_hbg_process_id;

      CURSOR c_hbg_pim_pca_stg IS
         SELECT *
           FROM hbg_pim_pca_stg hpps
          WHERE hpps.hbg_process_id = gv_hbg_process_id;

      CURSOR c_hbg_pim_pcc_stg IS
         SELECT *
           FROM hbg_pim_pcc_stg hpps
          WHERE hpps.hbg_process_id = gv_hbg_process_id;

      CURSOR c_hbg_pim_pem_stg IS
         SELECT *
           FROM hbg_pim_pem_stg hpps
          WHERE hpps.hbg_process_id = gv_hbg_process_id;

      CURSOR c_hbg_pim_prm_stg IS
         SELECT *
           FROM hbg_pim_prm_stg hpps
          WHERE hpps.hbg_process_id = gv_hbg_process_id;

      -- Table Types
      TYPE lt_hbg_pim_cpm_stg_tb IS TABLE OF c_hbg_pim_cpm_stg%ROWTYPE;
      TYPE lt_hbg_pim_pam_stg_tb IS TABLE OF c_hbg_pim_pam_stg%ROWTYPE;
      TYPE lt_hbg_pim_pat_stg_tb IS TABLE OF c_hbg_pim_pat_stg%ROWTYPE;
      TYPE lt_hbg_pim_pbc_stg_tb IS TABLE OF c_hbg_pim_pbc_stg%ROWTYPE;
      TYPE lt_hbg_pim_pca_stg_tb IS TABLE OF c_hbg_pim_pca_stg%ROWTYPE;
      TYPE lt_hbg_pim_pcc_stg_tb IS TABLE OF c_hbg_pim_pcc_stg%ROWTYPE;
      TYPE lt_hbg_pim_pem_stg_tb IS TABLE OF c_hbg_pim_pem_stg%ROWTYPE;
      TYPE lt_hbg_pim_prm_stg_tb IS TABLE OF c_hbg_pim_prm_stg%ROWTYPE;

      -- Exceptions
      le_insert_exception EXCEPTION;
      PRAGMA EXCEPTION_INIT(le_insert_exception, -24381);

      lc_bulk_collect_limit CONSTANT PLS_INTEGER DEFAULT 500;
      lv_aux_hbg_process_id NUMBER := -1;
      lv_debug VARCHAR2(1000);
      lv_error_msg VARCHAR2(32000);
      lv_hbg_pim_cpm_stg_tb lt_hbg_pim_cpm_stg_tb;
      lv_hbg_pim_pam_stg_tb lt_hbg_pim_pam_stg_tb;
      lv_hbg_pim_pat_stg_tb lt_hbg_pim_pat_stg_tb;
      lv_hbg_pim_pbc_stg_tb lt_hbg_pim_pbc_stg_tb;
      lv_hbg_pim_pca_stg_tb lt_hbg_pim_pca_stg_tb;
      lv_hbg_pim_pcc_stg_tb lt_hbg_pim_pcc_stg_tb;
      lv_hbg_pim_pem_stg_tb lt_hbg_pim_pem_stg_tb;
      lv_hbg_pim_prm_stg_tb lt_hbg_pim_prm_stg_tb;

   BEGIN

      lv_debug := 'VALIDATE_HBG_PROCESS_ID';
      BEGIN
         SELECT hbg_process_id
           INTO lv_aux_hbg_process_id
           FROM (SELECT hbg_process_id
                   FROM hbg_pim_cpm
                  WHERE hbg_process_id = gv_hbg_process_id
                  UNION
                 SELECT hbg_process_id
                   FROM hbg_pim_pam
                  WHERE hbg_process_id = gv_hbg_process_id
                  UNION
                 SELECT hbg_process_id
                   FROM hbg_pim_pat
                  WHERE hbg_process_id = gv_hbg_process_id
                  UNION
                 SELECT hbg_process_id
                   FROM hbg_pim_pbc
                  WHERE hbg_process_id = gv_hbg_process_id
                  UNION
                 SELECT hbg_process_id
                   FROM hbg_pim_pca
                  WHERE hbg_process_id = gv_hbg_process_id
                  UNION
                 SELECT hbg_process_id
                   FROM hbg_pim_pcc
                  WHERE hbg_process_id = gv_hbg_process_id
                  UNION
                 SELECT hbg_process_id
                   FROM hbg_pim_pem
                  WHERE hbg_process_id = gv_hbg_process_id
                  UNION
                 SELECT hbg_process_id
                   FROM hbg_pim_prm
                  WHERE hbg_process_id = gv_hbg_process_id);
         --
         IF lv_aux_hbg_process_id = gv_hbg_process_id THEN
            RAISE ge_custom_exception;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            NULL; -- valid HBG_PROCESS_ID
         WHEN ge_custom_exception THEN
            lv_error_msg := 'ERROR when validating HBG_PROCESS_ID in process tables. There are already '
                            || 'records in process tables with the same HBG_PROCESS_ID.';
            RAISE;
         WHEN OTHERS THEN
            lv_error_msg := 'GENERAL EXCEPTION when validating HBG_PROCESS_ID in process tables. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'OPEN_AND_FETCH_C_HBG_PIM_CPM_STG';
      BEGIN
         OPEN c_hbg_pim_cpm_stg;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_hbg_pim_cpm_stg BULK COLLECT INTO lv_hbg_pim_cpm_stg_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_hbg_pim_cpm_stg_tb.COUNT = 0;

            lv_debug := 'FORALL_C_HBG_PIM_CPM_STG';
            BEGIN
               FORALL i IN 1 .. lv_hbg_pim_cpm_stg_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_pim_cpm
                     (isbn13
                     ,isbn10
                     ,work_isbn
                     ,work_title
                     ,work_sub_title
                     ,owner_code
                     ,owner
                     ,reporting_group_code
                     ,reporting_group_code_desc
                     ,publisher_code
                     ,publisher
                     ,imprint_code
                     ,imprint
                     ,external_publisher_code
                     ,external_publisher
                     ,external_imprint_code
                     ,external_imprint
                     ,full_title
                     ,subtitle
                     ,long_title
                     ,short_title
                     ,author_name
                     ,associated_isbn
                     ,edition
                     ,edition_number
                     ,pub_status
                     ,media
                     ,format_code
                     ,format
                     ,sub_format_code
                     ,sub_format
                     ,series_name
                     ,series_number
                     ,by_line
                     ,on_sale_date
                     ,keyword
                     ,book_description
                     ,hide_from_onix
                     ,usd_msrp
                     ,cad_msrp
                     ,lot_size
                     ,planner_code
                     ,planner_code_desc
                     ,planner_segment_code
                     ,planner_segment_code_desc
                     ,planner_lead_time
                     ,reprint_weeks
                     ,delivery_weeks
                     ,planogram
                     ,fpm_date
                     ,abc_code
                     ,hot_title_flag
                     ,acquiring_editor
                     ,current_editor_name
                     ,profit_sharing
                     ,tier_name
                     ,tier_category_name
                     ,licensed_product_flag
                     ,item_type
                     ,saleable_ind
                     ,unit_height
                     ,unit_width
                     ,unit_depth
                     ,unit_weight
                     ,digital_content_flag
                     ,dbcs_create_timestamp
                     ,created_by
                     ,dbcs_update_timestamp
                     ,last_updated_by
                     ,hbg_process_id
                     ,oic_instance_id
                     )
                  VALUES
                     (lv_hbg_pim_cpm_stg_tb(i).isbn13
                     ,lv_hbg_pim_cpm_stg_tb(i).isbn10
                     ,lv_hbg_pim_cpm_stg_tb(i).work_isbn
                     ,lv_hbg_pim_cpm_stg_tb(i).work_title
                     ,lv_hbg_pim_cpm_stg_tb(i).work_sub_title
                     ,lv_hbg_pim_cpm_stg_tb(i).owner_code
                     ,lv_hbg_pim_cpm_stg_tb(i).owner
                     ,lv_hbg_pim_cpm_stg_tb(i).reporting_group_code
                     ,lv_hbg_pim_cpm_stg_tb(i).reporting_group_code_desc
                     ,lv_hbg_pim_cpm_stg_tb(i).publisher_code
                     ,lv_hbg_pim_cpm_stg_tb(i).publisher
                     ,lv_hbg_pim_cpm_stg_tb(i).imprint_code
                     ,lv_hbg_pim_cpm_stg_tb(i).imprint
                     ,lv_hbg_pim_cpm_stg_tb(i).external_publisher_code
                     ,lv_hbg_pim_cpm_stg_tb(i).external_publisher
                     ,lv_hbg_pim_cpm_stg_tb(i).external_imprint_code
                     ,lv_hbg_pim_cpm_stg_tb(i).external_imprint
                     ,lv_hbg_pim_cpm_stg_tb(i).full_title
                     ,lv_hbg_pim_cpm_stg_tb(i).subtitle
                     ,lv_hbg_pim_cpm_stg_tb(i).long_title
                     ,lv_hbg_pim_cpm_stg_tb(i).short_title
                     ,lv_hbg_pim_cpm_stg_tb(i).author_name
                     ,lv_hbg_pim_cpm_stg_tb(i).associated_isbn
                     ,lv_hbg_pim_cpm_stg_tb(i).edition
                     ,lv_hbg_pim_cpm_stg_tb(i).edition_number
                     ,lv_hbg_pim_cpm_stg_tb(i).pub_status
                     ,lv_hbg_pim_cpm_stg_tb(i).media
                     ,lv_hbg_pim_cpm_stg_tb(i).format_code
                     ,lv_hbg_pim_cpm_stg_tb(i).format
                     ,lv_hbg_pim_cpm_stg_tb(i).sub_format_code
                     ,lv_hbg_pim_cpm_stg_tb(i).sub_format
                     ,lv_hbg_pim_cpm_stg_tb(i).series_name
                     ,lv_hbg_pim_cpm_stg_tb(i).series_number
                     ,lv_hbg_pim_cpm_stg_tb(i).by_line
                     ,lv_hbg_pim_cpm_stg_tb(i).on_sale_date
                     ,lv_hbg_pim_cpm_stg_tb(i).keyword
                     ,lv_hbg_pim_cpm_stg_tb(i).book_description
                     ,lv_hbg_pim_cpm_stg_tb(i).hide_from_onix
                     ,lv_hbg_pim_cpm_stg_tb(i).usd_msrp
                     ,lv_hbg_pim_cpm_stg_tb(i).cad_msrp
                     ,lv_hbg_pim_cpm_stg_tb(i).lot_size
                     ,lv_hbg_pim_cpm_stg_tb(i).planner_code
                     ,lv_hbg_pim_cpm_stg_tb(i).planner_code_desc
                     ,lv_hbg_pim_cpm_stg_tb(i).planner_segment_code
                     ,lv_hbg_pim_cpm_stg_tb(i).planner_segment_code_desc
                     ,lv_hbg_pim_cpm_stg_tb(i).planner_lead_time
                     ,lv_hbg_pim_cpm_stg_tb(i).reprint_weeks
                     ,lv_hbg_pim_cpm_stg_tb(i).delivery_weeks
                     ,lv_hbg_pim_cpm_stg_tb(i).planogram
                     ,lv_hbg_pim_cpm_stg_tb(i).fpm_date
                     ,lv_hbg_pim_cpm_stg_tb(i).abc_code
                     ,lv_hbg_pim_cpm_stg_tb(i).hot_title_flag
                     ,lv_hbg_pim_cpm_stg_tb(i).acquiring_editor
                     ,lv_hbg_pim_cpm_stg_tb(i).current_editor_name
                     ,lv_hbg_pim_cpm_stg_tb(i).profit_sharing
                     ,lv_hbg_pim_cpm_stg_tb(i).tier_name
                     ,lv_hbg_pim_cpm_stg_tb(i).tier_category_name
                     ,lv_hbg_pim_cpm_stg_tb(i).licensed_product_flag
                     ,lv_hbg_pim_cpm_stg_tb(i).item_type
                     ,lv_hbg_pim_cpm_stg_tb(i).saleable_ind
                     ,lv_hbg_pim_cpm_stg_tb(i).unit_height
                     ,lv_hbg_pim_cpm_stg_tb(i).unit_width
                     ,lv_hbg_pim_cpm_stg_tb(i).unit_depth
                     ,lv_hbg_pim_cpm_stg_tb(i).unit_weight
                     ,lv_hbg_pim_cpm_stg_tb(i).digital_content_flag
                     ,CURRENT_DATE
                     ,(SELECT USER FROM dual)
                     ,CURRENT_DATE
                     ,(SELECT USER FROM dual)
                     ,lv_hbg_pim_cpm_stg_tb(i).hbg_process_id
                     ,gv_oic_instance_id
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_PIM_CPM - ISBN13 ['
                           || lv_hbg_pim_cpm_stg_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13 || '] - '
                           || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
                  END LOOP;
                  --
                  ROLLBACK;
                  lv_error_msg := 'ERROR when inserting records into [HBG_PIM_CPM]';
                  RAISE ge_custom_exception;
                  --
               WHEN OTHERS THEN
                  lv_error_msg := 'GENERAL ERROR when inserting records into [HBG_PIM_CPM] - ' || SQLERRM;
                  RAISE ge_custom_exception;
            END;
         END LOOP;
         --
         CLOSE c_hbg_pim_cpm_stg;
         --
      EXCEPTION
         WHEN ge_custom_exception THEN
            IF c_hbg_pim_cpm_stg%ISOPEN THEN
               CLOSE c_hbg_pim_cpm_stg;
            END IF;
            RAISE;
         WHEN OTHERS THEN
            IF c_hbg_pim_cpm_stg%ISOPEN THEN
               CLOSE c_hbg_pim_cpm_stg;
            END IF;
            --
            lv_error_msg := 'GENERAL EXCEPTION when loading records into [HBG_PIM_CPM]: ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'OPEN_AND_FETCH_C_HBG_PIM_PAM_STG';
      BEGIN
         OPEN c_hbg_pim_pam_stg;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_hbg_pim_pam_stg BULK COLLECT INTO lv_hbg_pim_pam_stg_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_hbg_pim_pam_stg_tb.COUNT = 0;

            lv_debug := 'FORALL_C_HBG_PIM_PAM_STG';
            BEGIN
               FORALL i IN 1 .. lv_hbg_pim_pam_stg_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_pim_pam
                     (isbn13
                     ,carton_qty
                     ,current_carton_qty
                     ,carton_weight
                     ,carton_height
                     ,carton_width
                     ,carton_depth
                     ,discount_group_code
                     ,discount_group_code_desc
                     ,product_profile_code
                     ,product_profile_desc
                     ,audience_code
                     ,audience_desc
                     ,language
                     ,language_desc
                     ,commodity_code
                     ,commodity_desc
                     ,customer_specific_code
                     ,customer_specific_desc
                     ,age_from
                     ,age_to
                     ,grade_from
                     ,grade_to
                     ,publication_date
                     ,epub_ver_no
                     ,product_content_type
                     ,osd_indicator
                     ,estimated_release_date
                     ,release_date
                     ,affidavit_laydown_flag
                     ,shipping_schedule
                     ,embargo_level
                     ,out_of_stock_reason
                     ,ito_ind
                     ,cancel_status_code
                     ,cancel_status_desc
                     ,return_deadline_date
                     ,reverted_no_sale_date
                     ,out_of_stock_date
                     ,print_on_demand_date
                     ,first_release_date
                     ,first_billing_date
                     ,first_ship_date
                     ,pub_cancel_date
                     ,rights_reverted_date
                     ,out_of_print_date
                     ,trim_size
                     ,audio_quantity
                     ,running_time
                     ,pagecount
                     ,bom_type
                     ,bom_boxed_set_ind
                     ,asstd_format_code
                     ,asstd_sub_format_code
                     ,age_group
                     ,isbn_on_book
                     ,pod_status_override
                     ,dbcs_create_timestamp
                     ,created_by
                     ,dbcs_update_timestamp
                     ,last_updated_by
                     ,hbg_process_id
                     ,oic_instance_id
                     )
                  VALUES
                     (lv_hbg_pim_pam_stg_tb(i).isbn13
                     ,lv_hbg_pim_pam_stg_tb(i).carton_qty
                     ,lv_hbg_pim_pam_stg_tb(i).current_carton_qty
                     ,lv_hbg_pim_pam_stg_tb(i).carton_weight
                     ,lv_hbg_pim_pam_stg_tb(i).carton_height
                     ,lv_hbg_pim_pam_stg_tb(i).carton_width
                     ,lv_hbg_pim_pam_stg_tb(i).carton_depth
                     ,lv_hbg_pim_pam_stg_tb(i).discount_group_code
                     ,lv_hbg_pim_pam_stg_tb(i).discount_group_code_desc
                     ,lv_hbg_pim_pam_stg_tb(i).product_profile_code
                     ,lv_hbg_pim_pam_stg_tb(i).product_profile_desc
                     ,lv_hbg_pim_pam_stg_tb(i).audience_code
                     ,lv_hbg_pim_pam_stg_tb(i).audience_desc
                     ,lv_hbg_pim_pam_stg_tb(i).language
                     ,lv_hbg_pim_pam_stg_tb(i).language_desc
                     ,lv_hbg_pim_pam_stg_tb(i).commodity_code
                     ,lv_hbg_pim_pam_stg_tb(i).commodity_desc
                     ,lv_hbg_pim_pam_stg_tb(i).customer_specific_code
                     ,lv_hbg_pim_pam_stg_tb(i).customer_specific_desc
                     ,lv_hbg_pim_pam_stg_tb(i).age_from
                     ,lv_hbg_pim_pam_stg_tb(i).age_to
                     ,lv_hbg_pim_pam_stg_tb(i).grade_from
                     ,lv_hbg_pim_pam_stg_tb(i).grade_to
                     ,lv_hbg_pim_pam_stg_tb(i).publication_date
                     ,lv_hbg_pim_pam_stg_tb(i).epub_ver_no
                     ,lv_hbg_pim_pam_stg_tb(i).product_content_type
                     ,lv_hbg_pim_pam_stg_tb(i).osd_indicator
                     ,lv_hbg_pim_pam_stg_tb(i).estimated_release_date
                     ,lv_hbg_pim_pam_stg_tb(i).release_date
                     ,lv_hbg_pim_pam_stg_tb(i).affidavit_laydown_flag
                     ,lv_hbg_pim_pam_stg_tb(i).shipping_schedule
                     ,lv_hbg_pim_pam_stg_tb(i).embargo_level
                     ,lv_hbg_pim_pam_stg_tb(i).out_of_stock_reason
                     ,lv_hbg_pim_pam_stg_tb(i).ito_ind
                     ,lv_hbg_pim_pam_stg_tb(i).cancel_status_code
                     ,lv_hbg_pim_pam_stg_tb(i).cancel_status_desc
                     ,lv_hbg_pim_pam_stg_tb(i).return_deadline_date
                     ,lv_hbg_pim_pam_stg_tb(i).reverted_no_sale_date
                     ,lv_hbg_pim_pam_stg_tb(i).out_of_stock_date
                     ,lv_hbg_pim_pam_stg_tb(i).print_on_demand_date
                     ,lv_hbg_pim_pam_stg_tb(i).first_release_date
                     ,lv_hbg_pim_pam_stg_tb(i).first_billing_date
                     ,lv_hbg_pim_pam_stg_tb(i).first_ship_date
                     ,lv_hbg_pim_pam_stg_tb(i).pub_cancel_date
                     ,lv_hbg_pim_pam_stg_tb(i).rights_reverted_date
                     ,lv_hbg_pim_pam_stg_tb(i).out_of_print_date
                     ,lv_hbg_pim_pam_stg_tb(i).trim_size
                     ,lv_hbg_pim_pam_stg_tb(i).audio_quantity
                     ,lv_hbg_pim_pam_stg_tb(i).running_time
                     ,lv_hbg_pim_pam_stg_tb(i).pagecount
                     ,lv_hbg_pim_pam_stg_tb(i).bom_type
                     ,lv_hbg_pim_pam_stg_tb(i).bom_boxed_set_ind
                     ,lv_hbg_pim_pam_stg_tb(i).asstd_format_code
                     ,lv_hbg_pim_pam_stg_tb(i).asstd_sub_format_code
                     ,lv_hbg_pim_pam_stg_tb(i).age_group
                     ,lv_hbg_pim_pam_stg_tb(i).isbn_on_book
                     ,lv_hbg_pim_pam_stg_tb(i).pod_status_override
                     ,CURRENT_DATE
                     ,(SELECT USER FROM dual)
                     ,CURRENT_DATE
                     ,(SELECT USER FROM dual)
                     ,lv_hbg_pim_pam_stg_tb(i).hbg_process_id
                     ,gv_oic_instance_id
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_PIM_PAM - ISBN13 ['
                           || lv_hbg_pim_pam_stg_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13 || '] - '
                           || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
                  END LOOP;
                  --
                  ROLLBACK;
                  lv_error_msg := 'ERROR when inserting records into [HBG_PIM_PAM]';
                  RAISE ge_custom_exception;
                  --
               WHEN OTHERS THEN
                  lv_error_msg := 'GENERAL ERROR when inserting records into [HBG_PIM_PAM] - ' || SQLERRM;
                  RAISE ge_custom_exception;
            END;
         END LOOP;
         --
         CLOSE c_hbg_pim_pam_stg;
         --
      EXCEPTION
         WHEN ge_custom_exception THEN
            IF c_hbg_pim_pam_stg%ISOPEN THEN
               CLOSE c_hbg_pim_pam_stg;
            END IF;
            RAISE;
         WHEN OTHERS THEN
            IF c_hbg_pim_pam_stg%ISOPEN THEN
               CLOSE c_hbg_pim_pam_stg;
            END IF;
            --
            lv_error_msg := 'GENERAL EXCEPTION when loading records into [HBG_PIM_PAM]: ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'OPEN_AND_FETCH_C_HBG_PIM_PAT_STG';
      BEGIN
         OPEN c_hbg_pim_pat_stg;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_hbg_pim_pat_stg BULK COLLECT INTO lv_hbg_pim_pat_stg_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_hbg_pim_pat_stg_tb.COUNT = 0;

            lv_debug := 'FORALL_C_HBG_PIM_PAT_STG';
            BEGIN
               FORALL i IN 1 .. lv_hbg_pim_pat_stg_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_pim_pat
                     (isbn13
                     ,alternate_item_code
                     ,alternate_item_type
                     ,default_flag
                     ,is_active
                     ,dbcs_create_timestamp
                     ,created_by
                     ,dbcs_update_timestamp
                     ,last_updated_by
                     ,hbg_process_id
                     ,oic_instance_id
                     )
                  VALUES
                     (lv_hbg_pim_pat_stg_tb(i).isbn13
                     ,lv_hbg_pim_pat_stg_tb(i).alternate_item_code
                     ,lv_hbg_pim_pat_stg_tb(i).alternate_item_type
                     ,lv_hbg_pim_pat_stg_tb(i).default_flag
                     ,lv_hbg_pim_pat_stg_tb(i).is_active
                     ,CURRENT_DATE
                     ,(SELECT USER FROM dual)
                     ,CURRENT_DATE
                     ,(SELECT USER FROM dual)
                     ,lv_hbg_pim_pat_stg_tb(i).hbg_process_id
                     ,gv_oic_instance_id
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_PIM_PAT - ISBN13 ['
                           || lv_hbg_pim_pat_stg_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13 || '] - '
                           || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
                  END LOOP;
                  --
                  ROLLBACK;
                  lv_error_msg := 'ERROR when inserting records into [HBG_PIM_PAT]';
                  RAISE ge_custom_exception;
                  --
               WHEN OTHERS THEN
                  lv_error_msg := 'GENERAL ERROR when inserting records into [HBG_PIM_PAT] - ' || SQLERRM;
                  RAISE ge_custom_exception;
            END;
         END LOOP;
         --
         CLOSE c_hbg_pim_pat_stg;
         --
      EXCEPTION
         WHEN ge_custom_exception THEN
            IF c_hbg_pim_pat_stg%ISOPEN THEN
               CLOSE c_hbg_pim_pat_stg;
            END IF;
            RAISE;
         WHEN OTHERS THEN
            IF c_hbg_pim_pat_stg%ISOPEN THEN
               CLOSE c_hbg_pim_pat_stg;
            END IF;
            --
            lv_error_msg := 'GENERAL EXCEPTION when loading records into [HBG_PIM_PAT]: ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'OPEN_AND_FETCH_C_HBG_PIM_PBC_STG';
      BEGIN
         OPEN c_hbg_pim_pbc_stg;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_hbg_pim_pbc_stg BULK COLLECT INTO lv_hbg_pim_pbc_stg_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_hbg_pim_pbc_stg_tb.COUNT = 0;

            lv_debug := 'FORALL_C_HBG_PIM_PBC_STG';
            BEGIN
               FORALL i IN 1 .. lv_hbg_pim_pbc_stg_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_pim_pbc
                     (isbn13
                     ,bisac_sequence
                     ,genbisac_code
                     ,genbisac_name
                     ,spcbisac_code
                     ,spcbisac_name
                     ,is_active
                     ,dbcs_create_timestamp
                     ,created_by
                     ,dbcs_update_timestamp
                     ,last_updated_by
                     ,hbg_process_id
                     ,oic_instance_id
                     )
                  VALUES
                     (lv_hbg_pim_pbc_stg_tb(i).isbn13
                     ,lv_hbg_pim_pbc_stg_tb(i).bisac_sequence
                     ,lv_hbg_pim_pbc_stg_tb(i).genbisac_code
                     ,lv_hbg_pim_pbc_stg_tb(i).genbisac_name
                     ,lv_hbg_pim_pbc_stg_tb(i).spcbisac_code
                     ,lv_hbg_pim_pbc_stg_tb(i).spcbisac_name
                     ,lv_hbg_pim_pbc_stg_tb(i).is_active
                     ,CURRENT_DATE
                     ,(SELECT USER FROM dual)
                     ,CURRENT_DATE
                     ,(SELECT USER FROM dual)
                     ,lv_hbg_pim_pbc_stg_tb(i).hbg_process_id
                     ,gv_oic_instance_id
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_PIM_PBC - ISBN13 ['
                           || lv_hbg_pim_pbc_stg_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13 || '] - '
                           || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
                  END LOOP;
                  --
                  ROLLBACK;
                  lv_error_msg := 'ERROR when inserting records into [HBG_PIM_PBC]';
                  RAISE ge_custom_exception;
                  --
               WHEN OTHERS THEN
                  lv_error_msg := 'GENERAL ERROR when inserting records into [HBG_PIM_PBC] - ' || SQLERRM;
                  RAISE ge_custom_exception;
            END;
         END LOOP;
         --
         CLOSE c_hbg_pim_pbc_stg;
         --
      EXCEPTION
         WHEN ge_custom_exception THEN
            IF c_hbg_pim_pbc_stg%ISOPEN THEN
               CLOSE c_hbg_pim_pbc_stg;
            END IF;
            RAISE;
         WHEN OTHERS THEN
            IF c_hbg_pim_pbc_stg%ISOPEN THEN
               CLOSE c_hbg_pim_pbc_stg;
            END IF;
            --
            lv_error_msg := 'GENERAL EXCEPTION when loading records into [HBG_PIM_PBC]: ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'OPEN_AND_FETCH_C_HBG_PIM_PCA_STG';
      BEGIN
         OPEN c_hbg_pim_pca_stg;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_hbg_pim_pca_stg BULK COLLECT INTO lv_hbg_pim_pca_stg_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_hbg_pim_pca_stg_tb.COUNT = 0;

            lv_debug := 'FORALL_C_HBG_PIM_PCA_STG';
            BEGIN
               FORALL i IN 1 .. lv_hbg_pim_pca_stg_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_pim_pca
                     (isbn13
                     ,contact_key
                     ,global_contact_key
                     ,role_code
                     ,role_desc
                     ,cntb_sequence
                     ,prefix
                     ,suffix
                     ,degree
                     ,first_name
                     ,middle_name
                     ,last_name
                     ,display_name
                     ,group_name
                     ,contact_type
                     ,is_active
                     ,dbcs_create_timestamp
                     ,created_by
                     ,dbcs_update_timestamp
                     ,last_updated_by
                     ,hbg_process_id
                     ,oic_instance_id
                     )
                  VALUES
                     (lv_hbg_pim_pca_stg_tb(i).isbn13
                     ,lv_hbg_pim_pca_stg_tb(i).contact_key
                     ,lv_hbg_pim_pca_stg_tb(i).global_contact_key
                     ,lv_hbg_pim_pca_stg_tb(i).role_code
                     ,lv_hbg_pim_pca_stg_tb(i).role_desc
                     ,lv_hbg_pim_pca_stg_tb(i).cntb_sequence
                     ,lv_hbg_pim_pca_stg_tb(i).prefix
                     ,lv_hbg_pim_pca_stg_tb(i).suffix
                     ,lv_hbg_pim_pca_stg_tb(i).degree
                     ,lv_hbg_pim_pca_stg_tb(i).first_name
                     ,lv_hbg_pim_pca_stg_tb(i).middle_name
                     ,lv_hbg_pim_pca_stg_tb(i).last_name
                     ,lv_hbg_pim_pca_stg_tb(i).display_name
                     ,lv_hbg_pim_pca_stg_tb(i).group_name
                     ,lv_hbg_pim_pca_stg_tb(i).contact_type
                     ,lv_hbg_pim_pca_stg_tb(i).is_active
                     ,CURRENT_DATE
                     ,(SELECT USER FROM dual)
                     ,CURRENT_DATE
                     ,(SELECT USER FROM dual)
                     ,lv_hbg_pim_pca_stg_tb(i).hbg_process_id
                     ,gv_oic_instance_id
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_PIM_PCA - ISBN13 ['
                           || lv_hbg_pim_pca_stg_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13 || '] - '
                           || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
                  END LOOP;
                  --
                  ROLLBACK;
                  lv_error_msg := 'ERROR when inserting records into [HBG_PIM_PCA]';
                  RAISE ge_custom_exception;
                  --
               WHEN OTHERS THEN
                  lv_error_msg := 'GENERAL ERROR when inserting records into [HBG_PIM_PCA] - ' || SQLERRM;
                  RAISE ge_custom_exception;
            END;
         END LOOP;
         --
         CLOSE c_hbg_pim_pca_stg;
         --
      EXCEPTION
         WHEN ge_custom_exception THEN
            IF c_hbg_pim_pca_stg%ISOPEN THEN
               CLOSE c_hbg_pim_pca_stg;
            END IF;
            RAISE;
         WHEN OTHERS THEN
            IF c_hbg_pim_pca_stg%ISOPEN THEN
               CLOSE c_hbg_pim_pca_stg;
            END IF;
            --
            lv_error_msg := 'GENERAL EXCEPTION when loading records into [HBG_PIM_PCA]: ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'OPEN_AND_FETCH_C_HBG_PIM_PCC_STG';
      BEGIN
         OPEN c_hbg_pim_pcc_stg;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_hbg_pim_pcc_stg BULK COLLECT INTO lv_hbg_pim_pcc_stg_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_hbg_pim_pcc_stg_tb.COUNT = 0;

            lv_debug := 'FORALL_C_HBG_PIM_PCC_STG';
            BEGIN
               FORALL i IN 1 .. lv_hbg_pim_pcc_stg_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_pim_pcc
                     (isbn13
                     ,po_number
                     ,component_suffix
                     ,print_run
                     ,po_cost_ind
                     ,wo_cost_ind
                     ,long_title
                     ,dbcs_create_timestamp
                     ,created_by
                     ,dbcs_update_timestamp
                     ,last_updated_by
                     ,hbg_process_id
                     ,oic_instance_id
                     )
                  VALUES
                     (lv_hbg_pim_pcc_stg_tb(i).isbn13
                     ,lv_hbg_pim_pcc_stg_tb(i).po_number
                     ,lv_hbg_pim_pcc_stg_tb(i).component_suffix
                     ,lv_hbg_pim_pcc_stg_tb(i).print_run
                     ,lv_hbg_pim_pcc_stg_tb(i).po_cost_ind
                     ,lv_hbg_pim_pcc_stg_tb(i).wo_cost_ind
                     ,lv_hbg_pim_pcc_stg_tb(i).long_title
                     ,CURRENT_DATE
                     ,(SELECT USER FROM dual)
                     ,CURRENT_DATE
                     ,(SELECT USER FROM dual)
                     ,lv_hbg_pim_pcc_stg_tb(i).hbg_process_id
                     ,gv_oic_instance_id
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_PIM_PCC - ISBN13 ['
                           || lv_hbg_pim_pcc_stg_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13 || '] - '
                           || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
                  END LOOP;
                  --
                  ROLLBACK;
                  lv_error_msg := 'ERROR when inserting records into [HBG_PIM_PCC]';
                  RAISE ge_custom_exception;
                  --
               WHEN OTHERS THEN
                  lv_error_msg := 'GENERAL ERROR when inserting records into [HBG_PIM_PCC] - ' || SQLERRM;
                  RAISE ge_custom_exception;
            END;
         END LOOP;
         --
         CLOSE c_hbg_pim_pcc_stg;
         --
      EXCEPTION
         WHEN ge_custom_exception THEN
            IF c_hbg_pim_pcc_stg%ISOPEN THEN
               CLOSE c_hbg_pim_pcc_stg;
            END IF;
            RAISE;
         WHEN OTHERS THEN
            IF c_hbg_pim_pcc_stg%ISOPEN THEN
               CLOSE c_hbg_pim_pcc_stg;
            END IF;
            --
            lv_error_msg := 'GENERAL EXCEPTION when loading records into [HBG_PIM_PCC]: ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'OPEN_AND_FETCH_C_HBG_PIM_PEM_STG';
      BEGIN
         OPEN c_hbg_pim_pem_stg;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_hbg_pim_pem_stg BULK COLLECT INTO lv_hbg_pim_pem_stg_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_hbg_pim_pem_stg_tb.COUNT = 0;

            lv_debug := 'FORALL_C_HBG_PIM_PEM_STG';
            BEGIN
               FORALL i IN 1 .. lv_hbg_pim_pem_stg_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_pim_pem
                     (isbn13
                     ,sequence
                     ,edition_code
                     ,edition_onix_name
                     ,edition_desc
                     ,dbcs_create_timestamp
                     ,created_by
                     ,dbcs_update_timestamp
                     ,last_updated_by
                     ,hbg_process_id
                     ,oic_instance_id
                     )
                  VALUES
                     (lv_hbg_pim_pem_stg_tb(i).isbn13
                     ,lv_hbg_pim_pem_stg_tb(i).sequence
                     ,lv_hbg_pim_pem_stg_tb(i).edition_code
                     ,lv_hbg_pim_pem_stg_tb(i).edition_onix_name
                     ,lv_hbg_pim_pem_stg_tb(i).edition_desc
                     ,CURRENT_DATE
                     ,(SELECT USER FROM dual)
                     ,CURRENT_DATE
                     ,(SELECT USER FROM dual)
                     ,lv_hbg_pim_pem_stg_tb(i).hbg_process_id
                     ,gv_oic_instance_id
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_PIM_PEM - ISBN13 ['
                           || lv_hbg_pim_pem_stg_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13 || '] - '
                           || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
                  END LOOP;
                  --
                  ROLLBACK;
                  lv_error_msg := 'ERROR when inserting records into [HBG_PIM_PEM]';
                  RAISE ge_custom_exception;
                  --
               WHEN OTHERS THEN
                  lv_error_msg := 'GENERAL ERROR when inserting records into [HBG_PIM_PEM] - ' || SQLERRM;
                  RAISE ge_custom_exception;
            END;
         END LOOP;
         --
         CLOSE c_hbg_pim_pem_stg;
         --
      EXCEPTION
         WHEN ge_custom_exception THEN
            IF c_hbg_pim_pem_stg%ISOPEN THEN
               CLOSE c_hbg_pim_pem_stg;
            END IF;
            RAISE;
         WHEN OTHERS THEN
            IF c_hbg_pim_pem_stg%ISOPEN THEN
               CLOSE c_hbg_pim_pem_stg;
            END IF;
            --
            lv_error_msg := 'GENERAL EXCEPTION when loading records into [HBG_PIM_PEM]: ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'OPEN_AND_FETCH_C_HBG_PIM_PRM_STG';
      BEGIN
         OPEN c_hbg_pim_prm_stg;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_hbg_pim_prm_stg BULK COLLECT INTO lv_hbg_pim_prm_stg_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_hbg_pim_prm_stg_tb.COUNT = 0;

            lv_debug := 'FORALL_C_HBG_PIM_PRM_STG';
            BEGIN
               FORALL i IN 1 .. lv_hbg_pim_prm_stg_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_pim_prm
                     (isbn13
                     ,parent_product
                     ,primary_ind
                     ,relation_type
                     ,relation_seq_no
                     ,pieces_in_pack
                     ,bom_type
                     ,zero_ind
                     ,is_active
                     ,dbcs_create_timestamp
                     ,created_by
                     ,dbcs_update_timestamp
                     ,last_updated_by
                     ,hbg_process_id
                     ,oic_instance_id
                     )
                  VALUES
                     (lv_hbg_pim_prm_stg_tb(i).isbn13
                     ,lv_hbg_pim_prm_stg_tb(i).parent_product
                     ,lv_hbg_pim_prm_stg_tb(i).primary_ind
                     ,lv_hbg_pim_prm_stg_tb(i).relation_type
                     ,lv_hbg_pim_prm_stg_tb(i).relation_seq_no
                     ,lv_hbg_pim_prm_stg_tb(i).pieces_in_pack
                     ,lv_hbg_pim_prm_stg_tb(i).bom_type
                     ,lv_hbg_pim_prm_stg_tb(i).zero_ind
                     ,lv_hbg_pim_prm_stg_tb(i).is_active
                     ,CURRENT_DATE
                     ,(SELECT USER FROM dual)
                     ,CURRENT_DATE
                     ,(SELECT USER FROM dual)
                     ,lv_hbg_pim_prm_stg_tb(i).hbg_process_id
                     ,gv_oic_instance_id
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_PIM_PRM - ISBN13 ['
                           || lv_hbg_pim_prm_stg_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13 || '] - '
                           || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
                  END LOOP;
                  --
                  ROLLBACK;
                  lv_error_msg := 'ERROR when inserting records into [HBG_PIM_PRM]';
                  RAISE ge_custom_exception;
                  --
               WHEN OTHERS THEN
                  lv_error_msg := 'GENERAL ERROR when inserting records into [HBG_PIM_PRM] - ' || SQLERRM;
                  RAISE ge_custom_exception;
            END;
         END LOOP;
         --
         CLOSE c_hbg_pim_prm_stg;
         --
      EXCEPTION
         WHEN ge_custom_exception THEN
            IF c_hbg_pim_prm_stg%ISOPEN THEN
               CLOSE c_hbg_pim_prm_stg;
            END IF;
            RAISE;
         WHEN OTHERS THEN
            IF c_hbg_pim_prm_stg%ISOPEN THEN
               CLOSE c_hbg_pim_prm_stg;
            END IF;
            --
            lv_error_msg := 'GENERAL EXCEPTION when loading records into [HBG_PIM_PRM]: ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

   EXCEPTION
      WHEN ge_custom_exception THEN
         log_p('ERROR'
              ,'ERROR at the step [' || lv_debug || '] of the [LOAD_PROCESS_TABLES_P]. ' || lv_error_msg);
         RAISE;
      WHEN OTHERS THEN
            log_p('ERROR'
                 ,'GENERAL ERROR at the step [' || lv_debug || '] of the [LOAD_PROCESS_TABLES_P] - ' || dbms_utility.format_error_backtrace);
         RAISE;
   END load_process_tables_p;

   -- -----------------------------------------------------------------------------------------------------------------
   --  PROCEDURE: validate_data_p
   -- -----------------------------------------------------------------------------------------------------------------
   --
   --  Description: Procedure to validate data in process tables
   --
   -- -----------------------------------------------------------------------------------------------------------------
   PROCEDURE validate_data_p IS

      lv_debug VARCHAR2(1000);
      lv_error_msg VARCHAR2(32000) := '';

   BEGIN

      lv_debug := 'VALIDATE_LONG_TITLE_NOT_NULL_IN_HBG_PIM_CPM';
      BEGIN
         UPDATE hbg_pim_cpm hpc
            SET hpc.status = 'ERROR'
               ,hpc.error_text = 'VALIDATION ERROR - LONG_TITLE can not be null.'
          WHERE hpc.hbg_process_id = gv_hbg_process_id
            AND hpc.long_title IS NULL;
      EXCEPTION
         WHEN OTHERS THEN
            lv_error_msg := 'ERROR when updating HBG_PIM_CPM status to ERROR because of [LONG_TITLE IS NULL] - ' || SQLERRM;
      END;

      lv_debug := 'VALIDATE_OWNER_NOT_NULL_IN_HBG_PIM_CPM';
      BEGIN
         UPDATE hbg_pim_cpm hpc
            SET hpc.status = 'ERROR'
               ,hpc.error_text = 'VALIDATION ERROR - OWNER_CODE can not be null.'
          WHERE hpc.hbg_process_id = gv_hbg_process_id
            AND hpc.owner_code IS NULL;
      EXCEPTION
         WHEN OTHERS THEN
            lv_error_msg := TRIM(lv_error_msg || ' ERROR when updating HBG_PIM_CPM status to ERROR because of [OWNER_CODE IS NULL] - '
                                 || SQLERRM);
      END;

      COMMIT;

      IF lv_error_msg IS NOT NULL THEN
         RAISE ge_custom_exception;
      END IF;

   EXCEPTION
      WHEN ge_custom_exception THEN
         log_p('ERROR'
              ,'ERROR at the step [' || lv_debug || '] of the [VALIDATE_DATA_P]. ' || lv_error_msg);
         RAISE;
      WHEN OTHERS THEN
            log_p('ERROR'
                 ,'GENERAL ERROR at the step [' || lv_debug || '] of the [VALIDATE_DATA_P] - ' || dbms_utility.format_error_backtrace);
         RAISE;
   END validate_data_p;

   -- -----------------------------------------------------------------------------------------------------------------
   --  PROCEDURE: load_fbdi_tables_p
   -- -----------------------------------------------------------------------------------------------------------------
   --
   --  Description: Procedure to map, apply rules and load data from process tables into FBDI tables
   --
   -- -----------------------------------------------------------------------------------------------------------------
   PROCEDURE load_fbdi_tables_p IS

      -- Data for EGP_SYSTEM_ITEMS_INTERFACE
      CURSOR c_egp_system_items_interface IS
         SELECT hptm.load_sequence
               ,hpc.isbn13
               ,hpc.isbn10
               ,hpc.work_isbn
               ,hptm.organization_code
               ,CASE
                   WHEN hptm.organization_code = 'ITEM_MASTER' THEN
                      hpc.long_title
                   ELSE
                      NULL
                END item_description
               ,hptm.template_name
               ,'PIMDH' source_system_code
               ,hptm.item_class_name
               -- Standard attributes
               ,CASE
                   WHEN hptm.organization_code IN ('ITEM_MASTER') AND hpc.owner_code IN ('HB', 'HL', 'HU', 'XX') THEN
                      hpc.saleable_ind
                   ELSE
                      NULL
                END customer_ordered
               ,CASE
                   WHEN hptm.organization_code IN ('ITEM_MASTER') AND hpc.owner_code IN ('HB', 'HL', 'HU', 'XX') THEN
                      hpc.unit_weight
                   ELSE
                      NULL
                END unit_weight
               ,CASE
                   WHEN hptm.organization_code IN ('ITEM_MASTER') AND hpc.owner_code IN ('HB', 'HL', 'HU', 'XX')
                        AND NVL(hpc.unit_weight, 0) > 0 THEN
                      'LB'
                   ELSE
                      NULL
                END weight_uom_name
               ,CASE
                   WHEN hptm.organization_code IN ('ITEM_MASTER') AND hpc.owner_code IN ('HB', 'HL', 'HU', 'XX')
                        AND (hpc.unit_depth IS NOT NULL OR hpc.unit_width IS NOT NULL OR hpc.unit_height IS NOT NULL) THEN
                      'Ea'
                   ELSE
                      NULL
                END dimension_uom_name
               ,CASE
                   WHEN hptm.organization_code IN ('ITEM_MASTER') AND hpc.owner_code IN ('HB', 'HL', 'HU', 'XX') THEN
                      hpc.unit_depth
                   ELSE
                      NULL
                END unit_depth
               ,CASE
                   WHEN hptm.organization_code IN ('ITEM_MASTER') AND hpc.owner_code IN ('HB', 'HL', 'HU', 'XX') THEN
                      hpc.unit_width
                   ELSE
                      NULL
                END unit_width
               ,CASE
                   WHEN hptm.organization_code IN ('ITEM_MASTER') AND hpc.owner_code IN ('HB', 'HL', 'HU', 'XX') THEN
                      hpc.unit_height
                   ELSE
                      NULL
                END unit_height
               -- Planning Attributes
               ,CASE
                   WHEN hptm.organization_code IN ('ITEM_MASTER', 'HBG') AND hpc.owner_code IN ('HB')
                        AND hpc.abc_code IN ('A', 'B', 'C') AND hpc.pub_status NOT IN ('AOD') THEN
                      '1'
                   ELSE
                      NULL
                END forecast_type
               ,CASE
                   WHEN hptm.organization_code IN ('ITEM_MASTER', 'HBG') AND hpc.owner_code IN ('HB')
                        AND hpc.abc_code IN ('A', 'B', 'C') AND hpc.pub_status NOT IN ('AOD') THEN
                      '2'
                   ELSE
                      NULL
                END forecast_control
               ,CASE
                   WHEN hptm.organization_code IN ('ITEM_MASTER', 'HBG') AND hpc.owner_code IN ('HB')
                        AND hpc.abc_code IN ('A', 'B', 'C') AND hpc.pub_status NOT IN ('AOD') THEN
                      'Y'
                   ELSE
                      NULL
                END create_supply
               ,CASE
                   WHEN hptm.organization_code IN ('ITEM_MASTER', 'HBG') AND hpc.owner_code IN ('HB')
                        AND hpc.abc_code IN ('A', 'B', 'C') AND hpc.pub_status NOT IN ('AOD') THEN
                      '3'
                   ELSE
                      NULL
                END planning_method
               ,CASE
                   WHEN hptm.organization_code IN ('ITEM_MASTER', 'HBG') AND hpc.owner_code IN ('HB')
                        AND hpc.abc_code IN ('A', 'B', 'C') AND hpc.pub_status NOT IN ('AOD') THEN
                      '1'
                   ELSE
                      NULL
                END round_order_quantities
               ,CASE
                   WHEN hptm.organization_code IN ('ITEM_MASTER', 'HBG') AND hpc.owner_code IN ('HB')
                        AND hpc.abc_code IN ('A', 'B', 'C') AND hpc.pub_status NOT IN ('AOD') THEN
                      (hpc.lot_size * 7) -- source value is in Weeks.. converting it to Days
                   ELSE
                      NULL
                END lot_size
               ,CASE
                   WHEN hptm.organization_code IN ('ITEM_MASTER', 'HBG') AND hpc.owner_code IN ('HB')
                        AND hpc.abc_code IN ('A', 'B', 'C') AND hpc.pub_status NOT IN ('AOD') THEN
                      hpc.planner_code
                   ELSE
                      NULL
                END planner_code
               ,CASE
                   WHEN hptm.organization_code IN ('ITEM_MASTER', 'HBG') AND hpc.owner_code IN ('HB')
                        AND hpc.abc_code IN ('A', 'B', 'C') AND hpc.pub_status NOT IN ('AOD') THEN
                      (hpc.planner_lead_time * 7) -- converting it from Weeks to Days
                   ELSE
                      NULL
                END planner_lead_time
               ,CASE
                   WHEN hptm.organization_code IN ('ITEM_MASTER', 'HBG') AND hpc.owner_code IN ('HB')
                        AND hpc.abc_code IN ('A', 'B', 'C') AND hpc.pub_status NOT IN ('AOD') THEN
                      (NVL(hpc.reprint_weeks, 0) + NVL(hpc.delivery_weeks, 0)) * 7 -- converting it from Weeks to Days
                   ELSE
                      NULL
                END processing_days
                -- DFFs
               ,TRIM(REPLACE(REPLACE(hpc.planogram, CHR(10), ' '), CHR(13), ' ')) planogram
               ,hpc.fpm_date
               ,(hpc.reporting_group_code || hpc.publisher_code || hpc.imprint_code || hpc.format_code) product_family_code
               ,TRIM(REPLACE(REPLACE(hpc.author_name, CHR(10), ' '), CHR(13), ' ')) author_name
               ,hpc.associated_isbn
               ,TRIM(REPLACE(REPLACE(hpc.short_title, CHR(10), ' '), CHR(13), ' ')) short_title
               ,TRIM(REPLACE(REPLACE(hpc.long_title, CHR(10), ' '), CHR(13), ' ')) long_title
               ,TRIM(REPLACE(REPLACE(hpc.series_name, CHR(10), ' '), CHR(13), ' ')) series_name
               ,TRIM(REPLACE(REPLACE(hpc.tier_name, CHR(10), ' '), CHR(13), ' ')) tier_name
               ,TRIM(REPLACE(REPLACE(hpc.acquiring_editor, CHR(10), ' '), CHR(13), ' ')) acquiring_editor
               ,TRIM(REPLACE(REPLACE(hpc.current_editor_name, CHR(10), ' '), CHR(13), ' ')) current_editor_name
               ,TRIM(REPLACE(REPLACE(hpc.profit_sharing, CHR(10), ' '), CHR(13), ' ')) profit_sharing
               ,'' contract_id1
               ,'' contract_id2
               ,hpc.pub_status
               ,TRIM(REPLACE(REPLACE(hpc.edition, CHR(10), ' '), CHR(13), ' ')) edition
               ,(SELECT CASE
                           WHEN hppbc.spcbisac_name IS NOT NULL THEN
                              TRIM(REPLACE(REPLACE(hppbc.genbisac_name || '/' || hppbc.spcbisac_name, CHR(10), ' '), CHR(13), ' '))
                           ELSE
                              TRIM(REPLACE(REPLACE(hppbc.genbisac_name, CHR(10), ' '), CHR(13), ' '))
                        END bisac
                   FROM hbg_pim_pbc hppbc
                  WHERE hppbc.isbn13 = hpc.isbn13
                    AND hppbc.bisac_sequence = 1) bisac_category
               ,(SELECT CASE
                           WHEN hppbc.spcbisac_name IS NOT NULL THEN
                              TRIM(REPLACE(REPLACE(hppbc.genbisac_name || '/' || hppbc.spcbisac_name, CHR(10), ' '), CHR(13), ' '))
                           ELSE
                              TRIM(REPLACE(REPLACE(hppbc.genbisac_name, CHR(10), ' '), CHR(13), ' '))
                        END bisac
                   FROM hbg_pim_pbc hppbc
                  WHERE hppbc.isbn13 = hpc.isbn13
                    AND hppbc.bisac_sequence = 2) bisac_category1
               ,(SELECT CASE
                           WHEN hppbc.spcbisac_name IS NOT NULL THEN
                              TRIM(REPLACE(REPLACE(hppbc.genbisac_name || '/' || hppbc.spcbisac_name, CHR(10), ' '), CHR(13), ' '))
                           ELSE
                              TRIM(REPLACE(REPLACE(hppbc.genbisac_name, CHR(10), ' '), CHR(13), ' '))
                        END bisac
                   FROM hbg_pim_pbc hppbc
                  WHERE hppbc.isbn13 = hpc.isbn13
                    AND hppbc.bisac_sequence = 3) bisac_category2
               ,'' total_copies_received
               ,'' daily_sales_current_flag
               ,CASE
                   WHEN hpc.isbn13 = hpc.work_isbn THEN
                      'Y'
                   ELSE
                      'N'
                END first_format
               ,TRIM(REPLACE(REPLACE(hpc.tier_category_name, CHR(10), ' '), CHR(13), ' ')) tier_category_name
               ,hpc.licensed_product_flag
               ,'' daily_sales_prior_flag
               ,DECODE(hpc.digital_content_flag
                      ,'0', 'N'
                      ,'1', 'Y'
                      ,hpc.digital_content_flag) digital_content_flag
               ,DECODE(hpc.item_type
                      ,'B', 'Book'
                      ,'N', 'Non-Book'
                      ,hpc.item_type) item_type
               ,TRIM(REPLACE(REPLACE(hpc.subtitle, CHR(10), ' '), CHR(13), ' ')) subtitle
               ,hpc.series_number
               ,hpc.usd_msrp
               ,hpc.cad_msrp
               ,'' actual_unit_cost
               ,hpc.edition_number
               ,hpc.delivery_weeks
               ,hpc.on_sale_date
           FROM hbg_pim_cpm hpc
               ,hbg_pim_template_mappings hptm
          WHERE hpc.owner_code = hptm.owner_code
            AND DECODE(hpc.digital_content_flag
                      ,'0', 'N'
                      ,'Y') = hptm.digital_content_flag
            AND hpc.hbg_process_id = gv_hbg_process_id
            AND NVL(hpc.status, 'OK') <> 'ERROR'
          ORDER BY hpc.isbn13
                  ,hptm.load_sequence;

      -- Data for EGP_ITEM_CATEGORIES_INTERFACE
      CURSOR c_egp_item_categories_interface IS
         -- 
         SELECT hpc.rowid hpc_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               ,'HBG Planner Segment' category_set_name
               ,'PS_' || NVL(hpc.planner_segment_code, 'No_Planner_Segment') category_code
           FROM hbg_pim_cpm hpc
          WHERE NVL(hpc.status, 'OK') <> 'ERROR'
            AND hpc.owner_code IN ('HB') -- HBG owned
            AND hpc.abc_code IN ('A', 'B', 'C')
            AND hpc.pub_status NOT IN ('AOD') -- AOD = Print On Demand

         UNION

         SELECT hpc.rowid hpc_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               ,'HBG Product Hierarchy' category_set_name
               ,hpc.owner_code || '_' || hpc.reporting_group_code || hpc.publisher_code || hpc.imprint_code category_code
           FROM hbg_pim_cpm hpc
          WHERE NVL(hpc.status, 'OK') <> 'ERROR'
            AND hpc.owner_code IN ('HB') -- HBG owned
            AND hpc.abc_code IN ('A', 'B', 'C')
            AND hpc.pub_status NOT IN ('AOD') -- AOD = Print On Demand

         UNION

         SELECT hpc.rowid hpc_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               ,'HBG Format Hierarchy' category_set_name
               ,'FM_' || hpc.format_code || NVL(hpc.sub_format_code, '00') category_code
           FROM hbg_pim_cpm hpc
          WHERE NVL(hpc.status, 'OK') <> 'ERROR'
            AND hpc.owner_code IN ('HB') -- HBG owned
            AND hpc.abc_code IN ('A', 'B', 'C')
            AND hpc.pub_status NOT IN ('AOD') -- AOD = Print On Demand
            AND hpc.format_code IS NOT NULL

         UNION

         SELECT hpc.rowid hpc_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               ,'HBG ABC Code' category_set_name
               ,'ABC_' || hpc.abc_code category_code
           FROM hbg_pim_cpm hpc
          WHERE NVL(hpc.status, 'OK') <> 'ERROR'
            AND hpc.owner_code IN ('HB') -- HBG owned
            AND hpc.abc_code IN ('A', 'B', 'C')
            AND hpc.pub_status NOT IN ('AOD') -- AOD = Print On Demand

         UNION

         SELECT hpc.rowid hpc_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               ,'HBG FPM Date' category_set_name
               ,'FPM_' || TO_CHAR(hpc.fpm_date, 'YYYY/MM/DD') category_code
           FROM hbg_pim_cpm hpc
          WHERE NVL(hpc.status, 'OK') <> 'ERROR'
            AND hpc.owner_code IN ('HB') -- HBG owned
            AND hpc.abc_code IN ('A', 'B', 'C')
            AND hpc.pub_status NOT IN ('AOD') -- AOD = Print On Demand
            AND hpc.fpm_date IS NOT NULL

         UNION

         SELECT hpc.rowid hpc_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               ,'HBG Series' category_set_name
               ,'SER_' || REPLACE(TRIM(REPLACE(REPLACE(hpc.series_name, CHR(10), ' '), CHR(13), ' ')), ' ', '_') category_code
           FROM hbg_pim_cpm hpc
          WHERE NVL(hpc.status, 'OK') <> 'ERROR'
            AND hpc.owner_code IN ('HB') -- HBG owned
            AND hpc.abc_code IN ('A', 'B', 'C')
            AND hpc.pub_status NOT IN ('AOD') -- AOD = Print On Demand
            AND hpc.series_name IS NOT NULL

         UNION

         SELECT hpc.rowid hpc_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               ,'HBG Customer Specific' category_set_name
               ,'CSE_' || hpc.external_publisher_code category_code
           FROM hbg_pim_cpm hpc
          WHERE NVL(hpc.status, 'OK') <> 'ERROR'
            AND hpc.owner_code IN ('HB') -- HBG owned
            AND hpc.abc_code IN ('A', 'B', 'C')
            AND hpc.pub_status NOT IN ('AOD') -- AOD = Print On Demand
            AND hpc.external_publisher_code IS NOT NULL
            AND EXISTS (SELECT 'CSE'
                          FROM hbg_pim_pem hpp
                         WHERE hpp.isbn13 = hpc.isbn13
                           AND hpp.edition_code = 'CSE')

         UNION

         SELECT hpc.rowid hpc_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               ,'HBG Hot Title' category_set_name
               ,'HT_HotTitle' category_code
           FROM hbg_pim_cpm hpc
          WHERE NVL(hpc.status, 'OK') <> 'ERROR'
            AND hpc.owner_code IN ('HB') -- HBG owned
            AND hpc.abc_code IN ('A', 'B', 'C')
            AND hpc.pub_status NOT IN ('AOD') -- AOD = Print On Demand
            AND hpc.hot_title_flag = 'Y'

         UNION

         SELECT hpc.rowid hpc_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               ,'HBG BISAC 1' category_set_name
               ,'BIS1_' || TRIM(REPLACE(REPLACE(TO_CHAR(hpp.genbisac_code) || TO_CHAR(hpp.spcbisac_code), CHR(10), ' '), CHR(13), ' ')) category_code
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pbc hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND hpc.owner_code IN ('HB') -- HBG owned
            AND hpc.abc_code IN ('A', 'B', 'C')
            AND hpc.pub_status NOT IN ('AOD') -- AOD = Print On Demand
            AND hpp.bisac_sequence = 1

         UNION

         SELECT hpc.rowid hpc_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               ,'HBG BISAC 2' category_set_name
               ,'BIS2_' || TRIM(REPLACE(REPLACE(TO_CHAR(hpp.genbisac_code) || TO_CHAR(hpp.spcbisac_code), CHR(10), ' '), CHR(13), ' ')) category_code
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pbc hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND hpc.owner_code IN ('HB') -- HBG owned
            AND hpc.abc_code IN ('A', 'B', 'C')
            AND hpc.pub_status NOT IN ('AOD') -- AOD = Print On Demand
            AND hpp.bisac_sequence = 2

         UNION

         SELECT hpc.rowid hpc_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               ,'HBG BISAC 3' category_set_name
               ,'BIS3_' || TRIM(REPLACE(REPLACE(TO_CHAR(hpp.genbisac_code) || TO_CHAR(hpp.spcbisac_code), CHR(10), ' '), CHR(13), ' ')) category_code
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pbc hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND hpc.owner_code IN ('HB') -- HBG owned
            AND hpc.abc_code IN ('A', 'B', 'C')
            AND hpc.pub_status NOT IN ('AOD') -- AOD = Print On Demand
            AND hpp.bisac_sequence = 3

         UNION

         SELECT hpc.rowid hpc_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               ,'HBG Edition 1' category_set_name
               ,'ED1_' || TRIM(REPLACE(REPLACE(hpp.edition_code, CHR(10), ' '), CHR(13), ' ')) category_code
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pem hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND hpc.owner_code IN ('HB') -- HBG owned
            AND hpc.abc_code IN ('A', 'B', 'C')
            AND hpc.pub_status NOT IN ('AOD') -- AOD = Print On Demand
            AND hpp.sequence = 1

         UNION

         SELECT hpc.rowid hpc_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               ,'HBG Edition 2' category_set_name
               ,'ED2_' || TRIM(REPLACE(REPLACE(hpp.edition_code, CHR(10), ' '), CHR(13), ' ')) category_code
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pem hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND hpc.owner_code IN ('HB') -- HBG owned
            AND hpc.abc_code IN ('A', 'B', 'C')
            AND hpc.pub_status NOT IN ('AOD') -- AOD = Print On Demand
            AND hpp.sequence = 2;

      -- Data for EGO_ITEM_INTF_EFF_B with Attribute Group Code = Alternate Item
      CURSOR c_ego_item_intf_eff_b_alternate_item IS
         SELECT hpp.rowid hpp_rowid
               ,hpp.isbn13
               ,'ITEM_MASTER' organization_code
               --,'Alternate Item' attribute_group_code
               ,hpp.alternate_item_code
               ,hpp.alternate_item_type
               ,hpp.default_flag
               ,DECODE(hpp.is_active
                      ,1, 'Y'
                      ,'N') is_active
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pat hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND hpc.hbg_process_id = hpp.hbg_process_id
            AND hpc.hbg_process_id = gv_hbg_process_id
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND NVL(hpp.status, 'OK') <> 'ERROR'
            AND hpc.digital_content_flag = '0' -- Physical ISBNs only
            AND hpp.alternate_item_code IS NOT NULL
            AND hpp.alternate_item_type IS NOT NULL;

      -- Data for EGO_ITEM_INTF_EFF_B with Attribute Group Codes: BOM
      CURSOR c_ego_item_intf_eff_b_bom IS
         SELECT hpp.rowid hpp_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               -- 'BOM' attribute_group_code
               ,hpp.bom_type
               ,hpp.bom_boxed_set_ind
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pam hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND hpc.hbg_process_id = hpp.hbg_process_id
            AND hpc.hbg_process_id = gv_hbg_process_id
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND NVL(hpp.status, 'OK') <> 'ERROR'
            AND hpc.digital_content_flag = '0' -- Physical ISBNs only
            AND (hpp.bom_type IS NOT NULL
                 OR hpp.bom_boxed_set_ind IS NOT NULL);

      -- Data for EGO_ITEM_INTF_EFF_B with Attribute Group Codes: By Line
      CURSOR c_ego_item_intf_eff_b_by_line IS
         SELECT hpc.rowid hpc_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               -- 'By Line' attribute_group_code
               ,TRIM(REPLACE(REPLACE(hpc.by_line, CHR(10), ' '), CHR(13), ' ')) by_line
           FROM hbg_pim_cpm hpc
          WHERE hpc.hbg_process_id = gv_hbg_process_id
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND hpc.digital_content_flag = '0' -- Physical ISBNs only
            AND hpc.by_line IS NOT NULL;

      -- Data for EGO_ITEM_INTF_EFF_B with Attribute Group Code = Carton
      CURSOR c_ego_item_intf_eff_b_carton IS
         SELECT hpp.rowid hpp_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               -- 'Carton' attribute_group_code
               ,hpp.current_carton_qty
               ,hpp.carton_qty
               ,hpp.carton_weight
               ,hpp.carton_height
               ,hpp.carton_width
               ,hpp.carton_depth
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pam hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND hpc.hbg_process_id = hpp.hbg_process_id
            AND hpc.hbg_process_id = gv_hbg_process_id
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND NVL(hpp.status, 'OK') <> 'ERROR'
            AND hpc.digital_content_flag = '0' -- Physical ISBNs only
            AND (hpp.current_carton_qty IS NOT NULL
                 OR hpp.carton_qty IS NOT NULL
                 OR hpp.carton_weight IS NOT NULL
                 OR hpp.carton_height IS NOT NULL
                 OR hpp.carton_width IS NOT NULL
                 OR hpp.carton_depth IS NOT NULL);

      -- Data for EGO_ITEM_INTF_EFF_B with Attribute Group Codes: Configuration
      CURSOR c_ego_item_intf_eff_b_configuration IS
         SELECT hpp.rowid hpp_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               -- 'Configuration' attribute_group_code
               ,hpp.trim_size
               ,hpp.audio_quantity
               ,hpp.running_time
               ,hpp.carton_qty
               ,hpp.pagecount
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pam hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND hpc.hbg_process_id = hpp.hbg_process_id
            AND hpc.hbg_process_id = gv_hbg_process_id
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND NVL(hpp.status, 'OK') <> 'ERROR'
            AND hpc.digital_content_flag = '0' -- Physical ISBNs only
            AND (hpp.trim_size IS NOT NULL
                 OR hpp.audio_quantity IS NOT NULL
                 OR hpp.running_time IS NOT NULL
                 OR hpp.pagecount IS NOT NULL);

      -- Data for EGO_ITEM_INTF_EFF_B with Attribute Group Codes: Content
      CURSOR c_ego_item_intf_eff_b_content IS
         SELECT hpp.rowid hpp_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               -- 'Content' attribute_group_code
               ,hpp.product_content_type
               ,hpp.epub_ver_no
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pam hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND hpc.hbg_process_id = hpp.hbg_process_id
            AND hpc.hbg_process_id = gv_hbg_process_id
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND NVL(hpp.status, 'OK') <> 'ERROR'
            AND hpc.digital_content_flag = '0' -- Physical ISBNs only
            AND (hpp.product_content_type IS NOT NULL
                 OR hpp.epub_ver_no IS NOT NULL);

      -- Data for EGO_ITEM_INTF_EFF_B with Attribute Group Code = Contributor
      CURSOR c_ego_item_intf_eff_b_contributor IS
         SELECT hpp.rowid hpp_rowid
               ,hpp.isbn13
               ,'ITEM_MASTER' organization_code
               --,'Contributor' attribute_group_code
               ,hpp.role_code
               ,hpp.prefix
               ,TRIM(REPLACE(REPLACE(hpp.first_name, CHR(10), ' '), CHR(13), ' ')) first_name
               ,TRIM(REPLACE(REPLACE(hpp.middle_name, CHR(10), ' '), CHR(13), ' ')) middle_name
               ,TRIM(REPLACE(REPLACE(hpp.last_name, CHR(10), ' '), CHR(13), ' ')) last_name
               ,hpp.suffix
               ,hpp.group_name
               ,'' honours_affiliation
               ,hpp.cntb_sequence
               ,hpp.global_contact_key
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pca hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND hpc.hbg_process_id = hpp.hbg_process_id
            AND hpc.hbg_process_id = gv_hbg_process_id
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND NVL(hpp.status, 'OK') <> 'ERROR'
            AND hpc.digital_content_flag = '0' -- Physical ISBNs only
            AND hpp.role_code IS NOT NULL
            AND hpp.cntb_sequence IS NOT NULL;

      -- Data for EGO_ITEM_INTF_EFF_B with Attribute Group Codes: Discount Group
      CURSOR c_ego_item_intf_eff_b_discount_group IS
         SELECT hpp.rowid hpp_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               -- 'Discount Group' attribute_group_code
               ,hpp.discount_group_code
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pam hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND hpc.hbg_process_id = hpp.hbg_process_id
            AND hpc.hbg_process_id = gv_hbg_process_id
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND NVL(hpp.status, 'OK') <> 'ERROR'
            AND hpc.digital_content_flag = '0' -- Physical ISBNs only
            AND hpp.discount_group_code IS NOT NULL;

      -- Data for EGO_ITEM_INTF_EFF_B with Attribute Group Code = Edition Information
      CURSOR c_ego_item_intf_eff_b_edition IS
         SELECT hpp.rowid hpp_rowid
               ,hpp.isbn13
               ,'ITEM_MASTER' organization_code
               --,'Edition Information' attribute_group_code
               ,hpp.edition_code
               ,hpp.sequence
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pem hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND hpc.hbg_process_id = hpp.hbg_process_id
            AND hpc.hbg_process_id = gv_hbg_process_id
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND NVL(hpp.status, 'OK') <> 'ERROR'
            AND hpc.digital_content_flag = '0' -- Physical ISBNs only
            AND hpp.edition_code IS NOT NULL
            AND hpp.sequence IS NOT NULL;

      -- Data for EGO_ITEM_INTF_EFF_B with Attribute Group Codes: Estimated Release
      CURSOR c_ego_item_intf_eff_b_estimated_rel IS
         SELECT hpp.rowid hpp_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               -- 'Estimated Release' attribute_group_code
               ,hpp.osd_indicator
               ,hpp.affidavit_laydown_flag
               ,hpp.estimated_release_date
               ,hpc.on_sale_date
               ,hpp.release_date
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pam hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND hpc.hbg_process_id = hpp.hbg_process_id
            AND hpc.hbg_process_id = gv_hbg_process_id
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND NVL(hpp.status, 'OK') <> 'ERROR'
            AND hpc.digital_content_flag = '0' -- Physical ISBNs only
            AND (hpp.osd_indicator IS NOT NULL
                 OR hpp.affidavit_laydown_flag IS NOT NULL
                 OR hpp.estimated_release_date IS NOT NULL
                 OR hpc.on_sale_date IS NOT NULL
                 OR hpp.release_date IS NOT NULL);

      -- Data for EGO_ITEM_INTF_EFF_B with Attribute Group Codes: Family Code
      CURSOR c_ego_item_intf_eff_b_family_code IS
         SELECT hpp.rowid hpp_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               -- 'Family Code' attribute_group_code
               ,hpc.owner_code
               ,hpc.reporting_group_code
               ,hpc.publisher_code
               ,hpc.imprint_code
               ,hpc.external_publisher_code
               ,hpc.external_imprint_code
               ,hpc.format_code
               ,hpc.sub_format_code
               ,hpp.asstd_format_code
               ,hpp.asstd_sub_format_code
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pam hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND hpc.hbg_process_id = hpp.hbg_process_id
            AND hpc.hbg_process_id = gv_hbg_process_id
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND NVL(hpp.status, 'OK') <> 'ERROR'
            AND hpc.digital_content_flag = '0' -- Physical ISBNs only
            AND (hpc.owner_code IS NOT NULL
                 OR hpc.reporting_group_code IS NOT NULL
                 OR hpc.publisher_code IS NOT NULL
                 OR hpc.imprint_code IS NOT NULL
                 OR hpc.external_publisher_code IS NOT NULL
                 OR hpc.external_imprint_code IS NOT NULL
                 OR hpc.format_code IS NOT NULL
                 OR hpc.sub_format_code IS NOT NULL
                 OR hpp.asstd_format_code IS NOT NULL
                 OR hpp.asstd_sub_format_code IS NOT NULL);

      -- Data for EGO_ITEM_INTF_EFF_B with Attribute Group Codes: General
      CURSOR c_ego_item_intf_eff_b_general IS
         SELECT hpp.rowid hpp_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               -- 'General' attribute_group_code
               ,hpp.product_profile_code
               ,hpp.audience_code
               ,hpp.language
               ,'' language2
               ,'' medium
               ,'' format_binding
               ,TRIM(REPLACE(REPLACE(hpp.commodity_code, CHR(10), ' '), CHR(13), ' ')) commodity_code
               ,CASE
                   WHEN NVL(hpc.usd_msrp, 0) > 0 OR NVL(hpc.cad_msrp, 0) > 0 THEN
                      'Y'
                   ELSE
                      'N'
                END price_on_book
               ,hpp.age_group
               ,hpp.customer_specific_code
               ,'' shrink_wrap
               ,hpp.isbn_on_book
               ,CASE
                   WHEN INSTR(TRIM(hpc.author_name), ' ') = 0 THEN
                      TRIM(REPLACE(REPLACE(SUBSTR(TRIM(hpc.author_name), 1, 9), CHR(10), ' '), CHR(13), ' ')) 
                   ELSE
                      TRIM(REPLACE(REPLACE(SUBSTR(TRIM(hpc.author_name), INSTR(TRIM(hpc.author_name), ' ', -1) + 1, 9), CHR(10), ' '), CHR(13), ' '))
                   END short_author
               ,hpp.age_from
               ,hpp.age_to
               ,hpp.grade_from
               ,hpp.grade_to
               ,hpp.publication_date
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pam hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND hpc.hbg_process_id = hpp.hbg_process_id
            AND hpc.hbg_process_id = gv_hbg_process_id
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND NVL(hpp.status, 'OK') <> 'ERROR'
            AND hpc.digital_content_flag = '0'; -- Physical ISBNs only

      -- Data for EGO_ITEM_INTF_EFF_B with Attribute Group Code = General BISAC
      CURSOR c_ego_item_intf_eff_b_general_bisac IS
         SELECT hpp.rowid hpp_rowid
               ,hpp.isbn13
               ,'ITEM_MASTER' organization_code
               --,'General BISAC' attribute_group_code
               ,TRIM(REPLACE(REPLACE(hpp.genbisac_code, CHR(10), ' '), CHR(13), ' ')) genbisac_code
               ,TRIM(REPLACE(REPLACE(hpp.spcbisac_code, CHR(10), ' '), CHR(13), ' ')) spcbisac_code
               ,hpp.bisac_sequence
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pbc hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND hpc.hbg_process_id = hpp.hbg_process_id
            AND hpc.hbg_process_id = gv_hbg_process_id
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND NVL(hpp.status, 'OK') <> 'ERROR'
            AND hpc.digital_content_flag = '0' -- Physical ISBNs only
            AND hpp.bisac_sequence IS NOT NULL;

      -- Data for EGO_ITEM_INTF_EFF_B with Attribute Group Codes: Hot Title Indicator
      CURSOR c_ego_item_intf_eff_b_hot_title_ind IS
         SELECT hpp.rowid hpp_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               -- 'Hot Title Indicator' attribute_group_code
               ,hpc.hot_title_flag
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pam hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND hpc.hbg_process_id = hpp.hbg_process_id
            AND hpc.hbg_process_id = gv_hbg_process_id
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND NVL(hpp.status, 'OK') <> 'ERROR'
            AND hpc.digital_content_flag = '0' -- Physical ISBNs only
            AND hpc.hot_title_flag IS NOT NULL;

      -- Data for EGO_ITEM_INTF_EFF_B with Attribute Group Codes: Status and Release
      CURSOR c_ego_item_intf_eff_b_status_and_release IS
         SELECT hpp.rowid hpp_rowid
               ,hpc.isbn13
               ,'ITEM_MASTER' organization_code
               -- 'Status and Release' attribute_group_code
               ,hpp.shipping_schedule
               ,hpp.pod_status_override
               ,DECODE(hpp.embargo_level, 'NA', '', hpp.embargo_level) embargo_level
               ,'' sequestered_indicator
               ,'' country_of_origin
               ,'' non_standard_flag
               ,TRIM(REPLACE(REPLACE(hpp.out_of_stock_reason, CHR(10), ' '), CHR(13), ' ')) out_of_stock_reason
               ,hpp.ito_ind
               ,'' nyp_canceled_indicator
               ,hpp.cancel_status_code
               ,'' rights_reverted_indicator
               ,hpp.return_deadline_date
               ,hpp.reverted_no_sale_date
               ,hpp.out_of_stock_date
               ,hpp.print_on_demand_date
               ,hpp.first_release_date
               ,hpp.first_billing_date
               ,hpp.first_ship_date
               ,hpp.pub_cancel_date
               ,hpp.rights_reverted_date
               ,hpp.out_of_print_date
           FROM hbg_pim_cpm hpc
               ,hbg_pim_pam hpp
          WHERE hpc.isbn13 = hpp.isbn13
            AND hpc.hbg_process_id = hpp.hbg_process_id
            AND hpc.hbg_process_id = gv_hbg_process_id
            AND NVL(hpc.status, 'OK') <> 'ERROR'
            AND NVL(hpp.status, 'OK') <> 'ERROR'
            AND hpc.digital_content_flag = '0' -- Physical ISBNs only
            AND (hpp.shipping_schedule IS NOT NULL
                 OR hpp.pod_status_override IS NOT NULL
                 OR DECODE(hpp.embargo_level, 'NA', '', hpp.embargo_level) IS NOT NULL
                 OR hpp.out_of_stock_reason IS NOT NULL
                 OR hpp.ito_ind IS NOT NULL
                 OR hpp.cancel_status_code IS NOT NULL
                 OR hpp.return_deadline_date IS NOT NULL
                 OR hpp.reverted_no_sale_date IS NOT NULL
                 OR hpp.out_of_stock_date IS NOT NULL
                 OR hpp.print_on_demand_date IS NOT NULL
                 OR hpp.first_release_date IS NOT NULL
                 OR hpp.first_billing_date IS NOT NULL
                 OR hpp.first_ship_date IS NOT NULL
                 OR hpp.pub_cancel_date IS NOT NULL
                 OR hpp.rights_reverted_date IS NOT NULL
                 OR hpp.out_of_print_date IS NOT NULL);

      -- Table Types
      TYPE lt_ego_item_intf_eff_b_alternate_item_tb IS TABLE OF c_ego_item_intf_eff_b_alternate_item%ROWTYPE;
      TYPE lt_ego_item_intf_eff_b_bom_tb IS TABLE OF c_ego_item_intf_eff_b_bom%ROWTYPE;
      TYPE lt_ego_item_intf_eff_b_by_line_tb IS TABLE OF c_ego_item_intf_eff_b_by_line%ROWTYPE;
      TYPE lt_ego_item_intf_eff_b_carton_tb IS TABLE OF c_ego_item_intf_eff_b_carton%ROWTYPE;
      TYPE lt_ego_item_intf_eff_b_configuration_tb IS TABLE OF c_ego_item_intf_eff_b_configuration%ROWTYPE;
      TYPE lt_ego_item_intf_eff_b_content_tb IS TABLE OF c_ego_item_intf_eff_b_content%ROWTYPE;
      TYPE lt_ego_item_intf_eff_b_contributor_tb IS TABLE OF c_ego_item_intf_eff_b_contributor%ROWTYPE;
      TYPE lt_ego_item_intf_eff_b_discount_group_tb IS TABLE OF c_ego_item_intf_eff_b_discount_group%ROWTYPE;
      TYPE lt_ego_item_intf_eff_b_edition_tb IS TABLE OF c_ego_item_intf_eff_b_edition%ROWTYPE;
      TYPE lt_ego_item_intf_eff_b_estimated_rel_tb IS TABLE OF c_ego_item_intf_eff_b_estimated_rel%ROWTYPE;
      TYPE lt_ego_item_intf_eff_b_family_code_tb IS TABLE OF c_ego_item_intf_eff_b_family_code%ROWTYPE;
      TYPE lt_ego_item_intf_eff_b_general_tb IS TABLE OF c_ego_item_intf_eff_b_general%ROWTYPE;
      TYPE lt_ego_item_intf_eff_b_general_bisac_tb IS TABLE OF c_ego_item_intf_eff_b_general_bisac%ROWTYPE;
      TYPE lt_ego_item_intf_eff_b_hot_title_ind_tb IS TABLE OF c_ego_item_intf_eff_b_hot_title_ind%ROWTYPE;
      TYPE lt_ego_item_intf_eff_b_status_and_release_tb IS TABLE OF c_ego_item_intf_eff_b_status_and_release%ROWTYPE;
      TYPE lt_egp_item_categories_interface_tb IS TABLE OF c_egp_item_categories_interface%ROWTYPE;
      TYPE lt_egp_system_items_interface_tb IS TABLE OF c_egp_system_items_interface%ROWTYPE;

      -- Exceptions
      le_insert_exception EXCEPTION;
      PRAGMA EXCEPTION_INIT(le_insert_exception, -24381);

      lc_bulk_collect_limit CONSTANT PLS_INTEGER DEFAULT 1000;
      lv_aux1 VARCHAR2(1000);
      lv_aux2 VARCHAR2(1000);
      lv_aux3 VARCHAR2(500);
      lv_aux4 VARCHAR2(500);
      lv_breakpoints VARCHAR2(32000);
      lv_debug VARCHAR2(32000);
      lv_ego_item_intf_eff_b_alternate_item_tb lt_ego_item_intf_eff_b_alternate_item_tb;
      lv_ego_item_intf_eff_b_bom_tb lt_ego_item_intf_eff_b_bom_tb;
      lv_ego_item_intf_eff_b_by_line_tb lt_ego_item_intf_eff_b_by_line_tb;
      lv_ego_item_intf_eff_b_carton_tb lt_ego_item_intf_eff_b_carton_tb;
      lv_ego_item_intf_eff_b_configuration_tb lt_ego_item_intf_eff_b_configuration_tb;
      lv_ego_item_intf_eff_b_content_tb lt_ego_item_intf_eff_b_content_tb;
      lv_ego_item_intf_eff_b_contributor_tb lt_ego_item_intf_eff_b_contributor_tb;
      lv_ego_item_intf_eff_b_discount_group_tb lt_ego_item_intf_eff_b_discount_group_tb;
      lv_ego_item_intf_eff_b_edition_tb lt_ego_item_intf_eff_b_edition_tb;
      lv_ego_item_intf_eff_b_estimated_rel_tb lt_ego_item_intf_eff_b_estimated_rel_tb;
      lv_ego_item_intf_eff_b_family_code_tb lt_ego_item_intf_eff_b_family_code_tb;
      lv_ego_item_intf_eff_b_general_tb lt_ego_item_intf_eff_b_general_tb;
      lv_ego_item_intf_eff_b_general_bisac_tb lt_ego_item_intf_eff_b_general_bisac_tb;
      lv_ego_item_intf_eff_b_hot_title_ind_tb lt_ego_item_intf_eff_b_hot_title_ind_tb;
      lv_ego_item_intf_eff_b_status_and_release_tb lt_ego_item_intf_eff_b_status_and_release_tb;
      lv_egp_item_categories_interface_tb lt_egp_item_categories_interface_tb;
      lv_egp_system_items_interface_tb lt_egp_system_items_interface_tb;
      lv_error_msg VARCHAR2(32000);

   BEGIN
      lv_debug := 'OPEN_AND_FETCH_C_EGP_SYSTEM_ITEMS_INTERFACE';
      -- Process records to be inserted into FBDI table HBG_EGP_SYSTEM_ITEMS_INTERFACE
      BEGIN
         OPEN c_egp_system_items_interface;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_egp_system_items_interface BULK COLLECT INTO lv_egp_system_items_interface_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_egp_system_items_interface_tb.COUNT = 0;

            lv_debug := 'FORALL_C_EGP_SYSTEM_ITEMS_INTERFACE';
            BEGIN
               FORALL i IN 1 .. lv_egp_system_items_interface_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_egp_system_items_interface
                     (transaction_type
                     ,batch_id
                     ,batch_number
                     ,item_number
                     ,organization_code
                     ,description
                     ,template_name
                     ,source_system_code
                     ,item_catalog_group_name
                     ,vmi_forecast_type
                     ,ato_forecast_control
                     ,create_supply_flag
                     ,mrp_planning_code
                     ,rounding_control_type
                     ,customer_order_flag
                     ,unit_weight
                     ,weight_uom_name
                     ,dimension_uom_name
                     ,unit_length
                     ,unit_width
                     ,unit_height
                     ,fixed_days_supply
                     ,planner_code
                     ,preprocessing_lead_time
                     ,full_lead_time
                     ,attribute1
                     ,attribute2
                     ,attribute3
                     ,attribute4
                     ,attribute5
                     ,attribute6
                     ,attribute7
                     ,attribute8
                     ,attribute9
                     ,attribute10
                     ,attribute11
                     ,attribute12
                     ,attribute13
                     ,attribute14
                     ,attribute15
                     ,attribute16
                     ,attribute17
                     ,attribute18
                     ,attribute19
                     ,attribute20
                     ,attribute21
                     ,attribute22
                     ,attribute23
                     ,attribute24
                     ,attribute25
                     ,attribute26
                     ,attribute27
                     ,attribute28
                     ,attribute29
                     ,attribute30
                     ,attribute_number1
                     ,attribute_number2
                     ,attribute_number3
                     ,attribute_number4
                     ,attribute_number5
                     ,attribute_date1
                     ,attribute_date2
                     )
                  VALUES
                     ('SYNC'
                     ,gv_hbg_process_id
                     ,gv_hbg_process_id
                     ,lv_egp_system_items_interface_tb(i).isbn13
                     ,lv_egp_system_items_interface_tb(i).organization_code
                     ,lv_egp_system_items_interface_tb(i).item_description
                     ,lv_egp_system_items_interface_tb(i).template_name
                     ,lv_egp_system_items_interface_tb(i).source_system_code
                     ,lv_egp_system_items_interface_tb(i).item_class_name
                     ,lv_egp_system_items_interface_tb(i).forecast_type
                     ,lv_egp_system_items_interface_tb(i).forecast_control
                     ,lv_egp_system_items_interface_tb(i).create_supply
                     ,lv_egp_system_items_interface_tb(i).planning_method
                     ,lv_egp_system_items_interface_tb(i).round_order_quantities
                     ,lv_egp_system_items_interface_tb(i).customer_ordered
                     ,lv_egp_system_items_interface_tb(i).unit_weight
                     ,lv_egp_system_items_interface_tb(i).weight_uom_name
                     ,lv_egp_system_items_interface_tb(i).dimension_uom_name
                     ,lv_egp_system_items_interface_tb(i).unit_height
                     ,lv_egp_system_items_interface_tb(i).unit_width
                     ,lv_egp_system_items_interface_tb(i).unit_depth
                     ,lv_egp_system_items_interface_tb(i).lot_size
                     ,lv_egp_system_items_interface_tb(i).planner_code
                     ,lv_egp_system_items_interface_tb(i).planner_lead_time
                     ,lv_egp_system_items_interface_tb(i).processing_days
                     -- DFFs
                     ,lv_egp_system_items_interface_tb(i).product_family_code
                     ,lv_egp_system_items_interface_tb(i).isbn10
                     ,lv_egp_system_items_interface_tb(i).author_name
                     ,lv_egp_system_items_interface_tb(i).associated_isbn
                     ,lv_egp_system_items_interface_tb(i).short_title
                     ,lv_egp_system_items_interface_tb(i).long_title
                     ,lv_egp_system_items_interface_tb(i).series_name
                     ,lv_egp_system_items_interface_tb(i).tier_name
                     ,lv_egp_system_items_interface_tb(i).acquiring_editor
                     ,lv_egp_system_items_interface_tb(i).current_editor_name
                     ,lv_egp_system_items_interface_tb(i).profit_sharing
                     ,lv_egp_system_items_interface_tb(i).contract_id1
                     ,lv_egp_system_items_interface_tb(i).contract_id2
                     ,lv_egp_system_items_interface_tb(i).pub_status
                     ,lv_egp_system_items_interface_tb(i).edition
                     ,lv_egp_system_items_interface_tb(i).bisac_category
                     ,lv_egp_system_items_interface_tb(i).bisac_category1
                     ,lv_egp_system_items_interface_tb(i).bisac_category2
                     ,lv_egp_system_items_interface_tb(i).work_isbn
                     ,lv_egp_system_items_interface_tb(i).total_copies_received
                     ,lv_egp_system_items_interface_tb(i).daily_sales_current_flag
                     ,lv_egp_system_items_interface_tb(i).first_format
                     ,lv_egp_system_items_interface_tb(i).tier_category_name
                     ,lv_egp_system_items_interface_tb(i).licensed_product_flag
                     ,lv_egp_system_items_interface_tb(i).daily_sales_prior_flag
                     ,lv_egp_system_items_interface_tb(i).digital_content_flag
                     ,lv_egp_system_items_interface_tb(i).planogram
                     ,lv_egp_system_items_interface_tb(i).item_type
                     ,lv_egp_system_items_interface_tb(i).subtitle
                     ,lv_egp_system_items_interface_tb(i).series_number
                     ,lv_egp_system_items_interface_tb(i).usd_msrp
                     ,lv_egp_system_items_interface_tb(i).cad_msrp
                     ,lv_egp_system_items_interface_tb(i).actual_unit_cost
                     ,lv_egp_system_items_interface_tb(i).edition_number
                     ,lv_egp_system_items_interface_tb(i).delivery_weeks
                     ,lv_egp_system_items_interface_tb(i).on_sale_date
                     ,lv_egp_system_items_interface_tb(i).fpm_date
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_EGP_SYSTEM_ITEMS_INTERFACE - Item ['
                           || lv_egp_system_items_interface_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13 || '] - Organization ['
                           || lv_egp_system_items_interface_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).organization_code
                           || '] - ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
                  END LOOP;
                  --
                  ROLLBACK;
                  lv_error_msg := 'ERROR when inserting records into [HBG_EGP_SYSTEM_ITEMS_INTERFACE]';
                  RAISE ge_custom_exception;
                  --
               WHEN OTHERS THEN
                  lv_error_msg := 'GENERAL ERROR when inserting records into [HBG_EGP_SYSTEM_ITEMS_INTERFACE] - ' || SQLERRM;
                  RAISE ge_custom_exception;
            END;
         END LOOP;
         --
         CLOSE c_egp_system_items_interface;
         --
      EXCEPTION
         WHEN ge_custom_exception THEN
            IF c_egp_system_items_interface%ISOPEN THEN
               CLOSE c_egp_system_items_interface;
            END IF;
            RAISE;
         WHEN OTHERS THEN
            IF c_egp_system_items_interface%ISOPEN THEN
               CLOSE c_egp_system_items_interface;
            END IF;
            --
            lv_error_msg := 'GENERAL EXCEPTION when loading records into [HBG_EGP_SYSTEM_ITEMS_INTERFACE]: ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'OPEN_AND_FETCH_C_EGP_ITEM_CATEGORIES_INTERFACE';
      -- Process records to be inserted into FBDI table HBG_EGP_ITEM_CATEGORIES_INTERFACE
      BEGIN
         OPEN c_egp_item_categories_interface;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_egp_item_categories_interface BULK COLLECT INTO lv_egp_item_categories_interface_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_egp_item_categories_interface_tb.COUNT = 0;

            lv_debug := 'FORALL_C_EGP_ITEM_CATEGORIES_INTERFACE';
            BEGIN
               FORALL i IN 1 .. lv_egp_item_categories_interface_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_egp_item_categories_interface
                     (transaction_type
                     ,batch_id
                     ,batch_number
                     ,item_number
                     ,organization_code
                     ,category_set_name
                     ,category_code
                     )
                  VALUES
                     ('SYNC'
                     ,gv_hbg_process_id
                     ,gv_hbg_process_id
                     ,lv_egp_item_categories_interface_tb(i).isbn13
                     ,lv_egp_item_categories_interface_tb(i).organization_code
                     ,lv_egp_item_categories_interface_tb(i).category_set_name
                     ,lv_egp_item_categories_interface_tb(i).category_code
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     lv_aux1 := lv_egp_item_categories_interface_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).hpc_rowid;
                     lv_aux2 := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                     lv_aux3 := lv_egp_item_categories_interface_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).category_set_name;
                     lv_aux4 := lv_egp_item_categories_interface_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).category_code;
                     --
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_EGP_ITEM_CATEGORIES_INTERFACE with Category Set Name ['
                           || lv_aux3 || '] - Category Code [' || lv_aux4 || '] - Item ['
                           || lv_egp_item_categories_interface_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                           || '] - ' || lv_aux2);
                     --
                     BEGIN
                        UPDATE hbg_pim_cpm
                           SET error_text = TRIM(error_text || ' Error when loading Item Categories FBDI table (catalog = '
                                            || lv_aux3 || ') - ' || lv_aux2)
                         WHERE ROWID = lv_aux1;
                     EXCEPTION
                        WHEN OTHERS THEN
                           log_p('ERROR'
                                ,'ERROR updating [HBG_PIM_CPM.ERROR_TEXT] - Item ['
                                 || lv_egp_item_categories_interface_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                                 || '] - Category Set Name [' || lv_aux3 || '] - Category Code [' || lv_aux4 || '] - '
                                 || SQLERRM);
                     END;
                  END LOOP;
                  COMMIT;
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' ERROR when inserting records into [HBG_EGP_ITEM_CATEGORIES_INTERFACE]');
               WHEN OTHERS THEN
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' GENERAL ERROR when inserting records into [HBG_EGP_ITEM_CATEGORIES'
                                  || '_INTERFACE] - ' || SQLERRM);
            END;
         END LOOP;
         --
         CLOSE c_egp_item_categories_interface;
         --
      EXCEPTION
         WHEN OTHERS THEN
            IF c_egp_item_categories_interface%ISOPEN THEN
               CLOSE c_egp_item_categories_interface;
            END IF;
            --
            lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
            lv_error_msg := TRIM(lv_error_msg || ' GENERAL EXCEPTION when loading records into [HBG_EGP_ITEM_CATEGORIES] - '
                                 || SQLERRM);
      END;

      lv_debug := 'OPEN_AND_FETCH_C_EGO_ITEM_INTF_EFF_B_ALTERNATE_ITEM';
      -- Process records to be inserted into FBDI table HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Alternate Item
      BEGIN
         OPEN c_ego_item_intf_eff_b_alternate_item;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_ego_item_intf_eff_b_alternate_item BULK COLLECT INTO lv_ego_item_intf_eff_b_alternate_item_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_ego_item_intf_eff_b_alternate_item_tb.COUNT = 0;

            lv_debug := 'FORALL_C_EGO_ITEM_INTF_EFF_B_-_ALTERNATE_ITEM';
            BEGIN
               FORALL i IN 1 .. lv_ego_item_intf_eff_b_alternate_item_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_ego_item_intf_eff_b
                     (transaction_type
                     ,batch_id
                     ,batch_number
                     ,item_number
                     ,organization_code
                     ,context_code
                     ,attribute_char1
                     ,attribute_char2
                     ,attribute_char3
                     ,attribute_char4
                     )
                  VALUES
                     ('SYNC'
                     ,gv_hbg_process_id
                     ,gv_hbg_process_id
                     ,lv_ego_item_intf_eff_b_alternate_item_tb(i).isbn13
                     ,lv_ego_item_intf_eff_b_alternate_item_tb(i).organization_code
                     ,'Alternate Item'
                     ,lv_ego_item_intf_eff_b_alternate_item_tb(i).alternate_item_code
                     ,lv_ego_item_intf_eff_b_alternate_item_tb(i).alternate_item_type
                     ,lv_ego_item_intf_eff_b_alternate_item_tb(i).default_flag
                     ,lv_ego_item_intf_eff_b_alternate_item_tb(i).is_active
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     lv_aux1 := lv_ego_item_intf_eff_b_alternate_item_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).hpp_rowid;
                     lv_aux2 := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                     --
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Alternate Item'
                           || ' - Item [' || lv_ego_item_intf_eff_b_alternate_item_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                           || '] - Alternate Item Code ['
                           || lv_ego_item_intf_eff_b_alternate_item_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).alternate_item_code
                           || '] - Alternate Item Type ['
                           || lv_ego_item_intf_eff_b_alternate_item_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).alternate_item_type
                           || '] - ' || lv_aux2);
                     --
                     BEGIN
                        UPDATE hbg_pim_pat
                           SET status = 'ERROR'
                              ,error_text = 'Error when loading FBDI table - ' || lv_aux2
                         WHERE ROWID = lv_aux1;
                     EXCEPTION
                        WHEN OTHERS THEN
                           log_p('ERROR'
                                ,'ERROR updating [HBG_PIM_PAT] - Item ['
                                 || lv_ego_item_intf_eff_b_alternate_item_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                                 || '] - Alternate Item Code  '
                                 || lv_ego_item_intf_eff_b_alternate_item_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).alternate_item_code
                                 || '] - Alternate Item Type ['
                                 || lv_ego_item_intf_eff_b_alternate_item_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).alternate_item_type
                                 || '] - Status [ERROR] - ' || SQLERRM);
                     END;
                  END LOOP;
                  COMMIT;
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' ERROR when inserting records into [HBG_EGO_ITEM_INTF_EFF_B]'
                                  || ' Attribute Group Code = Alternate Item');
               WHEN OTHERS THEN
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' GENERAL ERROR when inserting records into [HBG_EGO_ITEM_INTF'
                                  || '_EFF_B] Attribute Group Code = Alternate Item - ' || SQLERRM);
            END;
         END LOOP;
         --
         CLOSE c_ego_item_intf_eff_b_alternate_item;
         --
      EXCEPTION
         WHEN OTHERS THEN
            IF c_ego_item_intf_eff_b_alternate_item%ISOPEN THEN
               CLOSE c_ego_item_intf_eff_b_alternate_item;
            END IF;
            --
            lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
            lv_error_msg := TRIM(lv_error_msg || ' GENERAL EXCEPTION when loading records into [HBG_EGO_ITEM_INTF_EFF_B - '
                            || 'Alternate Item]: ' || SQLERRM);
      END;

      lv_debug := 'OPEN_AND_FETCH_C_EGO_ITEM_INTF_EFF_B_BOM';
      -- Process records to be inserted into FBDI table HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = BOM
      BEGIN
         OPEN c_ego_item_intf_eff_b_bom;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_ego_item_intf_eff_b_bom BULK COLLECT INTO lv_ego_item_intf_eff_b_bom_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_ego_item_intf_eff_b_bom_tb.COUNT = 0;

            lv_debug := 'FORALL_C_EGO_ITEM_INTF_EFF_B_-_BOM';
            BEGIN
               FORALL i IN 1 .. lv_ego_item_intf_eff_b_bom_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_ego_item_intf_eff_b
                     (transaction_type
                     ,batch_id
                     ,batch_number
                     ,item_number
                     ,organization_code
                     ,context_code
                     ,attribute_char1
                     ,attribute_char2
                     )
                  VALUES
                     ('SYNC'
                     ,gv_hbg_process_id
                     ,gv_hbg_process_id
                     ,lv_ego_item_intf_eff_b_bom_tb(i).isbn13
                     ,lv_ego_item_intf_eff_b_bom_tb(i).organization_code
                     ,'BOM'
                     ,lv_ego_item_intf_eff_b_bom_tb(i).bom_type
                     ,lv_ego_item_intf_eff_b_bom_tb(i).bom_boxed_set_ind
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     lv_aux1 := lv_ego_item_intf_eff_b_bom_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).hpp_rowid;
                     lv_aux2 := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                     --
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = BOM '
                           || '- Item [' || lv_ego_item_intf_eff_b_bom_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                           || '] - ' || lv_aux2);
                     --
                     BEGIN
                        UPDATE hbg_pim_pam
                           SET error_text = TRIM(error_text || ' Error when loading FBDI table - ' || lv_aux2)
                         WHERE ROWID = lv_aux1;
                     EXCEPTION
                        WHEN OTHERS THEN
                           log_p('ERROR'
                                ,'ERROR updating [HBG_PIM_PAM] - Item ['
                                 || lv_ego_item_intf_eff_b_bom_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                                 || '] when Attribute Group Code = BOM - Status [ERROR] - ' || SQLERRM);
                     END;
                  END LOOP;
                  COMMIT;
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' ERROR when inserting records into [HBG_EGO_ITEM_INTF_EFF_B]'
                                  || ' Attribute Group Code = BOM');
               WHEN OTHERS THEN
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' GENERAL ERROR when inserting records into [HBG_EGO_ITEM_INTF'
                                  || '_EFF_B] Attribute Group Code = BOM - ' || SQLERRM);
            END;
         END LOOP;
         --
         CLOSE c_ego_item_intf_eff_b_bom;
         --
      EXCEPTION
         WHEN OTHERS THEN
            IF c_ego_item_intf_eff_b_bom%ISOPEN THEN
               CLOSE c_ego_item_intf_eff_b_bom;
            END IF;
            --
            lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
            lv_error_msg := TRIM(lv_error_msg || ' GENERAL EXCEPTION when loading records into [HBG_EGO_ITEM_INTF_EFF_B'
                                 || ' - BOM]: ' || SQLERRM);
      END;

      lv_debug := 'OPEN_AND_FETCH_C_EGO_ITEM_INTF_EFF_B_BY_LINE';
      -- Process records to be inserted into FBDI table HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = By Line
      BEGIN
         OPEN c_ego_item_intf_eff_b_by_line;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_ego_item_intf_eff_b_by_line BULK COLLECT INTO lv_ego_item_intf_eff_b_by_line_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_ego_item_intf_eff_b_by_line_tb.COUNT = 0;

            lv_debug := 'FORALL_C_EGO_ITEM_INTF_EFF_B_-_BY_LINE';
            BEGIN
               FORALL i IN 1 .. lv_ego_item_intf_eff_b_by_line_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_ego_item_intf_eff_b
                     (transaction_type
                     ,batch_id
                     ,batch_number
                     ,item_number
                     ,organization_code
                     ,context_code
                     ,attribute_char1
                     )
                  VALUES
                     ('SYNC'
                     ,gv_hbg_process_id
                     ,gv_hbg_process_id
                     ,lv_ego_item_intf_eff_b_by_line_tb(i).isbn13
                     ,lv_ego_item_intf_eff_b_by_line_tb(i).organization_code
                     ,'By Line'
                     ,lv_ego_item_intf_eff_b_by_line_tb(i).by_line
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     lv_aux1 := lv_ego_item_intf_eff_b_by_line_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).hpc_rowid;
                     lv_aux2 := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                     --
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = By Line '
                           || '- Item [' || lv_ego_item_intf_eff_b_by_line_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                           || '] - ' || lv_aux2);
                     --
                     BEGIN
                        UPDATE hbg_pim_cpm
                           SET error_text = TRIM(error_text || ' Error when loading EFF FBDI table (context = By Line) - '
                                                 || lv_aux2)
                         WHERE ROWID = lv_aux1;
                     EXCEPTION
                        WHEN OTHERS THEN
                           log_p('ERROR'
                                ,'ERROR updating [HBG_PIM_CPM] - Item ['
                                 || lv_ego_item_intf_eff_b_by_line_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                                 || '] when Attribute Group Code = By Line - Status [ERROR] - ' || SQLERRM);
                     END;
                  END LOOP;
                  COMMIT;
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' ERROR when inserting records into [HBG_EGO_ITEM_INTF_EFF_B]'
                                  || ' Attribute Group Code = By Line');
               WHEN OTHERS THEN
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' GENERAL ERROR when inserting records into [HBG_EGO_ITEM_INTF'
                                  || '_EFF_B] Attribute Group Code = By Line - ' || SQLERRM);
            END;
         END LOOP;
         --
         CLOSE c_ego_item_intf_eff_b_by_line;
         --
      EXCEPTION
         WHEN OTHERS THEN
            IF c_ego_item_intf_eff_b_by_line%ISOPEN THEN
               CLOSE c_ego_item_intf_eff_b_by_line;
            END IF;
            --
            lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
            lv_error_msg := TRIM(lv_error_msg || ' GENERAL EXCEPTION when loading records into [HBG_EGO_ITEM_INTF_EFF_B'
                                 || ' - By Line]: ' || SQLERRM);
      END;

      lv_debug := 'OPEN_AND_FETCH_C_EGO_ITEM_INTF_EFF_B_CARTON';
      -- Process records to be inserted into FBDI table HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Carton
      BEGIN
         OPEN c_ego_item_intf_eff_b_carton;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_ego_item_intf_eff_b_carton BULK COLLECT INTO lv_ego_item_intf_eff_b_carton_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_ego_item_intf_eff_b_carton_tb.COUNT = 0;

            lv_debug := 'FORALL_C_EGO_ITEM_INTF_EFF_B_-_CARTON';
            BEGIN
               FORALL i IN 1 .. lv_ego_item_intf_eff_b_carton_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_ego_item_intf_eff_b
                     (transaction_type
                     ,batch_id
                     ,batch_number
                     ,item_number
                     ,organization_code
                     ,context_code
                     ,attribute_number1
                     ,attribute_number2
                     ,attribute_number3
                     ,attribute_number4
                     ,attribute_number5
                     ,attribute_number6
                     )
                  VALUES
                     ('SYNC'
                     ,gv_hbg_process_id
                     ,gv_hbg_process_id
                     ,lv_ego_item_intf_eff_b_carton_tb(i).isbn13
                     ,lv_ego_item_intf_eff_b_carton_tb(i).organization_code
                     ,'Carton'
                     ,lv_ego_item_intf_eff_b_carton_tb(i).current_carton_qty
                     ,lv_ego_item_intf_eff_b_carton_tb(i).carton_qty
                     ,lv_ego_item_intf_eff_b_carton_tb(i).carton_weight
                     ,lv_ego_item_intf_eff_b_carton_tb(i).carton_height
                     ,lv_ego_item_intf_eff_b_carton_tb(i).carton_width
                     ,lv_ego_item_intf_eff_b_carton_tb(i).carton_depth
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     lv_aux1 := lv_ego_item_intf_eff_b_carton_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).hpp_rowid;
                     lv_aux2 := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                     --
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Carton '
                           || '- Item [' || lv_ego_item_intf_eff_b_carton_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                           || '] - ' || lv_aux2);
                     --
                     BEGIN
                        UPDATE hbg_pim_pam
                           SET error_text = TRIM(error_text || ' Error when loading FBDI table - ' || lv_aux2)
                         WHERE ROWID = lv_aux1;
                     EXCEPTION
                        WHEN OTHERS THEN
                           log_p('ERROR'
                                ,'ERROR updating [HBG_PIM_PAM] - Item ['
                                 || lv_ego_item_intf_eff_b_carton_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                                 || '] when Attribute Group Code = Carton - Status [ERROR] - ' || SQLERRM);
                     END;
                  END LOOP;
                  COMMIT;
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' ERROR when inserting records into [HBG_EGO_ITEM_INTF_EFF_B]'
                                  || ' Attribute Group Code = Carton');
               WHEN OTHERS THEN
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' GENERAL ERROR when inserting records into [HBG_EGO_ITEM_INTF'
                                  || '_EFF_B] Attribute Group Code = Carton - ' || SQLERRM);
            END;
         END LOOP;
         --
         CLOSE c_ego_item_intf_eff_b_carton;
         --
      EXCEPTION
         WHEN OTHERS THEN
            IF c_ego_item_intf_eff_b_carton%ISOPEN THEN
               CLOSE c_ego_item_intf_eff_b_carton;
            END IF;
            --
            lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
            lv_error_msg := TRIM(lv_error_msg || ' GENERAL EXCEPTION when loading records into [HBG_EGO_ITEM_INTF_EFF_B'
                                 || ' - Carton]: ' || SQLERRM);
      END;

      lv_debug := 'OPEN_AND_FETCH_C_EGO_ITEM_INTF_EFF_B_CONFIGURATION';
      -- Process records to be inserted into FBDI table HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Configuration
      BEGIN
         OPEN c_ego_item_intf_eff_b_configuration;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_ego_item_intf_eff_b_configuration BULK COLLECT INTO lv_ego_item_intf_eff_b_configuration_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_ego_item_intf_eff_b_configuration_tb.COUNT = 0;

            lv_debug := 'FORALL_C_EGO_ITEM_INTF_EFF_B_-_CONFIGURATION';
            BEGIN
               FORALL i IN 1 .. lv_ego_item_intf_eff_b_configuration_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_ego_item_intf_eff_b
                     (transaction_type
                     ,batch_id
                     ,batch_number
                     ,item_number
                     ,organization_code
                     ,context_code
                     ,attribute_char1
                     ,attribute_number1
                     ,attribute_number2
                     ,attribute_number3
                     ,attribute_number4
                     )
                  VALUES
                     ('SYNC'
                     ,gv_hbg_process_id
                     ,gv_hbg_process_id
                     ,lv_ego_item_intf_eff_b_configuration_tb(i).isbn13
                     ,lv_ego_item_intf_eff_b_configuration_tb(i).organization_code
                     ,'Configuration'
                     ,lv_ego_item_intf_eff_b_configuration_tb(i).trim_size
                     ,lv_ego_item_intf_eff_b_configuration_tb(i).audio_quantity
                     ,lv_ego_item_intf_eff_b_configuration_tb(i).running_time
                     ,lv_ego_item_intf_eff_b_configuration_tb(i).carton_qty
                     ,lv_ego_item_intf_eff_b_configuration_tb(i).pagecount
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     lv_aux1 := lv_ego_item_intf_eff_b_configuration_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).hpp_rowid;
                     lv_aux2 := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                     --
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = '
                           || 'Configuration - Item ['
                           || lv_ego_item_intf_eff_b_configuration_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                           || '] - ' || lv_aux2);
                     --
                     BEGIN
                        UPDATE hbg_pim_pam
                           SET error_text = TRIM(error_text || ' Error when loading FBDI table - ' || lv_aux2)
                         WHERE ROWID = lv_aux1;
                     EXCEPTION
                        WHEN OTHERS THEN
                           log_p('ERROR'
                                ,'ERROR updating [HBG_PIM_PAM] - Item ['
                                 || lv_ego_item_intf_eff_b_configuration_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                                 || '] when Attribute Group Code = Configuration - Status [ERROR] - ' || SQLERRM);
                     END;
                  END LOOP;
                  COMMIT;
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' ERROR when inserting records into [HBG_EGO_ITEM_INTF_EFF_B]'
                                  || ' Attribute Group Code = Configuration');
               WHEN OTHERS THEN
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' GENERAL ERROR when inserting records into [HBG_EGO_ITEM_INTF'
                                  || '_EFF_B] Attribute Group Code = Configuration - ' || SQLERRM);
            END;
         END LOOP;
         --
         CLOSE c_ego_item_intf_eff_b_configuration;
         --
      EXCEPTION
         WHEN OTHERS THEN
            IF c_ego_item_intf_eff_b_configuration%ISOPEN THEN
               CLOSE c_ego_item_intf_eff_b_configuration;
            END IF;
            --
            lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
            lv_error_msg := TRIM(lv_error_msg || ' GENERAL EXCEPTION when loading records into [HBG_EGO_ITEM_INTF_EFF_B'
                                 || ' - Configuration]: ' || SQLERRM);
      END;

      lv_debug := 'OPEN_AND_FETCH_C_EGO_ITEM_INTF_EFF_B_CONTENT';
      -- Process records to be inserted into FBDI table HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Content
      BEGIN
         OPEN c_ego_item_intf_eff_b_content;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_ego_item_intf_eff_b_content BULK COLLECT INTO lv_ego_item_intf_eff_b_content_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_ego_item_intf_eff_b_content_tb.COUNT = 0;

            lv_debug := 'FORALL_C_EGO_ITEM_INTF_EFF_B_-_CONTENT';
            BEGIN
               FORALL i IN 1 .. lv_ego_item_intf_eff_b_content_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_ego_item_intf_eff_b
                     (transaction_type
                     ,batch_id
                     ,batch_number
                     ,item_number
                     ,organization_code
                     ,context_code
                     ,attribute_char1
                     ,attribute_number1
                     )
                  VALUES
                     ('SYNC'
                     ,gv_hbg_process_id
                     ,gv_hbg_process_id
                     ,lv_ego_item_intf_eff_b_content_tb(i).isbn13
                     ,lv_ego_item_intf_eff_b_content_tb(i).organization_code
                     ,'Content'
                     ,lv_ego_item_intf_eff_b_content_tb(i).product_content_type
                     ,lv_ego_item_intf_eff_b_content_tb(i).epub_ver_no
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     lv_aux1 := lv_ego_item_intf_eff_b_content_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).hpp_rowid;
                     lv_aux2 := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                     --
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Content '
                           || '- Item [' || lv_ego_item_intf_eff_b_content_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                           || '] - ' || lv_aux2);
                     --
                     BEGIN
                        UPDATE hbg_pim_pam
                           SET error_text = TRIM(error_text || ' Error when loading FBDI table - ' || lv_aux2)
                         WHERE ROWID = lv_aux1;
                        --
                        COMMIT;
                     EXCEPTION
                        WHEN OTHERS THEN
                           log_p('ERROR'
                                ,'ERROR updating [HBG_PIM_PAM] - Item ['
                                 || lv_ego_item_intf_eff_b_content_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                                 || '] when Attribute Group Code = Content - Status [ERROR] - ' || SQLERRM);
                     END;
                  END LOOP;
                  COMMIT;
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' ERROR when inserting records into [HBG_EGO_ITEM_INTF_EFF_B]'
                                  || ' Attribute Group Code = Content');
               WHEN OTHERS THEN
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' GENERAL ERROR when inserting records into [HBG_EGO_ITEM_INTF'
                                  || '_EFF_B] Attribute Group Code = Content - ' || SQLERRM);
            END;
         END LOOP;
         --
         CLOSE c_ego_item_intf_eff_b_content;
         --
      EXCEPTION
         WHEN OTHERS THEN
            IF c_ego_item_intf_eff_b_content%ISOPEN THEN
               CLOSE c_ego_item_intf_eff_b_content;
            END IF;
            --
            lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
            lv_error_msg := TRIM(lv_error_msg || ' GENERAL EXCEPTION when loading records into [HBG_EGO_ITEM_INTF_EFF_B'
                                 || ' - Content]: ' || SQLERRM);
      END;

      lv_debug := 'OPEN_AND_FETCH_C_EGO_ITEM_INTF_EFF_B_CONTRIBUTOR';
      -- Process records to be inserted into FBDI table HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Contributor
      BEGIN
         OPEN c_ego_item_intf_eff_b_contributor;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_ego_item_intf_eff_b_contributor BULK COLLECT INTO lv_ego_item_intf_eff_b_contributor_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_ego_item_intf_eff_b_contributor_tb.COUNT = 0;

            lv_debug := 'FORALL_C_EGO_ITEM_INTF_EFF_B_-_CONTRIBUTOR';
            BEGIN
               FORALL i IN 1 .. lv_ego_item_intf_eff_b_contributor_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_ego_item_intf_eff_b
                     (transaction_type
                     ,batch_id
                     ,batch_number
                     ,item_number
                     ,organization_code
                     ,context_code
                     ,attribute_char1
                     ,attribute_char2
                     ,attribute_char3
                     ,attribute_char4
                     ,attribute_char5
                     ,attribute_char6
                     ,attribute_char7
                     ,attribute_char8
                     ,attribute_number1
                     ,attribute_number2
                     )
                  VALUES
                     ('SYNC'
                     ,gv_hbg_process_id
                     ,gv_hbg_process_id
                     ,lv_ego_item_intf_eff_b_contributor_tb(i).isbn13
                     ,lv_ego_item_intf_eff_b_contributor_tb(i).organization_code
                     ,'Contributor'
                     ,lv_ego_item_intf_eff_b_contributor_tb(i).role_code
                     ,lv_ego_item_intf_eff_b_contributor_tb(i).prefix
                     ,lv_ego_item_intf_eff_b_contributor_tb(i).first_name
                     ,lv_ego_item_intf_eff_b_contributor_tb(i).middle_name
                     ,lv_ego_item_intf_eff_b_contributor_tb(i).last_name
                     ,lv_ego_item_intf_eff_b_contributor_tb(i).suffix
                     ,lv_ego_item_intf_eff_b_contributor_tb(i).group_name
                     ,lv_ego_item_intf_eff_b_contributor_tb(i).honours_affiliation
                     ,lv_ego_item_intf_eff_b_contributor_tb(i).cntb_sequence
                     ,lv_ego_item_intf_eff_b_contributor_tb(i).global_contact_key
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     lv_aux1 := lv_ego_item_intf_eff_b_contributor_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).hpp_rowid;
                     lv_aux2 := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                     --
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Contributor '
                           || '- Item [' || lv_ego_item_intf_eff_b_contributor_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                           || '] - Contributor Sequence ['
                           || lv_ego_item_intf_eff_b_contributor_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).cntb_sequence
                           || '] - Role Code ['
                           || lv_ego_item_intf_eff_b_contributor_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).role_code || '] - '
                           || lv_aux2);
                     --
                     BEGIN
                        UPDATE hbg_pim_pca
                           SET status = 'ERROR'
                              ,error_text = 'Error when loading FBDI table - ' || lv_aux2
                         WHERE ROWID = lv_aux1;
                     EXCEPTION
                        WHEN OTHERS THEN
                           log_p('ERROR'
                                ,'ERROR updating [HBG_PIM_PCA] - Item ['
                                 || lv_ego_item_intf_eff_b_contributor_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                                 || '] - Contributor Sequence ['
                                 || lv_ego_item_intf_eff_b_contributor_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).cntb_sequence
                                 || '] - Role Code ['
                                 || lv_ego_item_intf_eff_b_contributor_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).role_code
                                 || '] - Status [ERROR] - ' || SQLERRM);
                     END;
                  END LOOP;
                  COMMIT;
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' ERROR when inserting records into [HBG_EGO_ITEM_INTF_EFF_B]'
                                  || ' Attribute Group Code = Contributor');
               WHEN OTHERS THEN
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' GENERAL ERROR when inserting records into [HBG_EGO_ITEM_INTF'
                                  || '_EFF_B] Attribute Group Code = Contributor - ' || SQLERRM);
            END;
         END LOOP;
         --
         CLOSE c_ego_item_intf_eff_b_contributor;
         --
      EXCEPTION
         WHEN OTHERS THEN
            IF c_ego_item_intf_eff_b_contributor%ISOPEN THEN
               CLOSE c_ego_item_intf_eff_b_contributor;
            END IF;
            --
            lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
            lv_error_msg := TRIM(lv_error_msg || ' GENERAL EXCEPTION when loading records into [HBG_EGO_ITEM_INTF_EFF_B -'
                            || ' Contributor]: ' || SQLERRM);
      END;

      lv_debug := 'OPEN_AND_FETCH_C_EGO_ITEM_INTF_EFF_B_DISCOUNT_GROUP';
      -- Process records to be inserted into FBDI table HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Discount Group
      BEGIN
         OPEN c_ego_item_intf_eff_b_discount_group;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_ego_item_intf_eff_b_discount_group BULK COLLECT INTO lv_ego_item_intf_eff_b_discount_group_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_ego_item_intf_eff_b_discount_group_tb.COUNT = 0;

            lv_debug := 'FORALL_C_EGO_ITEM_INTF_EFF_B_-_DISCOUNT_GROUP';
            BEGIN
               FORALL i IN 1 .. lv_ego_item_intf_eff_b_discount_group_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_ego_item_intf_eff_b
                     (transaction_type
                     ,batch_id
                     ,batch_number
                     ,item_number
                     ,organization_code
                     ,context_code
                     ,attribute_char1
                     )
                  VALUES
                     ('SYNC'
                     ,gv_hbg_process_id
                     ,gv_hbg_process_id
                     ,lv_ego_item_intf_eff_b_discount_group_tb(i).isbn13
                     ,lv_ego_item_intf_eff_b_discount_group_tb(i).organization_code
                     ,'Discount Group'
                     ,lv_ego_item_intf_eff_b_discount_group_tb(i).discount_group_code
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     lv_aux1 := lv_ego_item_intf_eff_b_discount_group_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).hpp_rowid;
                     lv_aux2 := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                     --
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Discount Group '
                           || '- Item [' || lv_ego_item_intf_eff_b_discount_group_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                           || '] - ' || lv_aux2);
                     --
                     BEGIN
                        UPDATE hbg_pim_pam
                           SET error_text = TRIM(error_text || ' Error when loading FBDI table - ' || lv_aux2)
                         WHERE ROWID = lv_aux1;
                     EXCEPTION
                        WHEN OTHERS THEN
                           log_p('ERROR'
                                ,'ERROR updating [HBG_PIM_PAM] - Item ['
                                 || lv_ego_item_intf_eff_b_discount_group_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                                 || '] when Attribute Group Code = Discount Group - Status [ERROR] - ' || SQLERRM);
                     END;
                  END LOOP;
                  COMMIT;
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' ERROR when inserting records into [HBG_EGO_ITEM_INTF_EFF_B]'
                                  || ' Attribute Group Code = Discount Group');
               WHEN OTHERS THEN
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' GENERAL ERROR when inserting records into [HBG_EGO_ITEM_INTF'
                                  || '_EFF_B] Attribute Group Code = Discount Group - ' || SQLERRM);
            END;
         END LOOP;
         --
         CLOSE c_ego_item_intf_eff_b_discount_group;
         --
      EXCEPTION
         WHEN OTHERS THEN
            IF c_ego_item_intf_eff_b_discount_group%ISOPEN THEN
               CLOSE c_ego_item_intf_eff_b_discount_group;
            END IF;
            --
            lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
            lv_error_msg := TRIM(lv_error_msg || ' GENERAL EXCEPTION when loading records into [HBG_EGO_ITEM_INTF_EFF_B'
                                 || ' - Discount Group]: ' || SQLERRM);
      END;

      lv_debug := 'OPEN_AND_FETCH_C_EGO_ITEM_INTF_EFF_B_EDITION';
      -- Process records to be inserted into FBDI table HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Edition Information
      BEGIN
         OPEN c_ego_item_intf_eff_b_edition;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_ego_item_intf_eff_b_edition BULK COLLECT INTO lv_ego_item_intf_eff_b_edition_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_ego_item_intf_eff_b_edition_tb.COUNT = 0;

            lv_debug := 'FORALL_C_EGO_ITEM_INTF_EFF_B_-_DISTRIBUTION_EDITION_CODE';
            BEGIN
               FORALL i IN 1 .. lv_ego_item_intf_eff_b_edition_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_ego_item_intf_eff_b
                     (transaction_type
                     ,batch_id
                     ,batch_number
                     ,item_number
                     ,organization_code
                     ,context_code
                     ,attribute_char1
                     ,attribute_number1
                     )
                  VALUES
                     ('SYNC'
                     ,gv_hbg_process_id
                     ,gv_hbg_process_id
                     ,lv_ego_item_intf_eff_b_edition_tb(i).isbn13
                     ,lv_ego_item_intf_eff_b_edition_tb(i).organization_code
                     ,'Edition Information'
                     ,lv_ego_item_intf_eff_b_edition_tb(i).edition_code
                     ,lv_ego_item_intf_eff_b_edition_tb(i).sequence
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     lv_aux1 := lv_ego_item_intf_eff_b_edition_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).hpp_rowid;
                     lv_aux2 := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                     --
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Distribution '
                           || 'Edition Code - Item ['
                           || lv_ego_item_intf_eff_b_edition_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                           || '] - Edition Code ['
                           || lv_ego_item_intf_eff_b_edition_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).edition_code
                           || '] - Edition Sequence ['
                           || lv_ego_item_intf_eff_b_edition_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).sequence
                           || '] - ' || lv_aux2);
                     --
                     BEGIN
                        UPDATE hbg_pim_pem
                           SET status = 'ERROR'
                              ,error_text = 'Error when loading FBDI table - ' || lv_aux2
                         WHERE ROWID = lv_aux1;
                     EXCEPTION
                        WHEN OTHERS THEN
                           log_p('ERROR'
                                ,'ERROR updating [HBG_PIM_PEM] - Item ['
                                 || lv_ego_item_intf_eff_b_edition_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                                 || '] - Edition Code ['
                                 || lv_ego_item_intf_eff_b_edition_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).edition_code
                                 || '] - Edition Sequence ['
                                 || lv_ego_item_intf_eff_b_edition_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).sequence
                                 || '] - Status [ERROR] - ' || SQLERRM);
                     END;
                  END LOOP;
                  COMMIT;
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' ERROR when inserting records into [HBG_EGO_ITEM_INTF_EFF_B]'
                                  || ' Attribute Group Code = Edition Information');
               WHEN OTHERS THEN
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' GENERAL ERROR when inserting records into [HBG_EGO_ITEM_INTF'
                                  || '_EFF_B] Attribute Group Code = Edition Information - ' || SQLERRM);
            END;
         END LOOP;
         --
         CLOSE c_ego_item_intf_eff_b_edition;
         --
      EXCEPTION
         WHEN OTHERS THEN
            IF c_ego_item_intf_eff_b_edition%ISOPEN THEN
               CLOSE c_ego_item_intf_eff_b_edition;
            END IF;
            --
            lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
            lv_error_msg := TRIM(lv_error_msg || ' GENERAL EXCEPTION when loading records into [HBG_EGO_ITEM_INTF_EFF_B -'
                            || ' Edition Information]: ' || SQLERRM);
      END;

      -- Process records to be inserted into FBDI table HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Estimated Release
      BEGIN
         OPEN c_ego_item_intf_eff_b_estimated_rel;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_ego_item_intf_eff_b_estimated_rel BULK COLLECT INTO lv_ego_item_intf_eff_b_estimated_rel_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_ego_item_intf_eff_b_estimated_rel_tb.COUNT = 0;

            lv_debug := 'FORALL_C_EGO_ITEM_INTF_EFF_B_-_ESTIMATED_RELEASE';
            BEGIN
               FORALL i IN 1 .. lv_ego_item_intf_eff_b_estimated_rel_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_ego_item_intf_eff_b
                     (transaction_type
                     ,batch_id
                     ,batch_number
                     ,item_number
                     ,organization_code
                     ,context_code
                     ,attribute_char1
                     ,attribute_char2
                     ,attribute_date1
                     ,attribute_date2
                     ,attribute_date3
                     )
                  VALUES
                     ('SYNC'
                     ,gv_hbg_process_id
                     ,gv_hbg_process_id
                     ,lv_ego_item_intf_eff_b_estimated_rel_tb(i).isbn13
                     ,lv_ego_item_intf_eff_b_estimated_rel_tb(i).organization_code
                     ,'Estimated Release'
                     ,lv_ego_item_intf_eff_b_estimated_rel_tb(i).osd_indicator
                     ,lv_ego_item_intf_eff_b_estimated_rel_tb(i).affidavit_laydown_flag
                     ,lv_ego_item_intf_eff_b_estimated_rel_tb(i).estimated_release_date
                     ,lv_ego_item_intf_eff_b_estimated_rel_tb(i).on_sale_date
                     ,lv_ego_item_intf_eff_b_estimated_rel_tb(i).release_date
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     lv_aux1 := lv_ego_item_intf_eff_b_estimated_rel_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).hpp_rowid;
                     lv_aux2 := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                     --
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Estimated'
                           || ' Release - Item ['
                           || lv_ego_item_intf_eff_b_estimated_rel_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                           || '] - ' || lv_aux2);
                     --
                     BEGIN
                        UPDATE hbg_pim_pam
                           SET error_text = TRIM(error_text || ' Error when loading FBDI table - ' || lv_aux2)
                         WHERE ROWID = lv_aux1;
                     EXCEPTION
                        WHEN OTHERS THEN
                           log_p('ERROR'
                                ,'ERROR updating [HBG_PIM_PAM] - Item ['
                                 || lv_ego_item_intf_eff_b_estimated_rel_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                                 || '] when Attribute Group Code = Estimated Release - Status [ERROR] - ' || SQLERRM);
                     END;
                  END LOOP;
                  COMMIT;
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' ERROR when inserting records into [HBG_EGO_ITEM_INTF_EFF_B]'
                                  || ' Attribute Group Code = Estimated Release');
               WHEN OTHERS THEN
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' GENERAL ERROR when inserting records into [HBG_EGO_ITEM_INTF'
                                  || '_EFF_B] Attribute Group Code = Estimated Release - ' || SQLERRM);
            END;
         END LOOP;
         --
         CLOSE c_ego_item_intf_eff_b_estimated_rel;
         --
      EXCEPTION
         WHEN OTHERS THEN
            IF c_ego_item_intf_eff_b_estimated_rel%ISOPEN THEN
               CLOSE c_ego_item_intf_eff_b_estimated_rel;
            END IF;
            --
            lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
            lv_error_msg := TRIM(lv_error_msg || ' GENERAL EXCEPTION when loading records into [HBG_EGO_ITEM_INTF_EFF_B'
                                 || ' - Estimated Release]: ' || SQLERRM);
      END;

      lv_debug := 'OPEN_AND_FETCH_C_EGO_ITEM_INTF_EFF_B_FAMILY_CODE';
      -- Process records to be inserted into FBDI table HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Family Code
      BEGIN
         OPEN c_ego_item_intf_eff_b_family_code;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_ego_item_intf_eff_b_family_code BULK COLLECT INTO lv_ego_item_intf_eff_b_family_code_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_ego_item_intf_eff_b_family_code_tb.COUNT = 0;

            lv_debug := 'FORALL_C_EGO_ITEM_INTF_EFF_B_-_FAMILY_CODE';
            BEGIN
               FORALL i IN 1 .. lv_ego_item_intf_eff_b_family_code_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_ego_item_intf_eff_b
                     (transaction_type
                     ,batch_id
                     ,batch_number
                     ,item_number
                     ,organization_code
                     ,context_code
                     ,attribute_char1
                     ,attribute_char2
                     ,attribute_char3
                     ,attribute_char4
                     ,attribute_char5
                     ,attribute_char6
                     ,attribute_char7
                     ,attribute_char8
                     ,attribute_char9
                     ,attribute_char10
                     )
                  VALUES
                     ('SYNC'
                     ,gv_hbg_process_id
                     ,gv_hbg_process_id
                     ,lv_ego_item_intf_eff_b_family_code_tb(i).isbn13
                     ,lv_ego_item_intf_eff_b_family_code_tb(i).organization_code
                     ,'Family Code'
                     ,lv_ego_item_intf_eff_b_family_code_tb(i).owner_code
                     ,lv_ego_item_intf_eff_b_family_code_tb(i).reporting_group_code
                     ,lv_ego_item_intf_eff_b_family_code_tb(i).publisher_code
                     ,lv_ego_item_intf_eff_b_family_code_tb(i).imprint_code
                     ,lv_ego_item_intf_eff_b_family_code_tb(i).external_publisher_code
                     ,lv_ego_item_intf_eff_b_family_code_tb(i).external_imprint_code
                     ,lv_ego_item_intf_eff_b_family_code_tb(i).format_code
                     ,lv_ego_item_intf_eff_b_family_code_tb(i).sub_format_code
                     ,lv_ego_item_intf_eff_b_family_code_tb(i).asstd_format_code
                     ,lv_ego_item_intf_eff_b_family_code_tb(i).asstd_sub_format_code
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     lv_aux1 := lv_ego_item_intf_eff_b_family_code_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).hpp_rowid;
                     lv_aux2 := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                     --
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Family Code '
                           || '- Item [' || lv_ego_item_intf_eff_b_family_code_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                           || '] - ' || lv_aux2);
                     --
                     BEGIN
                        UPDATE hbg_pim_pam
                           SET error_text = TRIM(error_text || ' Error when loading FBDI table - ' || lv_aux2)
                         WHERE ROWID = lv_aux1;
                     EXCEPTION
                        WHEN OTHERS THEN
                           log_p('ERROR'
                                ,'ERROR updating [HBG_PIM_PAM] - Item ['
                                 || lv_ego_item_intf_eff_b_family_code_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                                 || '] when Attribute Group Code = Family Code - Status [ERROR] - ' || SQLERRM);
                     END;
                  END LOOP;
                  COMMIT;
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' ERROR when inserting records into [HBG_EGO_ITEM_INTF_EFF_B]'
                                  || ' Attribute Group Code = Family Code');
               WHEN OTHERS THEN
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' GENERAL ERROR when inserting records into [HBG_EGO_ITEM_INTF'
                                  || '_EFF_B] Attribute Group Code = Family Code - ' || SQLERRM);
            END;
         END LOOP;
         --
         CLOSE c_ego_item_intf_eff_b_family_code;
         --
      EXCEPTION
         WHEN OTHERS THEN
            IF c_ego_item_intf_eff_b_family_code%ISOPEN THEN
               CLOSE c_ego_item_intf_eff_b_family_code;
            END IF;
            --
            lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
            lv_error_msg := TRIM(lv_error_msg || ' GENERAL EXCEPTION when loading records into [HBG_EGO_ITEM_INTF_EFF_B'
                                 || ' - Family Code]: ' || SQLERRM);
      END;

      lv_debug := 'OPEN_AND_FETCH_C_EGO_ITEM_INTF_EFF_B_GENERAL';
      -- Process records to be inserted into FBDI table HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = General
      BEGIN
         OPEN c_ego_item_intf_eff_b_general;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_ego_item_intf_eff_b_general BULK COLLECT INTO lv_ego_item_intf_eff_b_general_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_ego_item_intf_eff_b_general_tb.COUNT = 0;

            lv_debug := 'FORALL_C_EGO_ITEM_INTF_EFF_B_-_GENERAL';
            BEGIN
               FORALL i IN 1 .. lv_ego_item_intf_eff_b_general_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_ego_item_intf_eff_b
                     (transaction_type
                     ,batch_id
                     ,batch_number
                     ,item_number
                     ,organization_code
                     ,context_code
                     --,attribute_char1
                     ,attribute_char2
                     ,attribute_char3
                     ,attribute_char4
                     ,attribute_char5
                     ,attribute_char6
                     ,attribute_char7
                     ,attribute_char8
                     ,attribute_char9
                     ,attribute_char10
                     ,attribute_char11
                     ,attribute_char12
                     ,attribute_char13
                     ,attribute_number1
                     ,attribute_number2
                     --,attribute_number3
                     --,attribute_number4
                     ,attribute_date1
                     )
                  VALUES
                     ('SYNC'
                     ,gv_hbg_process_id
                     ,gv_hbg_process_id
                     ,lv_ego_item_intf_eff_b_general_tb(i).isbn13
                     ,lv_ego_item_intf_eff_b_general_tb(i).organization_code
                     ,'General'
                     --,lv_ego_item_intf_eff_b_general_tb(i).product_profile_code
                     ,lv_ego_item_intf_eff_b_general_tb(i).audience_code
                     ,lv_ego_item_intf_eff_b_general_tb(i).language
                     ,lv_ego_item_intf_eff_b_general_tb(i).language2
                     ,lv_ego_item_intf_eff_b_general_tb(i).medium
                     ,lv_ego_item_intf_eff_b_general_tb(i).format_binding
                     ,lv_ego_item_intf_eff_b_general_tb(i).commodity_code
                     ,lv_ego_item_intf_eff_b_general_tb(i).price_on_book
                     ,lv_ego_item_intf_eff_b_general_tb(i).age_group
                     ,lv_ego_item_intf_eff_b_general_tb(i).customer_specific_code
                     ,lv_ego_item_intf_eff_b_general_tb(i).shrink_wrap
                     ,lv_ego_item_intf_eff_b_general_tb(i).isbn_on_book
                     ,lv_ego_item_intf_eff_b_general_tb(i).short_author
                     ,lv_ego_item_intf_eff_b_general_tb(i).age_from
                     ,lv_ego_item_intf_eff_b_general_tb(i).age_to
                     --,lv_ego_item_intf_eff_b_general_tb(i).grade_from
                     --,lv_ego_item_intf_eff_b_general_tb(i).grade_to
                     ,lv_ego_item_intf_eff_b_general_tb(i).publication_date
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     lv_aux1 := lv_ego_item_intf_eff_b_general_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).hpp_rowid;
                     lv_aux2 := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                     --
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = General '
                           || '- Item [' || lv_ego_item_intf_eff_b_general_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                           || '] - ' || lv_aux2);
                     --
                     BEGIN
                        UPDATE hbg_pim_pam
                           SET error_text = TRIM(error_text || ' Error when loading FBDI table - ' || lv_aux2)
                         WHERE ROWID = lv_aux1;
                     EXCEPTION
                        WHEN OTHERS THEN
                           log_p('ERROR'
                                ,'ERROR updating [HBG_PIM_PAM] - Item ['
                                 || lv_ego_item_intf_eff_b_general_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                                 || '] when Attribute Group Code = General - Status [ERROR] - ' || SQLERRM);
                     END;
                  END LOOP;
                  COMMIT;
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' ERROR when inserting records into [HBG_EGO_ITEM_INTF_EFF_B]'
                                  || ' Attribute Group Code = General');
               WHEN OTHERS THEN
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' GENERAL ERROR when inserting records into [HBG_EGO_ITEM_INTF'
                                  || '_EFF_B] Attribute Group Code = General - ' || SQLERRM);
            END;
         END LOOP;
         --
         CLOSE c_ego_item_intf_eff_b_general;
         --
      EXCEPTION
         WHEN OTHERS THEN
            IF c_ego_item_intf_eff_b_general%ISOPEN THEN
               CLOSE c_ego_item_intf_eff_b_general;
            END IF;
            --
            lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
            lv_error_msg := TRIM(lv_error_msg || ' GENERAL EXCEPTION when loading records into [HBG_EGO_ITEM_INTF_EFF_B'
                                 || ' - General]: ' || SQLERRM);
      END;

      lv_debug := 'OPEN_AND_FETCH_C_EGO_ITEM_INTF_EFF_B_GENERAL_BISAC';
      -- Process records to be inserted into FBDI table HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = General BISAC
      BEGIN
         OPEN c_ego_item_intf_eff_b_general_bisac;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_ego_item_intf_eff_b_general_bisac BULK COLLECT INTO lv_ego_item_intf_eff_b_general_bisac_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_ego_item_intf_eff_b_general_bisac_tb.COUNT = 0;

            lv_debug := 'FORALL_C_EGO_ITEM_INTF_EFF_B_-_GENERAL_BISAC';
            BEGIN
               FORALL i IN 1 .. lv_ego_item_intf_eff_b_general_bisac_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_ego_item_intf_eff_b
                     (transaction_type
                     ,batch_id
                     ,batch_number
                     ,item_number
                     ,organization_code
                     ,context_code
                     ,attribute_char1
                     ,attribute_number2
                     )
                  VALUES
                     ('SYNC'
                     ,gv_hbg_process_id
                     ,gv_hbg_process_id
                     ,lv_ego_item_intf_eff_b_general_bisac_tb(i).isbn13
                     ,lv_ego_item_intf_eff_b_general_bisac_tb(i).organization_code
                     ,'General BISAC'
                     ,lv_ego_item_intf_eff_b_general_bisac_tb(i).genbisac_code
                     ,lv_ego_item_intf_eff_b_general_bisac_tb(i).bisac_sequence
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     lv_aux1 := lv_ego_item_intf_eff_b_general_bisac_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).hpp_rowid;
                     lv_aux2 := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                     --
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = General '
                           || 'BISAC - Item ['
                           || lv_ego_item_intf_eff_b_general_bisac_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                           || '] - BISAC Sequence ['
                           || lv_ego_item_intf_eff_b_general_bisac_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).bisac_sequence
                           || '] - ' || lv_aux2);
                     --
                     BEGIN
                        UPDATE hbg_pim_pbc
                           SET status = 'ERROR'
                              ,error_text = 'Error when loading FBDI table - ' || lv_aux2
                         WHERE ROWID = lv_aux1;
                     EXCEPTION
                        WHEN OTHERS THEN
                           log_p('ERROR'
                                ,'ERROR updating [HBG_PIM_PBC] - Item ['
                                 || lv_ego_item_intf_eff_b_general_bisac_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                                 || '] - BISAC Sequence ['
                                 || lv_ego_item_intf_eff_b_general_bisac_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).bisac_sequence
                                 || '] - Status [ERROR] - ' || SQLERRM);
                     END;
                  END LOOP;
                  COMMIT;
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' ERROR when inserting records into [HBG_EGO_ITEM_INTF_EFF_B]'
                                  || ' Attribute Group Code = General BISAC');
               WHEN OTHERS THEN
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' GENERAL ERROR when inserting records into [HBG_EGO_ITEM_INTF'
                                  || '_EFF_B] Attribute Group Code = General BISAC - ' || SQLERRM);
            END;
         END LOOP;
         --
         CLOSE c_ego_item_intf_eff_b_general_bisac;
         --
      EXCEPTION
         WHEN OTHERS THEN
            IF c_ego_item_intf_eff_b_general_bisac%ISOPEN THEN
               CLOSE c_ego_item_intf_eff_b_general_bisac;
            END IF;
            --
            lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
            lv_error_msg := TRIM(lv_error_msg || ' GENERAL EXCEPTION when loading records into [HBG_EGO_ITEM_INTF_EFF_B'
                                 || ' - General BISAC]: ' || SQLERRM);
      END;

      lv_debug := 'OPEN_AND_FETCH_C_EGO_ITEM_INTF_EFF_B_HOT_TITLE_INDICATOR';
      -- Process records to be inserted into FBDI table HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Hot Title Indicator
      BEGIN
         OPEN c_ego_item_intf_eff_b_hot_title_ind;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_ego_item_intf_eff_b_hot_title_ind BULK COLLECT INTO lv_ego_item_intf_eff_b_hot_title_ind_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_ego_item_intf_eff_b_hot_title_ind_tb.COUNT = 0;

            lv_debug := 'FORALL_C_EGO_ITEM_INTF_EFF_B_-_HOT_TITLE_IND';
            BEGIN
               FORALL i IN 1 .. lv_ego_item_intf_eff_b_hot_title_ind_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_ego_item_intf_eff_b
                     (transaction_type
                     ,batch_id
                     ,batch_number
                     ,item_number
                     ,organization_code
                     ,context_code
                     ,attribute_char1
                     )
                  VALUES
                     ('SYNC'
                     ,gv_hbg_process_id
                     ,gv_hbg_process_id
                     ,lv_ego_item_intf_eff_b_hot_title_ind_tb(i).isbn13
                     ,lv_ego_item_intf_eff_b_hot_title_ind_tb(i).organization_code
                     ,'Hot Title Indicator'
                     ,lv_ego_item_intf_eff_b_hot_title_ind_tb(i).hot_title_flag
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     lv_aux1 := lv_ego_item_intf_eff_b_hot_title_ind_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).hpp_rowid;
                     lv_aux2 := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                     --
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Hot Title Indicator '
                           || '- Item [' || lv_ego_item_intf_eff_b_hot_title_ind_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                           || '] - ' || lv_aux2);
                     --
                     BEGIN
                        UPDATE hbg_pim_pam
                           SET error_text = TRIM(error_text || ' Error when loading FBDI table - ' || lv_aux2)
                         WHERE ROWID = lv_aux1;
                     EXCEPTION
                        WHEN OTHERS THEN
                           log_p('ERROR'
                                ,'ERROR updating [HBG_PIM_PAM] - Item ['
                                 || lv_ego_item_intf_eff_b_hot_title_ind_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                                 || '] when Attribute Group Code = Hot Title Indicator - Status [ERROR] - ' || SQLERRM);
                     END;
                  END LOOP;
                  COMMIT;
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' ERROR when inserting records into [HBG_EGO_ITEM_INTF_EFF_B]'
                                  || ' Attribute Group Code = Hot Title Indicator');
               WHEN OTHERS THEN
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' GENERAL ERROR when inserting records into [HBG_EGO_ITEM_INTF'
                                  || '_EFF_B] Attribute Group Code = Hot Title Indicator - ' || SQLERRM);
            END;
         END LOOP;
         --
         CLOSE c_ego_item_intf_eff_b_hot_title_ind;
         --
      EXCEPTION
         WHEN OTHERS THEN
            IF c_ego_item_intf_eff_b_hot_title_ind%ISOPEN THEN
               CLOSE c_ego_item_intf_eff_b_hot_title_ind;
            END IF;
            --
            lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
            lv_error_msg := TRIM(lv_error_msg || ' GENERAL EXCEPTION when loading records into [HBG_EGO_ITEM_INTF_EFF_B'
                                 || ' - Hot Title Indicator]: ' || SQLERRM);
      END;

      lv_debug := 'OPEN_AND_FETCH_C_EGO_ITEM_INTF_EFF_B_STATUS_AND_RELEASE';
      -- Process records to be inserted into FBDI table HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code = Status and Release
      BEGIN
         OPEN c_ego_item_intf_eff_b_status_and_release;
         LOOP
            -- Process collections of up to [lc_bulk_collect_limit] lines
            FETCH c_ego_item_intf_eff_b_status_and_release BULK COLLECT INTO lv_ego_item_intf_eff_b_status_and_release_tb LIMIT lc_bulk_collect_limit;
            EXIT WHEN lv_ego_item_intf_eff_b_status_and_release_tb.COUNT = 0;

            lv_debug := 'FORALL_C_EGO_ITEM_INTF_EFF_B_-_STATUS_AND_RELEASE';
            BEGIN
               FORALL i IN 1 .. lv_ego_item_intf_eff_b_status_and_release_tb.COUNT SAVE EXCEPTIONS
                  INSERT INTO hbg_ego_item_intf_eff_b
                     (transaction_type
                     ,batch_id
                     ,batch_number
                     ,item_number
                     ,organization_code
                     ,context_code
                     ,attribute_char1
                     ,attribute_char2
                     ,attribute_char3
                     ,attribute_char4
                     ,attribute_char5
                     ,attribute_char6
                     ,attribute_char7
                     ,attribute_char8
                     ,attribute_char9
                     ,attribute_char10
                     ,attribute_char11
                     ,attribute_date1
                     ,attribute_date2
                     ,attribute_date3
                     ,attribute_date4
                     ,attribute_date5
                     ,attribute_date6
                     ,attribute_date7
                     ,attribute_date8
                     ,attribute_date9
                     ,attribute_date10
                     )
                  VALUES
                     ('SYNC'
                     ,gv_hbg_process_id
                     ,gv_hbg_process_id
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).isbn13
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).organization_code
                     ,'Status and Release'
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).shipping_schedule
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).pod_status_override
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).embargo_level
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).sequestered_indicator
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).country_of_origin
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).non_standard_flag
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).out_of_stock_reason
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).ito_ind
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).nyp_canceled_indicator
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).cancel_status_code
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).rights_reverted_indicator
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).return_deadline_date
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).reverted_no_sale_date
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).out_of_stock_date
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).print_on_demand_date
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).first_release_date
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).first_billing_date
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).first_ship_date
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).pub_cancel_date
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).rights_reverted_date
                     ,lv_ego_item_intf_eff_b_status_and_release_tb(i).out_of_print_date
                     );
               --
               COMMIT;

            EXCEPTION
               WHEN le_insert_exception THEN
                  --
                  FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                     lv_aux1 := lv_ego_item_intf_eff_b_status_and_release_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).hpp_rowid;
                     lv_aux2 := SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                     --
                     log_p('ERROR'
                          ,'ERROR inserting records into HBG_EGO_ITEM_INTF_EFF_B with Attribute Group Code ='
                           || ' Status and Release - Item ['
                           || lv_ego_item_intf_eff_b_status_and_release_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                           || '] - ' || lv_aux2);
                     --
                     BEGIN
                        UPDATE hbg_pim_pam
                           SET error_text = TRIM(error_text || ' Error when loading FBDI table - ' || lv_aux2)
                         WHERE ROWID = lv_aux1;
                     EXCEPTION
                        WHEN OTHERS THEN
                           log_p('ERROR'
                                ,'ERROR updating [HBG_PIM_PAM] - Item ['
                                 || lv_ego_item_intf_eff_b_status_and_release_tb(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).isbn13
                                 || '] when Attribute Group Code = Status and Release - Status [ERROR] - ' || SQLERRM);
                     END;
                  END LOOP;
                  COMMIT;
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' ERROR when inserting records into [HBG_EGO_ITEM_INTF_EFF_B]'
                                  || ' Attribute Group Code = Status and Release');
               WHEN OTHERS THEN
                  lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
                  lv_error_msg := TRIM(lv_error_msg || ' GENERAL ERROR when inserting records into [HBG_EGO_ITEM_INTF'
                                  || '_EFF_B] Attribute Group Code = Status and Release - ' || SQLERRM);
            END;
         END LOOP;
         --
         CLOSE c_ego_item_intf_eff_b_status_and_release;
         --
      EXCEPTION
         WHEN OTHERS THEN
            IF c_ego_item_intf_eff_b_status_and_release%ISOPEN THEN
               CLOSE c_ego_item_intf_eff_b_status_and_release;
            END IF;
            --
            lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
            lv_error_msg := TRIM(lv_error_msg || ' GENERAL EXCEPTION when loading records into [HBG_EGO_ITEM_INTF_EFF_B'
                                 || ' - Status and Release]: ' || SQLERRM);
      END;

      lv_debug := 'UPDATE_STATUS_OF_HBG_PIM_PAM_RECORDS';
      BEGIN
         UPDATE hbg_pim_pam hpp
            SET hpp.status = CASE
           WHEN EXISTS (SELECT 1
                          FROM hbg_ego_item_intf_eff_b heiieb
                         WHERE heiieb.item_number = hpp.isbn13
                           AND heiieb.context_code IN ('BOM', 'Carton', 'Configuration', 'Content', 'Discount Group', 'Estimated Release'
                                                      ,'Family Code', 'General', 'Hot Title Indicator', 'Status and Release')) THEN
              'WARNING'
           ELSE
              'ERROR'
            END
         WHERE hpp.hbg_process_id = gv_hbg_process_id
           AND hpp.error_text IS NOT NULL;
      EXCEPTION
         WHEN OTHERS THEN
            log_p('ERROR'
                 ,'ERROR when updating status of HBG_PIM_PAM records - ' || SQLERRM);
            --
            lv_breakpoints := TRIM(lv_breakpoints || ' / ' || lv_debug);
            lv_error_msg := TRIM(lv_error_msg || ' ERROR when updating status of HBG_PIM_PAM records.');
      END;
      --
      COMMIT;

      IF lv_breakpoints IS NOT NULL THEN
         IF SUBSTR(lv_breakpoints, 1, 1) = '/' THEN
            lv_debug := TRIM(SUBSTR(lv_breakpoints, 2));
         ELSE
            lv_debug := lv_breakpoints;
         END IF;
         --
         RAISE_APPLICATION_ERROR(-20002, 'ERROR handling child records');
      END IF;

   EXCEPTION
      WHEN ge_custom_exception THEN
         log_p('ERROR'
              ,'ERROR at the step [' || lv_debug || '] of the [LOAD_FBDI_TABLES_P]. ' || lv_error_msg);
         RAISE;
      WHEN OTHERS THEN
         IF SQLCODE = -20002 THEN
            log_p('ERROR'
                 ,'ERROR at the step(s) [' || lv_debug || '] of the [LOAD_FBDI_TABLES_P]. ' || lv_error_msg);
         ELSE
            log_p('ERROR'
                 ,'GENERAL ERROR at the step [' || lv_debug || '] of the [LOAD_FBDI_TABLES_P] - ' || dbms_utility.format_error_backtrace);
         END IF;
         RAISE;
   END load_fbdi_tables_p;

   -- -----------------------------------------------------------------------------------------------------------------
   --  PROCEDURE: create_upload_fbdi_zip_file_p
   -- -----------------------------------------------------------------------------------------------------------------
   --
   --  Description: Procedure to create FBDI ZIP file (with CSVs) and transfer it to OIC SFTP
   --
   -- -----------------------------------------------------------------------------------------------------------------
   PROCEDURE create_upload_fbdi_zip_file_p IS

      -- Data for EgpSystemItemsInterface.csv
      CURSOR c_egp_system_items_interface IS
         SELECT /*+ index(HBG_EGP_SYSTEM_ITEMS_INTERFACE (ORGANIZATION_CODE)) */ *
           FROM hbg_egp_system_items_interface
          WHERE organization_code = 'ITEM_MASTER'
          UNION ALL
         SELECT /*+ index(HBG_EGP_SYSTEM_ITEMS_INTERFACE (ORGANIZATION_CODE)) */ *
           FROM hbg_egp_system_items_interface
          WHERE organization_code <> 'ITEM_MASTER';

      -- Data for EgpItemCategoriesInterface.csv
      CURSOR c_egp_item_categories_interface IS
         SELECT *
           FROM hbg_egp_item_categories_interface
          ORDER BY item_number
                  ,category_set_name;

      -- Data for EgoItemIntfEffb.csv
      CURSOR c_ego_item_intf_eff_b IS
         SELECT *
           FROM hbg_ego_item_intf_eff_b
          ORDER BY item_number
                  ,context_code;

      -- Type
      TYPE lt_ego_item_intf_eff_b_tb IS TABLE OF c_ego_item_intf_eff_b%ROWTYPE;
      TYPE lt_egp_item_categories_interface_tb IS TABLE OF c_egp_item_categories_interface%ROWTYPE;
      TYPE lt_egp_system_items_interface_tb IS TABLE OF c_egp_system_items_interface%ROWTYPE;

      lc_bulk_collect_limit CONSTANT PLS_INTEGER DEFAULT 10000;
      le_custom_exception EXCEPTION;
      lv_debug VARCHAR2(300);
      lv_ego_item_intf_eff_b_tb lt_ego_item_intf_eff_b_tb;
      lv_egp_item_categories_interface_tb lt_egp_item_categories_interface_tb;
      lv_egp_system_items_interface_tb lt_egp_system_items_interface_tb;
      lv_EgoItemIntfEffb_csv BLOB;
      lv_EgpItemCategoriesInterface_csv BLOB;
      lv_EgpSystemItemsInterface_csv BLOB;
      lv_error_msg VARCHAR2(32000);
      lv_file utl_file.file_type;
      lv_jobDetails_properties BLOB;
      lv_oic_ftp_folder VARCHAR2(50);
      lv_oic_ftp_host VARCHAR2(50);
      lv_oic_ftp_port NUMBER;
      lv_oic_ftp_user VARCHAR2(50);
      lv_zip_file BLOB;

   BEGIN
      -- Writing EgpSystemItemsInterface.csv
      lv_debug := 'WRITE_FILE_EgpSystemItemsInterface.csv_IN_HBG_CSV_IMPORT_DB_DIRECTORY';
      lv_file := utl_file.fopen(gv_db_directory, 'EgpSystemItemsInterface.csv', 'W', 32767);

      lv_debug := 'OPEN_CURSOR_C_EGP_SYSTEM_ITEMS_INTERFACE';
      OPEN c_egp_system_items_interface;
      LOOP
         FETCH c_egp_system_items_interface BULK COLLECT INTO lv_egp_system_items_interface_tb LIMIT lc_bulk_collect_limit;
         EXIT WHEN lv_egp_system_items_interface_tb.COUNT = 0;

         lv_debug := 'FOR_EACH_LINE_OF_CURSOR_C_EGP_SYSTEM_ITEMS_INTERFACE';
         FOR i IN lv_egp_system_items_interface_tb.first .. lv_egp_system_items_interface_tb.last LOOP
            utl_file.put_line(lv_file,
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).transaction_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).batch_id, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).batch_number, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).item_number, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).outside_process_service_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).organization_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).description, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).template_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).source_system_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).source_system_reference, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).source_system_reference_desc, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).item_catalog_group_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).primary_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).current_phase_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).inventory_item_status_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).new_item_class_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).asset_tracked_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).allow_maintenance_asset_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).enable_genealogy_tracking_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).asset_class, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).eam_item_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).eam_activity_type_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).eam_activity_cause_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).eam_act_notification_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).eam_act_shutdown_status, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).eam_activity_source_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).costing_enabled_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).std_lot_size, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).inventory_asset_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).default_include_in_rollup_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).order_cost, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).vmi_minimum_days, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).vmi_fixed_order_quantity, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).vmi_minimum_units, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).asn_autoexpire_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).carrying_cost, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).consigned_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).fixed_days_supply, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).fixed_lot_multiplier, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).fixed_order_quantity, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).forecast_horizon, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).inventory_planning_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).safety_stock_planning_method, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).demand_period, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).days_of_cover, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).min_minmax_quantity, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).max_minmax_quantity, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).minimum_order_quantity, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).maximum_order_quantity, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).planner_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).planning_make_buy_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).source_subinventory, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).source_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).so_authorization_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).subcontracting_component, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).vmi_forecast_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).vmi_maximum_units, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).vmi_maximum_days, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).source_organization_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).restrict_subinventories_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).restrict_locators_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).child_lot_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).child_lot_prefix, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).child_lot_starting_number, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).child_lot_validation_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).copy_lot_attribute_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).expiration_action_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).expiration_action_interval, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).stock_enabled_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).start_auto_lot_number, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).shelf_life_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).shelf_life_days, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).serial_number_control_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).serial_status_enabled, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).revision_qty_control_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).retest_interval, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).auto_lot_alpha_prefix, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).auto_serial_alpha_prefix, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).bulk_picked_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).check_shortages_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).cycle_count_enabled_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).default_grade, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).grade_control_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).hold_days, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).lot_divisible_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).maturity_days, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).default_lot_status_id, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).default_serial_status_id, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).lot_split_enabled, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).lot_merge_enabled, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).inventory_item_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).location_control_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).lot_control_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).lot_status_enabled, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).lot_substitution_enabled, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).lot_translate_enabled, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).mtl_transactions_enabled_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).positive_measurement_error, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).negative_measurement_error, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).parent_child_generation_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).reservable_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).start_auto_serial_number, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).invoicing_rule_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).tax_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).sales_account, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).payment_terms_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).invoice_enabled_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).invoiceable_item_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).accounting_rule_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).auto_created_config_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).replenish_to_order_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).pick_components_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).base_item_number, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).effectivity_control, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).config_orgs, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).config_match, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).config_model_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).bom_item_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).cum_manufacturing_lead_time, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).preprocessing_lead_time, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).cumulative_total_lead_time, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).fixed_lead_time, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).variable_lead_time, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).full_lead_time, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).lead_time_lot_size, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).postprocessing_lead_time, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).ato_forecast_control, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).critical_component_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).acceptable_early_days, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).create_supply_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).days_tgt_inv_supply, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).days_tgt_inv_window, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).days_max_inv_supply, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).days_max_inv_window, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).demand_time_fence_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).demand_time_fence_days, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).drp_planned_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).end_assembly_pegging_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).exclude_from_budget_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).mrp_calculate_atp_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).mrp_planning_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).planned_inv_point_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).planning_time_fence_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).planning_time_fence_days, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).preposition_point, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).release_time_fence_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).release_time_fence_days, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).repair_leadtime, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).repair_yield, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).repair_program, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).rounding_control_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).shrinkage_rate, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).substitution_window_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).substitution_window_days, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).trade_item_descriptor, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).allowed_units_lookup_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).dual_uom_deviation_high, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).dual_uom_deviation_low, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).item_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).long_description, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).html_long_description, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).ont_pricing_qty_source, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).secondary_default_ind, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).secondary_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).tracking_quantity_ind, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).engineered_item_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).atp_components_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).atp_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).over_shipment_tolerance, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).under_shipment_tolerance, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).over_return_tolerance, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).under_return_tolerance, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).downloadable_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).electronic_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).indivisible_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).internal_order_enabled_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).atp_rule_id, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).charge_periodicity_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).customer_order_enabled_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).default_shipping_org_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).default_so_source_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).eligibility_compatibility_rule, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).financing_allowed_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).internal_order_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).picking_rule_id, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).returnable_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).return_inspection_requirement, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).sales_product_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).back_to_back_enabled, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).shippable_item_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).ship_model_complete_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).so_transactions_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).customer_order_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).unit_weight, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).weight_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).unit_volume, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).volume_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).dimension_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).unit_length, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).unit_width, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).unit_height, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).collateral_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).container_item_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).container_type_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).equipment_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).event_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).internal_volume, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).maximum_load_weight, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).minimum_fill_percent, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).vehicle_item_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).cas_number, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).hazardous_material_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).process_costing_enabled_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).process_execution_enabled_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).process_quality_enabled_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).process_supply_locator_id, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).process_supply_subinventory, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).process_yield_locator_id, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).process_yield_subinventory, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).recipe_enabled_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).expense_account, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).un_number_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).unit_of_issue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).rounding_factor, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).receive_close_tolerance, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).purchasing_tax_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).purchasing_item_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).price_tolerance_percent, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).outsourced_assembly, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).outside_operation_uom_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).negotiation_required_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).must_use_approved_vendor_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).match_approval_level, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).invoice_match_option, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).list_price_per_unit, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).invoice_close_tolerance, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).hazard_class_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).buyer_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).taxable_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).purchasing_enabled_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).outside_operation_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).market_price, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).asset_category_id, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).allow_item_desc_update_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).allow_express_delivery_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).allow_substitute_receipts_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).allow_unordered_receipts_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).days_early_receipt_allowed, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).days_late_receipt_allowed, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).receiving_routing_id, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).enforce_ship_to_location_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).qty_rcv_exception_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).qty_rcv_tolerance, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).receipt_days_exception_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).asset_creation_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).service_start_type_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).comms_nl_trackable_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).css_enabled_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).contract_item_type_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).standard_coverage, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).defect_tracking_on_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).ib_item_instance_class, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).material_billable_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).recovered_part_disp_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).serviceable_product_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).service_starting_delay, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).service_duration, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).service_duration_period_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).serv_req_enabled_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).allow_suspend_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).allow_terminate_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).requires_fulfillment_loc_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).requires_itm_association_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).service_start_delay, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).service_duration_type_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).comms_activation_reqd_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).serv_billing_enabled_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).orderable_on_web_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).back_orderable_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).web_status, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).minimum_license_quantity, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).build_in_wip_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).contract_manufacturing, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).wip_supply_locator_id, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).wip_supply_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).wip_supply_subinventory, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).overcompletion_tolerance_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).overcompletion_tolerance_value, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).inventory_carry_penalty, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).operation_slack_penalty, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).revision, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).style_item_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).style_item_number, '"', '""') || '",' ||
                              '"' || TO_CHAR(lv_egp_system_items_interface_tb(i).version_start_date, 'YYYY/MM/DD') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).version_revision_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).version_label, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).start_upon_milestone_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).sales_product_sub_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute_category, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute1, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute2, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute3, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute4, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute5, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute6, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute7, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute8, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute9, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute10, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute_category, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute1, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute2, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute3, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute4, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute5, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute6, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute7, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute8, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute9, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute10, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute11, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute12, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute13, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute14, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute15, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute16, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute17, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute18, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute19, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute20, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute21, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute22, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute23, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute24, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute25, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute26, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute27, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute28, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute29, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute30, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute_number1, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute_number2, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute_number3, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute_number4, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute_number5, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute_number6, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute_number7, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute_number8, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute_number9, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute_number10, '"', '""') || '",' ||
                              '"' || TO_CHAR(lv_egp_system_items_interface_tb(i).attribute_date1, 'YYYY/MM/DD') || '",' ||
                              '"' || TO_CHAR(lv_egp_system_items_interface_tb(i).attribute_date2, 'YYYY/MM/DD') || '",' ||
                              '"' || TO_CHAR(lv_egp_system_items_interface_tb(i).attribute_date3, 'YYYY/MM/DD') || '",' ||
                              '"' || TO_CHAR(lv_egp_system_items_interface_tb(i).attribute_date4, 'YYYY/MM/DD') || '",' ||
                              '"' || TO_CHAR(lv_egp_system_items_interface_tb(i).attribute_date5, 'YYYY/MM/DD') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute_timestamp1, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute_timestamp2, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute_timestamp3, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute_timestamp4, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).attribute_timestamp5, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute11, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute12, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute13, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute14, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute15, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute16, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute17, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute18, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute19, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute20, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute_number1, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute_number2, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute_number3, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute_number4, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).global_attribute_number5, '"', '""') || '",' ||
                              '"' || TO_CHAR(lv_egp_system_items_interface_tb(i).global_attribute_date1, 'YYYY/MM/DD') || '",' ||
                              '"' || TO_CHAR(lv_egp_system_items_interface_tb(i).global_attribute_date2, 'YYYY/MM/DD') || '",' ||
                              '"' || TO_CHAR(lv_egp_system_items_interface_tb(i).global_attribute_date3, 'YYYY/MM/DD') || '",' ||
                              '"' || TO_CHAR(lv_egp_system_items_interface_tb(i).global_attribute_date4, 'YYYY/MM/DD') || '",' ||
                              '"' || TO_CHAR(lv_egp_system_items_interface_tb(i).global_attribute_date5, 'YYYY/MM/DD') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).prc_bu_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).force_purchase_lead_time_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).replacement_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).buyer_email_address, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).default_expenditure_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).hard_pegging_level, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).comn_supply_prj_demand_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).enable_iot_flag, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).packaging_string, '"', '""') || '",' ||
                              '"' || TO_CHAR(lv_egp_system_items_interface_tb(i).create_supply_after_date, 'YYYY/MM/DD') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).create_fixed_asset, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).under_compl_tolerance_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).under_compl_tolerance_value, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_system_items_interface_tb(i).repair_transaction_name, '"', '""') || '"'
                              );
         END LOOP;
      END LOOP;
      CLOSE c_egp_system_items_interface;

      lv_debug := 'CLOSE_FILE_EgpSystemItemsInterface.csv';
      utl_file.fclose(lv_file);

      lv_debug := 'CONVERT_TO_BLOB_EgpSystemItemsInterface.csv';
      lv_EgpSystemItemsInterface_csv := file_to_blob_f('EgpSystemItemsInterface.csv');

      lv_debug := 'ADD_EgpSystemItemsInterface.csv_INTO_ZIP';
      apex_zip.add_file(lv_zip_file
                       ,'EgpSystemItemsInterface.csv'
                       ,lv_EgpSystemItemsInterface_csv);

      -- Writing EgpItemCategoriesInterface.csv
      lv_debug := 'WRITE_FILE_EgpItemCategoriesInterface.csv_IN_HBG_CSV_IMPORT_DB_DIRECTORY';
      lv_file := utl_file.fopen(gv_db_directory
                               ,'EgpItemCategoriesInterface.csv'
                               ,'W');

      lv_debug := 'OPEN_CURSOR_C_EGP_ITEM_CATEGORIES_INTERFACE';
      OPEN c_egp_item_categories_interface;
      LOOP
         FETCH c_egp_item_categories_interface BULK COLLECT INTO lv_egp_item_categories_interface_tb LIMIT lc_bulk_collect_limit;
         EXIT WHEN lv_egp_item_categories_interface_tb.COUNT = 0;

         lv_debug := 'FOR_EACH_LINE_OF_CURSOR_C_EGP_ITEM_CATEGORIES_INTERFACE';
         FOR i IN lv_egp_item_categories_interface_tb.first .. lv_egp_item_categories_interface_tb.last LOOP
            utl_file.put_line(lv_file,
                              '"' || REPLACE(lv_egp_item_categories_interface_tb(i).transaction_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_item_categories_interface_tb(i).batch_id, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_item_categories_interface_tb(i).batch_number, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_item_categories_interface_tb(i).item_number, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_item_categories_interface_tb(i).organization_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_item_categories_interface_tb(i).category_set_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_item_categories_interface_tb(i).category_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_item_categories_interface_tb(i).category_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_item_categories_interface_tb(i).old_category_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_item_categories_interface_tb(i).old_category_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_item_categories_interface_tb(i).source_system_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_egp_item_categories_interface_tb(i).source_system_reference, '"', '""') || '",' ||
                              '"' || TO_CHAR(lv_egp_item_categories_interface_tb(i).start_date, 'YYYY/MM/DD') || '",' ||
                              '"' || TO_CHAR(lv_egp_item_categories_interface_tb(i).end_date, 'YYYY/MM/DD') || '"'
                             );
         END LOOP;
      END LOOP;
      CLOSE c_egp_item_categories_interface;

      lv_debug := 'CLOSE_FILE_EgpItemCategoriesInterface.csv';
      utl_file.fclose(lv_file);

      lv_debug := 'CONVERT_TO_BLOB_EgpItemCategoriesInterface.csv';
      lv_EgpItemCategoriesInterface_csv := file_to_blob_f('EgpItemCategoriesInterface.csv');

      lv_debug := 'ADD_EgpItemCategoriesInterface.csv_INTO_ZIP';
      apex_zip.add_file(lv_zip_file
                       ,'EgpItemCategoriesInterface.csv'
                       ,lv_EgpItemCategoriesInterface_csv);

      -- Writing EgoItemIntfEffb.csv
      lv_debug := 'WRITE_FILE_EgoItemIntfEffb.csv_IN_HBG_CSV_IMPORT_DB_DIRECTORY';
      lv_file := utl_file.fopen(gv_db_directory
                               ,'EgoItemIntfEffb.csv'
                               ,'W');

      lv_debug := 'OPEN_CURSOR_C_EGO_ITEM_INTF_EFF_B';
      OPEN c_ego_item_intf_eff_b;
      LOOP
         FETCH c_ego_item_intf_eff_b BULK COLLECT INTO lv_ego_item_intf_eff_b_tb LIMIT lc_bulk_collect_limit;
         EXIT WHEN lv_ego_item_intf_eff_b_tb.COUNT = 0;

         lv_debug := 'FOR_EACH_LINE_OF_CURSOR_C_EGO_ITEM_INTF_EFF_B';
         FOR i IN lv_ego_item_intf_eff_b_tb.first .. lv_ego_item_intf_eff_b_tb.last LOOP
            utl_file.put_line(lv_file,
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).transaction_type, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).batch_id, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).batch_number, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).item_number, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).organization_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).source_system_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).source_system_reference, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).context_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char1, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char2, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char3, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char4, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char5, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char6, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char7, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char8, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char9, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char10, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char11, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char12, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char13, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char14, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char15, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char16, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char17, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char18, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char19, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char20, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number1, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number2, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number3, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number4, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number5, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number6, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number7, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number8, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number9, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number10, '"', '""') || '",' ||
                              '"' || TO_CHAR(lv_ego_item_intf_eff_b_tb(i).attribute_date1, 'YYYY/MM/DD') || '",' ||
                              '"' || TO_CHAR(lv_ego_item_intf_eff_b_tb(i).attribute_date2, 'YYYY/MM/DD') || '",' ||
                              '"' || TO_CHAR(lv_ego_item_intf_eff_b_tb(i).attribute_date3, 'YYYY/MM/DD') || '",' ||
                              '"' || TO_CHAR(lv_ego_item_intf_eff_b_tb(i).attribute_date4, 'YYYY/MM/DD') || '",' ||
                              '"' || TO_CHAR(lv_ego_item_intf_eff_b_tb(i).attribute_date5, 'YYYY/MM/DD') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char21, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char22, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char23, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char24, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char25, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char26, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char27, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char28, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char29, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char30, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char31, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char32, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char33, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char34, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char35, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char36, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char37, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char38, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char39, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_char40, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number11, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number12, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number13, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number14, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number15, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number16, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number17, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number18, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number19, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number20, '"', '""') || '",' ||
                              '"' || TO_CHAR(lv_ego_item_intf_eff_b_tb(i).attribute_date6, 'YYYY/MM/DD') || '",' ||
                              '"' || TO_CHAR(lv_ego_item_intf_eff_b_tb(i).attribute_date7, 'YYYY/MM/DD') || '",' ||
                              '"' || TO_CHAR(lv_ego_item_intf_eff_b_tb(i).attribute_date8, 'YYYY/MM/DD') || '",' ||
                              '"' || TO_CHAR(lv_ego_item_intf_eff_b_tb(i).attribute_date9, 'YYYY/MM/DD') || '",' ||
                              '"' || TO_CHAR(lv_ego_item_intf_eff_b_tb(i).attribute_date10, 'YYYY/MM/DD') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_timestamp1, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_timestamp2, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_timestamp3, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_timestamp4, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_timestamp5, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_timestamp6, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_timestamp7, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_timestamp8, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_timestamp9, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_timestamp10, '"', '""') || '",' ||
                              '"' || TO_CHAR(lv_ego_item_intf_eff_b_tb(i).version_start_date, 'YYYY/MM/DD') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).version_revision_code, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number1_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number2_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number3_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number4_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number5_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number6_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number7_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number8_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number9_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number10_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number11_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number12_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number13_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number14_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number15_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number16_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number17_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number18_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number19_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number20_uom_name, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number1_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number2_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number3_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number4_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number5_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number6_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number7_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number8_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number9_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number10_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number11_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number12_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number13_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number14_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number15_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number16_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number17_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number18_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number19_ue, '"', '""') || '",' ||
                              '"' || REPLACE(lv_ego_item_intf_eff_b_tb(i).attribute_number20_ue, '"', '""') || '"'
                             );
         END LOOP;
      END LOOP;
      CLOSE c_ego_item_intf_eff_b;

      lv_debug := 'CLOSE_FILE_EgoItemIntfEffb.csv';
      utl_file.fclose(lv_file);

      lv_debug := 'CONVERT_TO_BLOB_EgoItemIntfEffb.csv';
      lv_EgoItemIntfEffb_csv := file_to_blob_f('EgoItemIntfEffb.csv');

      lv_debug := 'ADD_EgoItemIntfEffb.csv_INTO_ZIP';
      apex_zip.add_file(lv_zip_file
                       ,'EgoItemIntfEffb.csv'
                       ,lv_EgoItemIntfEffb_csv);

      -- Writing jobDetails.properties
      lv_debug := 'WRITE_FILE_jobDetails.properties_IN_HBG_CSV_IMPORT_DB_DIRECTORY';
      lv_file := utl_file.fopen(gv_db_directory
                               ,'jobDetails.properties'
                               ,'W');

      lv_debug := 'WRITE_A_LINE_IN_FILE_jobDetails.properties';
      -- Write job details in the file
      utl_file.put_line(lv_file,
                       '/oracle/apps/ess/scm/productModel/items,ItemImportJobDef,HBG_PIM_Items_' || TO_CHAR(gv_hbg_process_id)
                       || '.zip,' || TO_CHAR(gv_hbg_process_id));

      lv_debug := 'CLOSE_FILE_jobDetails.properties';
      utl_file.fclose(lv_file);

      lv_debug := 'CONVERT_TO_BLOB_jobDetails.properties';
      lv_jobDetails_properties := file_to_blob_f('jobDetails.properties');

      lv_debug := 'ADD_jobDetails.properties_INTO_ZIP';
      apex_zip.add_file(lv_zip_file
                       ,'jobDetails.properties'
                       ,lv_jobDetails_properties);

      -- Finish ZIP file
      lv_debug := 'FINISH_ZIP';
      apex_zip.finish(lv_zip_file);

      -- Get OIC FTP parameters
      lv_debug := 'GET_PARAMETER_OIC_FTP_HOST';
      BEGIN
         SELECT hpip.param_char1
           INTO lv_oic_ftp_host
           FROM hbg_pim_int_parameters hpip
          WHERE hpip.parameter_name = 'OIC_FTP_HOST';
      EXCEPTION
         WHEN OTHERS THEN
            lv_error_msg := SQLERRM;
            RAISE le_custom_exception;
      END;

      lv_debug := 'GET_PARAMETER_OIC_FTP_PORT';
      BEGIN
         SELECT hpip.param_number1
           INTO lv_oic_ftp_port
           FROM hbg_pim_int_parameters hpip
          WHERE hpip.parameter_name = 'OIC_FTP_PORT';
      EXCEPTION
         WHEN OTHERS THEN
            lv_error_msg := SQLERRM;
            RAISE le_custom_exception;
      END;

      lv_debug := 'GET_PARAMETER_OIC_FTP_USERNAME';
      BEGIN
         SELECT hpip.param_char1
           INTO lv_oic_ftp_user
           FROM hbg_pim_int_parameters hpip
          WHERE hpip.parameter_name = 'OIC_FTP_USERNAME';
      EXCEPTION
         WHEN OTHERS THEN
            lv_error_msg := SQLERRM;
            RAISE le_custom_exception;
      END;

      lv_debug := 'GET_PARAMETER_OIC_FTP_FOLDER';
      BEGIN
         SELECT hpip.param_char1
           INTO lv_oic_ftp_folder
           FROM hbg_pim_int_parameters hpip
          WHERE hpip.parameter_name = 'OIC_FTP_FOLDER';
      EXCEPTION
         WHEN OTHERS THEN
            lv_error_msg := SQLERRM;
            RAISE le_custom_exception;
      END;

      -- Transfer ZIP file to OIC FTP
      BEGIN
         lv_debug := 'TRANSFER_ZIP_FILE_TO_OIC_FTP_LOGIN';
         as_sftp_keymgmt.login(lv_oic_ftp_user
                              ,lv_oic_ftp_host
                              ,lv_oic_ftp_port
                              ,TRUE);

         lv_debug := 'TRANSFER_ZIP_FILE_TO_OIC_FTP_PUT_FILE';         
         as_sftp.put_file(lv_oic_ftp_folder || '/HBG_PIM_Items_' || TO_CHAR(gv_hbg_process_id) || '.zip'
                         ,lv_zip_file);

      EXCEPTION
         WHEN OTHERS THEN
            lv_error_msg := SQLERRM;
            RAISE le_custom_exception;
      END;

   EXCEPTION
      WHEN le_custom_exception THEN
         log_p('ERROR'
              ,'ERROR at the step [' || lv_debug || '] of the [CREATE_UPLOAD_FBDI_ZIP_FILE_P]. '
               || lv_error_msg);
      WHEN OTHERS THEN
         utl_file.fclose_all;
         log_p('ERROR'
              ,'GENERAL ERROR at the step [' || lv_debug || '] of the [CREATE_UPLOAD_FBDI_ZIP_FILE_P]. '
               || dbms_utility.format_error_backtrace);
   END create_upload_fbdi_zip_file_p;

   -- -----------------------------------------------------------------------------------------------------------------
   --  PROCEDURE: main_p
   -- -----------------------------------------------------------------------------------------------------------------
   --
   --  Parameters: p_hbg_process_id - HBG Process ID
   --              p_oic_instance_id - OIC Instance ID
   --              p_control_id_step_0 - Control ID of the step 0 in control table [HBG_INTEGRATION_CONTROL]
   --
   --  Description: main procedure of the integration process. It is responsible for running all subprocesses to
   --               generate a ZIP FBDI file ready to be loaded into Oracle ERP Cloud.
   --
   -- -----------------------------------------------------------------------------------------------------------------
   PROCEDURE main_p(p_hbg_process_id    IN NUMBER
                   ,p_oic_instance_id   IN NUMBER
                   ,p_control_id_step_0 IN NUMBER) IS

      lv_control_id NUMBER;
      lv_debug VARCHAR2(300);
      lv_error_msg VARCHAR2(32000);

   BEGIN
      -- Populate global variables
      gv_hbg_process_id := p_hbg_process_id;
      gv_oic_instance_id := p_oic_instance_id;

      BEGIN
         -- Step 1: Copy data from staging tables to process tables
         lv_debug := 'COPY_DATA_FROM_STAGING_TABLES_TO_PROCESS_TABLES';
         BEGIN
            -- Insert record into control table
            BEGIN
               lv_control_id := hbg_integration_control_seq.NEXTVAL;
               --
               INSERT INTO hbg_integration_control
                  (control_id
                  ,hbg_process_id
                  ,oic_instance_id
                  ,interface_name
                  ,step_name
                  ,step_number
                  ,status
                  ,start_date)
               VALUES
                  (lv_control_id
                  ,gv_hbg_process_id
                  ,gv_oic_instance_id
                  ,gv_interface_name
                  ,lv_debug
                  ,1
                  ,'IN PROGRESS'
                  ,CURRENT_DATE);
               --
               COMMIT;
            EXCEPTION
               WHEN OTHERS THEN
                  lv_error_msg := 'ERROR when inserting record into [HBG_INTEGRATION_CONTROL] - ' || SQLERRM;
                  RAISE ge_custom_exception;
            END;

            -- Call 'Load Process tables' subprocess
            BEGIN
               load_process_tables_p;
            EXCEPTION
               WHEN OTHERS THEN
                  lv_error_msg := 'ERROR when running [LOAD_PROCESS_TABLES_P] - ' || SQLERRM;
                  RAISE ge_custom_exception;
            END;

            -- Update control table
            BEGIN
               UPDATE hbg_integration_control
                  SET status = 'SUCCESS'
                     ,end_date = CURRENT_DATE
                WHERE control_id = lv_control_id;
               --
               COMMIT;
            EXCEPTION
               WHEN OTHERS THEN
                  ROLLBACK;
                  log_p('ERROR'
                       ,'ERROR when updating control table at the step [' || lv_debug || ']. ' || SQLERRM);
            END;
         END;

         -- Step 2: Validate data in process tables
         BEGIN
            lv_debug := 'VALIDATE_DATA';
            -- Insert record into control table
            BEGIN
               lv_control_id := hbg_integration_control_seq.NEXTVAL;
               --
               INSERT INTO hbg_integration_control
                  (control_id
                  ,hbg_process_id
                  ,oic_instance_id
                  ,interface_name
                  ,step_name
                  ,step_number
                  ,status
                  ,start_date)
               VALUES
                  (lv_control_id
                  ,gv_hbg_process_id
                  ,gv_oic_instance_id
                  ,gv_interface_name
                  ,lv_debug
                  ,2
                  ,'IN PROGRESS'
                  ,CURRENT_DATE);
               --
               COMMIT;
            EXCEPTION
               WHEN OTHERS THEN
                  lv_error_msg := 'ERROR when inserting record into [HBG_INTEGRATION_CONTROL] - ' || SQLERRM;
                  RAISE ge_custom_exception;
            END;

            -- Call Validation subprocess
            BEGIN
               validate_data_p;

               -- Update control table
               BEGIN
                  UPDATE hbg_integration_control
                     SET status = 'SUCCESS'
                        ,end_date = CURRENT_DATE
                   WHERE control_id = lv_control_id;
                  --
                  COMMIT;
               EXCEPTION
                  WHEN OTHERS THEN
                     ROLLBACK;
                     log_p('ERROR'
                          ,'ERROR when updating control table to SUCCESS at the step [' || lv_debug || ']. ' || SQLERRM);
               END;
            EXCEPTION
               WHEN OTHERS THEN
                  -- Update control table
                  BEGIN
                     UPDATE hbg_integration_control
                        SET status = 'ERROR'
                           ,end_date = CURRENT_DATE
                      WHERE control_id = lv_control_id;
                     --
                     COMMIT;
                  EXCEPTION
                     WHEN OTHERS THEN
                        ROLLBACK;
                        log_p('ERROR'
                             ,'ERROR when updating control table to ERROR at the step [' || lv_debug || ']. ' || SQLERRM);
                  END;
            END;
         END;

         -- Step 3: Load FBDI tables
         BEGIN
            lv_debug := 'LOAD_FBDI_TABLES';
            -- Insert record into control table
            BEGIN
               lv_control_id := hbg_integration_control_seq.NEXTVAL;
               --
               INSERT INTO hbg_integration_control
                  (control_id
                  ,hbg_process_id
                  ,oic_instance_id
                  ,interface_name
                  ,step_name
                  ,step_number
                  ,status
                  ,start_date)
               VALUES
                  (lv_control_id
                  ,gv_hbg_process_id
                  ,gv_oic_instance_id
                  ,gv_interface_name
                  ,lv_debug
                  ,3
                  ,'IN PROGRESS'
                  ,CURRENT_DATE);
               --
               COMMIT;
            EXCEPTION
               WHEN OTHERS THEN
                  lv_error_msg := 'ERROR when inserting record into [HBG_INTEGRATION_CONTROL] - ' || SQLERRM;
                  RAISE ge_custom_exception;
            END;

            -- Call 'Load FBDI tables' subprocess
            BEGIN
               load_fbdi_tables_p;
            EXCEPTION
               WHEN OTHERS THEN
                  lv_error_msg := 'ERROR when running [LOAD_FBDI_TABLES_P] - ' || SQLERRM;
                  RAISE ge_custom_exception;
            END;

            -- Update control table
            BEGIN
               UPDATE hbg_integration_control
                  SET status = 'SUCCESS'
                     ,end_date = CURRENT_DATE
                WHERE control_id = lv_control_id;
               --
               COMMIT;
            EXCEPTION
               WHEN OTHERS THEN
                  ROLLBACK;
                  log_p('ERROR'
                       ,'ERROR when updating control table at the step [' || lv_debug || ']. ' || SQLERRM);
            END;
         END;

         -- Step 4: Create and Upload FBDI ZIP file to OIC FTP
         BEGIN
            lv_debug := 'CREATE_AND_UPLOAD_FBDI_ZIP_FILE_TO_OIC_FTP';
            -- Insert record into control table
            BEGIN
               lv_control_id := hbg_integration_control_seq.NEXTVAL;
               --
               INSERT INTO hbg_integration_control
                  (control_id
                  ,hbg_process_id
                  ,oic_instance_id
                  ,interface_name
                  ,step_name
                  ,step_number
                  ,status
                  ,start_date)
               VALUES
                  (lv_control_id
                  ,gv_hbg_process_id
                  ,gv_oic_instance_id
                  ,gv_interface_name
                  ,lv_debug
                  ,4
                  ,'IN PROGRESS'
                  ,CURRENT_DATE);
               --
               COMMIT;
            EXCEPTION
               WHEN OTHERS THEN
                  lv_error_msg := 'ERROR when inserting record into [HBG_INTEGRATION_CONTROL] - ' || SQLERRM;
                  RAISE ge_custom_exception;
            END;

            -- Call Create and Upload FBDI File to OIC FTP subprocess
            BEGIN
               create_upload_fbdi_zip_file_p;
            EXCEPTION
               WHEN OTHERS THEN
                  lv_error_msg := 'ERROR when running [CREATE_UPLOAD_FBDI_ZIP_FILE_P] - ' || SQLERRM;
                  RAISE ge_custom_exception;
            END;

            -- Update control table
            BEGIN
               UPDATE hbg_integration_control
                  SET status = 'SUCCESS'
                     ,end_date = CURRENT_DATE
                WHERE control_id = lv_control_id;
               --
               COMMIT;
            EXCEPTION
               WHEN OTHERS THEN
                  log_p('ERROR'
                       ,'ERROR when updating control table at the step [' || lv_debug || ']. ' || SQLERRM);
            END;
         END;

      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            -- Update control table
            BEGIN
               UPDATE hbg_integration_control
                  SET status = 'ERROR'
                     ,end_date = CURRENT_DATE
                WHERE control_id = lv_control_id;
               --
               COMMIT;
            EXCEPTION
               WHEN OTHERS THEN
                  ROLLBACK;
                  log_p('ERROR'
                       ,'ERROR when updating control table at the step [' || lv_debug || ']. ' || SQLERRM);
            END;
            --
            RAISE ge_custom_exception;
      END;

      -- Step 0.1: Update the status of the step 0 to SUCCESS
      lv_debug := 'UPDATE_STEP_0_TO_SUCCESS';
      BEGIN
         UPDATE hbg_integration_control
            SET status = 'SUCCESS'
               ,end_date = CURRENT_DATE
          WHERE control_id = p_control_id_step_0;
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            lv_error_msg := 'ERROR when updating control table at the step [' || lv_debug || ']. ' || SQLERRM;
            RAISE ge_custom_exception;
      END;

      -- Step 5: OIC downloads and submits FBDI file to ERP Cloud
      lv_debug := 'OIC_DOWNLOADS_AND_SUBMITS_FBDI_FILE_TO_ORACLE_ERP_CLOUD';
      BEGIN
         lv_control_id := hbg_integration_control_seq.NEXTVAL;
         --
         INSERT INTO hbg_integration_control
            (control_id
            ,hbg_process_id
            ,oic_instance_id
            ,interface_name
            ,step_name
            ,step_number
            ,status
            ,start_date)
         VALUES
            (lv_control_id
            ,gv_hbg_process_id
            ,gv_oic_instance_id
            ,gv_interface_name
            ,lv_debug
            ,5
            ,'IN PROGRESS'
            ,CURRENT_DATE);
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            lv_error_msg := 'ERROR when inserting record for step [' || lv_debug || '] into [HBG_INTEGRATION_CONTROL] - '
                            || SQLERRM;
            RAISE ge_custom_exception;
      END;

      -- Step 6: Callback to update status in FBDI tables
      lv_debug := 'CALLBACK_TO_PROCESS_RETURNING_INFO';
      BEGIN
         lv_control_id := hbg_integration_control_seq.NEXTVAL;
         --
         INSERT INTO hbg_integration_control
            (control_id
            ,hbg_process_id
            ,oic_instance_id
            ,interface_name
            ,step_name
            ,step_number
            ,status)
         VALUES
            (lv_control_id
            ,gv_hbg_process_id
            ,NULL
            ,gv_interface_name
            ,lv_debug
            ,6
            ,'NOT STARTED');
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            lv_error_msg := 'ERROR when inserting record for step [' || lv_debug || '] into [HBG_INTEGRATION_CONTROL] - '
                            || SQLERRM;
            RAISE ge_custom_exception;
      END;

      -- Step 7: Update status in process tables
      lv_debug := 'UPDATE_STATUS_IN_PROCESS_TABLES';
      BEGIN
         lv_control_id := hbg_integration_control_seq.NEXTVAL;
         --
         INSERT INTO hbg_integration_control
            (control_id
            ,hbg_process_id
            ,oic_instance_id
            ,interface_name
            ,step_name
            ,step_number
            ,status)
         VALUES
            (lv_control_id
            ,gv_hbg_process_id
            ,NULL
            ,gv_interface_name
            ,lv_debug
            ,7
            ,'NOT STARTED');
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            lv_error_msg := 'ERROR when inserting record for step [' || lv_debug || '] into [HBG_INTEGRATION_CONTROL] - '
                            || SQLERRM;
            RAISE ge_custom_exception;
      END;

   EXCEPTION
      WHEN ge_custom_exception THEN
         BEGIN
            UPDATE hbg_integration_control
               SET status = 'ERROR'
                  ,end_date = CURRENT_DATE
             WHERE control_id = p_control_id_step_0;
            --
            COMMIT;
         EXCEPTION
            WHEN OTHERS THEN
               ROLLBACK;
               log_p('ERROR'
                    ,'ERROR when updating status to ERROR of step 0 in control table [GE_CUSTOM_EXCEPTION]. ' || SQLERRM);
         END;
         --
         log_p('ERROR'
              ,'ERROR at the step [' || lv_debug || '] of the [MAIN_P]. ' || lv_error_msg);
         raise_application_error(-20001,'ERROR occured in [HBG_PIM_INTEGRATION_PKG.MAIN_P]. Check logs for details.');

      WHEN OTHERS THEN
         BEGIN
            UPDATE hbg_integration_control
               SET status = 'ERROR'
                  ,end_date = CURRENT_DATE
             WHERE control_id = p_control_id_step_0;
            --
            COMMIT;
         EXCEPTION
            WHEN OTHERS THEN
               ROLLBACK;
               log_p('ERROR'
                    ,'ERROR when updating status to ERROR of step 0 in control table. ' || SQLERRM);
         END;
         --
         log_p('ERROR'
              ,'GENERAL ERROR at the step [' || lv_debug || '] of the program. ' || dbms_utility.format_error_backtrace);
         raise_application_error(-20001,'ERROR occured in [HBG_PIM_INTEGRATION_PKG.MAIN_P]. Check logs for details.');
   END main_p;

   -- -----------------------------------------------------------------------------------------------------------------
   --  PROCEDURE: submit_main_p
   -- -----------------------------------------------------------------------------------------------------------------
   --
   --  Parameters: p_hbg_process_id - HBG Process ID
   --              p_oic_instance_id - OIC Instance ID
   --
   --  Description: procedure responsible for creating a JOB to run the procedure [main_p]
   --
   -- -----------------------------------------------------------------------------------------------------------------
   PROCEDURE submit_main_p(p_hbg_process_id  IN NUMBER
                          ,p_oic_instance_id IN NUMBER) IS

      lv_control_id_step_0 NUMBER;
      lv_debug VARCHAR2(300);
      lv_error_msg VARCHAR2(32000);

   BEGIN
      gv_hbg_process_id := p_hbg_process_id;
      gv_oic_instance_id := p_oic_instance_id;
      
      lv_debug := 'INITIALIZE_INTEGRATION_IN_CONTROL_TABLE';
      BEGIN
         lv_control_id_step_0 := hbg_integration_control_seq.NEXTVAL;
         --
         INSERT INTO hbg_integration_control
            (control_id
            ,hbg_process_id
            ,oic_instance_id
            ,interface_name
            ,step_name
            ,step_number
            ,status
            ,start_date)
         VALUES
            (lv_control_id_step_0
            ,gv_hbg_process_id
            ,gv_oic_instance_id
            ,gv_interface_name
            ,lv_debug
            ,0
            ,'IN PROGRESS'
            ,CURRENT_DATE);
         --
         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            lv_error_msg := 'ERROR when inserting record for step [' || lv_debug || '] into [HBG_INTEGRATION_CONTROL] - '
                            || SQLERRM;
            RAISE ge_custom_exception;
      END;

      lv_debug := 'SUBMIT_JOB_TO_CALL_MAIN_P';
      dbms_scheduler.create_job(job_name   => 'HBG_LOAD_ITEMS_INFO_INTO_ORACLE_PIM_' || TO_CHAR(gv_hbg_process_id)
                               ,job_type   => 'PLSQL_BLOCK'
                               ,job_action => 'BEGIN
                                                  HBG_PIM_INTEGRATION_PKG.MAIN_P(' || gv_hbg_process_id
                                               || ',' || gv_oic_instance_id || ',' || lv_control_id_step_0 || '); END;'
                               ,enabled    => TRUE
                               ,auto_drop  => TRUE
                               ,comments   => 'HBG Load Items Information into Oracle PIM - HBG Process ID = '
                                              || TO_CHAR(gv_hbg_process_id) || ' - OIC Instance ID = '
                                              || TO_CHAR(gv_oic_instance_id) || ' - Control ID Step 0 = '
                                              || TO_CHAR(lv_control_id_step_0)) ;
   EXCEPTION
      WHEN ge_custom_exception THEN
         log_p('ERROR'
              ,'ERROR at the step [' || lv_debug || '] of the [SUBMIT_MAIN_P]. ' || lv_error_msg);
         raise_application_error(-20001,'ERROR occured in [HBG_PIM_INTEGRATION_PKG.SUBMIT_MAIN_P]. Check logs for details.');
      WHEN OTHERS THEN
         log_p('ERROR'
              ,'ERROR at the step [' || lv_debug || '] of the [SUBMIT_MAIN_P]. ' || SQLERRM);
         RAISE;
   END submit_main_p;

END hbg_pim_integration_pkg;

/
