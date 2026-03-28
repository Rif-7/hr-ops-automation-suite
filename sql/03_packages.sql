SET SERVEROUTPUT ON;


-- HR OPS AUTOMATION SUITE Packages and Procedures


CREATE OR REPLACE PROCEDURE pr_onboard_employee (
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
    IF INSTR(p_email, '@') = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid Email');
    END IF;

    SELECT COUNT(*) dept_id INTO v_count
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
/

 