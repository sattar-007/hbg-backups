--------------------------------------------------------
--  DDL for Package HBG_PIM_INTEGRATION_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."HBG_PIM_INTEGRATION_PKG" IS
   -- -----------------------------------------------------------------------------------------------------------------
   --  Package Spec: HBG_PIM_INTEGRATION_PKG
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

   TYPE hbg_ego_item_intf_eff_b_status_rec IS RECORD (
      batch_id NUMBER,
      item_number VARCHAR2(100),
      organization_code VARCHAR2(18),
      context_code VARCHAR2(80),
      attribute_char1 VARCHAR2(4000),
      attribute_char2 VARCHAR2(4000),
      attribute_char3 VARCHAR2(4000),
      attribute_number1 NUMBER,
      attribute_number2 NUMBER,
      attribute_number3 NUMBER,
      status VARCHAR2(100),
      error_text VARCHAR2(4000)
   );

   TYPE gt_hbg_ego_item_intf_eff_b_status_tb IS TABLE OF hbg_ego_item_intf_eff_b_status_rec;

   ge_custom_exception EXCEPTION;
   gv_db_directory VARCHAR2(50) := 'HBG_JSON_IMPORT'; --'HBG_CSV_IMPORT';
   gv_oic_instance_id NUMBER;
   gv_hbg_process_id NUMBER;
   gv_interface_name VARCHAR2(50) := 'HBG_LOAD_ITEMS_INFO_INTO_ORACLE_PIM';

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
                                     ,p_status         OUT VARCHAR2);

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
                                          ,p_item_intf_eff_b_tb IN gt_hbg_ego_item_intf_eff_b_status_tb);

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
                                                 ,p_oic_instance_id IN NUMBER);

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
                                                    ,p_oic_instance_id IN NUMBER);

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
                                    ,p_oic_instance_id IN NUMBER);

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
                                           ,p_oic_instance_id IN NUMBER);

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
                   ,p_control_id_step_0 IN NUMBER);

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
                          ,p_oic_instance_id IN NUMBER);

END hbg_pim_integration_pkg;

/
