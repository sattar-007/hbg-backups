--------------------------------------------------------
--  DDL for Package AS_SFTP_KEYMGMT_SECURITY
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."AS_SFTP_KEYMGMT_SECURITY" 
AS
    --
    -- These control access to records in the table as_sftp_private_keys
    --
    FUNCTION user_data_select_security (owner VARCHAR2, objname VARCHAR2)
    RETURN VARCHAR2;
    FUNCTION user_data_insert_security (owner VARCHAR2, objname VARCHAR2)
    RETURN VARCHAR2;
    FUNCTION user_data_update_security (owner VARCHAR2, objname VARCHAR2)
    RETURN VARCHAR2;
    FUNCTION user_data_delete_security (owner VARCHAR2, objname VARCHAR2)
    RETURN VARCHAR2;
END as_sftp_keymgmt_security;


/

  GRANT EXECUTE ON "HBG_INTEGRATION"."AS_SFTP_KEYMGMT_SECURITY" TO PUBLIC;
