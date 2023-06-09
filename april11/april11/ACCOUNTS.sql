--------------------------------------------------------
--  DDL for Table ACCOUNTS
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."ACCOUNTS" 
   (	"DISCOUNT" VARCHAR2(200 BYTE), 
	"PRICE" VARCHAR2(200 BYTE)
   ) SEGMENT CREATION DEFERRED 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."ACCOUNTS" TO "RO_HBG_INTEGRATION";
