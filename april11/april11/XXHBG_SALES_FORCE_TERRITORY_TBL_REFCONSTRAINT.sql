--------------------------------------------------------
--  Ref Constraints for Table XXHBG_SALES_FORCE_TERRITORY_TBL
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."XXHBG_SALES_FORCE_TERRITORY_TBL" ADD FOREIGN KEY ("SF_DIV_ID")
	  REFERENCES "HBG_INTEGRATION"."XXHBG_SALES_FORCE_DIV_TBL" ("SF_DIV_ID") ENABLE;
