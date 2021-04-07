/* 18 */ --- FINISHED
CREATE OR REPLACE FUNCTION get_my_registrations(in_cust_id INTEGER)
RETURNS TABLE (course_name TEXT, course_fees INTEGER, sess_date DATE, sess_start_hour TIME, 
    sess_duration INTEGER, instr_name TEXT) AS $$
DECLARE
    curs CURSOR FOR (
        SELECT DISTINCT course_id, launch_date, sid, fees, s_date, start_time, end_time, eid
        FROM Registers NATURAL JOIN Sessions NATURAL JOIN
            (SELECT course_id, launch_date, reg_deadline, fees FROM Offerings) Off
        WHERE number IN (SELECT number FROM Credit_cards WHERE cust_id = in_cust_id)
            AND CURRENT_DATE <= reg_deadline
        ORDER BY s_date, start_time);
    r RECORD;
BEGIN
    OPEN curs;
    LOOP
        FETCH curs INTO r;
        EXIT WHEN NOT FOUND;
        course_name := (SELECT course_name FROM Courses C WHERE course_id = r.course_id);
        course_fees := r.fees;
        sess_date := r.s_date;
        sess_start_hour := r.start_time;
        sess_duration := (SELECT EXTRACT(HOUR FROM (r.end_time - r.start_time)));
        instr_name := (SELECT name FROM Employees WHERE eid = r.eid);
        RETURN NEXT;
    END LOOP;
    CLOSE curs;
END;
$$ LANGUAGE plpgsql;

/* 19 */ -- FINISHED
CREATE OR REPLACE PROCEDURE update_course_session(in_cust_id INTEGER, in_course_id INTEGER, 
    in_launch_date DATE, new_sess_id INTEGER) AS $$
DECLARE
    prev_sess_id INTEGER;
    prev_sess_rid INTEGER;
    prev_sess_eid INTEGER;
    sess_reg_ddl DATE;
    new_sess_rid INTEGER;
    new_sess_eid INTEGER;
    new_sess_seating_capacity INTEGER;
    new_sess_valid_reg_count INTEGER;
    cust_card_number INTEGER;
    /*prev_sess_date DATE;
    prev_sess_start_time TIME;
    new_sess_date DATE;
    new_sess_start_time TIME;*/
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Customers WHERE cust_id = in_cust_id) THEN 
        RAISE EXCEPTION 'The customer specified does not exist.';
    END IF;

    -- prev session information
    SELECT number, sid INTO cust_card_number, prev_sess_id
    FROM Registers
    WHERE course_id = in_course_id AND launch_date = in_launch_date
        AND number IN (SELECT number FROM Credit_cards WHERE cust_id = in_cust_id);

    -- new session information
    new_sess_rid := (SELECT rid FROM Sessions 
                    WHERE course_id = in_course_id AND launch_date = in_launch_date AND sid = new_sess_id);
    
    IF prev_sess_id IS NULL THEN 
        RAISE EXCEPTION 'Customer has not registered for the course specified.';
    ELSIF new_sess_rid IS NULL THEN 
        RAISE EXCEPTION 'The new session specified does not exist.';
    END IF;

    /* EITHER Checking for registration deadline */
    sess_reg_ddl := 
        (SELECT reg_deadline FROM Offerings 
        WHERE course_id = in_course_id AND launch_date = in_launch_date);
    IF CURRENT_DATE > sess_reg_ddl  -- > or >= ?
        THEN RAISE EXCEPTION 'No update on course sessions allowed after the registration deadline';
    END IF;
    /* OR Checking for time - if neither session has started */
    /*SELECT s_date, start_time INTO prev_sess_date 
        FROM Sessions WHERE course_id = c_id AND launch_date = launch_d AND sid = prev_sess_id;
    SELECT s_date, start_time INTO new_sess_date, new_sess_start_time
        FROM Sessions WHERE course_id = c_id AND launch_date = launch_d AND sid = new_sess_id;
    IF prev_sess_date + prev_sess_start_time <= CURRENT_TIMESTAMP OR new_sess_date + new_sess_end_time <= CURRENT_TIMESTAMP THEN  
        RAISE EXCEPTION 'Updates involving ongoing or finished session are not allowed.';
    END IF;*/

    new_sess_seating_capacity := (SELECT seating_capacity FROM Rooms WHERE rid = new_sess_rid);
    new_sess_valid_reg_count := (SELECT COUNT(*) FROM Registers 
                            WHERE course_id = in_course_id AND launch_date = in_launch_date AND sid = new_sess_id);

    IF new_sess_seating_capacity <= new_sess_valid_reg_count THEN 
        RAISE EXCEPTION 'No vacancy in the new session.';
    ELSE 
        UPDATE Registers 
        SET sid = new_sess_id
        WHERE course_id = in_course_id AND launch_date = in_launch_date AND sid = prev_sess_id 
            AND number = cust_card_number;
    END IF;
