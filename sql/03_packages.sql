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
            RAISE_APPLICATION_ERROR(-20001, 'Invalid Email');
        END IF;

        SELECT COUNT(*) INTO v_count
        FROM cs_departments 
        WHERE dept_id = p_dept_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Department does not exist');
        END IF;

        IF p_salary < 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Invalid Salary');
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

END pkg_hr_ops;
/
