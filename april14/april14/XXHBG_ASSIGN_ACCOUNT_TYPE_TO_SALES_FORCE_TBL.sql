--------------------------------------------------------
--  DDL for Table XXHBG_ASSIGN_ACCOUNT_TYPE_TO_SALES_FORCE_TBL
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."XXHBG_ASSIGN_ACCOUNT_TYPE_TO_SALES_FORCE_TBL" 
   (	"SALES_FORCE" VARCHAR2(200 BYTE), 
	"SALES_FORCE_NAME" VARCHAR2(200 BYTE), 
	"SF_OWNER" VARCHAR2(200 BYTE), 
	"OWNER_NAME" VARCHAR2(200 BYTE), 
	"ACCOUNT_TYPE" VARCHAR2(200 BYTE), 
	"ACCOUNT_TYPE_NAME" VARCHAR2(200 BYTE), 
	"NOTES" VARCHAR2(200 BYTE), 
	"ENTERED_BY" VARCHAR2(40 BYTE), 
	"ENTERED_DATE" DATE, 
	"UPDATED_BY" VARCHAR2(40 BYTE), 
	"UPDATED_DATE" DATE, 
	"START_DATE" DATE, 
	"END_DATE" DATE, 
	"STATUS" VARCHAR2(20 BYTE), 
	"SF_ACCOUNT_ID" NUMBER
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."XXHBG_ASSIGN_ACCOUNT_TYPE_TO_SALES_FORCE_TBL" TO "RO_HBG_INTEGRATION";
