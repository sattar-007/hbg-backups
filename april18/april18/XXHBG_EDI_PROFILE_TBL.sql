--------------------------------------------------------
--  DDL for Table XXHBG_EDI_PROFILE_TBL
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."XXHBG_EDI_PROFILE_TBL" 
   (	"EDI_ID" NUMBER, 
	"ORDER_LOAD_STATUS" VARCHAR2(200 BYTE), 
	"BILL_TO_SAN" VARCHAR2(200 BYTE), 
	"ASN_FLAG" VARCHAR2(200 BYTE), 
	"ASN_OUTBOUND_COMMUNICATION" VARCHAR2(200 BYTE), 
	"EDI_INVOICE_FLAG_TYPE" VARCHAR2(200 BYTE), 
	"INVOICE_OUTBOUND_COMMUNICATION" VARCHAR2(200 BYTE), 
	"OUTBOUND_EDI_IDENTIFIER" VARCHAR2(200 BYTE), 
	"EDI_POA_FLAG" VARCHAR2(200 BYTE), 
	"EDI_POA_UPDATES" VARCHAR2(200 BYTE), 
	"NOP_DELETE_INDICATOR" VARCHAR2(200 BYTE), 
	"CONSOLIDATED_ASN_INDICATOR" VARCHAR2(200 BYTE), 
	"EDI_ORDER_SOURCE" VARCHAR2(200 BYTE), 
	"ENTERED_BY" VARCHAR2(200 BYTE), 
	"ENTERED_DATE" DATE, 
	"UPDATED_BY" VARCHAR2(200 BYTE), 
	"UPDATED_DATE" DATE, 
	"CUST_ACCOUNT_ID" VARCHAR2(200 BYTE)
   ) SEGMENT CREATION DEFERRED 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
