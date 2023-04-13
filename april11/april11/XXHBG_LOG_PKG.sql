--------------------------------------------------------
--  DDL for Package XXHBG_LOG_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "HBG_INTEGRATION"."XXHBG_LOG_PKG" AS
   
    level_fatal CONSTANT VARCHAR2 (20) := 'FATAL';
    level_severe CONSTANT VARCHAR2(20) := 'SEVERE';
    level_warning CONSTANT VARCHAR2(20) := 'WARNING';
    level_info CONSTANT VARCHAR2(20) := 'INFO';
    level_fine CONSTANT VARCHAR2(20) := 'FINE';
    level_finer CONSTANT VARCHAR2(20) := 'FINER';
    default_retention_period   CONSTANT NUMBER := 90;

    /*
       Adds an FINER level log statement
    */
    PROCEDURE add_finer_log (p_module       IN VARCHAR2,
        p_package      IN VARCHAR2,
        p_procedure    IN VARCHAR2,
        p_text         IN VARCHAR2,
        p_process_id   IN NUMBER
    );

    /*
       Adds an FINER level log for a huge statement like payloads,sql statements etc
    */
    PROCEDURE add_finer_log_clob (
        p_module       IN VARCHAR2,
        p_package      IN VARCHAR2,
        p_procedure    IN VARCHAR2,
        p_text         IN CLOB,
        p_process_id   IN NUMBER
    );

    /*
       Adds an FINE level log statement
    */
    PROCEDURE add_fine_log (p_module       IN VARCHAR2,
        p_package      IN VARCHAR2,
        p_procedure    IN VARCHAR2,
        p_text         IN VARCHAR2,
        p_process_id   IN NUMBER
    );

    /*
       Adds an FINE level log for a huge statement like payloads,sql statements etc
    */
    PROCEDURE add_fine_log_clob (
        p_module       IN VARCHAR2,
        p_package      IN VARCHAR2,
        p_procedure    IN VARCHAR2,
        p_text         IN CLOB,
        p_process_id   IN NUMBER
    );

    /*
       Adds an INFO level log statement
    */
    PROCEDURE add_info_log (p_module       IN VARCHAR2,
        p_package      IN VARCHAR2,
        p_procedure    IN VARCHAR2,
        p_text         IN VARCHAR2,
        p_process_id   IN NUMBER
    );

    /*
       Adds an INFO level log for a huge statement like payloads,sql statements etc
    */
    PROCEDURE add_info_log_clob (
        p_module       IN VARCHAR2,
        p_package      IN VARCHAR2,
        p_procedure    IN VARCHAR2,
        p_text         IN CLOB,
        p_process_id   IN NUMBER
    );

    /*
       Adds an WARNING level log statement
    */
    PROCEDURE add_warning_log (
        p_module       IN VARCHAR2,
        p_package      IN VARCHAR2,
        p_procedure    IN VARCHAR2,
        p_text         IN VARCHAR2,
        p_process_id   IN NUMBER
    );

    /*
       Adds an WARNING level log for a huge statement like payloads,sql statements etc
    */
    PROCEDURE add_warning_log_clob (
        p_module       IN VARCHAR2,
        p_package      IN VARCHAR2,
        p_procedure    IN VARCHAR2,
        p_text         IN CLOB,
        p_process_id   IN NUMBER
    );

    /*
       Adds an SEVERE level log statement
    */
    PROCEDURE add_severe_log (
        p_module       IN VARCHAR2,
        p_package      IN VARCHAR2,
        p_procedure    IN VARCHAR2,
        p_text         IN VARCHAR2,
        p_process_id   IN NUMBER
    );

    /*
       Adds an SEVERE level log for a huge statement like payloads,sql statements etc
    */
    PROCEDURE add_severe_log_clob (
        p_module       IN VARCHAR2,
        p_package      IN VARCHAR2,
        p_procedure    IN VARCHAR2,
        p_text         IN CLOB,
        p_process_id   IN NUMBER
    );

    /*
       Adds an FATAL level log statement
    */
    PROCEDURE add_fatal_log (p_module       IN VARCHAR2,
        p_package      IN VARCHAR2,
        p_procedure    IN VARCHAR2,
        p_text         IN VARCHAR2,
        p_process_id   IN NUMBER
    );

    /*
       Adds an FINER level log for a huge statement like payloads,sql statements etc
    */
    PROCEDURE add_fatal_log_clob (
        p_module       IN VARCHAR2,
        p_package      IN VARCHAR2,
        p_procedure    IN VARCHAR2,
        p_text         IN CLOB,
        p_process_id   IN NUMBER
    );

    /*
        Purges the historical logs.
        This is called by the auto purge program on scheduled basis.
    */
    PROCEDURE purge_logs(p_retention_period_in_days IN NUMBER);
END xxhbg_log_pkg;

/
