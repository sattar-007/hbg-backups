--------------------------------------------------------
--  DDL for Index IDX4_HBG_EGO_ITEM_SUPPLIER_INTF_EFF_TL
--------------------------------------------------------

  CREATE INDEX "HBG_INTEGRATION"."IDX4_HBG_EGO_ITEM_SUPPLIER_INTF_EFF_TL" ON "HBG_INTEGRATION"."HBG_EGO_ITEM_SUPPLIER_INTF_EFF_TL" ("ITEM_NUMBER", "ORGANIZATION_CODE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "HBG_INTEGRATION_TS_DATA" ;
