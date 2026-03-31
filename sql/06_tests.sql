SET SERVEROUTPUT ON

-- HR OPS AUTOMATION SUITE Tests


-- Milestone A

-- A1
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


-- A2
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

-- Comparing Payroll Snapshot using Cursor and Bulk Insert

BEGIN
    hr_ops.pkg_hr_security.pr_set_login_context;
END;
/

SET SERVEROUTPUT ON
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
