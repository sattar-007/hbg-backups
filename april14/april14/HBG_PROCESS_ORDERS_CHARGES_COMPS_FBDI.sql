--------------------------------------------------------
--  DDL for Table HBG_PROCESS_ORDERS_CHARGES_COMPS_FBDI
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_PROCESS_ORDERS_CHARGES_COMPS_FBDI" 
   (	"SOURCE_TRANSACTION_ID" VARCHAR2(50 BYTE), 
	"SOURCE_TRANSACTION_SYSTEM" VARCHAR2(30 BYTE), 
	"SOURCE_TRANSACTION_LINE_ID" VARCHAR2(50 BYTE), 
	"SOURCE_TRANSACTION_SCHEDULE_ID" VARCHAR2(50 BYTE), 
	"SOURCE_CHARGE_COMPONENT_ID" VARCHAR2(50 BYTE), 
	"SOURCE_CHARGE_ID" VARCHAR2(120 BYTE), 
	"SEQUENCE_NUMBER" NUMBER, 
	"SOURCE_PARENT_CHARGE_COMP_ID" VARCHAR2(50 BYTE), 
	"CHARGE_CURRENCY_CODE" VARCHAR2(1000 BYTE), 
	"CHARGE_CURRENCY_NAME" VARCHAR2(1000 BYTE), 
	"CHARGE_CURRENCY_EXT_AMOUNT" NUMBER, 
	"CHARGE_CURRENCY_UNIT_PRICE" NUMBER, 
	"HEADER_CURRENCY_CODE" VARCHAR2(1000 BYTE), 
	"HEADER_CURRENCY_NAME" VARCHAR2(1000 BYTE), 
	"HEADER_CURRENCY_EXT_AMOUNT" NUMBER, 
	"HEADER_CURRENCY_UNIT_PRICE" NUMBER, 
	"PRICE_ELEMENT_CODE" VARCHAR2(30 BYTE), 
	"PRICE_ELEMENT" VARCHAR2(240 BYTE), 
	"PRICE_ELEMENT_USAGE_CODE" VARCHAR2(30 BYTE), 
	"PRICE_ELEMENT_USAGE" VARCHAR2(240 BYTE), 
	"ROLLUP_FLAG" VARCHAR2(1 BYTE), 
	"TRANSACTIONAL_CURRENCY_CODE" VARCHAR2(1000 BYTE), 
	"EXPLANATION" VARCHAR2(1000 BYTE), 
	"SOURCE_MPA_ID" VARCHAR2(50 BYTE), 
	"CHARGE_CURR_DURATION_EXT_AMT" NUMBER, 
	"HEADER_CURR_DURATION_EXT_AMT" NUMBER, 
	"CREATION_DATE" DATE, 
	"LAST_UPDATE_DATE" DATE, 
	"CREATED_BY" VARCHAR2(360 BYTE), 
	"LAST_UPDATED_BY" VARCHAR2(360 BYTE), 
	"STATUS" VARCHAR2(360 BYTE), 
	"ERROR_MSG" VARCHAR2(1000 BYTE), 
	"GIS_ID" NUMBER, 
	"SOURCE_SYSTEM" VARCHAR2(20 BYTE), 
	"SBI_UUID" VARCHAR2(50 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;