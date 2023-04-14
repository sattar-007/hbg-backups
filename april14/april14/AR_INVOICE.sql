--------------------------------------------------------
--  DDL for Table AR_INVOICE
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."AR_INVOICE" 
   (	"BUSINESS_UNIT" VARCHAR2(200 BYTE), 
	"CUSTOMER_NAME" VARCHAR2(200 BYTE), 
	"INVOICE_NUMBER" NUMBER, 
	"CUSTOMER_SITE" VARCHAR2(200 BYTE), 
	"INVOICE_AMOUNT" NUMBER, 
	"INVOICE_DATE" NUMBER, 
	"PAYMENT_STATUS" VARCHAR2(200 BYTE)
   ) SEGMENT CREATION DEFERRED 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."AR_INVOICE" TO "RO_HBG_INTEGRATION";