END;
$$ LANGUAGE plpgsql;


/* 20 */ -- FINISHED
CREATE OR REPLACE PROCEDURE cancel_registration(in_cust_id INTEGER, in_course_id INTEGER, in_launch_date DATE) AS $$
DECLARE
    reg_cust_card_number INTEGER;
    late_cancel BOOLEAN;
    sess_redeemed BOOLEAN;
    early_cancel_ddl DATE;
    refund_amt FLOAT;
    package_credit INTEGER;
    sess_id INTEGER;
    payment_date DATE;
    redeemed_package_id INTEGER;
BEGIN
    SELECT number, sid INTO reg_cust_card_number, sess_id 
    FROM Registers 
    WHERE number IN (SELECT number FROM Credit_cards WHERE cust_id = in_cust_id)
    AND course_id = in_course_id AND launch_date = launch_d;

    IF sess_id IS NULL THEN 
        RAISE EXCEPTION 'No registration to cancel';
    END IF;

    early_cancel_ddl := (SELECT (s_date - INTERVAL '7 DAYS') 
                        FROM Sessions 
                        WHERE sid = sess_id AND course_id = in_course_id AND launch_date = in_launch_date);
    late_cancel := CASE WHEN CURRENT_DATE > early_cancel_ddl THEN TRUE 
                        ELSE FALSE 
                    END;
    redeemed_package_id := (SELECT package_id 
                            FROM Redeems 
                            WHERE course_id = in_course_id AND launch_date = in_launch_date AND sid = sess_id
                            AND number IN (SELECT number FROM Credit_cards WHERE cust_id = in_cust_id));
    sess_redeemed := CASE WHEN redeemed_package_id IS NOT NULL THEN TRUE 
                        ELSE FALSE 
                    END;
    refund_amt := CASE 
                    WHEN (NOT sess_redeemed) AND (NOT late_cancel) THEN 
                        0.9 * (SELECT fees FROM Offerings 
                            WHERE course_id = in_course_id AND launch_date = in_launch_date)
                    WHEN (NOT sess_redeemed) AND late_cancel THEN 0
                    ELSE NULL 
                END;
    package_credit := CASE 
                        WHEN sess_redeemed AND (NOT late_cancel) THEN 1 
                        WHEN sess_redeemed AND late_cancel THEN 0
                        ELSE NULL 
                    END;
    payment_date := CASE
                        WHEN sess_redeemed THEN 
                            (SELECT b_date FROM Redeems
                            WHERE course_id = in_course_id AND launch_date = in_launch_date AND sid = sess_id
                                AND number = reg_cust_card_number)
                        ELSE (SELECT r_date FROM Registers 
                            WHERE course_id = in_course_id AND launch_date = in_launch_date AND sid = sess_id
                                AND number IN (SELECT number FROM Credit_cards WHERE cust_id = in_cust_id))
                    END;

    DELETE FROM Registers 
    WHERE number = reg_cust_card_number 
        AND course_id = in_course_id AND launch_date = in_launch_date AND sid = sess_id;

    INSERT INTO Cancels (c_date, refund_amt, package_credit, cust_id, course_id, 
            launch_date, sid, payment_date) 
    VALUES (CURRENT_DATE, refund_amt, package_credit, in_cust_id, in_course_id, 
            in_launch_date, sess_id, payment_date);
        
    IF sess_redeemed THEN
        DELETE FROM Redeems 
        WHERE course_id = in_course_id AND launch_date = in_launch_date AND sid = sess_id
            AND number IN (SELECT number FROM Credit_cards WHERE cust_id = in_cust_id);
        
        IF NOT late_cancel THEN
            UPDATE Buys 
            SET num_remaining_redemptions = num_remaining_redemptions + 1
            WHERE package_id = redeemed_package_id 
            AND number IN (SELECT number FROM Credit_cards WHERE cust_id = in_cust_id);
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;


