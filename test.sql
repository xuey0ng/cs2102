/* Sample valid data */

/* All dates start from this month and increment accordingly. If an 'expired' date is needed
it's march*/
/* one-indexed. Rid increments by 1, Locations are a single capital letter increment by 1, 
seating capacity == rid*/
DELETE FROM Redeems;
DELETE FROM Registers;
DELETE FROM Cancels;
DELETE FROM Sessions;
DELETE FROM Offerings;
DELETE FROM Rooms;
DELETE FROM Specializes;
DELETE FROM Offerings;
DELETE FROM Courses;
DELETE FROM Course_areas;
DELETE FROM Managers;
DELETE FROM Administrators;
DELETE FROM Part_time_instructors;
DELETE FROM Full_time_instructors;
DELETE FROM Instructors;
DELETE FROM Part_time_emp;
DELETE FROM Full_time_emp;
DELETE FROM Buys;
DELETE FROM Credit_cards;
DELETE FROM Customers;
DELETE FROM Pay_slips;
DELETE FROM Employees;
DELETE FROM Course_packages;
-- RESETS serial number
TRUNCATE Customers RESTART IDENTITY CASCADE;
TRUNCATE Employees RESTART IDENTITY CASCADE;
TRUNCATE Courses RESTART IDENTITY CASCADE;
TRUNCATE Offerings RESTART IDENTITY CASCADE;
TRUNCATE Course_packages RESTART IDENTITY CASCADE;
TRUNCATE Rooms RESTART IDENTITY CASCADE;
insert into Rooms(rid, location, seating_capacity) values (1,'A', 1);
insert into Rooms values (2,'room_B', 2);
insert into Rooms values (3,'room_C', 3);
insert into Rooms values (4,'room_D', 4);
insert into Rooms values (5,'room_E', 5);
insert into Rooms values (6,'room_A1', 1);
insert into Rooms values (7,'room_B1', 2);
insert into Rooms values (8,'room_C1', 3);
/* add course areas and its employee. name prefixed with pti, fti, m or a.
(name TEXT, address TEXT, phone INTEGER, email TEXT, 
             salary_or_hourly_rate FLOAT, join_date DATE, category TEXT, 
             course_areas)
*/

CALL add_employee('m_A', 'addr_A', 10000000, 'A@A.com', 100.0, '2021-04-01', 'manager', '{"course_area_A"}');
CALL add_employee('m_B', 'addr_B', 20000000, 'B@B.com', 200.0, '2021-04-02', 'manager', '{"course_area_B"}');
CALL add_employee('m_C', 'addr_C', 30000000, 'C@C.com', 300.0, '2021-04-03', 'manager', '{"course_area_C"}');
CALL add_employee('m_D', 'addr_D', 30000000, 'D@D.com', 300.0, '2021-04-03', 'manager', '{"course_area_qn10"}');
CALL add_employee('pti_A', 'addr_A', 10000000, 'A@A.com', 1.0, '2021-04-01', 'part time instructor', '{"course_area_A"}');
CALL add_employee('pti_B', 'addr_B', 20000000, 'B@B.com', 2.0, '2021-04-02', 'part time instructor', '{"course_area_B"}');
CALL add_employee('pti_C', 'addr_C', 30000000, 'C@C.com', 3.0, '2021-04-03', 'part time instructor', '{"course_area_C"}');
CALL add_employee('pti_D', 'addr_D', 10000000, 'D@D.com', 1.0, '2021-04-01', 'part time instructor', '{"course_area_qn10"}');
CALL add_employee('pti_D2', 'addr_D2', 10000000, 'D2@D.com', 1.0, '2021-04-01', 'part time instructor', '{"course_area_qn10"}');
CALL add_employee('fti_A', 'addr_A', 10000000, 'A@A.com', 100, '2021-04-01', 'full time instructor', '{"course_area_A"}');
--10
CALL add_employee('fti_B', 'addr_B', 20000000, 'B@B.com', 200, '2021-04-02', 'full time instructor', '{"course_area_B"}');
CALL add_employee('fti_C', 'addr_C', 30000000, 'C@C.com', 300, '2021-04-03', 'full time instructor', '{"course_area_C"}');
CALL add_employee('a_A', 'addr_A', 10000000, 'A@A.com', 100, '2021-04-01', 'administrator', '{}');
CALL add_employee('a_B', 'addr_B', 20000000, 'B@B.com', 200, '2021-04-02', 'administrator', '{}');
CALL add_employee('a_C', 'addr_C', 30000000, 'C@C.com', 300, '2021-04-03', 'administrator', '{}');
CALL add_customer('c_A', 'addr_A', 10000000, 'A@A.com', 1, '2021-04-30', 1);
CALL add_customer('c_B', 'addr_B', 20000000, 'B@B.com', 20, '2021-04-03', 20);
CALL add_customer('c_C', 'addr_C', 30000000, 'C@C.com', 3, '2021-04-30', 3);
CALL add_customer('c_D', 'addr_D', 20000000, 'D@D.com', 4, '2021-04-30', 4);
CALL add_customer('c_E', 'addr_E', 30000000, 'E@E.com', 5, '2021-04-30', 5);
--20
/*  function 4 (cid INTEGER, cnumber INTEGER, cexpiry_date DATE, cvv INTEGER)*/
CALL update_credit_card(2, 2, '2021-04-30', 2);

