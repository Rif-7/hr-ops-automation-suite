SET SERVEROUTPUT ON
/
-- HR OPS AUTOMATION SUITE Tests

BEGIN
    hr_ops.pkg_hr_security.pr_set_login_context;
END;
/

-- Milestone A

-- A1

PROMPT ==========================================
PROMPT Milestone: A1 - Ensure Department Exists (Engineering)
PROMPT ==========================================


DECLARE
    v_dept_name   cs_departments.dept_name%TYPE := 'Engineering';
    v_dept_id     cs_departments.dept_id%TYPE;
BEGIN
    BEGIN
        SELECT dept_id
        INTO v_dept_id
        FROM cs_departments
        WHERE dept_name = v_dept_name;

        DBMS_OUTPUT.PUT_LINE('Department already exists. ID = ' || v_dept_id);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO cs_departments (dept_name)
            VALUES (v_dept_name)
            RETURNING dept_id INTO v_dept_id;

            DBMS_OUTPUT.PUT_LINE('Department inserted. ID = ' || v_dept_id);
    END;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- A2

PROMPT ==========================================
PROMPT Milestone A: A2 - Salary Band Classification
PROMPT ==========================================

DECLARE
    v_band_a NUMBER := 0;
    v_band_b NUMBER := 0;
    v_band_c NUMBER := 0;
BEGIN
    FOR rec IN (
        SELECT base_salary
        FROM cs_employee_salary
    )
    LOOP
        CASE
            WHEN rec.base_salary < 30000 THEN
                v_band_a := v_band_a + 1;

            WHEN rec.base_salary BETWEEN 30000 AND 70000 THEN
                v_band_b := v_band_b + 1;

            WHEN rec.base_salary > 70000 THEN
                v_band_c := v_band_c + 1;
        END CASE;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Salary Band Counts:');
    DBMS_OUTPUT.PUT_LINE('Band A (<30k)     = ' || v_band_a);
    DBMS_OUTPUT.PUT_LINE('Band B (30-70k)   = ' || v_band_b);
    DBMS_OUTPUT.PUT_LINE('Band C (>70k)     = ' || v_band_c);
END;
/



-- Onboard Employee Procedure Test

PROMPT ==========================================
PROMPT TEST: pr_onboard_employee (SUCCESS)
PROMPT ==========================================


/

DECLARE
    v_before NUMBER;
    v_after  NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_before FROM cs_employees;

    pkg_hr_ops.pr_onboard_employee(
        p_first_name => 'Test',
        p_last_name  => 'User',
        p_email      => 'test.user@test.com',
        p_phone      => '9999999999',
        p_dept_id    => 1,
        p_job_title  => 'Associate',
        p_manager_id => 2,
        p_salary     => 45000
    );

    SELECT COUNT(*) INTO v_after FROM cs_employees;

    DBMS_OUTPUT.PUT_LINE('Employees before: ' || v_before);
    DBMS_OUTPUT.PUT_LINE('Employees after : ' || v_after);
END;
/

SELECT * FROM cs_audit_log
WHERE table_name = 'cs_employees'
ORDER BY changed_at DESC;
/


PROMPT ==========================================
PROMPT TEST: pr_onboard_employee (INVALID EMAIL)
PROMPT ==========================================
/

BEGIN
    pkg_hr_ops.pr_onboard_employee(
        p_first_name => 'Bad',
        p_last_name  => 'Email',
        p_email      => 'invalidemail',
        p_phone      => '1111111111',
        p_dept_id    => 1,
        p_job_title  => 'Associate',
        p_manager_id => 2,
        p_salary     => 40000
    );
END;
/


SELECT *
FROM cs_audit_log
WHERE table_name = 'pr_onboard_employee'
ORDER BY changed_at DESC;

/
PROMPT ==========================================
PROMPT TEST: pr_onboard_employee (INVALID Department ID)
PROMPT ==========================================

BEGIN
    pkg_hr_ops.pr_onboard_employee(
        p_first_name => 'Bad',
        p_last_name  => 'Dep',
        p_email      => 'baddep@company.com',
        p_phone      => '1111111111',
        p_dept_id    => 9000,
        p_job_title  => 'Associate',
        p_manager_id => 2,
        p_salary     => 40000
    );
END;
/



SELECT *
FROM cs_audit_log
WHERE table_name = 'pr_onboard_employee'
ORDER BY changed_at DESC;
/


PROMPT ==========================================
PROMPT TEST: pr_onboard_employee (INVALID Salary)
PROMPT ==========================================

BEGIN
    pkg_hr_ops.pr_onboard_employee(
        p_first_name => 'Bad',
        p_last_name  => 'Dep',
        p_email      => 'baddep@company.com',
        p_phone      => '1111111111',
        p_dept_id    => 1,
        p_job_title  => 'Associate',
        p_manager_id => 2,
        p_salary     => -2000
    );
END;
/



SELECT *
FROM cs_audit_log
WHERE table_name = 'pr_onboard_employee'
ORDER BY changed_at DESC;
/

-- Transfer Employee Procedure Test

PROMPT ==========================================
PROMPT TEST: pr_transfer_employee
PROMPT ==========================================


SELECT emp_id, dept_id FROM cs_employees WHERE emp_id = 1;
/

BEGIN
    pkg_hr_ops.pr_transfer_employee(
        p_emp_id       => 1,
        p_to_dept_id   => 2,
        p_effective_on => SYSDATE,
        p_reason       => 'Test transfer'
    );
END;
/

SELECT emp_id, dept_id FROM cs_employees WHERE emp_id = 1;
/

