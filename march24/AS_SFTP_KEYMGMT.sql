--------------------------------------------------------
--  DDL for Package AS_SFTP_KEYMGMT
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."AS_SFTP_KEYMGMT" AS
    --
    -- Important! The private key lookup is case sensitive on i_host and i_user.
    --
    -- Does both open_connection and login with private key
    --
    PROCEDURE login(
         i_user         VARCHAR2
        ,i_host         VARCHAR2
        ,i_port         NUMBER
        ,i_trust_server BOOLEAN := FALSE
        ,i_passphrase   VARCHAR2 := NULL
        ,i_log_level    pls_integer := null
    );
-- comment out this function when done testing. It should not be public
    --FUNCTION get_priv_key(i_host VARCHAR2, i_user VARCHAR2) RETURN CLOB;
    --
    -- When keymgmt_security is activated (fine grained access control)
    -- These three methods are the only way to manipuate the data in the table as_sftp_private_keys
    -- other than to truncate it or do the task as sysdba.
    -- You cannot read the data at all as get_priv_key is a private function that only login() can call.
    --
    PROCEDURE insert_priv_key(i_host VARCHAR2, i_user VARCHAR2, i_key CLOB);
    PROCEDURE update_priv_key(i_host VARCHAR2, i_user VARCHAR2, i_key CLOB);
    PROCEDURE delete_priv_key(i_host VARCHAR2, i_user VARCHAR2);
END as_sftp_keymgmt;


/
