--------------------------------------------------------
--  DDL for Table DOO_HOLD_INSTANCES
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."DOO_HOLD_INSTANCES" 
   (	"HOLD_INSTANCE_ID" NUMBER, 
	"ORCHESTRATION_APPLICATION_ID" NUMBER, 
	"OBJECT_VERSION_NUMBER" NUMBER, 
	"DOO_HEADER_ID" NUMBER, 
	"DOO_LINE_ID" NUMBER, 
	"FULFILL_LINE_ID" NUMBER, 
	"SOURCE_REQUEST_ID" VARCHAR2(200 BYTE), 
	"SOURCE_ORDER_SYSTEM" VARCHAR2(200 BYTE), 
	"SOURCE_ORDER_ID" VARCHAR2(200 BYTE), 
	"SOURCE_ORDER_REVISION" VARCHAR2(200 BYTE), 
	"SOURCE_LINE_ID" VARCHAR2(200 BYTE), 
	"HOLD_CODE_ID" NUMBER, 
	"APPLY_SYSTEM" VARCHAR2(120 BYTE), 
	"APPLY_USER_ID" VARCHAR2(256 BYTE), 
	"APPLY_DATE" DATE, 
	"RELEASE_USER_ID" VARCHAR2(256 BYTE), 
	"RELEASE_DATE" DATE, 
	"ACTIVE_FLAG" VARCHAR2(4 BYTE), 
	"PENDING_FLAG" VARCHAR2(4 BYTE), 
	"DELETED_FLAG" VARCHAR2(4 BYTE), 
	"HOLD_RUNNING_TASK_FLAG" VARCHAR2(4 BYTE), 
	"HOLD_COMMENTS" VARCHAR2(960 BYTE), 
	"HOLD_RELEASE_REASON_CODE" VARCHAR2(120 BYTE), 
	"HOLD_RELEASE_COMMENTS" VARCHAR2(960 BYTE), 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_LOGIN" VARCHAR2(128 BYTE), 
	"TRANSACTION_ENTITY_ID1" NUMBER, 
	"TRANSACTION_ENTITY_NAME1" VARCHAR2(120 BYTE), 
	"TRANSACTION_ENTITY_ID2" NUMBER, 
	"TRANSACTION_ENTITY_NAME2" VARCHAR2(120 BYTE), 
	"TRANSACTION_ENTITY_ID3" NUMBER, 
	"TRANSACTION_ENTITY_NAME3" VARCHAR2(120 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."DOO_HOLD_INSTANCES" TO "RO_HBG_INTEGRATION";