/* 21 */ -- FINISHED
CREATE OR REPLACE PROCEDURE update_instructor(in_course_id INTEGER, in_launch_date DATE, 
    sess_id INTEGER, new_instr_id INTEGER) AS $$
DECLARE
    sess_date DATE;
    sess_start_time TIME;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Instructors WHERE eid = new_instr_id) THEN
        RAISE EXCEPTION 'The new instructor ID specified does not exist.';
    END IF;

    SELECT s_date, start_time INTO sess_date, sess_start_time 
    FROM Sessions 
    WHERE course_id = in_course_id AND launch_date = in_launch_date AND sid = sess_id;

    IF s_date IS NULL THEN 
        RAISE EXCEPTION 'Course Session specified does not exist.';
    ELSIF CURRENT_TIMESTAMP >= (sess_date + sess_start_time) THEN 
        RAISE EXCEPTION 'Changes cannot be made to an ongoing or finished session.';
    ELSE 
        UPDATE Sessions SET eid = new_instr_id 
        WHERE course_id = in_course_id AND launch_date = in_launch_date AND sid = sess_id;
    END IF;
END;
$$ LANGUAGE plpgsql;


/* 25 */ -- FINISHED
CREATE OR REPLACE FUNCTION pay_salary()
RETURNS TABLE(eid INTEGER, name TEXT, status TEXT, num_work_days INTEGER, 
	num_work_hours INTEGER, hourly_rate FLOAT, monthly_salary FLOAT, amount FLOAT) AS $$
DECLARE
	curs CURSOR FOR (SELECT * FROM Employees 
        WHERE depart_date IS NULL OR DATE_TRUNC('MONTH', depart_date) = DATE_TRUNC('MONTH', CURRENT_DATE)
        ORDER BY eid ASC);
	r RECORD;
	partTime BOOLEAN;
    depart_this_month BOOLEAN;
    join_this_month BOOLEAN;
    first_work_day DATE;
    last_work_day DATE;
    days_in_month INTEGER;
BEGIN
	OPEN curs;
	LOOP
		FETCH curs INTO r;
		EXIT WHEN NOT FOUND;
		eid := r.eid;
		name := r.name;
		partTime := (SELECT EXISTS(SELECT 1 FROM Part_time_emp PTE WHERE PTE.eid = r.eid));
        join_this_month := (SELECT DATE_TRUNC('MONTH', join_date) = DATE_TRUNC('MONTH', CURRENT_DATE));
        depart_this_month := (SELECT depart_date IS NOT NULL 
            AND DATE_TRUNC('MONTH', depart_date) = DATE_TRUNC('MONTH', CURRENT_DATE));
        first_work_day := 
            CASE 
                WHEN join_this_month THEN join_date
                ELSE DATE_TRUNC('MONTH', CURRENT_DATE) 
            END;
        last_work_day := 
            CASE
                WHEN depart_this_month THEN depart_date
                ELSE DATE_TRUNC('MONTH', CURRENT_DATE) + INTERVAL '1 MONTH' - INTERVAL '1 DAY' 
            END;

		IF partTime THEN 
			status := 'part-time';
			num_work_hours := 
                (SELECT SUM(sess_hours) FROM 
				    (SELECT ((EXTRACT(EPOCH FROM end_time)::INTEGER - EXTRACT(EPOCH FROM start_time)::INTEGER) / 3600) sess_hours
				    FROM Sessions S 
                    WHERE S.eid = r.eid 
                        AND s_date BETWEEN first_work_day 
                        AND last_work_day) AS Sess_hour_table );
			IF num_work_hours = 0 THEN 
                CONTINUE;
            END IF;
			num_work_days := NULL;
			hourly_rate := (SELECT hourly_rate FROM Part_time_emp PTE WHERE r.eid=PTE.eid);
			monthly_salary := NULL;
			amount := num_work_hours * hourly_rate;
		ELSE
			status := 'full-time';
			num_work_hours := NULL;
			num_work_days := (SELECT EXTRACT(DAY FROM last_work_day)::INTEGER - EXTRACT(DAY FROM first_work_day)::INTEGER + 1);
			IF num_work_days = 0 THEN 
                CONTINUE;
            END IF; -- Unnecessary
			hourly_rate := NULL;
			monthly_salary := (SELECT monthly_salary FROM Full_time_emp FTE WHERE FTE.eid = r.eid);
            days_in_month := (SELECT EXTRACT('DAY' FROM DATE_TRUNC('MONTH', CURRENT_DATE) + INTERVAL '1 MONTH' - INTERVAL '1 DAY'));
			amount := monthly_salary * (num_work_days / days_in_month);
		END IF;

		INSERT INTO Pay_slips (eid, payment_date, amt, num_work_hours, num_work_days) 
        VALUES (eid, CURRENT_DATE, amount, num_work_hours, num_work_days);

		RETURN NEXT;
	END LOOP;
	CLOSE curs;
