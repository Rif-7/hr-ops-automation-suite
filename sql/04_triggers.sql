SET SERVEROUTPUT ON;

-- HR OPS AUTOMATION SUITE Triggers

-- Milestone F

-- F1
CREATE OR REPLACE TRIGGER tr_cs_employees_bu
BEFORE UPDATE ON cs_employees
FOR EACH ROW
BEGIN
    :new.updated_at := SYSDATE;
END;

CREATE OR REPLACE TRIGGER tr_employees_audit_aiud
AFTER INSERT OR UPDATE OR DELETE 
ON cs_employees
REFERENCING OLD AS old NEW AS new 
FOR EACH ROW
DECLARE
    v_details CLOB;
BEGIN
    IF inserting THEN
        v_details := 'Inserted employee ' || 
                     :new.first_name || ' ' || :new.last_name ||
                     ' with ID - ' || :new.emp_id;

        INSERT INTO cs_audit_log (
            table_name,
            action_type,
            pk_value,
            details
        ) VALUES (
            'cs_employees',
            'INSERT',
            to_char(:new.emp_id),
            v_details
            
        );

    ELSIF updating THEN
        v_details := 'Update Info: ' || CHR(10) ||
                     'Updated At: ' || :new.updated_at || CHR(10);

        IF :old.first_name != :new.first_name THEN
            v_details := v_details || 'Old first_name: ' || :old.first_name || '- New first_name: ' || :new.first_name || CHR(10);
        END IF;

        IF :old.last_name != :new.last_name THEN
            v_details := v_details || 'Old last_name: ' || :old.last_name || '- New last_name: ' || :new.last_name || CHR(10);
        END IF;

        IF :old.email != :new.email THEN
            v_details := v_details || 'Old email: ' || :old.email || '- New email: ' || :new.email || CHR(10);
        END IF;

        IF NVL(:old.phone, '0') != NVL(:new.phone, '0') THEN
            v_details := v_details || 'Old phone: ' || :old.phone || '- New phone: ' || :new.phone || CHR(10);        
        END IF;

        IF :old.dept_id != :new.dept_id THEN
            v_details := v_details || 'Old dept_id: ' || :old.dept_id || '- New dept_id: ' || :new.dept_id || CHR(10);
        END IF;

        IF :old.job_title != :new.job_title THEN
            v_details := v_details || 'Old job_title: ' || :old.job_title || '- New job_title: ' || :new.job_title || CHR(10);
        END IF;        


        IF NVL(:old.manager_id, -1) != NVL(:new.manager_id, -1) THEN
            v_details := v_details || 'Old manager_id: ' || :old.manager_id || '- New manager_id: ' || :new.manager_id || CHR(10);
        END IF;

        IF :old.status != :new.status THEN
            v_details := v_details || 'Old status: ' || :old.status || '- New status: ' || :new.status || CHR(10);
        END IF;


        INSERT INTO cs_audit_log (
            table_name,
            action_type,
            pk_value,
            details
        ) VALUES (
            'cs_employees',
            'UPDATE',
            to_char(:new.emp_id),
            v_details
        );
    
    ELSIF deleting THEN
        v_details := 'Delete employee ' || 
                     :old.first_name || ' ' || :old.last_name ||
                     ' with ID - ' || :old.emp_id;

        INSERT INTO cs_audit_log (
            table_name,
            action_type,
            pk_value,
            details
        ) VALUES (
            'cs_employees',
            'DELETE',
            to_char(:old.emp_id),
            v_details
            
        );
    END IF;

    
END;


CREATE OR REPLACE TRIGGER tr_cs_employee_salary_bu
BEFORE UPDATE ON cs_employee_salary
FOR EACH ROW
BEGIN
    :new.updated_at := SYSDATE;
END;


CREATE OR REPLACE TRIGGER tr_employee_salary_au
AFTER UPDATE 
ON cs_employee_salary
REFERENCING OLD AS old NEW as new 
FOR EACH ROW
DECLARE
    v_details CLOB;
BEGIN
    v_details := 'Update Info: ' || CHR(10) ||
                 'Updated At: ' || :new.updated_at || CHR(10);
    
    IF :old.base_salary != :new.base_salary THEN
        v_details := v_details || 'Old base_salary: ' || :old.base_salary || '- New base_salary: ' || :new.base_salary || CHR(10);
    END IF;

    IF :old.bonus != :new.bonus THEN
        v_details := v_details || 'Old bonus: ' || :old.bonus || '- New bonus: ' || :new.bonus || CHR(10);
    END IF;

    IF :old.currency != :new.currency THEN
        v_details := v_details || 'Old currency: ' || :old.currency || '- New currency: ' || :new.currency || CHR(10);
    END IF;

    INSERT INTO cs_audit_log (
        table_name,
        action_type,
        pk_value,
        details
    ) VALUES(
        'cs_employee_salary',
        'UPDATE',
        to_char(:new.emp_id),
        v_details
    );

END;