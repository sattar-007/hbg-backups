--------------------------------------------------------
--  Ref Constraints for Table XXHBG_ASSIGN_DISTRUBUTION_CHANNEL_TBL
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."XXHBG_ASSIGN_DISTRUBUTION_CHANNEL_TBL" ADD FOREIGN KEY ("DIST_CHANNEL_ID")
	  REFERENCES "HBG_INTEGRATION"."XXHBG_DISTRUBUTION_CHANNEL_TBL" ("DIST_CHANNEL_ID") ENABLE;
