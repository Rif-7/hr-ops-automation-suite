SET SERVEROUTPUT ON;


-- HR OPS AUTOMATION SUITE Packages and Procedures


-- Milestone D

-- D1
CREATE OR REPLACE FUNCTION fn_get_emp_fullname (
    p_emp_id IN cs_employees.emp_id%TYPE
)
RETURN VARCHAR2
IS
    v_fullname VARCHAR2(200);
BEGIN
    SELECT first_name || ' ' || last_name
    INTO v_fullname
    FROM cs_employees
    WHERE emp_id = p_emp_id;

    RETURN v_fullname;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END;
/


CREATE OR REPLACE FUNCTION fn_compute_tax (
    p_gross IN NUMBER
)
RETURN NUMBER
IS
    v_tax NUMBER;
BEGIN
    IF p_gross < 50000 THEN
        v_tax := p_gross * 0.10;
    ELSE
        v_tax := p_gross * 0.20;
    END IF;

    RETURN v_tax;
END;
/

CREATE OR REPLACE FUNCTION fn_is_valid_email (
    p_email IN VARCHAR2
)
RETURN NUMBER
IS
BEGIN
    IF INSTR(p_email, '@') > 0 THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
/


-- D2
CREATE OR REPLACE PACKAGE pkg_hr_ops
IS
    PROCEDURE pr_onboard_employee(
        p_first_name   IN cs_employees.first_name%TYPE,
        p_last_name    IN cs_employees.last_name%TYPE,
        p_email        IN cs_employees.email%TYPE,
        p_phone        IN cs_employees.phone%TYPE,
        p_dept_id      IN cs_employees.dept_id%TYPE,
        p_job_title    IN cs_employees.job_title%TYPE,
        p_manager_id   IN cs_employees.manager_id%TYPE,
        p_salary       IN cs_employee_salary.base_salary%TYPE
    );

    PROCEDURE pr_generate_payroll(p_month IN DATE);

    PROCEDURE pr_transfer_employee(
        p_emp_id IN cs_employees.emp_id%TYPE,
        p_to_dept_id IN cs_departments.dept_id%TYPE,
        p_effective_on IN cs_transfers.effective_on%TYPE,
        p_reason IN cs_transfers.reason%TYPE
    );

    PROCEDURE pr_upload_doc(
        p_emp_id IN cs_employees.emp_id%TYPE,
        p_doc_type IN cs_employee_docs.doc_type%TYPE,
        p_blob IN cs_employee_docs.doc_content%TYPE,
        p_file_name IN cs_employee_docs.file_name%TYPE,
        p_mime IN cs_employee_docs.mime_type%TYPE
    );

    FUNCTION fn_employee_summary(p_emp_id IN cs_employees.emp_id%TYPE) RETURN CLOB;


END pkg_hr_ops;
/

