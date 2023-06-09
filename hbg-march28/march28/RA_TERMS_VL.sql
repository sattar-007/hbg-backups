--------------------------------------------------------
--  DDL for Table RA_TERMS_VL
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."RA_TERMS_VL" 
   (	"TERM_ID" NUMBER, 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(256 BYTE), 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_LOGIN" VARCHAR2(128 BYTE), 
	"CREDIT_CHECK_FLAG" VARCHAR2(4 BYTE), 
	"DUE_CUTOFF_DAY" NUMBER, 
	"PRINTING_LEAD_DAYS" NUMBER, 
	"START_DATE_ACTIVE" DATE, 
	"END_DATE_ACTIVE" DATE, 
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
	"BASE_AMOUNT" NUMBER, 
	"CALC_DISCOUNT_ON_LINES_FLAG" VARCHAR2(4 BYTE), 
	"DISCOUNT_BASIS_DATE_TYPE" VARCHAR2(80 BYTE), 
	"FIRST_INSTALLMENT_CODE" VARCHAR2(48 BYTE), 
	"IN_USE" VARCHAR2(4 BYTE), 
	"PARTIAL_DISCOUNT_FLAG" VARCHAR2(4 BYTE), 
	"ATTRIBUTE11" VARCHAR2(600 BYTE), 
	"ATTRIBUTE12" VARCHAR2(600 BYTE), 
	"ATTRIBUTE13" VARCHAR2(600 BYTE), 
	"ATTRIBUTE14" VARCHAR2(600 BYTE), 
	"ATTRIBUTE15" VARCHAR2(600 BYTE), 
	"NAME" VARCHAR2(60 BYTE), 
	"DESCRIPTION" VARCHAR2(960 BYTE), 
	"PREPAYMENT_FLAG" VARCHAR2(4 BYTE), 
	"BILLING_CYCLE_ID" NUMBER, 
	"SET_ID" NUMBER, 
	"MODULE_ID" VARCHAR2(128 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."RA_TERMS_VL" TO "RO_HBG_INTEGRATION";
