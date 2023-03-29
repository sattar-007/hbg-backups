--------------------------------------------------------
--  Constraints for Table DOO_LINES_EFF_B
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."DOO_LINES_EFF_B" ADD CONSTRAINT "DOO_LINES_EFF_B_PK" PRIMARY KEY ("EFF_LINE_ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  TABLESPACE "HBG_INTEGRATION_TS_DATA"  ENABLE;
