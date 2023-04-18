--------------------------------------------------------
--  DDL for Table XXDOO_ORDER_MANUAL_PRICE_ADJ_INT
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."XXDOO_ORDER_MANUAL_PRICE_ADJ_INT" 
   (	"SOURCE_TRANSACTION_ID" VARCHAR2(200 BYTE), 
	"REASON" VARCHAR2(4000 BYTE), 
	"PRICE_PERIODICITY" VARCHAR2(4000 BYTE), 
	"ADJUSTMENT_TYPE" VARCHAR2(4000 BYTE), 
	"SOURCE_TRANSACTION_SYSTEM" VARCHAR2(120 BYTE), 
	"SOURCE_TRANSACTION_LINE_ID" VARCHAR2(200 BYTE), 
	"SOURCE_TRANSACTION_SCHEDULE_ID" VARCHAR2(200 BYTE), 
	"CHARGE_DEFINITION" VARCHAR2(4000 BYTE), 
	"ADJUSTMENT_AMOUNT" NUMBER, 
	"ADJUSTMENT_TYPE_CODE" VARCHAR2(120 BYTE), 
	"ADJUSTMENT_ELEMENT_BASIS" VARCHAR2(120 BYTE), 
	"ADJUSTMENT_ELEMENT_BASIS_CODE" VARCHAR2(4000 BYTE), 
	"REASON_CODE" VARCHAR2(120 BYTE), 
	"COMMENTS" VARCHAR2(4000 BYTE), 
	"SEQUENCE" NUMBER, 
	"CHARGE_DEFINITION_CODE" VARCHAR2(120 BYTE), 
	"PRICE_PERIODICITY_CODE" VARCHAR2(120 BYTE), 
	"CHARGE_ROLLUP_FLAG" VARCHAR2(4 BYTE), 
	"VALIDATION_STATUS_CODE" VARCHAR2(120 BYTE), 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_LOGIN" VARCHAR2(128 BYTE), 
	"OBJECT_VERSION_NUMBER" NUMBER, 
	"SOURCE_MANUAL_PRICE_ADJ_ID" VARCHAR2(200 BYTE), 
	"LOAD_REQUEST_ID" NUMBER, 
	"INTERFACE_RUN_ID" NUMBER, 
	"ICS_RUN_ID" NUMBER, 
	"SAAS_PROCESS_ID" NUMBER, 
	"STATUS" VARCHAR2(10 BYTE), 
	"STATUS_MESSAGE" VARCHAR2(4000 BYTE), 
	"FILE_NAME" VARCHAR2(240 BYTE), 
	"ICS_BATCH_NO" NUMBER
   ) SEGMENT CREATION DEFERRED 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."XXDOO_ORDER_MANUAL_PRICE_ADJ_INT" TO "RO_HBG_INTEGRATION";
