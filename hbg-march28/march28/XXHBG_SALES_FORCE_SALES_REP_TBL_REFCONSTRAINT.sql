--------------------------------------------------------
--  Ref Constraints for Table XXHBG_SALES_FORCE_SALES_REP_TBL
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."XXHBG_SALES_FORCE_SALES_REP_TBL" ADD FOREIGN KEY ("SF_TERRITORY_ID")
	  REFERENCES "HBG_INTEGRATION"."XXHBG_SALES_FORCE_TERRITORY_TBL" ("SF_TERRITORY_ID") ENABLE;
