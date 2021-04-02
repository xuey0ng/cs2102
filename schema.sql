/* Missing roles, most relationships */

-- <---------------------- Customer side ---------------------->
CREATE TABLE Customers (
    cust_id INTEGER PRIMARY KEY,
    name VARCHAR(256),
    phone INTEGER,
    email VARCHAR(256),
    address TEXT,
);

CREATE TABLE Rooms (
    rid INTEGER PRIMARY KEY,
    location TEXT,
    seating_capacity INTEGER
);


CREATE TABLE Course_areas (
    name CHAR(256)
)


CREATE TABLE Course_packages (
    package_id INTEGER PRIMARY KEY,
    sale_start_date DATE,
    num_free_registrations INTEGER,
    sale_end_date DATE,
    name VARCHAR(256),
    price FLOAT
);

CREATE TABLE Credit_cards (
    number INTEGER PRIMARY KEY,
    CVV INTEGER,
    expiry_date DATE
)

CREATE TABLE Courses (
    course_id INTEGER PRIMARY KEY,
    duration FLOAT,
    description TEXT,
    title VARCHAR(256)
)

/* dk why is seating_capacity here tbh */
CREATE TABLE Offerings (
    course_id INTEGER REFERENCES Courses ON DELETE CASCADE,
    launch_date DATE,
    end_date DATE,
    start_date DATE,
    registration_deadline DATE,
    target_number_registrations INTEGER,
    seating_capacity INTEGER,
    fees FLOAT,
    PRIMARY KEY (course_id, launch_date)
);

CREATE TABLE Sessions (
    course_id INTEGER,
    launch_date DATE,
    sid INTEGER,
    date DATE,
    start_time TIME,
    end_time TIME,
    rid INTEGER REFERENCES Rooms ON DELETE CASCADE,
    FOREIGN KEY (course_id, launch_date) REFERENCES Offerings
    ON DELETE CASCADE,
    PRIMARY KEY (course_id, launch_date, sid, rid) --this is annoying
);
 --<----------------------- company side ----------------------->
CREATE TABLE Employees (
    eid INTEGER PRIMARY KEY,
    name VARCHAR(256),
    phone INTEGER,
    email VARCHAR(256),
    join_date DATE,
    address TEXT,
    depart_date DATE
);

CREATE TABLE Part_time_emp (
    eid CHAR(256) PRIMARY KEY REFERENCES Employees ON DELETE CASCADE,
    hourly_rate FLOAT
)

CREATE TABLE Full_time_emp (
    eid CHAR(256) PRIMARY KEY REFERENCES Employees ON DELETE CASCADE,
    monthly_salary FLOAT
)

CREATE TABLE Instructors (
    eid CHAR(256) PRIMARY KEY REFERENCES Employees,
        
)

CREATE TABLE Part_time_instructors (
    eid CHAR(256) PRIMARY KEY REFERENCES Part_time_emp REFERENCES Full_time_emp ON DELETE CASCADE
)

CREATE TABLE Full_time_instructors (
    eid CHAR(256) PRIMARY KEY REFERENCES Instructors REFERENCES Full_time_emp ON DELETE CASCADE
)

CREATE TABLE Administrators (
    eid CHAR(256) PRIMARY KEY REFERENCES Full_time_emp ON DELETE CASCADE
)

CREATE TABLE Managers (
    eid CHAR(256) PRIMARY KEY REFERENCES Full_time_emp ON DELETE CASCADE
)

CREATE TABLE Pay_slips (
    eid INTEGER REFERENCES Employees ON DELETE CASCADE,
    payment_date DATE,
    amount FLOAT,
    num_work_hours INTEGER,
    num_work_days INTEGER
    PRIMARY KEY (eid, payment_date)
);



-- <----------------------associations----------------------->
CREATE TABLE Cancels (
    date DATE PRIMARY KEY,
    refund_amt INTEGER,
    package_credit INTEGER,
    cust_id INTEGER REFERENCES Customers,
    course_id INTEGER,
    launch_date DATE,
    sid INTEGER,
    rid INTEGER,
    FOREIGN KEY (course_id, launch_date, sid, rid) references Sessions,
    PRIMARY KEY (cust_id, course_id, launch_date, sid, rid)
);


CREATE TABLE  Specializes (

);
