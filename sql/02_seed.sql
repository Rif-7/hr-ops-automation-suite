SET SERVEROUTPUT ON

-- HR OPS AUTOMATION SUITE Seed Data

-- Insert Departments
BEGIN
    INSERT INTO cs_departments (dept_name, location) VALUES ('Engineering', 'Pune');
    INSERT INTO cs_departments (dept_name, location) VALUES ('HR', 'Mumbai');
    INSERT INTO cs_departments (dept_name, location) VALUES ('Finance', 'Bangalore');
    INSERT INTO cs_departments (dept_name, location) VALUES ('Sales', 'Delhi');
    INSERT INTO cs_departments (dept_name, location) VALUES ('Operations', 'Chennai');

    DBMS_OUTPUT.PUT_LINE('Departments inserted.');
END;
/

-- Insert Employees
DECLARE
    v_dept_id NUMBER;
BEGIN
    FOR i IN 1..20 LOOP
    
        v_dept_id := MOD(i,5) + 1;
    
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
            'Emp'||i,
            'User'||i,
            'emp'||i||'@company.com',
            RPAD(i, 10, i),
            v_dept_id,
            CASE
                WHEN i <= 5 THEN 'Manager'
                WHEN i <= 12 THEN 'Senior Engineer'
                ELSE 'Associate'
            END,
            CASE
                WHEN i <= 5 THEN NULL
                ELSE MOD(i,5)+1
            END
        );
    
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('20 Employees inserted.');

END;
/

-- Insert Salary Rows
DECLARE
BEGIN
    FOR r IN (SELECT * FROM cs_employees) LOOP
    
        INSERT INTO cs_employee_salary (
            emp_id,
            base_salary,
            bonus
        )
        VALUES (
            r.emp_id,
            CASE WHEN r.job_title = 'Manager' THEN 90000 WHEN r.job_title = 'Senior Engineer' THEN 60000 ELSE 25000 END + DBMS_RANDOM.VALUE(0,5000), 
            DBMS_RANDOM.VALUE(1000,5000)
        );
    
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Salary rows inserted.');

END;
/

-- Insert user rows
DECLARE
    v_man_id cs_employees.emp_id%TYPE;
    v_emp_id cs_employees.emp_id%TYPE;
BEGIN

    INSERT INTO cs_user_identity (db_username) VALUES('HR_OPS');

    -- Inserting Manager
    INSERT INTO cs_employees (
        first_name,
        last_name,
        email,
        phone,
        dept_id,
        job_title,
        manager_id
    ) VALUES (
        'Pep',
        'Guardiola',
        'pep@mcfc.com',
        '4444444444',
        1,
        'Manager',
        null
    ) RETURNING emp_id INTO v_man_id;

    INSERT INTO cs_user_identity (
        db_username,
        emp_id
    ) VALUES (
        'manager_pep',
        v_man_id
    );

    INSERT INTO cs_employee_salary (
        emp_id,
        base_salary
    ) VALUES (
        v_man_id,
        80000
    );


    INSERT INTO cs_employees (
        first_name,
        last_name,
        email,
        phone,
        dept_id,
        job_title,
        manager_id
    ) VALUES (
        'Kevin',
        'De Bruyne',
        'kdb@mcfc.com',
        '1717171717',
        1,
        'Senior Engineer',
        v_man_id
    ) RETURNING emp_id INTO v_emp_id;

    INSERT INTO cs_user_identity (
        db_username,
        emp_id
    ) VALUES (
        'employee_kevin',
        v_emp_id
    );

    INSERT INTO cs_employee_salary (
        emp_id,
        base_salary
    ) VALUES (
        v_emp_id,
        70000
    );

END;
/

COMMIT;
/
