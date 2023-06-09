--------------------------------------------------------
--  DDL for Table XXDOO_ORDER_HDRS_ALL_EFF_B_INT
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."XXDOO_ORDER_HDRS_ALL_EFF_B_INT" 
   (	"SOURCE_TRANSACTION_ID" VARCHAR2(200 BYTE), 
	"SOURCE_TRANSACTION_SYSTEM" VARCHAR2(120 BYTE), 
	"CONTEXT_CODE" VARCHAR2(320 BYTE), 
	"LOAD_REQUEST_ID" NUMBER, 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_LOGIN" VARCHAR2(128 BYTE), 
	"OBJECT_VERSION_NUMBER" NUMBER, 
	"ATTRIBUTE_CHAR1" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR2" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR3" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR4" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR5" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR6" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR7" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR8" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR9" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR10" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR11" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR12" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR13" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR14" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR15" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR16" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR17" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR18" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR19" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_CHAR20" VARCHAR2(600 BYTE), 
	"ATTRIBUTE_NUMBER1" NUMBER, 
	"ATTRIBUTE_NUMBER2" NUMBER, 
	"ATTRIBUTE_NUMBER3" NUMBER, 
	"ATTRIBUTE_NUMBER4" NUMBER, 
	"ATTRIBUTE_NUMBER5" NUMBER, 
	"ATTRIBUTE_NUMBER6" NUMBER, 
	"ATTRIBUTE_NUMBER7" NUMBER, 
	"ATTRIBUTE_NUMBER8" NUMBER, 
	"ATTRIBUTE_NUMBER9" NUMBER, 
	"ATTRIBUTE_NUMBER10" NUMBER, 
	"ATTRIBUTE_DATE1" DATE, 
	"ATTRIBUTE_DATE2" DATE, 
	"ATTRIBUTE_DATE3" DATE, 
	"ATTRIBUTE_DATE4" DATE, 
	"ATTRIBUTE_DATE5" DATE, 
	"ATTRIBUTE_TIMESTAMP1" TIMESTAMP (6), 
	"ATTRIBUTE_TIMESTAMP2" TIMESTAMP (6), 
	"ATTRIBUTE_TIMESTAMP3" TIMESTAMP (6), 
	"ATTRIBUTE_TIMESTAMP4" TIMESTAMP (6), 
	"ATTRIBUTE_TIMESTAMP5" TIMESTAMP (6), 
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
  GRANT SELECT ON "HBG_INTEGRATION"."XXDOO_ORDER_HDRS_ALL_EFF_B_INT" TO "RO_HBG_INTEGRATION";
