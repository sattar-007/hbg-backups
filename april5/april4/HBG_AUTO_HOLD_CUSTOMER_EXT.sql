--------------------------------------------------------
--  DDL for Table HBG_AUTO_HOLD_CUSTOMER_EXT
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_AUTO_HOLD_CUSTOMER_EXT" 
   (	"CUST_ACCOUNT_ID" NUMBER, 
	"CUST_ACCT_SITE_ID" NUMBER, 
	"ACCOUNT_NUMBER" VARCHAR2(200 BYTE), 
	"ACCOUNT_NAME" VARCHAR2(200 BYTE), 
	"PARTY_SITE_NUMBER" VARCHAR2(200 BYTE), 
	"PARTY_SITE_NAME" VARCHAR2(200 BYTE), 
	"ORGANIZATION_NUMBER" VARCHAR2(200 BYTE), 
	"ORGANIZATION_NAME" VARCHAR2(200 BYTE), 
	"SITE_USE_CODE" VARCHAR2(200 BYTE), 
	"CREATED_BY" VARCHAR2(200 BYTE), 
	"CREATION_DATE" DATE, 
	"LAST_UPDATED_BY" VARCHAR2(200 BYTE), 
	"LAST_UPDATE_DATE" DATE, 
	"STATUS" VARCHAR2(200 BYTE), 
	"STATUS_MESSAGE" CLOB, 
	"OIC_RUN_ID" NUMBER, 
	"ORGANIZATION_ID" NUMBER, 
	"SITE_USE_ID" NUMBER, 
	"LOCATION_ID" NUMBER, 
	"ADDRESS1" VARCHAR2(255 BYTE), 
	"ADDRESS2" VARCHAR2(255 BYTE), 
	"ADDRESS3" VARCHAR2(255 BYTE), 
	"ADDRESS4" VARCHAR2(255 BYTE), 
	"CITY" VARCHAR2(255 BYTE), 
	"POSTAL_CODE" VARCHAR2(255 BYTE), 
	"STATE" VARCHAR2(255 BYTE), 
	"PROVINCE" VARCHAR2(255 BYTE), 
	"COUNTRY" VARCHAR2(255 BYTE), 
	"COUNTY" VARCHAR2(255 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" 
 LOB ("STATUS_MESSAGE") STORE AS SECUREFILE (
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ENABLE STORAGE IN ROW CHUNK 8192
  NOCACHE LOGGING  NOCOMPRESS  KEEP_DUPLICATES 
  STORAGE(INITIAL 106496 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)) ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_AUTO_HOLD_CUSTOMER_EXT" TO "RO_HBG_INTEGRATION";
