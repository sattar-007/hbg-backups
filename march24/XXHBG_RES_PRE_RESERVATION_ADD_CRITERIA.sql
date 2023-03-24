--------------------------------------------------------
--  DDL for Table XXHBG_RES_PRE_RESERVATION_ADD_CRITERIA
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."XXHBG_RES_PRE_RESERVATION_ADD_CRITERIA" 
   (	"CRITERIA_UID" NUMBER, 
	"ORDER_NUMBER" VARCHAR2(200 BYTE), 
	"RELEASE_DATE" DATE, 
	"ENTERED_BY" VARCHAR2(200 BYTE), 
	"PURCHASE_ORDER_NUMBER" VARCHAR2(200 BYTE), 
	"WORK_ORDER_NUMBER" VARCHAR2(200 BYTE), 
	"ORGANIZATION_CODE" VARCHAR2(200 BYTE), 
	"ACCOUNT_TYPE" VARCHAR2(200 BYTE), 
	"BILL_TO_CODE" VARCHAR2(200 BYTE), 
	"SHIP_TO_CODE" VARCHAR2(200 BYTE), 
	"SALE_TYPE" VARCHAR2(200 BYTE), 
	"OFFER_CODE" VARCHAR2(200 BYTE), 
	"OVERRIDE_HOT_TITLE" VARCHAR2(20 BYTE), 
	"RESERVATION_NUMBER" NUMBER, 
	"ITEM_CODE" VARCHAR2(200 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."XXHBG_RES_PRE_RESERVATION_ADD_CRITERIA" TO "RO_HBG_INTEGRATION";