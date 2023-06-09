--------------------------------------------------------
--  DDL for Table HBG_AR_CUST_MAINTENANCE_ACTIVITY
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_AR_CUST_MAINTENANCE_ACTIVITY" 
   (	"CUSTOMER_TRX_ID" VARCHAR2(200 BYTE), 
	"CUST_ACCOUNT_ID" VARCHAR2(200 BYTE), 
	"ACCOUNT_NUMBER" VARCHAR2(200 BYTE), 
	"PARTY_ID" VARCHAR2(200 BYTE), 
	"ORG_NBR" VARCHAR2(200 BYTE), 
	"INVOICE_NUMBER" VARCHAR2(200 BYTE), 
	"FLAG_CODE" VARCHAR2(200 BYTE), 
	"TRX_CODE" VARCHAR2(200 BYTE), 
	"TRX_TYPE" VARCHAR2(200 BYTE), 
	"CLAIM_NUMBER" VARCHAR2(200 BYTE), 
	"AMOUNT" VARCHAR2(200 BYTE), 
	"AMOUNT_APPLIED" VARCHAR2(200 BYTE), 
	"BALANCE" VARCHAR2(200 BYTE), 
	"DUE_DATE" VARCHAR2(200 BYTE), 
	"NEW_TRX_CODE" VARCHAR2(200 BYTE), 
	"NEW_CLAIM_NUMBER" VARCHAR2(200 BYTE), 
	"GL_ACCOUNT_NUMBER_NEW" VARCHAR2(200 BYTE), 
	"GL_ACCOUNT_NUMBER" VARCHAR2(200 BYTE), 
	"TRX_DATE" VARCHAR2(200 BYTE), 
	"INVOICE_PO_NUMBER" VARCHAR2(200 BYTE), 
	"AGING_CAT" VARCHAR2(200 BYTE), 
	"ACTION" VARCHAR2(200 BYTE), 
	"SUBMITTED_BY" VARCHAR2(200 BYTE), 
	"SUBMISSION_DATE" VARCHAR2(200 BYTE), 
	"NEW_ACCOUNT_NUMBER" VARCHAR2(20 BYTE), 
	"NEW_TRX_NUMBER" VARCHAR2(20 BYTE), 
	"ACCOUNT_NAME" VARCHAR2(50 BYTE), 
	"STATUS" VARCHAR2(50 BYTE), 
	"SESSION_ID" VARCHAR2(50 BYTE), 
	"TRX_CLASS" VARCHAR2(50 BYTE), 
	"TRX_KEY" VARCHAR2(50 BYTE), 
	"PAYMENT_TERMS" VARCHAR2(50 BYTE), 
	"INVOICE_REF_NUM" VARCHAR2(50 BYTE), 
	"EDI_TRANS_DATE" VARCHAR2(50 BYTE), 
	"EDI_REMIT_DATE" VARCHAR2(50 BYTE), 
	"EDI_ACK_DATE" VARCHAR2(50 BYTE), 
	"ORCL_STATUS" VARCHAR2(200 BYTE), 
	"ADJUSTMENT_NUMBER" VARCHAR2(50 BYTE), 
	"ADJUSTMENT_ID" NUMBER, 
	"ORCL_ERR_MESSAGE" VARCHAR2(4000 BYTE), 
	"PROCESS_ID" NUMBER
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_AR_CUST_MAINTENANCE_ACTIVITY" TO "RO_HBG_INTEGRATION";
