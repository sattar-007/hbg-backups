--------------------------------------------------------
--  DDL for Index IDX2_HBG_EGP_ITEM_REVISIONS_INTERFACE
--------------------------------------------------------

  CREATE INDEX "HBG_INTEGRATION"."IDX2_HBG_EGP_ITEM_REVISIONS_INTERFACE" ON "HBG_INTEGRATION"."HBG_EGP_ITEM_REVISIONS_INTERFACE" ("ORGANIZATION_CODE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
