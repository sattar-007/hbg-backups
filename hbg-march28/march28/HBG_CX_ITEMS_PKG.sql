--------------------------------------------------------
--  DDL for Package HBG_CX_ITEMS_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."HBG_CX_ITEMS_PKG" IS
  /*************************************************************************
  *
  * Description:   HBG Cx Items Integration
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
  ************************************************************************/
    g_directory    VARCHAR2(50) := 'HBG_JSON_IMPORT';
    g_content_name VARCHAR2(15) := 'content.json';
    g_instance_id NUMBER;
    g_auth VARCHAR2(2000);
    g_url VARCHAR2(200);

    PROCEDURE import_skus (
        p_instance_id IN NUMBER,
        p_user_token IN VARCHAR2,
        errbuf       OUT VARCHAR2,
        retcode      OUT VARCHAR2
    );

     PROCEDURE import_related_items (
        p_instance_id IN NUMBER,
        p_user_token  IN VARCHAR2,
        errbuf        OUT VARCHAR2,
        retcode       OUT VARCHAR2
    );

    PROCEDURE import_prices (
        p_instance_id IN NUMBER,
        p_user_token IN VARCHAR2,
        errbuf       OUT VARCHAR2,
        retcode      OUT VARCHAR2
    );

    PROCEDURE import_collections (
        p_instance_id IN NUMBER,
        p_user_token IN VARCHAR2,
        errbuf       OUT VARCHAR2,
        retcode      OUT VARCHAR2
    );

    PROCEDURE import_inventory (
        p_instance_id IN NUMBER,
        p_user_token IN VARCHAR2,
        errbuf       OUT VARCHAR2,
        retcode      OUT VARCHAR2
    );

    PROCEDURE MAIN (p_instanceid IN NUMBER, p_auth IN VARCHAR2 DEFAULT NULL, p_url IN VARCHAR2);

    FUNCTION get_api_access_token RETURN VARCHAR2;

    FUNCTION file_to_blob (
        p_filename VARCHAR2
    ) RETURN BLOB;


    FUNCTION execute_import_api (
        p_uri VARCHAR2,
        p_user_token   VARCHAR2,
        p_request_json CLOB,
        p_id VARCHAR2 DEFAULT NULL
    ) RETURN CLOB;

    FUNCTION execute_bulk_import_api (
        p_user_token   VARCHAR2,
        p_operation VARCHAR2 
    ) RETURN VARCHAR2;

    function clob2blob(AClob CLOB) return BLOB;

    FUNCTION generateReports(p_instance_id NUMBER) return VARCHAR2;

    FUNCTION failedInvokeProc (p_instance_id NUMBER) RETURN VARCHAR2;
    FUNCTION deleteFailedItems(p_instance_id NUMBER) RETURN VARCHAR2;
    PROCEDURE publishChanges(p_auth IN VARCHAR2, errbuf OUT VARCHAR2,retcode OUT VARCHAR2);
    PROCEDURE call_main_job(p_instanceid IN NUMBER, p_auth IN VARCHAR2, p_url IN VARCHAR2, errbuf OUT VARCHAR2,retcode OUT VARCHAR2, job_status out varchar2,  job_name out varchar2);
    FUNCTION check_inventory_stock_level (
        p_user_token   VARCHAR2,
        p_id VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

    FUNCTION start_file_upload_api (
        p_user_token VARCHAR2,
        p_file_blob  BLOB,
        p_file_name  VARCHAR2
    ) RETURN VARCHAR2;

    PROCEDURE get_import_process_api (
        p_user_token IN VARCHAR2,
        p_process_id IN VARCHAR2,
        l_json_report_clob OUT CLOB,
        l_failed_records_clob OUT CLOB,
        l_failure_count OUT NUMBER,
        errbuf OUT VARCHAR2,
        retcode OUT NUMBER
    );

    FUNCTION clearStageTables (p_instance_id NUMBER) RETURN VARCHAR2;
    FUNCTION file_to_base64 (
        p_filename VARCHAR2
    ) RETURN CLOB;

     PROCEDURE upload_from_ui_api (
        p_user_token IN VARCHAR2,
        p_file_clob  IN CLOB,
        p_file_name  IN VARCHAR2,
        x_file_token OUT VARCHAR2,
        errbuf       OUT VARCHAR2,
        retcode      OUT NUMBER
    );

     FUNCTION validate_file_from_ui (
        p_user_token VARCHAR2,
        p_token varchar2
    ) RETURN CLOB;

     PROCEDURE import_assets_ui (
        p_user_token IN VARCHAR2,
        p_token IN VARCHAR2,
        x_total OUT NUMBER,
        retcode OUT NUMBER,
        errbuf OUT VARCHAR2
    );

    FUNCTION get_ui_import_status (
        p_user_token VARCHAR2
    ) RETURN varchar2;

    PROCEDURE isbn_validation ( p_instance_id IN NUMBER,
                                errbuf        OUT VARCHAR2,
                                retcode       OUT VARCHAR2
    );

    FUNCTION create_collections (
        owner_code VARCHAR2,
        genre_code VARCHAR2,
        p_instance_id NUMBER
    )RETURN varchar2;
END hbg_cx_items_pkg;


/
