--------------------------------------------------------
--  DDL for Package Body XXHBG_SAAS_DATA_SYNC
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "HBG_INTEGRATION"."XXHBG_SAAS_DATA_SYNC" 
AS
    TYPE dbtable_rec IS RECORD
    (
        column_name    VARCHAR2 (30),
        data_type      VARCHAR2 (30),
        data_length    NUMBER
    );

    TYPE dbtable_tbl_type IS TABLE OF dbtable_rec
        INDEX BY BINARY_INTEGER;

    TYPE varchar240tabtype IS TABLE OF VARCHAR2 (240);

    TYPE number_array IS TABLE OF NUMBER
        INDEX BY BINARY_INTEGER;

    xml_timestamp_format          VARCHAR2 (100) := 'YYYY-MM-DD"T"HH24:MI:SS.FF9tzh:tzm';
    xml_timestamp_format_quotes   VARCHAR2 (100)
                                      := '''YYYY-MM-DD"T"HH24:MI:SS.FF9tzh:tzm''';
    datetime_format               VARCHAR2 (100) := 'YYYY-MM-DD HH24:MI:SS';
    datetime_format_quotes        VARCHAR2 (100) := '''YYYY-MM-DD HH24:MI:SS''';

    -- PROCEDURE put_info_log (p_proc IN VARCHAR2, p_message IN CLOB);

    PROCEDURE put_info_log (p_proc IN VARCHAR2, p_message IN CLOB)
    IS
    BEGIN
        xxhbg_log_pkg.add_info_log_clob (p_module       => 'SAAS DATA SYNC',
                                         p_package      => 'xxhbg_SAAS_DATA_SYNC',
                                         p_procedure    => p_proc,
                                         p_text         => p_message,
                                         p_process_id   => NULL);
    END put_info_log;

    --  PROCEDURE put_severe_log (p_proc IN VARCHAR2, p_message IN CLOB);

    PROCEDURE put_severe_log (p_proc IN VARCHAR2, p_message IN CLOB)
    IS
    BEGIN
        xxhbg_log_pkg.add_severe_log_clob (p_module       => 'SAAS DATA SYNC',
                                           p_package      => 'xxhbg_SAAS_DATA_SYNC',
                                           p_procedure    => p_proc,
                                           p_text         => p_message,
                                           p_process_id   => NULL);
    END put_severe_log;

    FUNCTION ready_for_sync (p_freq_type       IN VARCHAR2,
                             p_freq_value      IN NUMBER,
                             p_last_run_date   IN TIMESTAMP)
        RETURN VARCHAR2
    AS
        v_return_flag           VARCHAR2 (1) := 'N';
        v_time_in_millis        NUMBER := 0;
        v_time_in_sec           NUMBER := 0;
        v_sec_in_day            NUMBER := 24 * 60 * 60;
        v_time_in_days          NUMBER (10, 15) := 0.0;
        v_diff_time_in_millis   NUMBER := 0;
    BEGIN
        -- Days
        IF p_freq_type = 'DAY'
        THEN
            v_time_in_sec := p_freq_value * 24 * 60 * 60;
        -- Hourly
        ELSIF p_freq_type = 'HOUR'
        THEN
            v_time_in_sec := p_freq_value * 60 * 60;
        -- Minutes
        ELSIF p_freq_type = 'MINUTE'
        THEN
            v_time_in_sec := p_freq_value * 60;
        -- Seconds
        ELSIF p_freq_type = 'SECOND'
        THEN
            v_time_in_sec := p_freq_value;
        END IF;

        IF (p_last_run_date IS NULL)
        THEN
            v_return_flag := 'Y';
        END IF;

        SELECT   (  (  EXTRACT (
                           DAY FROM SYS_EXTRACT_UTC (SYSTIMESTAMP) - p_last_run_date)
                     * 24
                     * 60
                     * 60)
                  + (  EXTRACT (
                           HOUR FROM SYS_EXTRACT_UTC (SYSTIMESTAMP) - p_last_run_date)
                     * 60
                     * 60)
                  + (  EXTRACT (
                           MINUTE FROM SYS_EXTRACT_UTC (SYSTIMESTAMP) - p_last_run_date)
                     * 60)
                  + EXTRACT (
                        SECOND FROM SYS_EXTRACT_UTC (SYSTIMESTAMP) - p_last_run_date))
               * 1000
          INTO v_diff_time_in_millis
          FROM DUAL;

        --      IF( (sysdate-p_last_run_date)> (v_time_in_sec/v_sec_in_day) ) THEN
        --        v_return_flag                             := 'Y';
        --      END IF;

        IF (v_diff_time_in_millis > (v_time_in_sec * 1000))
        THEN
            v_return_flag := 'Y';
        END IF;

        RETURN v_return_flag;
    END ready_for_sync;


    FUNCTION construct_filters_sql (p_object_id NUMBER)
        RETURN CLOB
    IS
        CURSOR filters_crsr IS
              SELECT column_name, filter_type, filter_value
                FROM xxhbg_saas_data_sync_filters
               WHERE object_id = p_object_id AND enabled = 'Y'
            ORDER BY column_name, filter_type, filter_value;

        l_curr_filter_col_name        VARCHAR2 (100);
        l_curr_filter_type            VARCHAR2 (100);
        l_curr_filter_in_clause       CLOB;
        l_curr_filter_not_in_clause   CLOB;
        l_filter_count                NUMBER := 0;
        l_sql_qry                     CLOB;
    BEGIN
        DBMS_LOB.createtemporary (l_sql_qry, TRUE);
        DBMS_LOB.createtemporary (l_curr_filter_in_clause, TRUE);
        DBMS_LOB.createtemporary (l_curr_filter_not_in_clause, TRUE);
        l_filter_count := 0;
        l_curr_filter_col_name := NULL;
        l_curr_filter_type := NULL;

        FOR filters_rec IN filters_crsr
        LOOP
            l_filter_count := l_filter_count + 1;
            put_info_log (
                p_proc   => 'construct_filters_sql',
                p_message   =>
                       filters_rec.column_name
                    || ' - '
                    || filters_rec.filter_type
                    || ' - '
                    || filters_rec.filter_value);

            IF (l_curr_filter_col_name IS NULL)
            THEN
                l_curr_filter_col_name := filters_rec.column_name;
                l_curr_filter_type := filters_rec.filter_type;

                IF (l_curr_filter_type = 'INCLUDE')
                THEN
                    DBMS_LOB.append (
                        l_curr_filter_in_clause,
                           ' AND '
                        || l_curr_filter_col_name
                        || ' IN ('''
                        || filters_rec.filter_value
                        || '''');
                ELSE
                    DBMS_LOB.append (
                        l_curr_filter_not_in_clause,
                           ' AND '
                        || l_curr_filter_col_name
                        || ' NOT IN ('''
                        || filters_rec.filter_value
                        || '''');
                END IF;
            ELSIF (l_curr_filter_col_name = filters_rec.column_name)
            THEN
                IF (l_curr_filter_type = filters_rec.filter_type)
                THEN
                    DBMS_LOB.append (l_curr_filter_in_clause,
                                     ' , ' || '''' || filters_rec.filter_value || '''');
                ELSE
                    IF (l_curr_filter_type = 'INCLUDE')
                    THEN
                        DBMS_LOB.append (l_curr_filter_in_clause, ')');
                        l_sql_qry := l_sql_qry || l_curr_filter_in_clause;
                    ELSIF (l_curr_filter_type = 'EXCLUDE')
                    THEN
                        DBMS_LOB.append (l_curr_filter_not_in_clause, ')');
                        DBMS_LOB.append (l_sql_qry, l_curr_filter_not_in_clause);
                    END IF;

                    l_curr_filter_col_name := filters_rec.column_name;
                    l_curr_filter_type := filters_rec.filter_type;
                    DBMS_LOB.createtemporary (l_curr_filter_in_clause, TRUE);
                    DBMS_LOB.createtemporary (l_curr_filter_not_in_clause, TRUE);

                    IF (l_curr_filter_type = 'INCLUDE')
                    THEN
                        DBMS_LOB.append (
                            l_curr_filter_in_clause,
                               ' AND '
                            || l_curr_filter_col_name
                            || ' IN ('''
                            || filters_rec.filter_value
                            || '''');
                    ELSIF (l_curr_filter_type = 'EXCLUDE')
                    THEN
                        DBMS_LOB.append (
                            l_curr_filter_not_in_clause,
                               ' AND '
                            || l_curr_filter_col_name
                            || ' NOT IN ('''
                            || filters_rec.filter_value
                            || '''');
                    END IF;
                END IF;
            ELSE
                IF (l_curr_filter_type = 'INCLUDE')
                THEN
                    DBMS_LOB.append (l_curr_filter_in_clause, ')');
                    DBMS_LOB.append (l_sql_qry, l_curr_filter_in_clause);
                ELSIF (l_curr_filter_type = 'EXCLUDE')
                THEN
                    DBMS_LOB.append (l_curr_filter_not_in_clause, ')');
                    DBMS_LOB.append (l_sql_qry, l_curr_filter_not_in_clause);
                END IF;

                l_curr_filter_col_name := filters_rec.column_name;
                l_curr_filter_type := filters_rec.filter_type;
                DBMS_LOB.createtemporary (l_curr_filter_in_clause, TRUE);
                DBMS_LOB.createtemporary (l_curr_filter_not_in_clause, TRUE);

                IF (l_curr_filter_type = 'INCLUDE')
                THEN
                    DBMS_LOB.append (
                        l_curr_filter_in_clause,
                           ' AND '
                        || l_curr_filter_col_name
                        || ' IN ('''
                        || filters_rec.filter_value
                        || '''');
                ELSIF (l_curr_filter_type = 'EXCLUDE')
                THEN
                    DBMS_LOB.append (
                        l_curr_filter_not_in_clause,
                           ' AND '
                        || l_curr_filter_col_name
                        || ' NOT IN ('''
                        || filters_rec.filter_value
                        || '''');
                END IF;
            END IF;
        END LOOP;

        IF (l_filter_count > 0 AND l_curr_filter_type = 'INCLUDE')
        THEN
            DBMS_LOB.append (l_curr_filter_in_clause, ')');
            DBMS_LOB.append (l_sql_qry, l_curr_filter_in_clause);
        ELSIF (l_curr_filter_type = 'EXCLUDE')
        THEN
            DBMS_LOB.append (l_curr_filter_not_in_clause, ')');
            DBMS_LOB.append (l_sql_qry, l_curr_filter_not_in_clause);
        END IF;

        put_info_log (p_proc      => 'construct_filters_sql',
                      p_message   => 'Constructed filters where clause : ' || l_sql_qry);
        RETURN l_sql_qry;
    END construct_filters_sql;


    FUNCTION construct_sql_for_object (p_sync_obj_rec xxhbg_saas_data_sync_conf_rec)
        RETURN CLOB
    IS
        l_sql_lastupd_where_clause   VARCHAR2 (100) := ') TBL where last_update_date >= ';
        l_sql_qry                    CLOB;
        l_sql_prefix                 VARCHAR2 (4000)
            := 'select tbl.*,' || CHR (10) || 'ROW_NUMBER() OVER (';
        l_count                      NUMBER;
        l_last_upd_chk_needed        VARCHAR2 (1);
        l_wildcard_indx_on_sql       NUMBER;
        l_pk_cols_order_clause       VARCHAR2 (1000) := 'ORDER BY ';
    BEGIN
        DBMS_LOB.createtemporary (l_sql_qry, TRUE);

        -- check if default sync mode is full for this object
        IF (p_sync_obj_rec.default_sync_mode = 'FULL')
        THEN
            l_last_upd_chk_needed := 'N';
        ELSE
            -- if last update date is a column in the sql
            IF (DBMS_LOB.INSTR (UPPER (p_sync_obj_rec.sql_query), 'LAST_UPDATE_DATE') > 0)
            THEN
                l_last_upd_chk_needed := 'Y';
            ELSE
                l_last_upd_chk_needed := 'N';
            END IF;

            -- if wildcard is used, check find if last update date is a column on the table

            IF (l_last_upd_chk_needed = 'N')
            THEN
                l_wildcard_indx_on_sql :=
                    DBMS_LOB.INSTR (UPPER (p_sync_obj_rec.sql_query), '*');

                IF (l_wildcard_indx_on_sql > 0)
                THEN
                    --SELECT DECODE (COUNT (*), 1, 'Y', 'N')
                    SELECT DECODE (COUNT (*), 0, 'N', 'Y')
                      INTO l_last_upd_chk_needed
                      FROM all_tab_columns
                     WHERE     table_name = UPPER (TRIM (p_sync_obj_rec.paas_table_name))
                           AND owner = 'HGB_INTEGRATION'
                           AND column_name = 'LAST_UPDATE_DATE';

                    IF (l_last_upd_chk_needed = 'N')
                    THEN
                        put_info_log (
                            p_proc   => 'construct_sql_for_object',
                            p_message   =>
                                   'Skipping entry for '
                                || p_sync_obj_rec.object_name
                                || ' for LAST UPDATE DATE check. SQL query doesnt have LAST_UPDATE_DATE.');
                    END IF;
                END IF;
            END IF;
        END IF;

        -- construct primary key cols

        FOR primary_columns_rec
            IN (  SELECT cols.column_name,
                         cols.position,
                         cons.constraint_name,
                         cons.constraint_type
                    FROM all_constraints cons, all_cons_columns cols
                   WHERE     cols.table_name =
                             UPPER (TRIM (p_sync_obj_rec.paas_table_name))
                         AND cons.constraint_type = 'P'
                         AND cons.constraint_name = cols.constraint_name
                         AND cons.owner = cols.owner
                ORDER BY cols.position)
        LOOP
            l_pk_cols_order_clause :=
                   l_pk_cols_order_clause
                || ' TBL.'
                || primary_columns_rec.column_name
                || ',';
        END LOOP;

        l_pk_cols_order_clause := RTRIM (l_pk_cols_order_clause, ',');
        put_info_log (
            p_proc      => 'construct_sql_for_object',
            p_message   => 'ROW_NUMBER ORDER BY clause :  ' || l_pk_cols_order_clause);
        l_sql_prefix :=
               l_sql_prefix
            || l_pk_cols_order_clause
            || ') rowno '
            || CHR (10)
            || 'FROM ('
            || CHR (10);

        IF (l_last_upd_chk_needed = 'Y')
        THEN
            IF (p_sync_obj_rec.last_run_date IS NOT NULL)
            THEN
                l_sql_qry := l_sql_prefix;
                DBMS_LOB.append (l_sql_qry, p_sync_obj_rec.sql_query);
                DBMS_LOB.append (l_sql_qry, l_sql_lastupd_where_clause);
                DBMS_LOB.append (
                    l_sql_qry,
                       ' TO_TIMESTAMP('''
                    || p_sync_obj_rec.last_run_date
                    || ''','
                    || datetime_format_quotes
                    || ')');

                put_info_log (
                    p_proc   => 'construct_sql_for_object',
                    p_message   =>
                           'Constructed SQL with LAST_UPDATE_DATE check for '
                        || p_sync_obj_rec.object_name
                        || ' is : '
                        || l_sql_qry);
            ELSE
                -- First time synchronization, avoid LAST_UPDATE_DATE check
                l_sql_qry := l_sql_prefix || p_sync_obj_rec.sql_query;
                l_sql_qry := l_sql_qry || ') TBL WHERE 1=1 ';
                put_info_log (
                    p_proc   => 'construct_sql_for_object',
                    p_message   =>
                           'First time synchronization for '
                        || p_sync_obj_rec.object_name
                        || ' , avoiding LAST UPDATE DATE check.');
            END IF;
        ELSE
            l_sql_qry := l_sql_prefix || p_sync_obj_rec.sql_query;
            l_sql_qry := l_sql_qry || ') TBL WHERE 1=1 ';
            put_info_log (p_proc => 'construct_sql_for_object', p_message => l_sql_qry);
        END IF;

        put_info_log (p_proc      => 'construct_sql_for_object',
                      p_message   => 'SQL source - constructed SQL : ' || l_sql_qry);

        -- append filters to SQL
        DBMS_LOB.append (l_sql_qry, construct_filters_sql (p_sync_obj_rec.object_id));

        put_info_log (p_proc      => 'construct_sql_for_object',
                      p_message   => 'Final l_sql_qry : ' || l_sql_qry);
        RETURN l_sql_qry;
    END construct_sql_for_object;



    PROCEDURE fetch_objects_to_be_synced (
        x_sync_objects_tbl   OUT xxhbg_saas_data_sync_conf_tbl)
    IS
    BEGIN
        BEGIN
            x_sync_objects_tbl := xxhbg_saas_data_sync_conf_tbl ();

              SELECT xxhbg_saas_data_sync_conf_rec (object_id,
                                                    object_name,
                                                    NULL,
                                                    paas_table_name,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL,
                                                    NULL)
                BULK COLLECT INTO x_sync_objects_tbl
                FROM xxhbg_saas_data_sync_config conf
               WHERE     enabled = 'Y'
                     AND xxhbg_saas_data_sync.ready_for_sync (frequency_type,
                                                              frequency_value,
                                                              last_run_date) =
                         'Y'
                     AND NOT EXISTS
                             (SELECT 1
                                FROM xxhbg_saas_data_sync_run runs
                               WHERE     conf.object_id = runs.object_id
                                     AND runs.batch_number > 1
                                     AND runs.creation_date >
                                         (SYSDATE - INTERVAL '1' MINUTE))
            ORDER BY priority,last_run_date NULLS FIRST;

            put_info_log (
                p_proc   => 'FETCH_OBJECTS_TO_BE_SYNCED',
                p_message   =>
                    'Number of objects to be synched : ' || x_sync_objects_tbl.COUNT);
        EXCEPTION
            WHEN OTHERS
            THEN
                put_severe_log (
                    p_proc   => 'FETCH_OBJECTS_TO_BE_SYNCED',
                    p_message   =>
                        'Unable to fetch objects to be synched due to ' || SQLERRM);
                RAISE;
        END;
    END fetch_objects_to_be_synced;


    PROCEDURE get_sync_object_info (
        p_object_name       IN     VARCHAR2,
        p_full_sync_flag    IN     VARCHAR2,
        x_status_code          OUT VARCHAR2,
        x_status_msg           OUT VARCHAR2,
        x_sync_object_rec      OUT xxhbg_saas_data_sync_conf_rec)
    IS        
        l_sql_qry                 CLOB;
        l_dm_path                 xxhbg_saas_data_sync_config.bi_data_model_path%TYPE := NULL;
        l_parallel_req_flag       VARCHAR2 (1);
        l_pk_col_count            NUMBER := 0;
        l_paas_table_accessible   VARCHAR2 (1);
    BEGIN
        put_info_log (
            p_proc   => 'get_sync_object_info',
            p_message   =>
                   'Sync object name => '
                || p_object_name
                || ' , p_full_sync_flag => '
                || p_full_sync_flag);
        x_sync_object_rec := xxhbg_saas_data_sync_conf_rec ();

        SELECT xxhbg_saas_data_sync_conf_rec (
                   object_id,
                   object_name,
                   description,
                   paas_table_name,
                   bi_data_model_path,
                   sql_query,
                   enabled,
                   TO_CHAR (last_run_date, datetime_format),
                   frequency_type,
                   frequency_value,
                   offset_frequency_type,
                   offset_frequency_value,
                   CASE
                       WHEN     sync_source = 'SQL'
                            AND bi_data_model_path IS NOT NULL
                            AND LENGTH (TRIM (bi_data_model_path)) > 0
                       THEN
                           'DM'
                       ELSE
                           sync_source
                   END,
                   default_sync_mode,
                   NVL (batch_size, default_batch_size))
          INTO x_sync_object_rec
          FROM xxhbg_saas_data_sync_config
         WHERE enabled = 'Y' AND UPPER (object_name) = UPPER (TRIM (p_object_name));

        -- check if the paas table exists and has PK configured
        BEGIN
            SELECT 'Y'
              INTO l_paas_table_accessible
              FROM all_tables
             WHERE table_name = x_sync_object_rec.paas_table_name;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                x_status_code := 'E';
                x_status_msg :=
                    'Unable to find the corresponding PaaS table for this object. Please make sure that the table exists and is accessible.';
                RETURN;
        END;

        -- check if the paas table has PK columns configured
        BEGIN
            SELECT COUNT (1)
              INTO l_pk_col_count
              FROM all_constraints cons, all_cons_columns cols
             WHERE     cols.table_name = x_sync_object_rec.paas_table_name
                   AND cons.constraint_type = 'P'
                   AND cons.constraint_name = cols.constraint_name
                   AND cons.owner = cols.owner;

            IF (l_pk_col_count = 0)
            THEN
                x_status_code := 'E';
                x_status_msg :=
                    'PaaS table does not have a primary key configured. Please address it before you make an attempt to sync it.';
                RETURN;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                x_status_code := 'E';
                x_status_msg :=
                    'PaaS table does not have a primary key configured. Please address it before you sync it.';
                RETURN;
        END;

        --check if another sync run in progess
        IF (   x_sync_object_rec.default_sync_mode = 'FULL'
            OR p_full_sync_flag = 'Y'
            OR (    x_sync_object_rec.default_sync_mode = 'DELTA'
                AND x_sync_object_rec.offset_frequency_type IN ('DAY', 'HOUR', 'MINUTE')))
        THEN
            put_info_log (
                p_proc   => 'get_sync_object_info',
                p_message   =>
                    'Checking for parallel request run for object ' || p_object_name);

            BEGIN
                SELECT 'Y'
                  INTO l_parallel_req_flag
                  FROM DUAL
                 WHERE EXISTS
                           (SELECT 1
                              FROM xxhbg_saas_data_sync_run runs
                             WHERE     runs.object_id = x_sync_object_rec.object_id
                                   AND runs.batch_number > 1
                                   AND runs.creation_date >
                                       (SYSDATE - INTERVAL '10' SECOND));

                put_info_log (
                    p_proc   => 'get_sync_object_info',
                    p_message   =>
                        'Another request to sync the object is in progres. Skipping this request.');

                x_status_code := 'E';
                x_status_msg :=
                    'Another request to sync this object is in progres. Please try after sometime';
                RETURN;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    put_info_log (
                        p_proc   => 'get_sync_object_info',
                        p_message   =>
                            'No parallel request in progess. Continuing with this request.');
                WHEN OTHERS
                THEN
                    put_severe_log (
                        p_proc   => 'get_sync_object_info',
                        p_message   =>
                            'Parallel sync request check has failed due to : ' || SQLERRM);
            END;
        END IF;


        DBMS_LOB.createtemporary (l_sql_qry, TRUE);
        l_sql_qry := '';        

        -- check if default sync mode is full for this object
        IF (x_sync_object_rec.default_sync_mode = 'FULL' OR p_full_sync_flag = 'Y')
        THEN
            x_sync_object_rec.default_sync_mode := 'FULL';

            UPDATE xxhbg_saas_data_sync_config
               SET last_run_date = NULL
             WHERE object_id = x_sync_object_rec.object_id;

            x_sync_object_rec.last_run_date := NULL;
            put_info_log (
                p_proc   => 'get_sync_object_info',
                p_message   =>
                    'Default sync mode is FULL, resetting the last run date to null');
        END IF;

        IF (   x_sync_object_rec.last_run_date IS NOT NULL
            OR LENGTH (TRIM (x_sync_object_rec.last_run_date)) > 0)
        THEN
            put_info_log (
                p_proc   => 'get_sync_object_info',
                p_message   =>
                    'Last run date in UTC : ' || x_sync_object_rec.last_run_date);

            x_sync_object_rec.last_run_date :=
                TO_CHAR (
                      TO_DATE (x_sync_object_rec.last_run_date, datetime_format)
                    - NUMTODSINTERVAL (
                          NVL (x_sync_object_rec.offset_frequency_value,
                               default_offset_value),
                          NVL (x_sync_object_rec.offset_frequency_type,
                               default_offset_type)),
                    datetime_format);

            put_info_log (
                p_proc   => 'get_sync_object_info',
                p_message   =>
                       'After adding precautionary offset : '
                    || x_sync_object_rec.last_run_date);
        END IF;

        -- SYNC SOURCE is SQL
        IF (x_sync_object_rec.sync_source = 'SQL')
        THEN
            l_sql_qry := construct_sql_for_object (x_sync_object_rec);
            x_sync_object_rec.sql_query := l_sql_qry;
        END IF;

        x_status_code := 'S';
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            put_severe_log (
                p_proc   => 'get_sync_object_info',
                p_message   =>
                    'Invalid object name has been passed. Please make sure that the requested object does exist on the config table.');
            x_status_code := 'E';
            x_status_msg :=
                'Invalid object name has been passed. Please make sure that the requested object does exist on the config table.';
        WHEN OTHERS
        THEN
            put_severe_log (
                p_proc   => 'get_sync_object_info',
                p_message   =>
                       'Unable to fetch sync object info due to an unknown error '
                    || SQLERRM);
            x_status_code := 'E';
            x_status_msg :=
                'Unable to fetch sync object info due to an unknown error ' || SQLERRM;
    END get_sync_object_info;

    PROCEDURE sync_saas_data (p_object_id         IN     NUMBER,
                              p_full_sync_flag    IN     VARCHAR2,
                              p_resp_xmltype      IN     XMLTYPE,
                              p_batch_num         IN     NUMBER,
                              p_sync_start_time   IN     VARCHAR2,
                              x_rows_merged          OUT NUMBER,
                              x_has_more_data        OUT VARCHAR2,
                              x_status_code          OUT VARCHAR2,
                              x_status_msg           OUT VARCHAR2)
    IS
        CURSOR dbtable_csr (p_db_table_name IN VARCHAR2)
        IS
            SELECT column_name, data_type, data_length
              FROM all_tab_columns
             WHERE table_name = UPPER (TRIM (p_db_table_name)) AND owner = 'HBG_INTEGRATION';

        l_xml_recs_cnt             NUMBER;
        l_object_name              xxhbg_saas_data_sync_config.object_name%TYPE;
        l_db_table_name            xxhbg_saas_data_sync_config.paas_table_name%TYPE;
        l_primary_key_col_cnt      NUMBER := 0;
        l_col_count                NUMBER := 0;
        l_pk_col_names             varchar240tabtype := varchar240tabtype ();
        l_dbtable_tbl              dbtable_tbl_type;
        l_merge_prefix             VARCHAR2 (32767);
        l_merge_on_clause          VARCHAR2 (32767);
        l_xmltable_select_clause   CLOB;
        l_xmltable_tags_clause     CLOB;
        l_update_clause            CLOB;
        l_insert_cols_clause       CLOB;
        l_insert_values_clause     CLOB;
        l_merge_statement          CLOB;
        l_curr_run_id              NUMBER;
        l_xml_root_node            VARCHAR2 (400);
        l_sync_source              VARCHAR2 (50);
        l_current_run_date         TIMESTAMP (6) WITH TIME ZONE;
        l_last_run_date            TIMESTAMP (6) WITH TIME ZONE;
        l_status_message           VARCHAR2 (32767);
        l_sql_rowcount             NUMBER := 0;
        l_data_root_tag            VARCHAR2 (500);
        l_dm_curr_tag              VARCHAR2 (500);
        l_num_of_child_nodes       NUMBER := 0;
        l_default_sync_mode        VARCHAR2 (50);
        l_diff_del_obj_pk_cols     VARCHAR2 (500) := '';
        l_diff_delete_stmt         VARCHAR2 (4000) := '';
        l_diff_del_diff_tbl_cols   VARCHAR2 (500) := '';
        l_diff_cleanup_reqd        VARCHAR2 (1) := 'N';
        l_post_sync_process        VARCHAR2 (256);
        l_batch_size               NUMBER;
    BEGIN
        IF (p_object_id IS NULL OR LENGTH (TRIM (p_object_id)) = 0)
        THEN
            put_severe_log (p_proc      => 'SYNC_SAAS_DATA',
                            p_message   => 'OBJECT_ID is null. Stopped processing');
            x_rows_merged := 0;
            x_status_code := 'E';
            x_status_msg := 'OBJECT_ID is null. Stopped processing';

            RETURN;
        END IF;

        IF (p_resp_xmltype IS NULL)
        THEN
            put_severe_log (p_proc      => 'SYNC_SAAS_DATA',
                            p_message   => 'XML Response is null. Stopped processing');
            x_rows_merged := 0;
            x_status_code := 'E';
            x_status_msg := 'XML Response is null. Stopped processing';
            RETURN;
        END IF;

        -- Fetch rest of the columns for the sync object
        SELECT CASE
                   WHEN     sync_source = 'SQL'
                        AND bi_data_model_path IS NOT NULL
                        AND LENGTH (TRIM (bi_data_model_path)) > 0
                   THEN
                       'DM'
                   ELSE
                       sync_source
               END,
               paas_table_name,
               object_name,
               last_run_date,
               DECODE (p_full_sync_flag, 'Y', 'FULL', default_sync_mode),
               post_sync_process,
               batch_size
          INTO l_sync_source,
               l_db_table_name,
               l_object_name,
               l_last_run_date,
               l_default_sync_mode,
               l_post_sync_process,
               l_batch_size
          FROM xxhbg_saas_data_sync_config
         WHERE object_id = p_object_id;

        l_db_table_name := UPPER (TRIM (l_db_table_name));

        put_info_log (
            p_proc   => 'SYNC_SAAS_DATA',
            p_message   =>
                '******  Start of execution for ' || l_object_name || '*********');
        put_info_log (p_proc      => 'SYNC_SAAS_DATA',
                      p_message   => 'l_sync_source: ' || l_sync_source);
        put_info_log (p_proc      => 'SYNC_SAAS_DATA',
                      p_message   => 'l_db_table_name: ' || l_db_table_name);
        put_info_log (p_proc      => 'SYNC_SAAS_DATA',
                      p_message   => 'l_last_run_date: ' || l_last_run_date);
        put_info_log (p_proc      => 'SYNC_SAAS_DATA',
                      p_message   => 'p_batch_num: ' || p_batch_num);
        put_info_log (p_proc      => 'SYNC_SAAS_DATA',
                      p_message   => 'l_batch_size: ' || l_batch_size);

        l_current_run_date :=
            TO_TIMESTAMP_TZ (p_sync_start_time, xml_timestamp_format) AT TIME ZONE 'UTC' - NUMTODSINTERVAL (30, 'MINUTE');
        put_info_log (p_proc      => 'SYNC_SAAS_DATA',
                      p_message   => 'l_current_run_date: ' || l_current_run_date);

        -- If sync mode is FULL, delete the rows from the table
        IF (l_default_sync_mode = 'FULL' AND p_batch_num = 1)
        THEN
            BEGIN
                EXECUTE IMMEDIATE 'DELETE FROM ' || l_db_table_name;

                put_info_log (
                    p_proc   => 'SYNC_SAAS_DATA',
                    p_message   =>
                           'Sync Mode is FULL. Deleted all the '
                        || SQL%ROWCOUNT
                        || ' rows in the table '
                        || l_db_table_name);
            EXCEPTION
                WHEN OTHERS
                THEN
                    put_severe_log (
                        p_proc   => 'SYNC_SAAS_DATA',
                        p_message   =>
                            'Unable to delete rows for Full Sync due to ' || SQLERRM);
                    raise_application_error (
                        -20102,
                        'Unable to delete rows for for Full Sync due to ' || SQLERRM);
            END;
        END IF;

        -- Insert the XML Response for further processing
        SELECT xxhbg_saas_data_sync_runid_seq.NEXTVAL INTO l_curr_run_id FROM DUAL;

        INSERT INTO xxhbg_saas_data_sync_run (run_id,
                                                    object_id,
                                                    sync_mode,
                                                    xml_response,
                                                    creation_date,
                                                    batch_number,
                                                    batch_size)
             VALUES (l_curr_run_id,
                     p_object_id,
                     l_default_sync_mode,
                     p_resp_xmltype,
                     SYSDATE,
                     p_batch_num,
                     l_batch_size);

        COMMIT;

        -- Prepare root tag based on sync source
        IF l_sync_source = 'DM'
        THEN
            FOR l_root_element
                IN (SELECT VALUE (t).getclobval ()     elem
                      FROM TABLE (XMLSEQUENCE (EXTRACT (p_resp_xmltype, '/DATA_DS/*'))) t)
            LOOP
                l_num_of_child_nodes := l_num_of_child_nodes + 1;
                l_dm_curr_tag :=
                    DBMS_LOB.SUBSTR (l_root_element.elem,
                                     DBMS_LOB.INSTR (l_root_element.elem, '>'));

                l_dm_curr_tag := TRIM (TRAILING '>' FROM l_dm_curr_tag);
                l_dm_curr_tag := TRIM (LEADING '<' FROM l_dm_curr_tag);
                l_dm_curr_tag := TRIM (TRAILING '/' FROM l_dm_curr_tag);

                -- IF Data Tag
                IF (    l_dm_curr_tag <> 'LASTRUNDATE'
                    AND l_dm_curr_tag <> 'BATCHSIZE'
                    AND l_dm_curr_tag <> 'BATCHNUM'
                    AND l_dm_curr_tag <> 'SYSTIME')
                THEN
                    l_data_root_tag := l_dm_curr_tag;
                END IF;
            END LOOP;

            put_info_log (p_proc      => 'SYNC_SAAS_DATA',
                          p_message   => 'l_data_root_tag : ' || l_data_root_tag);

            IF (l_data_root_tag IS NULL OR LENGTH (TRIM (l_data_root_tag)) = 0)
            THEN
                IF (   l_num_of_child_nodes = 0
                    OR (    l_num_of_child_nodes <= 4
                        AND (   l_dm_curr_tag = 'LASTRUNDATE'
                             OR l_dm_curr_tag = 'SYSTIME'
                             OR l_dm_curr_tag = 'BATCHSIZE'
                             OR l_dm_curr_tag = 'BATCHNUM')))
                THEN
                    x_rows_merged := 0;
                    x_status_code := 'S';
                    x_status_msg := 'There are no changes on SAAS to be processed.';

                    -- if last run date is not null, then the SQL might not be of any issue - SAAS might not have any recent updates
                    UPDATE xxhbg_saas_data_sync_config
                       SET last_run_date = l_current_run_date
                     WHERE object_id = p_object_id;

                    UPDATE xxhbg_saas_data_sync_run
                       SET run_status_code = x_status_code,
                           run_status_message = x_status_msg,
                           rows_merged = 0
                     WHERE run_id = l_curr_run_id;

                    put_info_log (
                        p_proc   => 'SYNC_SAAS_DATA',
                        p_message   =>
                               'There are no changes on SAAS to be processed. Updating LAST_RUN_DATE date with '
                            || l_current_run_date);

                    RETURN;
                ELSE
                    put_severe_log (
                        p_proc      => 'SYNC_SAAS_DATA',
                        p_message   => 'Couldnt construct the root tag dynamically');
                    x_rows_merged := 0;
                    x_status_code := 'E';
                    x_status_msg :=
                        'Couldnt construct the root tag dynamically. Please verify the datamodel once';

                    UPDATE xxhbg_saas_data_sync_run
                       SET run_status_code = x_status_code,
                           run_status_message =
                               'Couldnt construct the root tag dynamically. Please verify the datamodel once',
                           rows_merged = 0
                     WHERE run_id = l_curr_run_id;

                    RETURN;
                END IF;
            END IF;

            l_xml_root_node := '/DATA_DS/' || l_data_root_tag;
        ELSIF l_sync_source = 'SQL'
        THEN
            l_xml_root_node := '/ROWSET/ROW';
        END IF;

        put_info_log (p_proc      => 'SYNC_SAAS_DATA',
                      p_message   => 'l_xml_root_node: ' || l_xml_root_node);

        -- Printing the no of recs in XML response
        SELECT COUNT (*)
          INTO l_xml_recs_cnt
          FROM XMLTABLE (l_xml_root_node PASSING p_resp_xmltype);

        put_info_log (
            p_proc      => 'SYNC_SAAS_DATA',
            p_message   => 'No of records from XMLTable : ' || TO_CHAR (l_xml_recs_cnt));

        IF l_xml_recs_cnt = 0
        THEN
            x_rows_merged := 0;
            x_status_code := 'S';
            x_status_msg :=
                'XML Response doesnt have any records. There might not be any recently updated records in SAAS.';
            put_info_log (
                p_proc   => 'SYNC_SAAS_DATA',
                p_message   =>
                    'XML Response doesnt have any records. There might not be any recently updated records in SAAS.');

            -- if last run date is not null, then the SQL might not be of any issue - SAAS might not have any recent updates
            UPDATE xxhbg_saas_data_sync_config
               SET last_run_date = l_current_run_date
             WHERE object_id = p_object_id;

            UPDATE xxhbg_saas_data_sync_run
               SET run_status_code = x_status_code,
                   run_status_message = x_status_msg,
                   rows_merged = 0
             WHERE run_id = l_curr_run_id;

            put_info_log (
                p_proc      => 'SYNC_SAAS_DATA',
                p_message   => 'Updating LAST_RUN_DATE date with ' || l_current_run_date);

            RETURN;
        END IF;

        -- if count is more than batch size, let system know there are more records
        IF l_xml_recs_cnt >= l_batch_size - 1
        THEN
            x_has_more_data := 'Y';
            put_info_log (
                p_proc   => 'SYNC_SAAS_DATA',
                p_message   =>
                    'Fetched the max rows allowed in a batch. There are more rows to be processed.');
        ELSE
            x_has_more_data := 'N';
            put_info_log (
                p_proc   => 'SYNC_SAAS_DATA',
                p_message   =>
                    'There are less rows than max allowed in a batch. No further batches needed.');
        END IF;

        -- Initialising the variables

        DBMS_LOB.createtemporary (l_xmltable_select_clause, TRUE);
        DBMS_LOB.createtemporary (l_xmltable_tags_clause, TRUE);
        DBMS_LOB.createtemporary (l_update_clause, TRUE);
        DBMS_LOB.createtemporary (l_insert_cols_clause, TRUE);
        DBMS_LOB.createtemporary (l_insert_values_clause, TRUE);
        DBMS_LOB.createtemporary (l_merge_statement, TRUE);
        l_col_count := 0;
        l_merge_prefix :=
               'MERGE INTO '
            || l_db_table_name
            || ' DBTBL'
            || CHR (10)
            || 'USING ('
            || CHR (10);

        l_merge_on_clause := 'ON ( 1 = 1 ';
        DBMS_LOB.append (l_xmltable_select_clause, TO_CLOB ('  SELECT '));
        DBMS_LOB.append (l_update_clause, TO_CLOB ('UPDATE SET '));
        DBMS_LOB.append (l_insert_cols_clause, TO_CLOB ('INSERT ('));
        DBMS_LOB.append (l_insert_values_clause, TO_CLOB ('VALUES ('));

        -- Preparing the primary key cols
        put_info_log (p_proc => 'SYNC_SAAS_DATA', p_message => 'Printing primary key(s)');

        FOR primary_columns_rec
            IN (  SELECT cols.column_name,
                         cols.position,
                         cons.constraint_name,
                         cons.constraint_type
                    FROM all_constraints cons, all_cons_columns cols
                   WHERE     cols.table_name = l_db_table_name
                         AND cons.constraint_type = 'P'
                         AND cons.constraint_name = cols.constraint_name
                         AND cons.owner = cols.owner
                ORDER BY cols.position)
        LOOP
            l_primary_key_col_cnt := l_primary_key_col_cnt + 1;
            l_pk_col_names.EXTEND (1);
            l_pk_col_names (l_primary_key_col_cnt) := primary_columns_rec.column_name;
            put_info_log (p_proc      => 'SYNC_SAAS_DATA',
                          p_message   => primary_columns_rec.column_name);
            l_merge_on_clause :=
                   l_merge_on_clause
                || ' AND '
                || 'DBTBL.'
                || primary_columns_rec.column_name
                || ' = XMLTBL.'
                || primary_columns_rec.column_name;
        END LOOP;

        IF (l_primary_key_col_cnt = 0)
        THEN
            put_info_log (
                p_proc   => 'SYNC_SAAS_DATA',
                p_message   =>
                    'There are no primary key(s) defined on this table. Skipping the processing for this table.');
            x_status_code := 'E';
            x_status_msg :=
                   'There are no primary keys defined on the table '
                || l_db_table_name
                || '. Skipping the processing for this table.';
            RETURN;
        ELSE
            l_merge_on_clause := l_merge_on_clause || ')' || CHR (10);
            put_info_log (p_proc      => 'SYNC_SAAS_DATA',
                          p_message   => 'l_merge_on_clause : ' || l_merge_on_clause);
        END IF;

        OPEN dbtable_csr (l_db_table_name);

        FETCH dbtable_csr BULK COLLECT INTO l_dbtable_tbl;

        CLOSE dbtable_csr;

        put_info_log (p_proc      => 'SYNC_SAAS_DATA',
                      p_message   => 'cols count : ' || l_dbtable_tbl.COUNT);

        -- Preparing the xml table select and db table update,insert
        FOR j IN 1 .. l_dbtable_tbl.COUNT
        LOOP
            -- put_info_log(p_proc => 'SYNC_SAAS_DATA', p_message =>'**************'||l_dbtable_tbl(j).column_name);
            -- append paas table col names for insert,update clauses
            -- avoid PK cols in update clause
            IF (NOT l_dbtable_tbl (j).column_name MEMBER OF l_pk_col_names)
            THEN
                DBMS_LOB.append (
                    l_update_clause,
                    TO_CLOB (
                           'DBTBL.'
                        || l_dbtable_tbl (j).column_name
                        || ' = XMLTBL.'
                        || l_dbtable_tbl (j).column_name));
            END IF;

            DBMS_LOB.append (l_insert_cols_clause,
                             TO_CLOB ('DBTBL.' || l_dbtable_tbl (j).column_name));

            DBMS_LOB.append (l_insert_values_clause,
                             TO_CLOB ('XMLTBL.' || l_dbtable_tbl (j).column_name));

            IF l_dbtable_tbl (j).data_type = 'DATE'
            THEN
                DBMS_LOB.append (
                    l_xmltable_select_clause,
                    TO_CLOB (
                           'TO_TIMESTAMP(DECODE(xt.'
                        || l_dbtable_tbl (j).column_name
                        || ',''null'',null,null,null,REPLACE(SUBSTR('
                        || ' xt.'
                        || l_dbtable_tbl (j).column_name
                        || ',1,INSTR('
                        || 'xt.'
                        || l_dbtable_tbl (j).column_name
                        || ', '
                        || '''+'''
                        || ')-1),'
                        || '''T'''
                        || ','
                        || ''' '''
                        || ')),'
                        || '''YYYY-MM-DD HH24:MI:SS.FF'''
                        || ' ) '
                        || l_dbtable_tbl (j).column_name));

                DBMS_LOB.append (
                    l_xmltable_tags_clause,
                    TO_CLOB (
                           l_dbtable_tbl (j).column_name
                        || ' '
                        || 'VARCHAR2(50)'
                        || ' path '
                        || ''''
                        || l_dbtable_tbl (j).column_name
                        || ''''));
            ELSIF INSTR (l_dbtable_tbl (j).data_type, 'TIMESTAMP') <> 0
            THEN
                DBMS_LOB.append (
                    l_xmltable_select_clause,
                    TO_CLOB (
                           'TO_TIMESTAMP_TZ( DECODE(xt.'
                        || l_dbtable_tbl (j).column_name
                        || ',''null'',null,null,null,'
                        || 'xt.'
                        || l_dbtable_tbl (j).column_name
                        || '), ''YYYY-MM-DD"T"HH24:MI:SS.FF9tzh:tzm'''
                        || ') '
                        || l_dbtable_tbl (j).column_name));

                DBMS_LOB.append (
                    l_xmltable_tags_clause,
                    TO_CLOB (
                           l_dbtable_tbl (j).column_name
                        || ' '
                        || 'VARCHAR2(50)'
                        || ' path '
                        || ''''
                        || l_dbtable_tbl (j).column_name
                        || ''''));
            ELSIF l_dbtable_tbl (j).data_type = 'VARCHAR2'
            THEN
                DBMS_LOB.append (l_xmltable_select_clause,
                                 TO_CLOB (' xt.' || l_dbtable_tbl (j).column_name));

                DBMS_LOB.append (
                    l_xmltable_tags_clause,
                    TO_CLOB (
                           l_dbtable_tbl (j).column_name
                        || ' '
                        || l_dbtable_tbl (j).data_type
                        || '('
                        || l_dbtable_tbl (j).data_length
                        || ') path '
                        || ''''
                        || l_dbtable_tbl (j).column_name
                        || ''''));
            ELSIF l_dbtable_tbl (j).data_type = 'NUMBER'
            THEN
                DBMS_LOB.append (l_xmltable_select_clause,
                                 TO_CLOB (' xt.' || l_dbtable_tbl (j).column_name));

                DBMS_LOB.append (
                    l_xmltable_tags_clause,
                    TO_CLOB (
                           l_dbtable_tbl (j).column_name
                        || ' '
                        || l_dbtable_tbl (j).data_type
                        || ' path '
                        || ''''
                        || l_dbtable_tbl (j).column_name
                        || ''''));
            ELSE
                --put_info_log(p_proc => 'SYNC_SAAS_DATA', p_message =>'Not a regular datatype found : ' || l_dbtable_tbl(j).column_name ||' ' ||l_dbtable_tbl(j).data_type);
                DBMS_LOB.append (l_xmltable_select_clause,
                                 TO_CLOB (' xt.' || l_dbtable_tbl (j).column_name));

                DBMS_LOB.append (
                    l_xmltable_tags_clause,
                    TO_CLOB (
                           l_dbtable_tbl (j).column_name
                        || ' '
                        || l_dbtable_tbl (j).data_type
                        || ' path '
                        || ''''
                        || l_dbtable_tbl (j).column_name
                        || ''''));
            END IF;

            -- append comma and new line chars

            IF (j < l_dbtable_tbl.COUNT)
            THEN
                IF (NOT l_dbtable_tbl (j).column_name MEMBER OF l_pk_col_names)
                THEN
                    DBMS_LOB.append (l_update_clause, TO_CLOB (',' || CHR (10)));
                END IF;

                DBMS_LOB.append (l_insert_cols_clause, TO_CLOB (',' || CHR (10)));
                DBMS_LOB.append (l_insert_values_clause, TO_CLOB (',' || CHR (10)));
                DBMS_LOB.append (l_xmltable_select_clause, TO_CLOB (',' || CHR (10)));
                DBMS_LOB.append (l_xmltable_tags_clause, TO_CLOB (',' || CHR (10)));
            END IF;
        --            put_info_log(p_proc => 'SYNC_SAAS_DATA', p_message =>'l_update_clause:'||l_update_clause);
        --            put_info_log(p_proc => 'SYNC_SAAS_DATA', p_message =>'l_insert_cols_clause:'||l_insert_cols_clause);
        --            put_info_log(p_proc => 'SYNC_SAAS_DATA', p_message =>'l_insert_values_clause:'||l_insert_values_clause);
        --            put_info_log(p_proc => 'SYNC_SAAS_DATA', p_message =>'l_xmltable_select_clause:'||l_xmltable_select_clause);
        --            put_info_log(p_proc => 'SYNC_SAAS_DATA', p_message =>'l_xmltable_tags_clause:'||l_xmltable_tags_clause);

        END LOOP;

        DBMS_LOB.append (l_merge_statement, TO_CLOB (l_merge_prefix));
        DBMS_LOB.append (l_merge_statement, l_xmltable_select_clause);
        DBMS_LOB.append (
            l_merge_statement,
            TO_CLOB (
                   CHR (10)
                || 'FROM XXHBG_SAAS_DATA_SYNC_RUN xh,'
                || CHR (10)
                || 'xmltable ('''
                || l_xml_root_node
                || ''' passing xh.XML_RESPONSE columns '));

        DBMS_LOB.append (l_merge_statement, l_xmltable_tags_clause);
        DBMS_LOB.append (
            l_merge_statement,
            TO_CLOB (
                   ' ) xt '
                || CHR (10)
                || ' WHERE xh.object_id = '
                || p_object_id
                || CHR (10)
                || ' and xh.run_id = '
                || l_curr_run_id
                || CHR (10)
                || ') XMLTBL'
                || CHR (10)));

        DBMS_LOB.append (l_merge_statement, l_merge_on_clause);

        -- Remove any redundant comma at the end of update clause
        l_update_clause := RTRIM (l_update_clause, ',' || CHR (10));

        -- IF all cols are PK cols, then ignore update case
        IF (l_primary_key_col_cnt <> l_dbtable_tbl.COUNT)
        THEN
            DBMS_LOB.append (
                l_merge_statement,
                TO_CLOB (
                       CHR (10)
                    || 'WHEN MATCHED THEN '
                    || CHR (10)
                    || l_update_clause
                    || CHR (10)));
        END IF;

        DBMS_LOB.append (
            l_merge_statement,
            TO_CLOB (
                   CHR (10)
                || 'WHEN NOT MATCHED THEN '
                || CHR (10)
                || l_insert_cols_clause
                || ')'
                || CHR (10)
                || l_insert_values_clause
                || ')'
                || CHR (10)));

        put_info_log (p_proc      => 'SYNC_SAAS_DATA',
                      p_message   => 'l_merge_statement : ' || l_merge_statement);

        -- Issuing merge statements
        EXECUTE IMMEDIATE l_merge_statement;

        l_sql_rowcount := SQL%ROWCOUNT;
        put_info_log (p_proc      => 'SYNC_SAAS_DATA',
                      p_message   => 'Number of rows merged : ' || l_sql_rowcount);
        l_status_message := 'Number of rows merged : ' || l_sql_rowcount || CHR (10);

        -- Updating LAST_RUN_DATE
        IF (x_has_more_data = 'N')
        THEN
            UPDATE xxhbg_saas_data_sync_config
               SET last_run_date = l_current_run_date
             WHERE object_id = p_object_id;
        END IF;

        UPDATE xxhbg_saas_data_sync_run
           SET run_status_code = 'S',
               run_status_message = l_status_message,
               rows_merged = l_sql_rowcount
         WHERE run_id = l_curr_run_id;

        COMMIT;
        x_rows_merged := l_sql_rowcount;
        x_status_code := 'S';
        x_status_msg := l_status_message;

        -- handle saas deletes
        /*
        IF (l_diff_cleanup_reqd = 'Y')
        THEN
            BEGIN
                l_diff_delete_stmt :=
                    'DELETE FROM ' || l_db_table_name || ' where 1=1 AND (';

                FOR i IN l_pk_col_names.FIRST .. l_pk_col_names.LAST
                LOOP
                    l_diff_del_obj_pk_cols :=
                        l_diff_del_obj_pk_cols || l_pk_col_names (i) || ',';
                    l_diff_del_diff_tbl_cols :=
                        l_diff_del_diff_tbl_cols || 'PK_COL' || i || ',';
                END LOOP;

                l_diff_del_obj_pk_cols := RTRIM (l_diff_del_obj_pk_cols, ',');
                l_diff_del_diff_tbl_cols := RTRIM (l_diff_del_diff_tbl_cols, ',');

                l_diff_delete_stmt :=
                       l_diff_delete_stmt
                    || l_diff_del_obj_pk_cols
                    || ' ) IN (select '
                    || l_diff_del_diff_tbl_cols
                    || ' from xxhbg_SAAS_DATA_SYNC_DIFF where object_name = '''
                    || l_object_name
                    || ''' )';

                put_info_log (
                    p_proc   => 'SYNC_SAAS_DATA',
                    p_message   =>
                           'Delete statement for removing the extra rows in PaaS - '
                        || l_diff_delete_stmt);

                EXECUTE IMMEDIATE l_diff_delete_stmt;

                l_sql_rowcount := SQL%ROWCOUNT;

                put_info_log (
                    p_proc   => 'SYNC_SAAS_DATA',
                    p_message   =>
                           'Number of extra rows in PaaS that have been deleted - '
                        || l_sql_rowcount);

                IF (l_sql_rowcount > 0)
                THEN
                    UPDATE xxhbg_saas_data_sync_run
                       SET run_status_message =
                                  run_status_message
                               || CHR (10)
                               || 'Number of extra rows in PaaS that have been deleted '
                               || l_sql_rowcount
                     WHERE run_id = l_curr_run_id;
                END IF;

                COMMIT;
            EXCEPTION
                WHEN OTHERS
                THEN
                    ROLLBACK;
                    put_severe_log (
                        p_proc   => 'SYNC_SAAS_DATA',
                        p_message   =>
                               'Deleting the PaaS differences have failed due to : '
                            || SQLERRM);
            END;
        END IF;
        **/

        -- post sync processing
        IF (LENGTH (TRIM (l_post_sync_process)) > 0)
        THEN
            BEGIN
                put_info_log (
                    p_proc   => 'SYNC_SAAS_DATA',
                    p_message   =>
                           'Calling post sync processing procedure - '
                        || l_post_sync_process);

                EXECUTE IMMEDIATE 'BEGIN ' || l_post_sync_process || '; END;';
            EXCEPTION
                WHEN OTHERS
                THEN
                    put_severe_log (
                        p_proc   => 'SYNC_SAAS_DATA',
                        p_message   =>
                               'Calling post sync processing has failed due to : '
                            || SQLERRM);
            END;
        END IF;

        put_info_log (
            p_proc      => 'SYNC_SAAS_DATA',
            p_message   => '******  End of execution for ' || l_object_name || '*********');
    EXCEPTION
        WHEN OTHERS
        THEN
            put_severe_log (p_proc      => 'SYNC_SAAS_DATA',
                            p_message   => 'Processing has failed due to : ' || SQLERRM);
            ROLLBACK;

            IF dbtable_csr%ISOPEN
            THEN
                CLOSE dbtable_csr;
            END IF;

            x_rows_merged := 0;
            x_status_code := 'E';
            x_status_msg := SUBSTR (SQLERRM, 1, 4000);

            UPDATE xxhbg_saas_data_sync_run
               SET run_status_code = 'E', run_status_message = x_status_msg
             WHERE run_id = l_curr_run_id;

            COMMIT;
    END sync_saas_data;

    PROCEDURE purge_sync_runs (p_retention_period_in_days IN NUMBER)
    AS
        runid_tbl   number_array;
    BEGIN
        put_info_log (
            p_proc   => 'purge_interface_runs',
            p_message   =>
                   'Start of purge_sync_runs - p_retention_period_in_days '
                || p_retention_period_in_days);

        SELECT run_id
          BULK COLLECT INTO runid_tbl
          FROM xxhbg_saas_data_sync_run
         WHERE TRUNC (creation_date) <=
               TRUNC (
                   SYSDATE - NVL (p_retention_period_in_days, default_retention_period));

        FORALL i IN runid_tbl.FIRST .. runid_tbl.LAST
            DELETE FROM xxhbg_saas_data_sync_run
                  WHERE run_id = runid_tbl (i);

        put_info_log (
            p_proc      => 'ARCHIVE_SYNC_RUNS',
            p_message   => 'Number of historical sync runs cleaned up ' || runid_tbl.COUNT);
    EXCEPTION
        WHEN OTHERS
        THEN
            put_severe_log (
                p_proc      => 'ARCHIVE_SYNC_RUNS',
                p_message   => 'Archiving of sync runs has failed due to : ' || SQLERRM);
    END purge_sync_runs;

    PROCEDURE clean_up_sync_objects (p_cleanup_start_time IN VARCHAR2)
    IS
        l_current_date   TIMESTAMP (6) WITH TIME ZONE;
        l_cnt            NUMBER := 0;
    -- l_tbls_cleaned   xxhbg_varchar_tbl_type := xxhbg_varchar_tbl_type ();
    BEGIN
        l_current_date :=
            TO_TIMESTAMP_TZ (p_cleanup_start_time, xml_timestamp_format)
                AT TIME ZONE 'UTC';

        put_info_log (
            p_proc   => 'clean_up_sync_objects',
            p_message   =>
                'Start of sync object clean up - start time is ' || l_current_date);

        FOR obj
            IN (SELECT *
                  FROM xxhbg_saas_data_sync_config conf
                 WHERE     conf.enabled = 'Y'
                       AND conf.cleanup_required = 'Y'
                       AND conf.cleanup_utc_hour =
                           EXTRACT (HOUR FROM SYS_EXTRACT_UTC (SYSTIMESTAMP))
                       AND conf.last_run_date + conf.cleanup_range_in_days >
                           NVL (conf.last_cleanup_date,
                                SYSDATE - conf.cleanup_range_in_days)
                       AND EXISTS
                               (SELECT 1
                                  FROM all_tab_columns
                                 WHERE     table_name = conf.paas_table_name
                                       AND UPPER (column_name) = 'LAST_UPDATE_DATE'))
        LOOP
            l_cnt := 0;

            BEGIN
                EXECUTE IMMEDIATE   'select count(1) from '
                                 || obj.paas_table_name
                                 || ' where last_update_date is not null'
                    INTO l_cnt;

                IF (l_cnt > 0)
                THEN
                    EXECUTE IMMEDIATE   'delete from '
                                     || obj.paas_table_name
                                     || ' where last_update_date > sysdate - '
                                     || obj.cleanup_range_in_days;

                    put_info_log (
                        p_proc   => 'clean_up_sync_objects',
                        p_message   =>
                               'Number of rows deleted in '
                            || obj.paas_table_name
                            || ' - '
                            || SQL%ROWCOUNT);

                    --  l_tbls_cleaned.EXTEND;
                    --   l_tbls_cleaned (l_tbls_cleaned.COUNT) := obj.paas_table_name;

                    UPDATE xxhbg_saas_data_sync_config
                       SET last_run_date =
                                 last_run_date
                               - cleanup_range_in_days
                               - NUMTODSINTERVAL (5, 'MINUTE'),
                           last_cleanup_date = l_current_date
                     WHERE paas_table_name = obj.paas_table_name;

                    put_info_log (
                        p_proc   => 'clean_up_sync_objects',
                        p_message   =>
                               'Updated last run date of '
                            || obj.paas_table_name
                            || ' to '
                            || (  obj.last_run_date
                                - obj.cleanup_range_in_days
                                - NUMTODSINTERVAL (5, 'MINUTE')));

                    COMMIT;
                ELSE
                    put_info_log (
                        p_proc   => 'clean_up_sync_objects',
                        p_message   =>
                               'Ignoring '
                            || obj.paas_table_name
                            || ' as it doesnt sync LAST_UPDATE_DATE');
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    put_info_log (
                        p_proc   => 'clean_up_sync_objects',
                        p_message   =>
                               'Unable to cleanup '
                            || obj.paas_table_name
                            || ' due to - '
                            || SQLERRM);

                    ROLLBACK;
            END;
        END LOOP;
    END clean_up_sync_objects;

    procedure update_datamodel_path(p_object_name IN VARCHAR2,
                                    p_bi_datamodel_path IN VARCHAR2,
                                    x_status                 OUT VARCHAR2,
                                    x_status_message         OUT VARCHAR2)
    as
    begin
        update xxhbg_saas_data_sync_config
        set bi_data_model_path = p_bi_datamodel_path
        where object_name = p_object_name;
        x_status := 'S';
    exception
        when others then
            x_status := 'E';
            x_status_message := SQLERRM;
    end update_datamodel_path;

    PROCEDURE prepare_datamodel_xml (p_object_name         IN     VARCHAR2,
                                     x_return_base64_xml      OUT CLOB,
                                     x_status                 OUT VARCHAR2,
                                     x_status_message         OUT VARCHAR2)
    AS
        l_dm_xml                     CLOB;
        l_dm_sql                     CLOB;
        l_select_clause              CLOB;
        l_pk_col_count               NUMBER := 0;
        l_paas_table_accessible      VARCHAR2 (1);
        l_pk_cols_list               VARCHAR2 (4000);
        l_last_upd_date_col_exists   VARCHAR2 (1) := 'N';
        l_object_id                  xxhbg_saas_data_sync_config.object_id%TYPE;
        l_sql_query                  xxhbg_saas_data_sync_config.sql_query%TYPE;
        l_db_table_name              xxhbg_saas_data_sync_config.paas_table_name%TYPE;
        l_count                      NUMBER := 1;
    BEGIN
        BEGIN
            SELECT object_id, sql_query, UPPER(TRIM(paas_table_name))
              INTO l_object_id, l_sql_query, l_db_table_name
              FROM xxhbg_saas_data_sync_config
             WHERE object_name = p_object_name AND LENGTH (sql_query) > 0;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                put_severe_log ('prepare_sql_for_dm', 'Invalid object name');
                x_status := 'E';
                x_status_message := 'Invalid object name';
                RETURN;
        END;

        -- check if the paas table exists and has PK configured
        BEGIN
            SELECT 'Y'
              INTO l_paas_table_accessible
              FROM all_tables
             WHERE table_name = l_db_table_name;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                x_status := 'E';
                x_status_message :=
                    'Unable to find the corresponding PaaS table for this object. Please make sure that the table exists and is accessible.';
                RETURN;
        END;

        -- check if the paas table has PK columns configured
        BEGIN
            SELECT COUNT (1)
              INTO l_pk_col_count
              FROM all_constraints cons, all_cons_columns cols
             WHERE     cols.table_name = l_db_table_name
                   AND cons.constraint_type = 'P'
                   AND cons.constraint_name = cols.constraint_name
                   AND cons.owner = cols.owner;

            IF (l_pk_col_count = 0)
            THEN
                x_status := 'E';
                x_status_message := 'PaaS table does not have a primary key configured.';
                RETURN;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                x_status := 'E';
                x_status_message := 'PaaS table does not have a primary key configured.';
                RETURN;
        END;

        DBMS_LOB.createtemporary (l_dm_xml, TRUE);
        DBMS_LOB.createtemporary (l_dm_sql, TRUE);
        DBMS_LOB.createtemporary (l_select_clause, TRUE);

        DBMS_LOB.append (
            l_dm_xml,
            '<?xml version = ''1.0'' encoding = ''utf-8''?>
<dataModel xmlns="http://xmlns.oracle.com/oxp/xmlp" version="2.0" xmlns:xdm="http://xmlns.oracle.com/oxp/xmlp" xmlns:xsd="http://wwww.w3.org/2001/XMLSchema" defaultDataSourceRef="demo">
	<dataProperties>
		<property name="include_parameters" value="false"/>
		<property name="include_null_Element" value="false"/>
		<property name="include_rowsettag" value="false"/>
		<property name="xml_tag_case" value="upper"/>
		<property name="generate_output_format" value="xml"/>
		<property name="sql_monitor_report_generated" value="false"/>
		<property name="optimize_query_executions" value="false"/>
	</dataProperties>
	<dataSets>');

        DBMS_LOB.append (l_dm_xml,
                         '<dataSet name="' || p_object_name || '" type="complex">');

        DBMS_LOB.append (l_dm_xml, '<sql dataSourceRef="ApplicationDB_FSCM">');

        DBMS_LOB.append (l_dm_xml, '<![CDATA[');

        -- Datamodel SQL construction
        DBMS_LOB.append (l_dm_sql, 'SELECT * FROM ( SELECT tbl.*, ');

          SELECT RTRIM (LISTAGG (cols.column_name || ','), ',')
            INTO l_pk_cols_list
            FROM all_constraints cons, all_cons_columns cols
           WHERE     cols.table_name = l_db_table_name
                 AND cons.constraint_type = 'P'
                 AND cons.constraint_name = cols.constraint_name
                 AND cons.owner = cols.owner
        ORDER BY cols.position;

        DBMS_LOB.append (
            l_dm_sql,
            'ROW_NUMBER() OVER(ORDER BY ' || l_pk_cols_list || ') rowno ' || CHR (10));


        DBMS_LOB.append (l_dm_sql, 'FROM ( ' || l_sql_query || ' ) tbl ');

        BEGIN
            SELECT 'Y'
              INTO l_last_upd_date_col_exists
              FROM all_tab_columns
             WHERE table_name = l_db_table_name AND column_name = 'LAST_UPDATE_DATE';

            DBMS_LOB.append (
                l_dm_sql,
                'WHERE LAST_UPDATE_DATE >= NVL(:LastRunDate,LAST_UPDATE_DATE)');
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                put_info_log (
                    'prepare_sql_for_dm',
                    'LAST_UPDATE_DATE column doesnt exist on the table. Skipping the delta check');
        END;

        --append filters
        DBMS_LOB.append (l_dm_sql, construct_filters_sql (l_object_id));

        DBMS_LOB.append (l_dm_sql, ') WHERE FLOOR (rowno / :BatchSize) + 1 = :BatchNum');
        put_info_log ('prepare_sql_for_dm', 'Prepared SQL for Data Model - ' || l_dm_sql);
        DBMS_LOB.append (l_dm_xml, l_dm_sql);

        DBMS_LOB.append (l_dm_xml, ']]></sql>
		</dataSet>
	</dataSets>');

        -- constructing data structure
        DBMS_LOB.append (
            l_dm_xml,
               '<output rootName="DATA_DS" uniqueRowName="false">
      <nodeList name="data-structure">
         <dataStructure tagName="DATA_DS">
            <group name="'
            || p_object_name
            || '" label="'
            || p_object_name
            || '" source="'
            || p_object_name
            || '">');

        FOR tablecols IN (SELECT column_name, data_type
                            FROM all_tab_columns cols
                             WHERE
                        (REGEXP_COUNT(l_sql_query,'*') > 0
                        OR EXISTS (  SELECT 1 FROM (xxhbg_paas_extn_utils_pkg.csv_to_table(ltrim(substr(UPPER(l_sql_query),1,INSTR(UPPER(l_sql_query),'FROM')-1),'SELECT ')))  selectcols
                                    where selectcols.column_value like '%'|| cols.column_name || '%'))
                         and table_name = l_db_table_name)
        LOOP
            DBMS_LOB.append (
                l_dm_xml,
                   ' <element name="'
                || tablecols.column_name
                || '" value="'
                || tablecols.column_name
                || '" label="'
                || tablecols.column_name
                || '" dataType="xsd:string"'
                || ' breakOrder="" fieldOrder="'
                || l_count
                || '"/>');
            l_count := l_count + 1;
        END LOOP;

        IF (REGEXP_COUNT (l_sql_query, 'SYSTIMESTAMP CURRENT_RUN_DATE') > 0)
        THEN
            DBMS_LOB.append (
                l_dm_xml,
                   '<element name="CURRENT_RUN_DATE" value="CURRENT_RUN_DATE" label="CURRENT_RUN_DATE" dataType="xsd:date" breakOrder="" fieldOrder="'
                || l_count
                || '"/>');
            l_count := l_count + 1;
        END IF;

        DBMS_LOB.append (
            l_dm_xml,
               '<element name="ROWNO" value="ROWNO" label="ROWNO" dataType="xsd:double" breakOrder="" fieldOrder="'
            || l_count
            || '"/>');

        DBMS_LOB.append (l_dm_xml, '</group>
			</dataStructure>
		</nodeList>
	</output>
	<eventTriggers/>
	<lexicals/>
	<parameters>');

        IF (l_last_upd_date_col_exists = 'Y')
        THEN
            DBMS_LOB.append (
                l_dm_xml,
                '<parameter name="LastRunDate" dataType="xsd:date" rowPlacement="1">
			<date label="Last Run Date" format="yyyy-MM-dd HH:mm:ss"/>
		</parameter>');
        END IF;

        DBMS_LOB.append (
            l_dm_xml,
               '<parameter name="BatchSize" defaultValue="5000" dataType="xsd:string" rowPlacement="1">
			<input label="Batch Size"/>
		</parameter>
		<parameter name="BatchNum" defaultValue="1" dataType="xsd:string" rowPlacement="1">
			<input label="Batch Number"/>
		</parameter>
	</parameters>
	<valueSets/>
	<bursting/>
    <validations>
      <validation>N</validation>
    </validations>
	<display>
		<layouts>
			<layout name="'
            || p_object_name
            || '" left="285px" top="0px"/>
			<layout name="DATA_DS" left="5px" top="393px"/>
		</layouts>
		<groupLinks/>
	</display>   
</dataModel>');

        put_info_log ('prepare_sql_for_dm', 'XML generated for datamodel - ' || l_dm_xml);
        x_return_base64_xml := xxhbg_paas_extn_utils_pkg.clob_to_base64 (l_dm_xml);
        x_status := 'S';
    EXCEPTION
        WHEN OTHERS
        THEN
            x_status := 'E';
            x_status_message := SQLERRM;
    END prepare_datamodel_xml;

    PROCEDURE reduce_batch_size (p_object_name        IN     VARCHAR2,
                                 p_reduce_by_number   IN     NUMBER DEFAULT 500,
                                 x_status                OUT VARCHAR2,
                                 x_status_message        OUT VARCHAR2)
    IS
    BEGIN
        UPDATE xxhbg_saas_data_sync_config
           SET batch_size = batch_size - p_reduce_by_number
         WHERE object_name = p_object_name AND batch_size - p_reduce_by_number > 0;

        put_info_log (
            'reduce_batch_size',
               p_object_name
            || ' has hit 10MB limit. Batch size has been reduced by '
            || p_reduce_by_number);
        x_status := 'S';
    EXCEPTION
        WHEN OTHERS
        THEN
            put_severe_log (
                'reduce_batch_size',
                   'Unable to reduce the batch size for '
                || p_object_name
                || ' due to : '
                || SQLERRM);
            x_status := 'E';
            x_status_message :=
                   'Unable to reduce the batch size for '
                || p_object_name
                || ' due to : '
                || SQLERRM;
    END reduce_batch_size;
END xxhbg_saas_data_sync;

/
