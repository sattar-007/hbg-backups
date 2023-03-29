--------------------------------------------------------
--  Constraints for Table HBG_CX_ITEMS_COLLECTIONS
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."HBG_CX_ITEMS_COLLECTIONS" ADD PRIMARY KEY ("COLLECTION_ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "HBG_INTEGRATION_TS_DATA"  ENABLE;
