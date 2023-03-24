--------------------------------------------------------
--  DDL for Type XXHBG_SAAS_DATA_SYNC_CONF_REC
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "HBG_INTEGRATION"."XXHBG_SAAS_DATA_SYNC_CONF_REC" force AS OBJECT (
    object_id            NUMBER,
    object_name          VARCHAR2(200 BYTE),
    description          VARCHAR2(4000 BYTE),
    paas_table_name      VARCHAR2(200 BYTE),
    bi_data_model_path   VARCHAR2(500 BYTE),
    sql_query            CLOB,
    enabled              VARCHAR2(1 BYTE),
    last_run_date        VARCHAR2(50 BYTE),
    frequency_type       VARCHAR2(100 BYTE),
    frequency_value      NUMBER,
    offset_frequency_type  VARCHAR2(100 BYTE),
    offset_frequency_value NUMBER,
    sync_source          VARCHAR2(20 BYTE),
    default_sync_mode    VARCHAR2(20 BYTE),
    batch_size           number,
    CONSTRUCTOR FUNCTION XXHBG_SAAS_DATA_SYNC_CONF_REC
        RETURN SELF AS RESULT
);

/
CREATE OR REPLACE EDITIONABLE TYPE BODY "HBG_INTEGRATION"."XXHBG_SAAS_DATA_SYNC_CONF_REC" AS
 CONSTRUCTOR FUNCTION XXHBG_SAAS_DATA_SYNC_CONF_REC
        RETURN SELF AS RESULT
    AS
    BEGIN
        RETURN;
    END;
END;

/
