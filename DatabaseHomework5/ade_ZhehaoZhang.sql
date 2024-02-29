-- HW5: Identifying Adverse Drug Events (ADEs) with Stored Programs
-- Prof. Rachlin
-- CS 3200 / CS5200: Databases

-- We've already setup the ade database by running ade_setup.sql
-- First, make ade the active database.  Note, this database is actually based on
-- the emr_sp schema used in the lab, but it included some extra tables.

use ade;



-- A stored procedure to process and validate prescriptions
-- Four things we need to check
-- a) Is patient a child and is medication suitable for children?
-- b) Is patient pregnant and is medication suitable for pregnant women?
-- c) Are there any adverse drug reactions


drop procedure if exists prescribe;

delimiter //
create procedure prescribe
(
    in patient_name_param varchar(255),
    in doctor_name_param varchar(255),
    in medication_name_param varchar(255),
    in ppd_param int -- pills per day prescribed
)
begin
	-- variable declarations
    declare patient_id_var int;
    declare age_var float;
    declare is_pregnant_var boolean;
    declare weight_var int;
    declare doctor_id_var int;
    declare medication_id_var int;
    declare take_under_12_var boolean;
    declare take_if_pregnant_var boolean;
    declare mg_per_pill_var double;
    declare max_mg_per_10kg_var double;

    declare message varchar(255); -- The error message
    declare ddi_medication varchar(255); -- The name of a medication involved in a drug-drug interaction

    -- select relevant values into variables
	SELECT p.patient_id, 
       TIMESTAMPDIFF(YEAR, p.dob, CURDATE()), 
       p.is_pregnant, 
       p.weight 
INTO patient_id_var, 
     age_var, 
     is_pregnant_var, 
     weight_var 
FROM patient p
WHERE p.patient_name = patient_name_param;

SELECT d.doctor_id 
INTO doctor_id_var 
FROM doctor d
WHERE d.doctor_name = doctor_name_param;

SELECT m.medication_id, 
       m.take_under_12, 
       m.take_if_pregnant, 
       m.mg_per_pill, 
       m.max_mg_per_10kg 
INTO medication_id_var, 
     take_under_12_var, 
     take_if_pregnant_var, 
     mg_per_pill_var, 
     max_mg_per_10kg_var 
FROM medication m
WHERE m.medication_name = medication_name_param;

    -- check age of patient
   IF age_var < 12 THEN
   IF take_under_12_var = FALSE THEN
   SET message = CONCAT(medication_name_param, ' cannot be prescribed to children under 12.');
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = message;
   END IF;
   END IF;

    -- check if medication ok for pregnant women
    IF is_pregnant_var = TRUE THEN
        IF take_if_pregnant_var = FALSE THEN
            -- Instead of signaling an error, log this information
            INSERT INTO prescription_log (patient_id, medication_id, log_message)
            VALUES (patient_id_var, medication_id_var, CONCAT(medication_name_param, ' was prescribed to pregnant patient ', patient_name_param));
            -- Optionally, you can still continue to insert the prescription or choose to skip it
        END IF;
    END IF;

    -- Check for reactions involving medications already prescribed to patient
	SELECT m2.medication_name INTO ddi_medication
    FROM prescription AS p
    JOIN interaction AS i ON p.medication_id = i.medication_1 OR p.medication_id = i.medication_2
    JOIN medication AS m2 ON m2.medication_id = i.medication_2 OR m2.medication_id = i.medication_1
    WHERE p.patient_id = patient_id_var AND (i.medication_1 = medication_id_var OR i.medication_2 = medication_id_var)
    LIMIT 1;

    IF ddi_medication IS NOT NULL THEN
	SET message = CONCAT(medication_name_param, ' interacts with ', ddi_medication, ' currently prescribed to ', patient_name_param);
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = message;
    END IF;

    -- No exceptions thrown, so insert the prescription record
    INSERT INTO prescription (medication_id, patient_id, doctor_id, ppd)
    VALUES (medication_id_var, patient_id_var, doctor_id_var, ppd_param);
end //
delimiter ;



-- Trigger

DROP TRIGGER IF EXISTS patient_after_update_pregnant;

DELIMITER //

CREATE TRIGGER patient_after_update_pregnant
	AFTER UPDATE ON patient
	FOR EACH ROW
BEGIN

    -- Patient became pregnant
    IF NEW.is_pregnant THEN
    -- Add pre-natal recommenation
    INSERT INTO recommendation (patient_id, message) VALUES (NEW.patient_id, 'Take pre-natal vitamins');
    -- Delete any prescriptions that shouldn't be taken if pregnant
    DELETE FROM prescription
            WHERE patient_id = NEW.patient_id
            AND medication_id IN (SELECT medication_id FROM medication WHERE take_if_pregnant = FALSE);
        END IF;
    -- Patient is no longer pregnant
    IF NOT NEW.is_pregnant THEN
    -- Remove pre-natal recommendation
    DELETE FROM recommendation
            WHERE patient_id = NEW.patient_id
            AND message = 'Take pre-natal vitamins';
        END IF;
	
END //

DELIMITER ;



-- --------------------------                  TEST CASES                     -----------------------
-- -------------------------- DONT CHANGE BELOW THIS LINE! -----------------------
-- Test cases
truncate prescription;

-- These prescriptions should succeed
call prescribe('Jones', 'Dr.Marcus', 'Happyza', 2);
call prescribe('Johnson', 'Dr.Marcus', 'Forgeta', 1);
call prescribe('Williams', 'Dr.Marcus', 'Happyza', 1);
call prescribe('Phillips', 'Dr.McCoy', 'Forgeta', 1);

-- These prescriptions should fail
-- Pregnancy violation
call prescribe('Jones', 'Dr.Marcus', 'Forgeta', 2);

-- Age restriction
call prescribe('BillyTheKid', 'Dr.Marcus', 'Muscula', 1);


-- Drug interaction
call prescribe('Williams', 'Dr.Marcus', 'Sadza', 1);



-- Testing trigger
-- Phillips (patient_id=4) becomes pregnant
-- Verify that a recommendation for pre-natal vitamins is added
-- and that her prescription for
update patient
set is_pregnant = True
where patient_id = 4;

select * from recommendation;
select * from prescription;


-- Phillips (patient_id=4) is no longer pregnant
-- Verify that the prenatal vitamin recommendation is gone
-- Her old prescription does not need to be added back

update patient
set is_pregnant = False
where patient_id = 4;

select * from recommendation;
