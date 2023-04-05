--------------------------------------------------------
--  Constraints for Table HBG_CX_ORDERS_JOB_TRACKER
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."HBG_CX_ORDERS_JOB_TRACKER" ADD PRIMARY KEY ("INSTANCEID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "HBG_INTEGRATION_TS_DATA"  ENABLE;
