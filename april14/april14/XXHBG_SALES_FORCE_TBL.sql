--------------------------------------------------------
--  DDL for Table XXHBG_SALES_FORCE_TBL
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."XXHBG_SALES_FORCE_TBL" 
   (	"SALES_FORCE_ID" NUMBER, 
	"OM_DESTINATION_ACCOUNT" NUMBER, 
	"OM_SALES_FORCE_CODE" NUMBER, 
	"OM_DIVISION" NUMBER, 
	"OM_TERRITORY" NUMBER, 
	"OM_SALES_REP" NUMBER, 
	"OM_DISTRIBUTION_CHANNEL" VARCHAR2(200 BYTE), 
	"AR_SALES_FORCE_CODE" NUMBER, 
	"AR_DIVISION" NUMBER, 
	"AR_TERRITORY" NUMBER, 
	"AR_SALES_REP" NUMBER, 
	"AR_DISTRIBUTION_CHANNEL" VARCHAR2(200 BYTE), 
	"CREATED_BY" VARCHAR2(200 BYTE), 
	"CREATED_DATE" DATE, 
	"LAST_UPDATED_BY" VARCHAR2(200 BYTE), 
	"LAST_UPDATED_DATE" DATE
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."XXHBG_SALES_FORCE_TBL" TO "RO_HBG_INTEGRATION";