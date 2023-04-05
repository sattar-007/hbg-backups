--------------------------------------------------------
--  DDL for Table HBG_CX_ITEMS_PRICE_JSON_REPORT
--------------------------------------------------------

  CREATE TABLE "HBG_INTEGRATION"."HBG_CX_ITEMS_PRICE_JSON_REPORT" 
   (	"COMMENTS" VARCHAR2(4000 BYTE), 
	"LINE_NUMBER" NUMBER, 
	"INSTANCEID" NUMBER
   ) SEGMENT CREATION DEFERRED 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
  GRANT SELECT ON "HBG_INTEGRATION"."HBG_CX_ITEMS_PRICE_JSON_REPORT" TO "RO_HBG_INTEGRATION";