/* function 5 (title TEXT, description TEXT, area TEXT, duration INTEGER) */
CALL add_course('course_A1', 'course_A1', 'course_area_A',1);
CALL add_course('course_D2', 'course_D2', 'course_area_qn10',4);  
CALL add_course('course_D', 'course_D', 'course_area_qn10',1);   

/* function 11 (p_name TEXT, num_free INTEGER,
                start_date DATE, end_date DATE, p_price FLOAT)*/
CALL add_course_packages('Home Ing', 1, '2021-04-04', '2021-04-29', 61.61);
CALL add_course_packages('Greenlam', 2, '2021-04-02', '2021-04-27', 82.97);
CALL add_course_packages('Namfix', 3, '2021-04-03', '2021-04-24', 7.08);
CALL add_course_packages('Matsoft', 4, '2021-04-04', '2021-04-25', 38.12);
CALL add_course_packages('Toughjoyfax', 5, '2021-04-02', '2021-04-24', 43.63);
CALL add_course_packages('Fix San', 6, '2021-04-02', '2021-04-22', 14.54);
CALL add_course_packages('Domainer', 7, '2021-04-04', '2021-04-28', 88.39);
CALL add_course_packages('Lotlux', 8, '2021-04-01', '2021-04-29', 4.91);
CALL add_course_packages('Temp', 9, '2021-04-02', '2021-04-20', 17.54);
CALL add_course_packages('Kanlam', 10, '2021-04-04', '2021-04-18', 29.7);
CALL add_course_packages('Transcof', 11, '2021-04-01', '2021-04-24', 95.06);
CALL add_course_packages('Hatity', 12, '2021-04-03', '2021-04-25', 73.2);
CALL add_course_packages('Regrant', 13, '2021-04-03', '2021-04-26', 5.17);
CALL add_course_packages('Fintone', 14, '2021-04-01', '2021-04-24', 2.06);
CALL add_course_packages('Home Ing', 15, '2021-04-04', '2021-04-26', 70.93);
CALL add_course_packages('Gembucket', 16, '2021-04-03', '2021-04-26', 68.38);
CALL add_course_packages('Job', 17, '2021-04-03', '2021-04-23', 55.69);
CALL add_course_packages('Viva', 18, '2021-04-03', '2021-04-25', 73.84);
CALL add_course_packages('Cardify', 19, '2021-04-01', '2021-04-21', 8.87);
CALL add_course_packages('Cardguard', 20, '2021-04-04', '2021-04-21', 70.74);
CALL add_course_packages('Ronstring', 21, '2021-04-01', '2021-04-19', 94.54);
CALL add_course_packages('Stim', 22, '2021-04-03', '2021-04-23', 47.94);
CALL add_course_packages('Toughjoyfax', 23, '2021-04-03', '2021-04-25', 74.98);
CALL add_course_packages('Cookley', 24, '2021-04-04', '2021-04-27', 61.97);
CALL add_course_packages('Otcom', 25, '2021-04-02', '2021-04-18', 14.9);
CALL add_course_packages('Stronghold', 26, '2021-04-02', '2021-04-24', 75.4);
CALL add_course_packages('Lotlux', 27, '2021-04-03', '2021-04-25', 88.8);
CALL add_course_packages('Ronstring', 28, '2021-04-03', '2021-04-22', 50.74);
CALL add_course_packages('Rank', 29, '2021-04-01', '2021-04-28', 56.25);
CALL add_course_packages('Sonair', 30, '2021-04-01', '2021-04-22', 94.5);
CALL add_course_packages('Holdlamis', 31, '2021-04-01', '2021-04-24', 70.66);
CALL add_course_packages('Bigtax', 32, '2021-04-03', '2021-04-22', 33.67);
CALL add_course_packages('Lotstring', 33, '2021-04-04', '2021-04-24', 52.37);
CALL add_course_packages('Redhold', 34, '2021-04-04', '2021-04-28', 76.85);
CALL add_course_packages('Cardify', 35, '2021-04-03', '2021-04-25', 16.8);
CALL add_course_packages('Vagram', 36, '2021-04-03', '2021-04-28', 1.3);
CALL add_course_packages('Zontrax', 37, '2021-04-04', '2021-04-18', 5.41);
CALL add_course_packages('Regrant', 38, '2021-04-24', '2021-04-28', 45.61);
CALL add_course_packages('Cookley', 39, '2021-04-05', '2021-04-06', 38.98);
CALL add_course_packages(NULL, 40, '2021-04-04', '2021-04-18', 1.08);