END;
$$ LANGUAGE plpgsql;


/* 26 */
/*
CREATE OR REPLACE FUNCTION promote_courses()
RETURNS TABLE (cust_id INTEGER, cust_name TEXT, course_area TEXT, course_id INTEGER, 
    title_C TEXT, launch_date DATE, reg_deadline DATE, fees FLOAT) AS $$
DECLARE
    curs CURSOR FOR (SELECT * FROM Customers
        WHERE NOT EXISTS (SELECT 1 FROM Registers WHERE r_date < (CURRENT_DATE - INTERVAL '6 MONTHS'))
        ORDER BY cust_id ASC);
	r RECORD;
    no_registration BOOLEAN;
BEGIN
    OPEN curs;
	LOOP
		FETCH curs INTO r;
		EXIT WHEN NOT FOUND;
        cust_id := r.cust_id;
        name := r.cust_name;
        no_registration := CASE
            WHEN 0 = SELECT COUNT(*) FROM Registers 
                WHERE number IN (SELECT number FROM Credit_cards WHERE cust_id = r.cust_id) THEN TRUE
                ELSE FALSE END;
        FOR (course_area_interest IN 
            WITH 
            Areas_not_interest AS (
                SELECT course_id
                FROM Registers R
                WHERE number IN (SELECT number FROM Credit_cards WHERE cust_id = r.cust_id)
                ORDER BY r_date DESC
                LIMIT 3
            )
            SELECT course_area_name
            FROM Courses_areas
            WHERE NOT EXISTS (
                SELECT 1 FROM Areas_not_interest ANI
                WHERE ANI.course_id = C.course_id))
        LOOP
            course_area := SELECT course_area_name FROM Course_areas WHERE course_id = 

        RETURN NEXT;
	END LOOP;
	CLOSE curs;
END;
$$ LANGUAGE plpgsql;*/


/* 27 */
CREATE OR REPLACE FUNCTION top_packages(top_limit_num INTEGER)
RETURNS TABLE (package_id INTEGER, num_free_registrations INTEGER, price FLOAT, sale_start_date DATE,
    sale_end_date DATE, num_package_sold INTEGER) AS $$
BEGIN
    RETURN QUERY
    WITH 
    Info_table AS (
        SELECT package_id, num_free_registrations, price, 
            sale_start_date, sale_end_date, COUNT(*) AS num_package_sold
        FROM Buys NATURAL JOIN Course_packages
        WHERE sale_start_date >= DATE_TRUNC('YEAR', CURRENT_DATE) 
        GROUP BY package_id
    ),
    Nth_info AS (
        SELECT num_package_sold, price
        FROM Info_table
        ORDER BY num_package_sold DESC, price DESC
        LIMIT 1
        OFFSET top_limit_num - 1
    )
    SELECT *
    FROM Info_table
    WHERE num_package_sold > (SELECT MAX(num_package_sold) FROM Nth_info)
        OR (num_package_sold = (SELECT MAX(num_package_sold) FROM Nth_info)
            AND price >= (SELECT MAX(price) FROM Nth_info));
END;
$$ LANGUAGE plpgsql;


/* 28 */
CREATE OR REPLACE FUNCTION popular_courses() 
RETURNS TABLE (course_id INTEGER, course_title TEXT, course_area TEXT, 
    num_offerings INTEGER, num_reg_latest_off INTEGER) AS $$
