--------------------------------------------------------
--  DDL for Table HBG_ITEMS
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_ITEMS" 
   (	"ITEM_OWNER" VARCHAR2(200 BYTE), 
	"ACCOUNT_TYPE_CODE" VARCHAR2(200 BYTE), 
	"ACCOUNT_TYPE_DESCRIPTION" VARCHAR2(500 BYTE), 
	"START_DATE" VARCHAR2(200 BYTE), 
	"END_DATE" VARCHAR2(200 BYTE), 
	"STATUS" VARCHAR2(100 BYTE), 
	"STAGE_ID" NUMBER, 
	"CREATION_DATE" DATE, 
	"CREATED_BY" VARCHAR2(100 BYTE), 
	"LAST_UPDATE_DATE" DATE, 
	"LAST_UPDATED_BY" VARCHAR2(100 BYTE), 
	"ACCOUNT_NUMBER" VARCHAR2(200 BYTE), 
	"CUST_ACCT_ID" NUMBER
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_ITEMS" TO "RO_HBG_INTEGRATION";