CREATE OR REPLACE PACKAGE BODY pkg_hr_ops 
IS
    -- Milestone B

    -- B1
    PROCEDURE pr_onboard_employee (
        p_first_name   IN cs_employees.first_name%TYPE,
        p_last_name    IN cs_employees.last_name%TYPE,
        p_email        IN cs_employees.email%TYPE,
        p_phone        IN cs_employees.phone%TYPE,
        p_dept_id      IN cs_employees.dept_id%TYPE,
        p_job_title    IN cs_employees.job_title%TYPE,
        p_manager_id   IN cs_employees.manager_id%TYPE,
        p_salary       IN cs_employee_salary.base_salary%TYPE
    ) IS
        v_emp_id NUMBER;
        v_count NUMBER;
    BEGIN
        IF FN_IS_VALID_EMAIL(p_email) = 0 THEN
            RAISE pkg_error.ex_invalid_email;
        END IF;

        SELECT COUNT(*) INTO v_count
        FROM cs_departments 
        WHERE dept_id = p_dept_id;

        IF v_count = 0 THEN
            RAISE pkg_error.ex_dept_not_found;
        END IF;

        IF p_salary < 0 THEN
            RAISE pkg_error.ex_invalid_salary;
        END IF;

        INSERT INTO cs_employees (
            first_name,
            last_name,
            email,
            phone,
            dept_id,
            job_title,
            manager_id
        )
        VALUES (
            p_first_name,
            p_last_name,
            p_email,
            p_phone,
            p_dept_id,
            p_job_title,
            p_manager_id
        ) RETURNING emp_id INTO v_emp_id;

        INSERT INTO cs_employee_salary (
            emp_id,
            base_salary
        )
        VALUES (
            v_emp_id,
            p_salary
        );

        COMMIT;

        DBMS_OUTPUT.PUT_LINE('Employee onboarded. ID = ' || v_emp_id);

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Onboarding failed: ' || SQLERRM);
            RAISE;
    END;


    -- Milestone C

    -- C1
    PROCEDURE pr_generate_payroll (
        p_month IN DATE
    )
    IS
        TYPE t_emp_rec IS RECORD (
            emp_id      cs_employees.emp_id%TYPE,
            base_salary cs_employee_salary.base_salary%TYPE,
            bonus       cs_employee_salary.bonus%TYPE
        );

        TYPE t_failed_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
        v_failed t_failed_tab;
        v_fail_count NUMBER := 0;

        CURSOR c_emp IS
            SELECT e.emp_id,
                s.base_salary,
                NVL(s.bonus,0) bonus
            FROM cs_employees e
            JOIN cs_employee_salary s
            ON e.emp_id = s.emp_id;

        v_rec   t_emp_rec;
        v_gross NUMBER;
        v_tax   NUMBER;
        v_net   NUMBER;

    BEGIN
        OPEN c_emp;

        LOOP
            FETCH c_emp INTO v_rec;
            EXIT WHEN c_emp%NOTFOUND;

            BEGIN
                v_gross := v_rec.base_salary + v_rec.bonus;

                v_tax := FN_COMPUTE_TAX(v_gross);


                v_net := v_gross - v_tax;

                INSERT INTO cs_payroll_snapshot (
                    snap_month,
                    emp_id,
                    gross_pay,
                    tax_amount,
                    net_pay
                )
                VALUES (
                    TRUNC(p_month, 'MM'),
                    v_rec.emp_id,
                    v_gross,
                    v_tax,
                    v_net
                );

            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN
                    v_fail_count := v_fail_count + 1;
                    v_failed(v_fail_count) := v_rec.emp_id;

                WHEN OTHERS THEN
                    v_fail_count := v_fail_count + 1;
                    v_failed(v_fail_count) := v_rec.emp_id;
            END;

        END LOOP;

        DBMS_OUTPUT.PUT_LINE('Processed rows: ' || c_emp%ROWCOUNT);
        DBMS_OUTPUT.PUT_LINE('Failures: ' || v_fail_count);

        IF v_fail_count > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Failed employees:');
            FOR i IN 1 .. v_fail_count LOOP
                DBMS_OUTPUT.PUT_LINE( v_failed(i) || ' - ' || FN_GET_EMP_FULLNAME(v_failed(i)));
            END LOOP;
        END IF;

        CLOSE c_emp;

    EXCEPTION
        WHEN OTHERS THEN
            IF c_emp%ISOPEN THEN
                CLOSE c_emp;
            END IF;
            RAISE;
    END;


    PROCEDURE pr_transfer_employee(
        p_emp_id       IN cs_employees.emp_id%TYPE,
        p_to_dept_id   IN cs_departments.dept_id%TYPE,
        p_effective_on IN cs_transfers.effective_on%TYPE,
        p_reason       IN cs_transfers.reason%TYPE
    )
    IS
        v_from_dept cs_employees.dept_id%TYPE;
        v_count     NUMBER;
    BEGIN
        SELECT dept_id
        INTO v_from_dept
        FROM cs_employees
        WHERE emp_id = p_emp_id;

        SELECT COUNT(*)
        INTO v_count
        FROM cs_departments
        WHERE dept_id = p_to_dept_id;

        IF v_count = 0 THEN
            RAISE pkg_error.ex_target_dept_not_found;
        END IF;

        INSERT INTO cs_transfers(
            emp_id,
            from_dept_id,
            to_dept_id,
            effective_on,
            reason
        )
        VALUES(
            p_emp_id,
            v_from_dept,
            p_to_dept_id,
            p_effective_on,
            p_reason
        );

        UPDATE cs_employees
        SET dept_id   = p_to_dept_id,
            updated_at = SYSDATE
        WHERE emp_id = p_emp_id;

        DBMS_OUTPUT.PUT_LINE('Employee transferred');

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE pkg_error.ex_employee_not_found;
    END;

    PROCEDURE pr_upload_doc(
        p_emp_id    IN cs_employees.emp_id%TYPE,
        p_doc_type  IN cs_employee_docs.doc_type%TYPE,
        p_blob      IN cs_employee_docs.doc_content%TYPE,
        p_file_name IN cs_employee_docs.file_name%TYPE,
        p_mime      IN cs_employee_docs.mime_type%TYPE
    )
    IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM cs_employees
        WHERE emp_id = p_emp_id;

        IF v_count = 0 THEN
            RAISE pkg_error.ex_employee_not_found;
        END IF;

        INSERT INTO cs_employee_docs(
            emp_id,
            doc_type,
            file_name,
            mime_type,
            doc_content
        )
        VALUES(
            p_emp_id,
            p_doc_type,
            p_file_name,
            p_mime,
            p_blob
        );

        DBMS_OUTPUT.PUT_LINE('Document uploaded');
    END;


    FUNCTION fn_employee_summary(
        p_emp_id IN cs_employees.emp_id%TYPE
    ) RETURN CLOB
    IS
        v_clob CLOB;
        v_name VARCHAR2(200);
        v_dept VARCHAR2(100);
        v_salary NUMBER;
    BEGIN
        SELECT e.first_name || ' ' || e.last_name,
               d.dept_name,
               s.base_salary
        INTO v_name,
             v_dept,
             v_salary
        FROM cs_employees e
        JOIN cs_departments d
            ON e.dept_id = d.dept_id
        LEFT JOIN cs_employee_salary s
            ON e.emp_id = s.emp_id
        WHERE e.emp_id = p_emp_id;

        v_clob :=
            '{' ||
            '"emp_id": ' || p_emp_id || ',' ||
            '"name": "' || v_name || '",' ||
            '"department": "' || v_dept || '",' ||
            '"salary": ' || NVL(v_salary,0) ||
            '}';

        RETURN v_clob;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN '{"error":"employee not found"}';
    END;

END pkg_hr_ops;
/


-- Milestone E

-- E1
CREATE OR REPLACE PACKAGE pkg_error IS

    ex_invalid_email EXCEPTION;
    ex_dept_not_found EXCEPTION;
    ex_invalid_salary EXCEPTION;
    ex_target_dept_not_found EXCEPTION;
    ex_employee_not_found EXCEPTION;

    PRAGMA EXCEPTION_INIT(ex_invalid_email, -20001);
    PRAGMA EXCEPTION_INIT(ex_dept_not_found, -20002);
    PRAGMA EXCEPTION_INIT(ex_invalid_salary, -20003);
    PRAGMA EXCEPTION_INIT(ex_target_dept_not_found, -20010);
    PRAGMA EXCEPTION_INIT(ex_employee_not_found, -20011);

END pkg_error;
/