BEGIN 
    RETURN QUERY
    WITH
    Curr_year_offerings AS (
        SELECT course_id, launch_date, start_date, 
            (SELECT COUNT(*) FROM Registers R 
            WHERE R.course_id = O.course_id AND R.launch_date = O.launch_date) num_reg
        FROM Offerings O
        WHERE start_date >= DATE_TRUNC('YEAR', CURRENT_DATE)
    ),
    Multi_off_courses AS (
        SELECT course_id, COUNT(*) num_offerings, MAX(num_reg) num_reg_latest_off
        FROM Curr_year_offerings
        GROUP BY course_id
        HAVING COUNT(*) >= 2
    )
    SELECT course_id, 
        (SELECT title FROM Courses C WHERE C.course_id = M.course_id) AS course_title,
        (SELECT course_area_name FROM Courses C WHERE C.course_id = M.course_id) AS course_area,
        num_offerings, num_reg_latest_off
    FROM Multi_off_courses M
    WHERE NOT EXISTS 
        (SELECT 1 FROM Curr_year_offerings A, Curr_year_offerings B
        WHERE M.course_id = A.course_id AND A.course_id = B.course_id 
            AND A.launch_date <> B.launch_date AND A.start_date < B.start_date 
            AND A.num_reg >= B.num_reg)
    ORDER BY num_reg_latest_off DESC, course_id ASC;
END;
$$ LANGUAGE plpgsql;


/* 29 */
CREATE OR REPLACE FUNCTION view_summary_report(num_month INTEGER) 
RETURNS TABLE (month INTEGER, year INTEGER, total_salary FLOAT, total_packages_sales_amt FLOAT, 
    total_reg_fees_card FLOAT, total_amt_refunded_fees FLOAT, total_num_reg_redeem INTEGER) AS $$
DECLARE
    first_day_of_month DATE := DATE_TRUNC('MONTH', CURRENT_DATE);
    last_day_of_month DATE := DATE_TRUNC('MONTH', CURRENT_DATE + INTERVAL '1 MONTH') - INTERVAL '1 DAY';
BEGIN
    FOR num_month_counter IN 1..num_month 
    LOOP
        month := (SELECT EXTRACT ('MONTH' FROM first_day_of_month));
        year := (SELECT EXTRACT ('YEAR' FROM first_day_of_month));
        total_salary := (SELECT SUM(amt) 
                        FROM Pay_slips 
                        WHERE payment_date BETWEEN first_day_of_month AND last_day_of_month);
        total_packages_sales_amt := 
            (SELECT SUM(package_sale_amt) 
            FROM (
                SELECT (price * COUNT(*)) package_sale_amt
                FROM Buys NATURAL JOIN Course_packages
                WHERE b_date BETWEEN first_day_of_month AND last_day_of_month
                GROUP BY package_id, price) AS Package_sale_amt_table);
        total_reg_fees_card := 
            (SELECT SUM(offering_fees) 
            FROM
                (SELECT COUNT(*) * (SELECT fees 
                                    FROM Offerings O 
                                    WHERE O.course_id = Rgst.course_id 
                                    AND O.launch_date = Rgst.launch_date) offering_fees
                FROM Registers Rgst
                WHERE NOT EXISTS (
                    SELECT 1 FROM Redeems Rdm 
                    WHERE Rdm.course_id = Rgst.course_id AND Rdm.launch_date = Rgst.launch_date AND Rdm.sid = Rgst.sid
                        AND Rdm.number = Rgst.number)
                GROUP BY course_id, launch_date) off_fees)
            + 
            (SELECT SUM(offering_fees) 
            FROM
                (SELECT (COUNT(*) * (SELECT fees 
                                FROM Offerings O 
                                WHERE O.course_id = Rgst.course_id AND O.launch_date = Rgst.launch_date)) AS offering_fees
                FROM Cancels C
                WHERE refund_amt IS NOT NULL
                GROUP BY course_id, launch_date) off_fees_table);
        total_amt_refunded_fees := 
            (SELECT SUM(refund_amt) 
            FROM Cancels
            WHERE c_date BETWEEN first_day_of_month AND last_day_of_month);
        total_num_reg_redeem := 
            (SELECT COUNT(*) 
            FROM Redeems 
            WHERE r_date BETWEEN first_day_of_month AND last_day_of_month);
        RETURN NEXT;
        first_day_of_month := first_day_of_month - INTERVAL '1 MONTH';
        last_day_of_month := last_day_of_month - INTERVAL '1 MONTH';
    END LOOP;
END;
$$ LANGUAGE plpgsql;


/* 30 */
CREATE OR REPLACE FUNCTION view_manager_report()
RETURNS TABLE (manager_name TEXT, num_course_areas INTEGER, num_co_ending_this_year INTEGER,
    net_reg_fees_co_ending_this_year FLOAT, co_title_highest_net_reg_fees TEXT[]) AS $$
