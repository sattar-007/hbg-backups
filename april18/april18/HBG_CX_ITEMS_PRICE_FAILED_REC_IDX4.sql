--------------------------------------------------------
--  DDL for Index HBG_CX_ITEMS_PRICE_FAILED_REC_IDX4
--------------------------------------------------------

  CREATE INDEX "HBG_INTEGRATION"."HBG_CX_ITEMS_PRICE_FAILED_REC_IDX4" ON "HBG_INTEGRATION"."HBG_CX_ITEMS_PRICE_FAILED_REC" ("LINE_NUMBER", "INSTANCEID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
