--------------------------------------------------------
--  DDL for Type HBG_SO_HOT_TITLE_RT
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "HBG_INTEGRATION"."HBG_SO_HOT_TITLE_RT" FORCE AS OBJECT (
    sourceordersystem     VARCHAR2(200),
    sourceorderid         VARCHAR2(200),
    sourcelineid          VARCHAR2(200),
    sourceholdcode        VARCHAR2(200),
    holdreleasereasoncode VARCHAR2(200),
    holdcomments          VARCHAR2(2000),
    sourcenumber          VARCHAR2(200),
    sourceorderlineid     VARCHAR2(200),
    CONSTRUCTOR FUNCTION hbg_so_hot_title_rt RETURN SELF AS RESULT
);
/
CREATE OR REPLACE EDITIONABLE TYPE BODY "HBG_INTEGRATION"."HBG_SO_HOT_TITLE_RT" 
AS
    CONSTRUCTOR FUNCTION hbg_so_hot_title_rt
        RETURN SELF AS RESULT
    AS
    BEGIN
        RETURN;
    END;
END;

/
