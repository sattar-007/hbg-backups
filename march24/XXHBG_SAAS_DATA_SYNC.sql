--------------------------------------------------------
--  DDL for Package XXHBG_SAAS_DATA_SYNC
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."XXHBG_SAAS_DATA_SYNC" 
AS
   
    
    default_batch_size         CONSTANT NUMBER := 3000;
    default_offset_type        CONSTANT VARCHAR2 (20) := 'SECOND';
    default_offset_value       CONSTANT NUMBER := 10;
    default_retention_period   CONSTANT NUMBER := 90;

    /*
        Determines whether an object is ready for sync based on its last successful run date and its frequency
    */
    FUNCTION ready_for_sync (p_freq_type       IN VARCHAR2,
                             p_freq_value      IN NUMBER,
                             p_last_run_date   IN TIMESTAMP)
        RETURN VARCHAR2;

    /*
        Fetches all the objects to be synched up at this moment
    */
    PROCEDURE fetch_objects_to_be_synced (
        x_sync_objects_tbl   OUT XXHBG_saas_data_sync_conf_tbl);

    /*
        Fetches the sync object information
    */
    PROCEDURE get_sync_object_info (
        p_object_name       IN     VARCHAR2,
        p_full_sync_flag    IN     VARCHAR2 DEFAULT 'N',
        x_status_code          OUT VARCHAR2,
        x_status_msg           OUT VARCHAR2,
        x_sync_object_rec      OUT XXHBG_saas_data_sync_conf_rec);

    /*
        Syncs up the data retrieved from SaaS to the corresponding PaaS table
    */
    PROCEDURE sync_saas_data (p_object_id         IN     NUMBER,
                              p_full_sync_flag    IN     VARCHAR2 DEFAULT 'N',
                              p_resp_xmltype      IN     XMLTYPE,
                              p_batch_num         IN     NUMBER,
                              p_sync_start_time   IN     VARCHAR2,
                              x_rows_merged          OUT NUMBER,
                              x_has_more_data        OUT VARCHAR2,
                              x_status_code          OUT VARCHAR2,
                              x_status_msg           OUT VARCHAR2);

    /*
        Purges all the historical sync runs information
        It is called from the auto purge program
    */
    PROCEDURE purge_sync_runs (p_retention_period_in_days IN NUMBER);

    /*
        Resets the last run date to a historical date and 
        deletes the data pertaining to that time period from the corresponding PaaS table
    */
    PROCEDURE clean_up_sync_objects (p_cleanup_start_time IN VARCHAR2);

    /*
        Updates the datamodel path of an object
    */    
    procedure update_datamodel_path(p_object_name IN VARCHAR2,
                                    p_bi_datamodel_path IN VARCHAR2,
                                    x_status                 OUT VARCHAR2,
                                    x_status_message         OUT VARCHAR2);

    /*
        Prepares the datamodel XML in base 64 format
        Used in migrating from SQL based sync object to a datamodel based sync object
    */
    PROCEDURE prepare_datamodel_xml (p_object_name         IN     VARCHAR2,
                                     x_return_base64_xml      OUT CLOB,
                                     x_status                 OUT VARCHAR2,
                                     x_status_message         OUT VARCHAR2);

    /*
        Reduces the batch size of an object
    */
    PROCEDURE reduce_batch_size (p_object_name        IN     VARCHAR2,
                                 p_reduce_by_number   IN     NUMBER DEFAULT 500,
                                 x_status                OUT VARCHAR2,
                                 x_status_message        OUT VARCHAR2);
END XXHBG_saas_data_sync;

/