DECLARE
    r RECORD;
    first_day_of_year DATE := DATE_TRUNC('YEAR', CURRENT_DATE);
    last_day_of_year DATE := DATE_TRUNC('YEAR', CURRENT_DATE) + INTERVAL '1 YEAR' - INTERVAL '1 DAY';
BEGIN
    FOR r IN SELECT * FROM Managers NATURAL JOIN Employees ORDER BY name ASC 
    LOOP
        manager_name := r.name;
        num_course_areas := (SELECT COUNT(*) FROM Course_areas WHERE eid = r.manager_id);
        num_co_ending_this_year := (SELECT COUNT(*)
                                    FROM (SELECT course_id, launch_date, end_date FROM Offerings) O
                                        NATURAL JOIN (SELECT course_id, course_area_name FROM Courses) C
                                        NATURAL JOIN (SELECT * FROM Course_areas) CA
                                    WHERE (end_date BETWEEN first_day_of_year AND last_day_of_year)
                                        AND eid = r.manager_id);
        WITH
        Valid_course_offs AS (
            SELECT course_id, launch_date, fees
            FROM (SELECT course_id, launch_date, fees, end_date FROM Offerings) O
                NATURAL JOIN (SELECT course_id, course_area_name FROM Courses) C
                NATURAL JOIN (SELECT * FROM Course_areas) CA
            WHERE (end_date BETWEEN first_day_of_year AND last_day_of_year)
            AND eid = r.manager_id
        ),
        Card_reg_fees_in_Registers AS (
            SELECT (COUNT(*) * fees) registers_card_reg_fees, course_id, launch_date
            FROM 
                ((SELECT course_id, launch_date, fees
                FROM Registers NATURAL JOIN Valid_course_offs)
                EXCEPT ALL
                (SELECT course_id, launch_date, fees
                FROM Redeems NATURAL JOIN Valid_course_offs)) Card_regs
            GROUP BY course_id, launch_date, fees
        ),
        Net_cancelled_card_reg_fees AS (
            SELECT (COUNT(*) * fees - SUM(refund_amt)) cancels_card_reg_fees, course_id, launch_date
            FROM Cancels NATURAL JOIN Valid_course_offs
            WHERE package_credit IS NULL
            GROUP BY course_id, launch_date, fees
        ),
        No_credit_back_late_cancel_redemp_reg_fees AS (
            SELECT course_id, launch_date, 
                SUM(reg_fees) cancels_redemp_reg_fees,
                (SELECT ROUND(price / num_free_registrations) session_price
                FROM Course_packages 
                WHERE package_id = 
                    (SELECT package_id 
                    FROM Buys 
                    WHERE b_date = CV.payment_date
                    AND number IN (SELECT number FROM Credit_cards WHERE cust_id = CV.cust_id)
                    LIMIT 1)) reg_fees
            FROM (Cancels NATURAL JOIN Valid_course_offs) CV
            WHERE refund_amt IS NULL AND package_credit = 0
            GROUP BY course_id, launch_date
        ),
        Redemption_fees_Redeems AS (
            SELECT course_id, launch_date, 
                SUM(reg_fees) redeems_redemp_reg_fees,
                (SELECT ROUND(price / num_free_registrations) AS session_price
                FROM Course_packages 
                WHERE package_id = RV.package_id) AS reg_fees
            FROM (Redeems NATURAL JOIN Valid_course_offs) RV
            GROUP BY course_id, launch_date
        ),
        Course_off_fees AS (
            SELECT course_id, launch_date, 
                (registers_card_reg_fees + cancels_card_reg_fees + cancels_redemp_reg_fees + redeems_redemp_reg_fees) AS net_co_reg_fees
            FROM Card_reg_fees_in_Registers
            NATURAL JOIN Net_cancelled_card_reg_fees
            NATURAL JOIN No_credit_back_late_cancel_redemp_reg_fees
            NATURAL JOIN Redemption_fees_Redeems
        )
        SELECT SUM(net_co_reg_fees), 
            ARRAY(SELECT title FROM Courses 
                WHERE course_id = (SELECT course_id FROM Course_off_fees 
                                    HAVING net_co_reg_fees = (SELECT MAX(net_co_reg_fees) 
                                                            FROM Course_off_fees)))
        INTO net_reg_fees_co_ending_this_year, co_title_highest_net_reg_fees
        FROM Course_off_fees COF;

        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;