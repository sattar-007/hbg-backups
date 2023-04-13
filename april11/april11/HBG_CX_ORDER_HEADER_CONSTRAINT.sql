--------------------------------------------------------
--  Constraints for Table HBG_CX_ORDER_HEADER
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."HBG_CX_ORDER_HEADER" ADD CONSTRAINT "PK_SYSTEM_ORDER_ID" PRIMARY KEY ("SYSTEM_ORDER_ID")
  USING INDEX "HBG_INTEGRATION"."PK_SYSTEM_ORDER_ID"  ENABLE;
