
--psql -U postgres
--CREATE DATABASE homebase;
--\c homebase

-- DROP TABLE IF EXISTS COMPANY_PROFILE cascade;
-- DROP TABLE IF EXISTS USR_WORK_PROFILE cascade;
-- DROP TABLE IF EXISTS ANSWERS cascade;
-- DROP TABLE IF EXISTS QUESTIONS cascade;
-- DROP TABLE IF EXISTS QUESTIONS_LOOKUP cascade;
-- DROP TABLE IF EXISTS USERS cascade;
-- DROP TABLE IF EXISTS PERMISSIONS_LOOKUP cascade;
-- DROP TABLE IF EXISTS ROLES cascade;
-- DROP TABLE IF EXISTS USERSTATUS cascade;

--- Creating Custom Domain
--DOMAIN - email

DROP DOMAIN IF EXISTS EMAIL_ADDRESS;
CREATE DOMAIN EMAIL_ADDRESS AS TEXT CHECK (VALUE ~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}$');

---Create Tables.
-- Create Get next Instance
DROP TABLE IF EXISTS GET_NEXT_ID CASCADE;
Create TABLE GET_NEXT_ID(NEXT_ID INT NOT NULL,
						 TBL_NAME VARCHAR(100) NOT NULL,
						 HOLDING_PROCESS VARCHAR(200) DEFAULT NULL);
						 
--ROLES
DROP TABLE IF EXISTS ROLES CASCADE;
-- CREATE TABLE ROLES(ID SERIAL,
-- 				   ROLE_ID INT PRIMARY KEY,
-- 				   DESCRIPTION VARCHAR(10),
-- 				   SHORT_DESC VARCHAR(3),
-- 				   UPDATED_DATE_TIME TIMESTAMP default CURRENT_TIMESTAMP,
-- 				   CONSTRAINT FK_ROLES
-- 				   UNIQUE (ROLE_ID));
---USERSTATUS
DROP TABLE IF EXISTS USERSTATUS CASCADE;
CREATE TABLE USERSTATUS(ID SERIAL PRIMARY KEY,
				   DESCRIPTION VARCHAR(10),
				   UPDATED_DATE_TIME TIMESTAMP default CURRENT_TIMESTAMP);


--USERS
DROP TABLE IF EXISTS USERS CASCADE;
CREATE TABLE USERS
	(ID SERIAL PRIMARY KEY,
	 FIRST_NAME VARCHAR(100) NOT NULL,
	 LAST_NAME VARCHAR(100) NOT NULL,
	 EMAIL EMAIL_ADDRESS NOT NULL,
	 PHONE VARCHAR(15) NOT NULL,
	 USER_STATUS INT NOT NULL,
	 USR_PASS TEXT DEFAULT 'Password1!',
	 UPDATED_DATE_TIME TIMESTAMP default CURRENT_TIMESTAMP,
	 CONSTRAINT FK_ROLLS
	 UNIQUE (EMAIL),
	 UNIQUE (PHONE),
	 FOREIGN KEY(USER_STATUS) REFERENCES USERSTATUS(ID) ON DELETE CASCADE);

-- Permission_Lookup
DROP TABLE IF EXISTS PERMISSIONS_LOOKUP CASCADE;
CREATE TABLE PERMISSIONS_LOOKUP(ID SERIAL,
								PERM_ID INT PRIMARY KEY,
								DESCRIPTION VARCHAR(20),
								SHORT_DESC VARCHAR(3),
								UPDATED_DATE_TIME TIMESTAMP default CURRENT_TIMESTAMP,
							    CONSTRAINT FK_PERMISS
								UNIQUE (PERM_ID));
--- screens 
DROP TABLE IF EXISTS ACCESS_GROUP CASCADE;

