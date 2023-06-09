--------------------------------------------------------
--  DDL for Table HZ_CUST_ACCOUNTS
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HZ_CUST_ACCOUNTS" 
   (	"CUST_ACCOUNT_ID" NUMBER, 
	"PARTY_ID" NUMBER, 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"ACCOUNT_NUMBER" VARCHAR2(120 BYTE), 
	"LAST_UPDATED_BY" VARCHAR2(256 BYTE), 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_LOGIN" VARCHAR2(128 BYTE), 
	"REQUEST_ID" NUMBER, 
	"JOB_DEFINITION_NAME" VARCHAR2(400 BYTE), 
	"JOB_DEFINITION_PACKAGE" VARCHAR2(3600 BYTE), 
	"ATTRIBUTE_CATEGORY" VARCHAR2(120 BYTE), 
	"ATTRIBUTE1" VARCHAR2(600 BYTE), 
	"ATTRIBUTE2" VARCHAR2(600 BYTE), 
	"ATTRIBUTE3" VARCHAR2(600 BYTE), 
	"ATTRIBUTE4" VARCHAR2(600 BYTE), 
	"ATTRIBUTE5" VARCHAR2(600 BYTE), 
	"ATTRIBUTE6" VARCHAR2(600 BYTE), 
	"ATTRIBUTE7" VARCHAR2(600 BYTE), 
	"ATTRIBUTE8" VARCHAR2(600 BYTE), 
	"ATTRIBUTE9" VARCHAR2(600 BYTE), 
	"ATTRIBUTE10" VARCHAR2(600 BYTE), 
	"ATTRIBUTE11" VARCHAR2(600 BYTE), 
	"ATTRIBUTE12" VARCHAR2(600 BYTE), 
	"ATTRIBUTE13" VARCHAR2(600 BYTE), 
	"ATTRIBUTE14" VARCHAR2(600 BYTE), 
	"ATTRIBUTE15" VARCHAR2(600 BYTE), 
	"ATTRIBUTE16" VARCHAR2(600 BYTE), 
	"ATTRIBUTE17" VARCHAR2(600 BYTE), 
	"ATTRIBUTE18" VARCHAR2(600 BYTE), 
	"ATTRIBUTE19" VARCHAR2(600 BYTE), 
	"ATTRIBUTE20" VARCHAR2(600 BYTE), 
	"ORIG_SYSTEM_REFERENCE" VARCHAR2(960 BYTE), 
	"STATUS" VARCHAR2(4 BYTE), 
	"CUSTOMER_TYPE" VARCHAR2(120 BYTE), 
	"CUSTOMER_CLASS_CODE" VARCHAR2(120 BYTE), 
	"TAX_CODE" VARCHAR2(200 BYTE), 
	"TAX_HEADER_LEVEL_FLAG" VARCHAR2(4 BYTE), 
	"TAX_ROUNDING_RULE" VARCHAR2(120 BYTE), 
	"COTERMINATE_DAY_MONTH" VARCHAR2(24 BYTE), 
	"ACCOUNT_ESTABLISHED_DATE" DATE, 
	"HELD_BILL_EXPIRATION_DATE" DATE, 
	"HOLD_BILL_FLAG" VARCHAR2(4 BYTE), 
	"ACCOUNT_NAME" VARCHAR2(960 BYTE), 
	"DEPOSIT_REFUND_METHOD" VARCHAR2(80 BYTE), 
	"NPA_NUMBER" VARCHAR2(240 BYTE), 
	"SOURCE_CODE" VARCHAR2(600 BYTE), 
	"COMMENTS" VARCHAR2(4000 BYTE), 
	"DATE_TYPE_PREFERENCE" VARCHAR2(80 BYTE), 
	"ARRIVALSETS_INCLUDE_LINES_FLAG" VARCHAR2(4 BYTE), 
	"STATUS_UPDATE_DATE" DATE, 
	"AUTOPAY_FLAG" VARCHAR2(4 BYTE), 
	"LAST_BATCH_ID" NUMBER, 
	"OBJECT_VERSION_NUMBER" NUMBER, 
	"CREATED_BY_MODULE" VARCHAR2(120 BYTE), 
	"SELLING_PARTY_ID" NUMBER, 
	"CONFLICT_ID" NUMBER, 
	"USER_LAST_UPDATE_DATE" TIMESTAMP (6), 
	"ATTRIBUTE21" VARCHAR2(600 BYTE), 
	"ATTRIBUTE22" VARCHAR2(600 BYTE), 
	"ATTRIBUTE23" VARCHAR2(600 BYTE), 
	"ATTRIBUTE24" VARCHAR2(600 BYTE), 
	"ATTRIBUTE25" VARCHAR2(600 BYTE), 
	"ATTRIBUTE26" VARCHAR2(600 BYTE), 
	"ATTRIBUTE27" VARCHAR2(600 BYTE), 
	"ATTRIBUTE28" VARCHAR2(600 BYTE), 
	"ATTRIBUTE29" VARCHAR2(600 BYTE), 
	"ATTRIBUTE30" VARCHAR2(1020 BYTE), 
	"CPDRF_VER_SOR" NUMBER, 
	"CPDRF_VER_PILLAR" NUMBER, 
	"CPDRF_LAST_UPD" VARCHAR2(60 BYTE), 
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
	"ATTRIBUTE_NUMBER11" NUMBER, 
	"ATTRIBUTE_NUMBER12" NUMBER, 
	"ATTRIBUTE_DATE1" DATE, 
	"ATTRIBUTE_DATE2" DATE, 
	"ATTRIBUTE_DATE3" DATE, 
	"ATTRIBUTE_DATE4" DATE, 
	"ATTRIBUTE_DATE5" DATE, 
	"ATTRIBUTE_DATE6" DATE, 
	"ATTRIBUTE_DATE7" DATE, 
	"ATTRIBUTE_DATE8" DATE, 
	"ATTRIBUTE_DATE9" DATE, 
	"ATTRIBUTE_DATE10" DATE, 
	"ATTRIBUTE_DATE11" DATE, 
	"ATTRIBUTE_DATE12" DATE, 
	"ACCOUNT_TERMINATION_DATE" DATE
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."HZ_CUST_ACCOUNTS" TO "RO_HBG_INTEGRATION";
