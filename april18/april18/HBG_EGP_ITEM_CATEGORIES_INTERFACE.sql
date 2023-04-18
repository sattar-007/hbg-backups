--------------------------------------------------------
--  DDL for Table HBG_EGP_ITEM_CATEGORIES_INTERFACE
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_EGP_ITEM_CATEGORIES_INTERFACE" 
   (	"TRANSACTION_TYPE" VARCHAR2(10 BYTE), 
	"BATCH_ID" NUMBER(18,0), 
	"BATCH_NUMBER" VARCHAR2(40 BYTE), 
	"ITEM_NUMBER" VARCHAR2(300 BYTE), 
	"ORGANIZATION_CODE" VARCHAR2(18 BYTE), 
	"CATEGORY_SET_NAME" VARCHAR2(30 BYTE), 
	"CATEGORY_NAME" VARCHAR2(250 BYTE), 
	"CATEGORY_CODE" VARCHAR2(820 BYTE), 
	"OLD_CATEGORY_NAME" VARCHAR2(250 BYTE), 
	"OLD_CATEGORY_CODE" VARCHAR2(820 BYTE), 
	"SOURCE_SYSTEM_CODE" VARCHAR2(30 BYTE), 
	"SOURCE_SYSTEM_REFERENCE" VARCHAR2(255 BYTE), 
	"START_DATE" DATE, 
	"END_DATE" DATE, 
	"STATUS" VARCHAR2(50 BYTE), 
	"ERROR_TEXT" VARCHAR2(4000 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_EGP_ITEM_CATEGORIES_INTERFACE" TO "RO_HBG_INTEGRATION";