CREATE TABLE ACCESS_GROUP(ID SERIAL,
						  SCREEN_ID INT NOT NULL PRIMARY KEY,
						  PARENT_ID INT NOT NULL,
						  DESCRIPTION VARCHAR(50),
						  ROUTES  VARCHAR(50),
						  MAP_ROUTE VARCHAR(50),
						  UPDATED_DATE_TIME TIMESTAMP default CURRENT_TIMESTAMP,
						  CONSTRAINT FK_SCREENS
						  UNIQUE (SCREEN_ID),
						  FOREIGN KEY(PARENT_ID) REFERENCES ACCESS_GROUP(SCREEN_ID));
-- User Group
DROP TABLE IF EXISTS USER_GROUP CASCADE;
CREATE TABLE USER_GROUP(ID SERIAL,
						GROUP_ID INT NOT NULL PRIMARY KEY,
						ACCESS_ID INT NOT NULL,
						USER_ID INT NOT NULL,
						DESCRIPTION VARCHAR(50),
						UPDATED_DATE_TIME TIMESTAMP default CURRENT_TIMESTAMP,
						CONSTRAINT FK_USER_GROUP
						UNIQUE (GROUP_ID),
						FOREIGN KEY(ACCESS_ID) REFERENCES ACCESS_GROUP(SCREEN_ID),
					   FOREIGN KEY(USER_ID) REFERENCES USERS(ID));


--COMPANY_PROFILE
DROP TABLE IF EXISTS COMPANY_PROFILE;
CREATE TABLE COMPANY_PROFILE(ID SERIAL PRIMARY KEY,
							 COMPANY_NAME TEXT NOT NULL,
							 ISPRODUCT_BASED BOOLEAN NOT NULL,
							UPDATED_DATE_TIME TIMESTAMP default CURRENT_TIMESTAMP);

---USR_WORK_PROFILE
DROP TABLE IF EXISTS USR_WORK_PROFILE CASCADE;
CREATE TABLE USR_WORK_PROFILE(ID SERIAL PRIMARY KEY,
							  C_ID INT NOT NULL,
							  DURATION_FROM DATE default CURRENT_DATE - 30,
							  DURATION_TO DATE default CURRENT_DATE,
							  CURRENT_CTC INT NOT NULL,
							  EXPECTED_CTC INT NOT NULL,
							  UPDATED_DATE_TIME TIMESTAMP default CURRENT_TIMESTAMP,
							  USR_ID INT NOT NULL,
							  CONSTRAINT FK_PROFILE
							  FOREIGN KEY(USR_ID) REFERENCES USERS(ID),
							  FOREIGN KEY(C_ID) REFERENCES COMPANY_PROFILE(ID) ON DELETE CASCADE);


--QUESTIONS TYPE LOOKUP
DROP TABLE IF EXISTS QUESTIONS_LOOKUP CASCADE;
CREATE TABLE QUESTIONS_LOOKUP(ID SERIAL PRIMARY KEY,
							  DESCRIPTION VARCHAR(50) NOT NULL,
							  POINTS INT NOT NULL,
							  TIME INT default 300,
							  UPDATED_DATE_TIME TIMESTAMP default CURRENT_TIMESTAMP);



-- Topic_lookup
DROP TABLE IF EXISTS TEST_TYPE  CASCADE;
CREATE TABLE TEST_TYPE(ID SERIAL PRIMARY KEY,
					   DESCRIPTION VARCHAR(50) NOT NULL,
					   POINTS INT NOT NULL,
					   UPDATED_DATE_TIME TIMESTAMP default CURRENT_TIMESTAMP);



--- TEST_LOOKUP
DROP TABLE IF EXISTS TEST_LOOKUP CASCADE;
CREATE TABLE TEST_LOOKUP(ID SERIAL PRIMARY KEY,
						 TITLE VARCHAR(100) NOT NULL,
						 DESCRIPTION TEXT NOT NULL,
						 TYP_ID INT NOT NULL,
						 UPDATED_DATE_TIME TIMESTAMP default CURRENT_TIMESTAMP,
						 CONSTRAINT FK_TEST_LOOKUP
						 FOREIGN KEY(TYP_ID) REFERENCES TEST_TYPE(ID));

--1


