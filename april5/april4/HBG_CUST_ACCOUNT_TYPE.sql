--------------------------------------------------------
--  DDL for Table HBG_CUST_ACCOUNT_TYPE
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_CUST_ACCOUNT_TYPE" 
   (	"ACC_TYP_ID" NUMBER DEFAULT "HBG_INTEGRATION"."ACC_TYP_ID_SEQ"."NEXTVAL", 
	"CUSTOMER_NAME" VARCHAR2(200 BYTE), 
	"ACCOUNT_NUMBER" VARCHAR2(200 BYTE), 
	"ACCOUNT_NAME" VARCHAR2(200 BYTE), 
	"CUST_ACCNT_ID" NUMBER, 
	"PARTY_ID" VARCHAR2(200 BYTE), 
	"DEFAULT_ACCOUNT_TYPE" VARCHAR2(200 BYTE), 
	"ACCOUNT_TYPE_DESC" VARCHAR2(200 BYTE), 
	"ENTERED_BY" VARCHAR2(200 BYTE), 
	"ENTERED_DATE" DATE, 
	"UPDATED_BY" VARCHAR2(200 BYTE), 
	"UPDATED_DATE" DATE, 
	"REGISTRY_ID" NUMBER, 
	"ORGANIZATION_NAME" VARCHAR2(200 BYTE), 
	"SITE_NUMBER" VARCHAR2(200 BYTE), 
	"SITE_NAME" VARCHAR2(200 BYTE), 
	"COUNTRY" VARCHAR2(200 BYTE), 
	"ADDRESS" VARCHAR2(200 BYTE), 
	"CITY" VARCHAR2(200 BYTE), 
	"STATE" VARCHAR2(200 BYTE), 
	"POSTAL_CODE" VARCHAR2(200 BYTE), 
	"SAN" VARCHAR2(200 BYTE), 
	"LOOKUP" VARCHAR2(200 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_CUST_ACCOUNT_TYPE" TO "RO_HBG_INTEGRATION";
