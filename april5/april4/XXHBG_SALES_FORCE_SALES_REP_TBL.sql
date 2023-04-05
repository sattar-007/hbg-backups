--------------------------------------------------------
--  DDL for Table XXHBG_SALES_FORCE_SALES_REP_TBL
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."XXHBG_SALES_FORCE_SALES_REP_TBL" 
   (	"SF_SALES_REP_ID" NUMBER, 
	"SALES_REP_NUMBER" VARCHAR2(200 BYTE), 
	"SALES_REP_NAME" VARCHAR2(200 BYTE), 
	"EXTERNAL_SALES_REP_IDENTIFIER" NUMBER, 
	"ADDRESS" VARCHAR2(300 BYTE), 
	"CITY" VARCHAR2(200 BYTE), 
	"STATE" VARCHAR2(200 BYTE), 
	"POSTAL_CODE" VARCHAR2(200 BYTE), 
	"COUNTRY" VARCHAR2(200 BYTE), 
	"PHONE_NUMBER" VARCHAR2(200 BYTE), 
	"EMAIL" VARCHAR2(200 BYTE), 
	"COMPANY" VARCHAR2(200 BYTE), 
	"COMPANY_DESCRIPTION" VARCHAR2(200 BYTE), 
	"EXTERNAL_CHECKBOX" VARCHAR2(20 BYTE), 
	"WHOLESALE_COMMISION" NUMBER, 
	"RETAIL_COMMISION" NUMBER, 
	"EDELWEISS" VARCHAR2(20 BYTE), 
	"NOTES" VARCHAR2(200 BYTE), 
	"ENTERED_BY" VARCHAR2(200 BYTE), 
	"ENTERED_DATE" DATE, 
	"UPDATED_BY" VARCHAR2(200 BYTE), 
	"UPDATED_DATE" DATE, 
	"START_DATE" DATE, 
	"END_DATE" DATE, 
	"STATUS" VARCHAR2(20 BYTE), 
	"SF_TERRITORY_ID" NUMBER, 
	"SALES_FORCE_ID" NUMBER, 
	"SF_DIV_ID" NUMBER
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."XXHBG_SALES_FORCE_SALES_REP_TBL" TO "RO_HBG_INTEGRATION";