--QUESTIONS
DROP TABLE IF EXISTS QUESTIONS  CASCADE;
CREATE TABLE QUESTIONS(ID SERIAL PRIMARY KEY,
					   QUESTION TEXT NOT NULL,
					   OPTIONS TEXT NOT NULL,
					   ANSWER TEXT NOT NULL,
					   ID_LOOKUP INT NOT NULL,
					   TEST_LOOKUP_ID INT NOT NULL,
					   UPDATED_DATE_TIME TIMESTAMP default CURRENT_TIMESTAMP,
					   CONSTRAINT FK_QUESTIONS_LOOKUP
					   FOREIGN KEY(ID_LOOKUP) REFERENCES QUESTIONS_LOOKUP(ID),
					   FOREIGN KEY(TEST_LOOKUP_ID) REFERENCES TEST_LOOKUP(ID) ON DELETE CASCADE);



-- Answers
DROP TABLE IF EXISTS ANSWERS  CASCADE;
CREATE TABLE ANSWERS(ID SERIAL PRIMARY KEY,
					 Q_ID INT NOT NULL,
					 USR_ID INT NOT NULL,
					 ISTAKEN BOOLEAN NOT NULL,
					 ANSR TEXT,
					 UPDATED_DATE_TIME TIMESTAMP default CURRENT_TIMESTAMP,
					 CONSTRAINT FK_QUESTIONS
					 FOREIGN KEY(Q_ID) REFERENCES QUESTIONS(ID),
					 FOREIGN KEY(USR_ID) REFERENCES USERS(ID) ON DELETE CASCADE);



--answered
DROP TYPE IF EXISTS USER_ANSWERED CASCADE;
CREATE TYPE user_answered AS (id INT,
							  question TEXT,
							  OPTIONS text,
							  answer TEXT,
							  POINTS INT,
							  TIME INT,
							  ANSWERED_TIME TIMESTAMP
);

CREATE OR REPLACE FUNCTION get_answered(user_id INT)
RETURNS SETOF user_answered
AS $$
DECLARE
  result user_answered;
BEGIN
  FOR result IN
    SELECT ans.id,
	q.question,
	q."options",
	ans.ansr,
	q_l.points,
	q_l."time",
	ans.updated_date_time
    FROM answers ans
    JOIN questions q ON ans.q_id = q.id
	JOIN users usr ON usr.id = ans.usr_id
	JOIN questions_lookup  q_l ON q_l.id = q.id_lookup
	WHERE ans.usr_id = user_id
  LOOP
    RETURN NEXT result;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- user test available
DROP TYPE IF EXISTS TEST_AVAILABLE_TBL CASCADE;
CREATE TYPE TEST_AVAILABLE_TBL AS (id INT,
								   description TEXT,
								   bonus_point INT,
								   question_point INT,
								   question_time INT
);

CREATE OR REPLACE FUNCTION TEST_AVAILABLE(user_id INT)
RETURNS SETOF TEST_AVAILABLE_TBL
AS $$
DECLARE
  result TEST_AVAILABLE_TBL;
BEGIN
  FOR result IN
    SELECT DISTINCT tt.id,tt.description,tt.points as bonus_point,
	SUM(ql.points) AS question_point,
	SUM(ql."time") AS question_time
	FROM test_type tt
	LEFT JOIN test_lookup tl ON tl.typ_id = tt.id
	LEFT JOIN questions q ON  q.test_lookup_id = tl.id
	LEFT JOIN questions_lookup ql ON  ql.id = q.id_lookup
	LEFT JOIN answers a ON a.q_id = q.id
	WHERE a.usr_id = user_id
	GROUP BY tt.id
  LOOP
    RETURN NEXT result;
  END LOOP;
END;
$$ LANGUAGE plpgsql;



--Select * from COMPANY_PROFILE;
--Select * from USR_WORK_PROFILE;
--Select * from ANSWERS ;
--Select * from QUESTIONS;
--Select * from QUESTIONS_LOOKUP;
--Select * from USERS ;
--Select * from ROLES ;
--SELECT * FROM get_answered(3);
--SELECT * FROM TEST_AVAILABLE(3);

--update USERS set email='ksnavinkumar.diary@gmail.com' where id = 1