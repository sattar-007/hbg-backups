--------------------------------------------------------
--  Ref Constraints for Table EMP
--------------------------------------------------------

  ALTER TABLE "HBG_INTEGRATION"."EMP" ADD FOREIGN KEY ("MGR")
	  REFERENCES "HBG_INTEGRATION"."EMP" ("EMPNO") ENABLE;
  ALTER TABLE "HBG_INTEGRATION"."EMP" ADD FOREIGN KEY ("DEPTNO")
	  REFERENCES "HBG_INTEGRATION"."DEPT" ("DEPTNO") ENABLE;
