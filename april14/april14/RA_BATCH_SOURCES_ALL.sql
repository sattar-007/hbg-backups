--------------------------------------------------------
--  DDL for Table RA_BATCH_SOURCES_ALL
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."RA_BATCH_SOURCES_ALL" 
   (	"BATCH_SOURCE_ID" NUMBER, 
	"LAST_UPDATE_DATE" TIMESTAMP (6), 
	"LAST_UPDATED_BY" VARCHAR2(256 BYTE), 
	"CREATION_DATE" TIMESTAMP (6), 
	"CREATED_BY" VARCHAR2(256 BYTE), 
	"LAST_UPDATE_LOGIN" VARCHAR2(128 BYTE), 
	"NAME" VARCHAR2(200 BYTE), 
	"SET_ID" NUMBER, 
	"DESCRIPTION" VARCHAR2(960 BYTE), 
	"STATUS" VARCHAR2(4 BYTE), 
	"LAST_BATCH_NUM" NUMBER, 
	"DEFAULT_INV_TRX_TYPE" NUMBER, 
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
	"ACCOUNTING_FLEXFIELD_RULE" VARCHAR2(120 BYTE), 
	"ACCOUNTING_RULE_RULE" VARCHAR2(120 BYTE), 
	"AGREEMENT_RULE" VARCHAR2(120 BYTE), 
	"AUTO_BATCH_NUMBERING_FLAG" VARCHAR2(4 BYTE), 
	"AUTO_TRX_NUMBERING_FLAG" VARCHAR2(4 BYTE), 
	"BATCH_SOURCE_TYPE" VARCHAR2(120 BYTE), 
	"BILL_ADDRESS_RULE" VARCHAR2(120 BYTE), 
	"BILL_CONTACT_RULE" VARCHAR2(120 BYTE), 
	"BILL_CUSTOMER_RULE" VARCHAR2(120 BYTE), 
	"CREATE_CLEARING_FLAG" VARCHAR2(4 BYTE), 
	"CUST_TRX_TYPE_RULE" VARCHAR2(120 BYTE), 
	"DERIVE_DATE_FLAG" VARCHAR2(4 BYTE), 
	"END_DATE" DATE, 
	"FOB_POINT_RULE" VARCHAR2(120 BYTE), 
	"GL_DATE_PERIOD_RULE" VARCHAR2(120 BYTE), 
	"INVALID_LINES_RULE" VARCHAR2(120 BYTE), 
	"INVALID_TAX_RATE_RULE" VARCHAR2(120 BYTE), 
	"INVENTORY_ITEM_RULE" VARCHAR2(120 BYTE), 
	"INVOICING_RULE_RULE" VARCHAR2(120 BYTE), 
	"MEMO_REASON_RULE" VARCHAR2(120 BYTE), 
	"REV_ACC_ALLOCATION_RULE" VARCHAR2(120 BYTE), 
	"SALESPERSON_RULE" VARCHAR2(120 BYTE), 
	"SALES_CREDIT_RULE" VARCHAR2(120 BYTE), 
	"SALES_CREDIT_TYPE_RULE" VARCHAR2(120 BYTE), 
	"SALES_TERRITORY_RULE" VARCHAR2(120 BYTE), 
	"SHIP_ADDRESS_RULE" VARCHAR2(120 BYTE), 
	"SHIP_CONTACT_RULE" VARCHAR2(120 BYTE), 
	"SHIP_CUSTOMER_RULE" VARCHAR2(120 BYTE), 
	"SHIP_VIA_RULE" VARCHAR2(120 BYTE), 
	"SOLD_CUSTOMER_RULE" VARCHAR2(120 BYTE), 
	"START_DATE" DATE, 
	"TERM_RULE" VARCHAR2(120 BYTE), 
	"UNIT_OF_MEASURE_RULE" VARCHAR2(120 BYTE), 
	"ATTRIBUTE11" VARCHAR2(600 BYTE), 
	"ATTRIBUTE12" VARCHAR2(600 BYTE), 
	"ATTRIBUTE13" VARCHAR2(600 BYTE), 
	"ATTRIBUTE14" VARCHAR2(600 BYTE), 
	"ATTRIBUTE15" VARCHAR2(600 BYTE), 
	"CUSTOMER_BANK_ACCOUNT_RULE" VARCHAR2(120 BYTE), 
	"MEMO_LINE_RULE" VARCHAR2(120 BYTE), 
	"RECEIPT_METHOD_RULE" VARCHAR2(120 BYTE), 
	"RELATED_DOCUMENT_RULE" VARCHAR2(120 BYTE), 
	"ALLOW_SALES_CREDIT_FLAG" VARCHAR2(4 BYTE), 
	"GROUPING_RULE_ID" NUMBER, 
	"CREDIT_MEMO_BATCH_SOURCE_ID" NUMBER, 
	"GLOBAL_ATTRIBUTE_CATEGORY" VARCHAR2(120 BYTE), 
	"GLOBAL_ATTRIBUTE1" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE2" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE3" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE4" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE5" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE6" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE7" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE8" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE9" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE10" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE11" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE12" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE13" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE14" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE15" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE16" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE17" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE18" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE19" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE20" VARCHAR2(600 BYTE), 
	"GLOBAL_ATTRIBUTE_NUMBER1" NUMBER, 
	"GLOBAL_ATTRIBUTE_NUMBER2" NUMBER, 
	"GLOBAL_ATTRIBUTE_NUMBER3" NUMBER, 
	"GLOBAL_ATTRIBUTE_NUMBER4" NUMBER, 
	"GLOBAL_ATTRIBUTE_NUMBER5" NUMBER, 
	"GLOBAL_ATTRIBUTE_DATE1" DATE, 
	"GLOBAL_ATTRIBUTE_DATE2" DATE, 
	"GLOBAL_ATTRIBUTE_DATE3" DATE, 
	"GLOBAL_ATTRIBUTE_DATE4" DATE, 
	"GLOBAL_ATTRIBUTE_DATE5" DATE, 
	"COPY_DOC_NUMBER_FLAG" VARCHAR2(4 BYTE), 
	"DEFAULT_REFERENCE" VARCHAR2(320 BYTE), 
	"COPY_INV_TIDFF_TO_CM_FLAG" VARCHAR2(4 BYTE), 
	"RECEIPT_HANDLING_OPTION" VARCHAR2(120 BYTE), 
	"ALLOW_DUPLICATE_TRX_NUM_FLAG" VARCHAR2(4 BYTE), 
	"LEGAL_ENTITY_ID" NUMBER, 
	"OBJECT_VERSION_NUMBER" NUMBER, 
	"BATCH_SOURCE_SEQ_ID" NUMBER, 
	"DEFAULT_INV_TRX_TYPE_SEQ_ID" NUMBER, 
	"CM_BATCH_SOURCE_SEQ_ID" NUMBER, 
	"BM_ENDPOINT_KEY_NAME" VARCHAR2(2000 BYTE), 
	"SEED_DATA_SOURCE" VARCHAR2(2048 BYTE), 
	"DOCUMENT_TYPE_ID" NUMBER, 
	"CONTROL_TRX_COMPLETION_FLAG" VARCHAR2(4 BYTE), 
	"ORA_SEED_SET1" VARCHAR2(4 BYTE), 
	"ORA_SEED_SET2" VARCHAR2(4 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
