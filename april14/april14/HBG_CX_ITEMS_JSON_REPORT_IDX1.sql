--------------------------------------------------------
--  DDL for Index HBG_CX_ITEMS_JSON_REPORT_IDX1
--------------------------------------------------------

  CREATE INDEX "HBG_INTEGRATION"."HBG_CX_ITEMS_JSON_REPORT_IDX1" ON "HBG_INTEGRATION"."HBG_CX_ITEMS_JSON_REPORT" ("LINE_NUMBER", "INSTANCEID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "HBG_TS_DEBUG" ;
