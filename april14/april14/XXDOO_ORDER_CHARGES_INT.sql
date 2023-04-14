--------------------------------------------------------
--  DDL for Table XXDOO_ORDER_CHARGES_INT
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."XXDOO_ORDER_CHARGES_INT" 
   (	"SOURCE_TRANSACTION_ID" VARCHAR2(200 BYTE), 
	"PRICE_PERIODICITY" VARCHAR2(100 BYTE), 
	"APPLY_TO_NAME" VARCHAR2(320 BYTE), 
	"SOURCE_TRANSACTION_SYSTEM" VARCHAR2(120 BYTE), 
	"SOURCE_TRANSACTION_LINE_ID" VARCHAR2(200 BYTE), 
	"SOURCE_TRANSACTION_SCHEDULE_ID" VARCHAR2(200 BYTE), 
	"SOURCE_CHARGE_ID" VARCHAR2(200 BYTE), 
	"CHARGE_DEFINITION_CODE" VARCHAR2(120 BYTE), 
	"CHARGE_DEFINITION" VARCHAR2(320 BYTE), 
	"CHARGE_TYPE_CODE" VARCHAR2(120 BYTE), 
	"CHARGE_TYPE" VARCHAR2(320 BYTE), 
	"CHARGE_SUBTYPE_CODE" VARCHAR2(120 BYTE), 
	"CHARGE_SUBTYPE" VARCHAR2(320 BYTE), 
	"SEQUENCE_NUMBER" NUMBER, 
	"PRICE_TYPE_CODE" VARCHAR2(120 BYTE), 
	"PRICE_TYPE" VARCHAR2(960 BYTE), 
	"PRICED_QUANTITY" NUMBER, 
	"PRICED_QUANTITY_UOM_CODE" VARCHAR2(12 BYTE), 
	"PRICED_QUANTITY_UOM" VARCHAR2(100 BYTE), 
	"PRIMARY_FLAG" VARCHAR2(4 BYTE), 
	"APPLY_TO" VARCHAR2(120 BYTE), 
	"ROLLUP_FLAG" VARCHAR2(4 BYTE), 
	"CHARGE_CURRENCY_CODE" VARCHAR2(4000 BYTE), 
	"CHARGE_CURRENCY_NAME" VARCHAR2(4000 BYTE), 
	"PRICE_PERIODICITY_CODE" VARCHAR2(120 BYTE), 
	"GSA_UNIT_PRICE" NUMBER, 
	"TRANSACTIONAL_CURRENCY_CODE" VARCHAR2(4000 BYTE), 
	"TRANSACTIONAL_UOM_CODE" VARCHAR2(12 BYTE), 
	"AVERAGE_UNIT_SELLING_PRICE" NUMBER, 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_LOGIN" VARCHAR2(128 BYTE), 
	"OBJECT_VERSION_NUMBER" NUMBER, 
	"LOAD_REQUEST_ID" NUMBER, 
	"BATCH_ID" NUMBER, 
	"VALIDATION_BITSET" NUMBER, 
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
  GRANT SELECT ON "HBG_INTEGRATION"."XXDOO_ORDER_CHARGES_INT" TO "RO_HBG_INTEGRATION";
