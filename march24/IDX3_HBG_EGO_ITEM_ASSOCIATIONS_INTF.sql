--------------------------------------------------------
--  DDL for Index IDX3_HBG_EGO_ITEM_ASSOCIATIONS_INTF
--------------------------------------------------------

  CREATE INDEX "HBG_INTEGRATION"."IDX3_HBG_EGO_ITEM_ASSOCIATIONS_INTF" ON "HBG_INTEGRATION"."HBG_EGO_ITEM_ASSOCIATIONS_INTF" ("BATCH_ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
