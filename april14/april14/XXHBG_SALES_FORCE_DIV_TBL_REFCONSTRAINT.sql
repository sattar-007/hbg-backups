--------------------------------------------------------
--  Ref Constraints for Table XXHBG_SALES_FORCE_DIV_TBL
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."XXHBG_SALES_FORCE_DIV_TBL" ADD FOREIGN KEY ("SALES_FORCE_ID")
	  REFERENCES "HBG_INTEGRATION"."XXHBG_SALES_FORCE_MAINTENANCE_TBL" ("SALES_FORCE_ID") ENABLE;
