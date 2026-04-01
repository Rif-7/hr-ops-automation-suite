CREATE OR REPLACE VIEW vw_emp_payroll_latest 
AS
    SELECT e.emp_id,
           e.first_name,
           e.last_name,
           e.dept_id,
           e.manager_id,
           ps.snap_month,
           ps.gross_pay,
           ps.tax_amount,
           ps.net_pay
    FROM cs_employees e
    JOIN cs_payroll_snapshot ps
    ON (e.emp_id = ps.emp_id)
    WHERE ps.snap_month = (
        SELECT MAX(ps2.snap_month) 
        FROM cs_payroll_snapshot ps2
        WHERE ps2.emp_id = e.emp_id
    );
/


CREATE OR REPLACE PROCEDURE pr_emp_payroll_latest (
    p_dept_id IN cs_employees.emp_id%TYPE,
    p_out OUT SYS_REFCURSOR
) IS

BEGIN
    IF p_dept_id IS NULL THEN
        OPEN p_out FOR SELECT * FROM vw_emp_payroll_latest ORDER BY emp_id;
    ELSE
        OPEN p_out FOR SELECT * FROM vw_emp_payroll_latest WHERE dept_id = p_dept_id ORDER BY emp_id;
    END IF;
END;