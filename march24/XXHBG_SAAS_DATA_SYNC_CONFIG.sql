--------------------------------------------------------
--  DDL for Table XXHBG_SAAS_DATA_SYNC_CONFIG
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."XXHBG_SAAS_DATA_SYNC_CONFIG" 
   (	"OBJECT_NAME" VARCHAR2(200 BYTE), 
	"PAAS_TABLE_NAME" VARCHAR2(200 BYTE), 
	"BI_DATA_MODEL_PATH" VARCHAR2(500 BYTE), 
	"OBJECT_ID" NUMBER, 
	"DESCRIPTION" VARCHAR2(4000 BYTE), 
	"ENABLED" VARCHAR2(1 BYTE), 
	"LAST_RUN_DATE" TIMESTAMP (6) WITH TIME ZONE, 
	"FREQUENCY_TYPE" VARCHAR2(100 BYTE), 
	"FREQUENCY_VALUE" NUMBER, 
	"SYNC_SOURCE" VARCHAR2(20 BYTE), 
	"SQL_QUERY" CLOB, 
	"PRIORITY" NUMBER DEFAULT 1, 
	"DEFAULT_SYNC_MODE" VARCHAR2(20 BYTE) DEFAULT 'DELTA', 
	"POST_SYNC_PROCESS" VARCHAR2(256 BYTE), 
	"OFFSET_FREQUENCY_TYPE" VARCHAR2(100 BYTE) DEFAULT 'SECOND', 
	"OFFSET_FREQUENCY_VALUE" NUMBER DEFAULT 10, 
	"BATCH_SIZE" NUMBER DEFAULT 10000, 
	"CLEANUP_UTC_HOUR" NUMBER DEFAULT 8, 
	"LAST_CLEANUP_DATE" TIMESTAMP (6) WITH TIME ZONE, 
	"CLEANUP_RANGE_IN_DAYS" NUMBER DEFAULT 30, 
	"CLEANUP_REQUIRED" VARCHAR2(1 BYTE) DEFAULT 'N'
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" 
 LOB ("SQL_QUERY") STORE AS SECUREFILE (
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ENABLE STORAGE IN ROW CHUNK 8192
  NOCACHE LOGGING  NOCOMPRESS  KEEP_DUPLICATES 
  STORAGE(INITIAL 106496 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)) ;
  GRANT SELECT ON "HBG_INTEGRATION"."XXHBG_SAAS_DATA_SYNC_CONFIG" TO "RO_HBG_INTEGRATION";
