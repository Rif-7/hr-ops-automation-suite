SET SERVEROUTPUT ON;


-- HR OPS AUTOMATION SUITE VPD's

CREATE OR REPLACE FUNCTION fn_vpd_salary_policy (
    p_schema IN VARCHAR2,
    p_object IN VARCHAR2
)
RETURN VARCHAR2
IS
    l_emp_id  NUMBER       := SYS_CONTEXT('HR_CTX', 'EMP_ID');
    l_role    VARCHAR2(20) := SYS_CONTEXT('HR_CTX', 'ROLE_TYPE');
BEGIN
    IF l_role = 'HR_ADMIN' THEN
        RETURN '1 = 1';

    ELSIF l_role = 'MANAGER' THEN
        RETURN
        'emp_id IN (
             SELECT emp_id
             FROM cs_employees
             WHERE manager_id = ' || l_emp_id || '
         )';

    ELSIF l_role = 'EMPLOYEE' THEN
        RETURN 'emp_id = ' || l_emp_id;

    ELSE
        RETURN '1 = 0';
    END IF;
END;
/

BEGIN
    DBMS_RLS.ADD_POLICY(
        object_schema   => USER,
        object_name     => 'CS_EMPLOYEE_SALARY',
        policy_name     => 'VPD_SALARY_ACCESS',
        function_schema => USER,
        policy_function => 'FN_VPD_SALARY_POLICY',
        statement_types => 'SELECT',
        update_check    => TRUE
    );
END;
/
