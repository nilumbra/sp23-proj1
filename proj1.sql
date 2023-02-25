-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era) FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear FROM people 
  WHERE weight > 300; -- replace this line
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear FROM people people
  WHERE namefirst LIKE '% %' ORDER BY namefirst, namelast; -- replace this line
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height) as avgheight, COUNT(*) as count FROM people
  GROUP BY birthyear HAVING count > 0 ORDER BY birthyear; -- replace this line
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT * FROM q1iii WHERE avgheight > 70 ORDER BY birthyear;-- replace this line
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT namefirst, namelast, playerid, yearid FROM halloffame H
    NATURAL JOIN people WHERE H.inducted = 'Y'
    ORDER BY yearid DESC, playerid ASC  -- replace this line
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT namefirst, namelast, playerid, S.schoolid, yearid FROM q2i Q NATURAL JOIN collegeplaying C 
    JOIN schools S ON S.schoolid = C.schoolid 
    WHERE schoolstate = 'CA' AND EXISTS (
      SELECT * FROM collegeplaying C JOIN schools S ON C.schoolid = S.schoolid WHERE C.playerid = Q.playerid
    ) ORDER BY Q.yearid DESC, S.schoolid, playerid;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT Q.playerid, namefirst, namelast, S.schoolid FROM q2i Q 
    LEFT OUTER JOIN collegeplaying C ON C.playerid = Q.playerid
    LEFT OUTER JOIN schools S ON S.schoolid = C.schoolid 
    ORDER BY Q.playerid DESC, S.schoolid
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  WITH cte AS (SELECT playerid, yearid, teamid, (H - H2B - H3B -HR) as H1B, H2B, H3B, HR, AB FROM batting WHERE AB > 50)
  SELECT P.playerid, namefirst, namelast, yearid, (H1B + 2*H2B + 3*H3B + 4*HR) / CAST(AB AS DOUBLE) as slg FROM cte AS C
    JOIN people P ON P.playerid = C.playerid
   ORDER BY slg DESC, yearid, P.playerid LIMIT 10;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  WITH cte AS (SELECT * FROM (SELECT playerid, SUM(H) as H, SUM(H2B) as H2B, SUM(H3B) as H3B, SUM(HR) as HR, SUM(H - H2B - H3B - HR) as H1B, SUM(AB) as AB FROM batting 
      GROUP BY playerid) WHERE AB > 50)
  SELECT P.playerid, namefirst, namelast, (H1B + 2*H2B + 3*H3B + 4*HR) / CAST(AB AS DOUBLE) as lslg FROM cte AS C
    JOIN people P ON P.playerid = C.playerid
    ORDER BY lslg DESC, P.playerid LIMIT 10;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  WITH cte AS (SELECT * FROM (SELECT playerid, SUM(H) as H, SUM(H2B) as H2B, SUM(H3B) as H3B, SUM(HR) as HR, SUM(H - H2B - H3B - HR) as H1B, SUM(AB) as AB FROM batting 
    GROUP BY playerid) WHERE AB > 50)
  SELECT namefirst, namelast, (H1B + 2*H2B + 3*H3B + 4*HR) / CAST(AB AS DOUBLE) as lslg FROM cte C
    JOIN people P on P.playerid = C.playerid
    WHERE lslg > (SELECT (H1B + 2*H2B + 3*H3B + 4*HR) / CAST(AB AS DOUBLE) FROM cte WHERE playerid = 'mayswi01'
      );


-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid, MIN(salary) as min, MAX(salary) as max, AVG(salary) as avg FROM salaries 
  GROUP BY yearid ORDER BY yearid;


-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS

WITH
  salary_range AS (
    SELECT MIN(salary) AS min_salary, MAX(salary) AS max_salary
    FROM Salaries
    WHERE yearID = 2016
  ),
  bins AS ( -- all the bins with binid, LOW, HIGH
    SELECT binid, (min_salary + (max_salary - min_salary) * binid / 10.0) AS low, (min_salary + (max_salary - min_salary) * (binid + 1) / 10.0) AS high
    FROM binids, salary_range
  ),
  salary_bins AS (
    SELECT bins.binid, bins.low, bins.high, COUNT(*) AS count
    FROM Salaries
    JOIN bins ON Salaries.salary >= bins.low AND Salaries.salary < bins.high
    WHERE yearID = 2016 AND bins.binid < 9
    GROUP BY bins.binid
    UNION ALL 
    SELECT bins.binid, bins.low, bins.high, COUNT(*) AS count
    FROM Salaries
    JOIN bins ON Salaries.salary >= bins.low AND Salaries.salary <= bins.high
    WHERE yearID = 2016 AND bins.binid = 9
    GROUP BY bins.binid
  )
SELECT *
FROM salary_bins
UNION ALL
SELECT bins.binid, bins.low, bins.high, 0 AS count
FROM bins
LEFT JOIN salary_bins ON bins.binid = salary_bins.binid
WHERE salary_bins.binid IS NULL
ORDER BY binid ASC;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  SELECT curr.yearid, curr.min - prev.min, curr.max - prev.max, curr.avg - prev.avg FROM q4i prev JOIN q4i curr 
  ON prev.yearid + 1 = curr.yearid; 


-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  SELECT playerid, namefirst, namelast, salary, yearid FROM salaries NATURAL JOIN people 
  WHERE (salary, yearid) IN (
    SELECT max, yearid FROM q4i WHERE yearid = 2000 OR yearid = 2001
  );


-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT A.teamid, MAX(salary) - MIN(salary) FROM allstarfull A JOIN salaries S 
    ON A.playerid = S.playerid AND S.yearid = A.yearid
  WHERE A.yearid = 2016
  GROUP BY A.teamid;
-- WHERE A.yearid = 2016 


