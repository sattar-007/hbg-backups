--------------------------------------------------------
--  DDL for Index IDX3_HBG_EGP_ITEM_REVISIONS_INTERFACE
--------------------------------------------------------

  CREATE INDEX "HBG_INTEGRATION"."IDX3_HBG_EGP_ITEM_REVISIONS_INTERFACE" ON "HBG_INTEGRATION"."HBG_EGP_ITEM_REVISIONS_INTERFACE" ("BATCH_ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
