--------------------------------------------------------
--  DDL for Package Body XXHBG_LOG_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."XXHBG_LOG_PKG" 
AS
  
    TYPE number_array IS TABLE OF NUMBER
        INDEX BY BINARY_INTEGER;

    FUNCTION is_debug_mode (p_module IN VARCHAR2, p_log_level IN VARCHAR2)
        RETURN VARCHAR2
    IS
        l_log_conf_level       VARCHAR2 (50) := level_warning;
        l_enabled              VARCHAR2 (1) := 'Y';
        l_log_level_conf_num   NUMBER;
        l_log_level_num        NUMBER;
    BEGIN
        BEGIN
            SELECT log_level, enabled
              INTO l_log_conf_level, l_enabled
              FROM xxhbg_logs_config
             WHERE module = p_module;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                l_log_conf_level := level_warning;
                l_enabled := 'Y';
            WHEN OTHERS
            THEN
                l_log_conf_level := level_warning;
                l_enabled := 'Y';
        END;

        IF (l_enabled = 'Y')
        THEN
            SELECT DECODE (l_log_conf_level,
                           level_fatal, 6,
                           level_severe, 5,
                           level_warning, 4,
                           level_info, 3,
                           level_fine, 2,
                           level_finer, 1,
                           level_warning),
                   DECODE (p_log_level,
                           level_fatal, 6,
                           level_severe, 5,
                           level_warning, 4,
                           level_info, 3,
                           level_fine, 2,
                           level_finer, 1,
                           level_warning)
              INTO l_log_level_conf_num, l_log_level_num
              FROM DUAL;

            IF (l_log_level_num >= l_log_level_conf_num)
            THEN
        RETURN 'Y';
            ELSE
                RETURN 'N';
            END IF;
        ELSE
            RETURN 'N';
        END IF;
    END is_debug_mode;

    PROCEDURE add_log (p_module       IN VARCHAR2 DEFAULT NULL,
                       p_package      IN VARCHAR2,
                       p_procedure    IN VARCHAR2,
                       p_text         IN VARCHAR2,
                       p_text_clob    IN CLOB,
                       p_level        IN VARCHAR2,
                       p_process_id   IN NUMBER DEFAULT 1,
                       p_email_yn     IN VARCHAR2 DEFAULT 'Y')
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        IF NVL (is_debug_mode (p_module, p_level), 'N') = 'Y'
        THEN