SELECT * FROM cs_transfers
ORDER BY created_at DESC;
/

PROMPT ==========================================
PROMPT TEST: pr_transfer_employee (INVALID DEPT)
PROMPT ==========================================

BEGIN
    pkg_hr_ops.pr_transfer_employee(
        p_emp_id       => 1,
        p_to_dept_id   => 999,
        p_effective_on => SYSDATE,
        p_reason       => 'Invalid test'
    );
END;
/

SELECT *
FROM cs_audit_log
WHERE table_name = 'pr_transfer_employee'
ORDER BY changed_at DESC;
/

-- Upload Document Procedure Test

PROMPT ==========================================
PROMPT TEST: pr_upload_doc
PROMPT ==========================================


DECLARE
    v_blob BLOB;
    v_text VARCHAR2(100) := 'Sample document for testing';
BEGIN
    DBMS_LOB.CREATETEMPORARY(v_blob, TRUE);

    DBMS_LOB.WRITE(
        v_blob,
        LENGTH(v_text),
        1,
        UTL_RAW.CAST_TO_RAW(v_text)
    );

    pkg_hr_ops.pr_upload_doc(
        p_emp_id    => 1,
        p_doc_type  => 'TestDoc',
        p_blob      => v_blob,
        p_file_name => 'test.txt',
        p_mime      => 'text/plain'
    );

    DBMS_LOB.FREETEMPORARY(v_blob);
END;
/

SELECT * FROM cs_employee_docs
ORDER BY uploaded_at DESC;
/

-- Employee Summary Function Test

PROMPT ==========================================
PROMPT TEST: fn_employee_summary
PROMPT ==========================================


/

DECLARE
    v_summary CLOB;
BEGIN
    v_summary := pkg_hr_ops.fn_employee_summary(1);
    DBMS_OUTPUT.PUT_LINE(v_summary);
END;
/

-- Employee Report Procedure Test

PROMPT ==========================================
PROMPT TEST: pr_employee_report
PROMPT ==========================================


VARIABLE rc REFCURSOR;

BEGIN
    pkg_hr_ops.pr_employee_report(
        p_filter_col => 'DEPT_ID',
        p_filter_val => '1',
        p_sort_col   => 'EMP_ID',
        p_sort_dir   => 'ASC',
        p_out        => :rc
    );
END;
/

PRINT rc;
/

PROMPT ==========================================
PROMPT TEST: pr_employee_report (INVALID COLUMN)
PROMPT ==========================================

VARIABLE rc REFCURSOR;

BEGIN
    pkg_hr_ops.pr_employee_report(
        p_filter_col => 'HACK',
        p_filter_val => '1',
        p_sort_col   => 'EMP_ID',
        p_sort_dir   => 'ASC',
        p_out        => :rc
    );
END;
/

SELECT *
FROM cs_audit_log
WHERE table_name = 'pr_employee_report'
ORDER BY changed_at DESC;
/

-- Document Metadata Function Test

PROMPT ==========================================
PROMPT TEST: fn_get_doc_metadata
PROMPT ==========================================
/

SELECT pkg_hr_ops.fn_get_doc_metadata(
    (SELECT MAX(doc_id) FROM cs_employee_docs)
) FROM dual;
/

-- Document Blob Summary Test

PROMPT ==========================================
PROMPT TEST: fn_get_doc_blob_summary
PROMPT ==========================================

SELECT pkg_hr_ops.fn_get_doc_blob_summary(
    (SELECT MAX(doc_id) FROM cs_employee_docs)
) FROM dual;
/

-- Trigger Employee Update Audit Test

PROMPT ==========================================
PROMPT TEST: Employee Update Trigger
PROMPT ==========================================
/

UPDATE cs_employees
SET job_title = 'Senior Engineer'
WHERE emp_id = 1;
/

SELECT *
FROM cs_audit_log
WHERE table_name = 'cs_employees'
ORDER BY changed_at DESC;
/

-- Trigger Salary Update Audit Test

PROMPT ==========================================
PROMPT TEST: Salary Update Trigger
PROMPT ==========================================
/

UPDATE cs_employee_salary
SET base_salary = base_salary + 1000
WHERE emp_id = 1;
/

SELECT *
FROM cs_audit_log
WHERE table_name = 'cs_employee_salary'
ORDER BY changed_at DESC;
/

-- VPD Salary Access Test

PROMPT ==========================================
PROMPT TEST: VPD Salary Access
PROMPT ==========================================
/

BEGIN
    hr_ops.pkg_hr_security.pr_set_login_context;
END;
/

SELECT * FROM cs_employee_salary;
/


-- Comparing Payroll Snapshot using Cursor and Bulk Insert

BEGIN
    hr_ops.pkg_hr_security.pr_set_login_context;
END;
/

SET TIMING ON
/

PROMPT ==========================================
PROMPT ROW-BY-ROW CURSOR VERSION (June)
PROMPT ==========================================
/

BEGIN
    DELETE FROM cs_payroll_snapshot
    WHERE snap_month = DATE '2026-06-01';
    COMMIT;
END;
/

BEGIN
    pkg_hr_ops.pr_generate_payroll(
    p_month => DATE '2026-06-01'
    );
END;
/

PROMPT ==========================================
PROMPT BULK COLLECT + FORALL VERSION (June)
PROMPT ==========================================
/

BEGIN
    DELETE FROM cs_payroll_snapshot
    WHERE snap_month = DATE '2026-06-01';
    COMMIT;
END;
/

BEGIN
    pkg_hr_ops.pr_generate_payroll_bulk(
    p_month => DATE '2026-06-01'
    );
END;
/
