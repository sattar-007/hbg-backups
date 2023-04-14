--------------------------------------------------------
--  DDL for Index IDX4_HBG_EGP_ITEM_ATTACHMENTS_INTF
--------------------------------------------------------

  CREATE INDEX "HBG_INTEGRATION"."IDX4_HBG_EGP_ITEM_ATTACHMENTS_INTF" ON "HBG_INTEGRATION"."HBG_EGP_ITEM_ATTACHMENTS_INTF" ("ITEM_NUMBER", "ORGANIZATION_CODE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