--        null;
            INSERT INTO xxhbg_logs (log_id,
                                    module,
                                    package,
                                    procedure,
                                    log_level,
                                    MESSAGE_TEXT,
                                    message_clob,
                                    creation_date,
                                    process_id)
                 VALUES (xxhbg_log_id_seq.NEXTVAL,
                         UPPER(p_module),
                         UPPER(p_package),
                         UPPER(p_procedure),
                         p_level,
                         SUBSTR(p_text,1,4000),
                         p_text_clob,
                         SYSTIMESTAMP,
                         p_process_id);

            COMMIT;
        END IF;
    END add_log;

    PROCEDURE add_finer_log (p_module       IN VARCHAR2,
                            p_package      IN VARCHAR2,
                            p_procedure    IN VARCHAR2,
                            p_text         IN VARCHAR2,
                            p_process_id   IN NUMBER)
    IS
    BEGIN
        add_log (p_module       => p_module,
                 p_package      => p_package,
                 p_procedure    => p_procedure,
                 p_text         => SUBSTR(p_text,1,4000),
                 p_text_clob    => NULL,
                 p_process_id   => p_process_id,
                 p_level        => level_finer);
    END add_finer_log;

    PROCEDURE add_finer_log_clob (p_module       IN VARCHAR2,
                                 p_package      IN VARCHAR2,
                                 p_procedure    IN VARCHAR2,
                                 p_text         IN CLOB,
                                 p_process_id   IN NUMBER)
    IS
    BEGIN
        add_log (p_module       => p_module,
                 p_package      => p_package,
                 p_procedure    => p_procedure,
                 p_text         => NULL,
                 p_text_clob    => p_text,
                 p_process_id   => p_process_id,
                 p_level        => level_finer);
    END add_finer_log_clob;

    PROCEDURE add_fine_log (p_module       IN VARCHAR2,
                            p_package      IN VARCHAR2,
                            p_procedure    IN VARCHAR2,
                            p_text         IN VARCHAR2,
                            p_process_id   IN NUMBER)
    IS
    BEGIN
        add_log (p_module       => p_module,
                 p_package      => p_package,
                 p_procedure    => p_procedure,
                 p_text         => SUBSTR(p_text,1,4000),
                 p_text_clob    => NULL,
                 p_process_id   => p_process_id,
                 p_level        => level_fine);
    END add_fine_log;

    PROCEDURE add_fine_log_clob (p_module       IN VARCHAR2,
                                 p_package      IN VARCHAR2,
                                 p_procedure    IN VARCHAR2,
                                 p_text         IN CLOB,
                                 p_process_id   IN NUMBER)
    IS
    BEGIN
        add_log (p_module       => p_module,
                 p_package      => p_package,
                 p_procedure    => p_procedure,
                 p_text         => NULL,
                 p_text_clob    => p_text,
                 p_process_id   => p_process_id,
                 p_level        => level_fine);
    END add_fine_log_clob;

    PROCEDURE add_info_log (p_module       IN VARCHAR2,
                            p_package      IN VARCHAR2,
                            p_procedure    IN VARCHAR2,
                            p_text         IN VARCHAR2,
                            p_process_id   IN NUMBER)
    IS
    BEGIN
        add_log (p_module       => p_module,
                 p_package      => p_package,
                 p_procedure    => p_procedure,
                 p_text         => SUBSTR(p_text,1,4000),
                 p_text_clob    => NULL,
                 p_process_id   => p_process_id,
                 p_level        => level_info);
    END add_info_log;

    PROCEDURE add_info_log_clob (p_module       IN VARCHAR2,
                                 p_package      IN VARCHAR2,
                                 p_procedure    IN VARCHAR2,
                                 p_text         IN CLOB,
                                 p_process_id   IN NUMBER)
    IS
    BEGIN
        add_log (p_module       => p_module,
                 p_package      => p_package,
                 p_procedure    => p_procedure,
                 p_text         => NULL,
                 p_text_clob    => p_text,
                 p_process_id   => p_process_id,
                 p_level        => level_info);
    END add_info_log_clob;

    PROCEDURE add_warning_log (p_module       IN VARCHAR2,
                               p_package      IN VARCHAR2,
                               p_procedure    IN VARCHAR2,
                               p_text         IN VARCHAR2,
                               p_process_id   IN NUMBER)
    IS
    BEGIN
        add_log (p_module       => p_module,
                 p_package      => p_package,
                 p_procedure    => p_procedure,
                 p_text         => p_text,
                 p_text_clob    => NULL,
                 p_process_id   => p_process_id,
                 p_level        => level_warning);
    END add_warning_log;

    PROCEDURE add_warning_log_clob (p_module       IN VARCHAR2,
                                    p_package      IN VARCHAR2,
                                    p_procedure    IN VARCHAR2,
                                    p_text         IN CLOB,
                                    p_process_id   IN NUMBER)
    IS
    BEGIN
        add_log (p_module       => p_module,
                 p_package      => p_package,
                 p_procedure    => p_procedure,
                 p_text         => NULL,
                 p_text_clob    => p_text,
                 p_process_id   => p_process_id,
                 p_level        => level_warning);
    END add_warning_log_clob;

    PROCEDURE add_severe_log (p_module       IN VARCHAR2,
                              p_package      IN VARCHAR2,
                              p_procedure    IN VARCHAR2,
                              p_text         IN VARCHAR2,
                              p_process_id   IN NUMBER)
    IS
    BEGIN
        add_log (p_module       => p_module,
                 p_package      => p_package,
                 p_procedure    => p_procedure,
                 p_text         => p_text,
                 p_text_clob    => NULL,
                 p_process_id   => p_process_id,
                 p_level        => level_severe);
    END add_severe_log;

    PROCEDURE add_fatal_log (p_module       IN VARCHAR2,
                            p_package      IN VARCHAR2,
                            p_procedure    IN VARCHAR2,
                            p_text         IN VARCHAR2,
                            p_process_id   IN NUMBER)
    IS
    BEGIN
        add_log (p_module       => p_module,
                 p_package      => p_package,
                 p_procedure    => p_procedure,
                 p_text         => SUBSTR(p_text,1,4000),
                 p_text_clob    => NULL,
                 p_process_id   => p_process_id,
                 p_level        => level_fatal);
    END add_fatal_log;

    PROCEDURE add_fatal_log_clob (p_module       IN VARCHAR2,
                                 p_package      IN VARCHAR2,
                                 p_procedure    IN VARCHAR2,
                                 p_text         IN CLOB,
                                 p_process_id   IN NUMBER)
    IS
    BEGIN
        add_log (p_module       => p_module,
                 p_package      => p_package,
                 p_procedure    => p_procedure,
                 p_text         => NULL,
                 p_text_clob    => p_text,
                 p_process_id   => p_process_id,
                 p_level        => level_fatal);
    END add_fatal_log_clob;

    PROCEDURE add_severe_log_clob (p_module       IN VARCHAR2,
                                   p_package      IN VARCHAR2,
                                   p_procedure    IN VARCHAR2,
                                   p_text         IN CLOB,
                                   p_process_id   IN NUMBER)
    IS
    BEGIN
        add_log (p_module       => p_module,
                 p_package      => p_package,
                 p_procedure    => p_procedure,
                 p_text         => NULL,
                 p_text_clob    => p_text,
                 p_process_id   => p_process_id,
                 p_level        => level_severe);
    END add_severe_log_clob;

    PROCEDURE purge_logs(p_retention_period_in_days IN NUMBER)
    AS
        logid_tbl   number_array;
    BEGIN

        add_info_log (
            p_module       => 'LOG_UTILS',
            p_package      => 'xxhbg_log_pkg',
            p_procedure    => 'purge_logs',
            p_text         => 'Start of purge logs - p_retention_period_in_days ' || p_retention_period_in_days,
            p_process_id   => NULL);

        SELECT log_id
          BULK COLLECT INTO logid_tbl
          FROM xxhbg_logs
         WHERE TRUNC (creation_date) <=
               TRUNC (
                   SYSDATE - NVL (p_retention_period_in_days, default_retention_period));

        FORALL i IN logid_tbl.FIRST .. logid_tbl.LAST
            DELETE FROM xxhbg_logs
                  WHERE log_id = logid_tbl (i);

        add_info_log (
            p_module       => 'LOG_UTILS',
            p_package      => 'xxhbg_log_pkg',
            p_procedure    => 'archive_logs',
            p_text         => 'Number of historical logs cleaned up ' || logid_tbl.COUNT,
            p_process_id   => NULL);
    EXCEPTION
        WHEN OTHERS
        THEN
            add_severe_log (
                p_module       => 'LOG_UTILS',
                p_package      => 'xxhbg_log_pkg',
                p_procedure    => 'archive_logs',
                p_text         =>
                    'Cleaning up the historical logs failed due to ' || SQLERRM,
                p_process_id   => NULL);
    END purge_logs;
END xxhbg_log_pkg;

/
