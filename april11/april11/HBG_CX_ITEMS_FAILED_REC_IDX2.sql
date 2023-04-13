--------------------------------------------------------
--  DDL for Index HBG_CX_ITEMS_FAILED_REC_IDX2
--------------------------------------------------------

  CREATE INDEX "HBG_INTEGRATION"."HBG_CX_ITEMS_FAILED_REC_IDX2" ON "HBG_INTEGRATION"."HBG_CX_ITEMS_FAILED_REC" ("LINE_NUMBER", "INSTANCEID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "HBG_TS_DEBUG" ;