/* function 12 */
-- SELECT * FROM get_available_course_packages(); -- expect 38 results

/* Test case for 6 and 10 */
INSERT INTO Offerings VALUES
(2, '2021-03-01', '2021-04-01', '2021-04-11', '2021-03-10', 10, 10, 1.0, 13);

/* ------------------------------- Assign sessions ----------------------------- */
INSERT INTO Sessions (sid, s_date, start_time, end_time, course_id ,
    launch_date, rid, eid)
VALUES
(9, '2021-04-01', '09:00:00', 
'10:00:00', 2, '2021-03-01', 1, 9);
INSERT INTO Sessions VALUES
(10, '2021-04-01', '11:00:00', 
'12:00:00', 2, '2021-03-01', 1, 9);
/* --------------  1 hr left --------------*/
INSERT INTO Sessions VALUES
(1, '2021-04-02', '14:00:00', 
'18:00:00', 2, '2021-03-01', 2, 8);
INSERT INTO Sessions VALUES
(2, '2021-04-03', '14:00:00', 
'18:00:00', 2, '2021-03-01', 2, 8);
INSERT INTO Sessions VALUES
(3, '2021-04-04', '14:00:00', 
'18:00:00', 2, '2021-03-01', 2, 8);
INSERT INTO Sessions VALUES
(4, '2021-04-05', '14:00:00', 
'18:00:00', 2, '2021-03-01', 2, 8);
INSERT INTO Sessions VALUES
(5, '2021-04-06', '14:00:00', 
'18:00:00', 2, '2021-03-01', 2, 8);
INSERT INTO Sessions VALUES
(6, '2021-04-07', '14:00:00', 
'18:00:00', 2, '2021-03-01', 2, 8);
INSERT INTO Sessions VALUES
(7, '2021-04-08', '14:00:00', 
'18:00:00', 2, '2021-03-01', 2, 8);
INSERT INTO Sessions VALUES
(8, '2021-04-10', '17:00:00', 
'18:00:00', 2, '2021-03-01', 1, 8);
/* -----------------------------------------------*/



/* ------- Qn 10 Test case -----------*/
-- CALL add_course_offering(3, 1.0,'2021-03-02','2021-03-15', 2, 13, 
-- ('2021-04-02', '09:00:00', 2), ('2021-04-02', '10:00:00', 1), ('2021-04-02', '11:00:00', 2));    
-- CALL add_course_offering(3, 1.0,'2021-03-02','2021-03-15', 2, 13, 
-- ('2021-04-02', '09:00:00', 2), ('2021-04-02', '10:00:00', 1), ('2021-04-02', '10:00:00', 2));// expect fail