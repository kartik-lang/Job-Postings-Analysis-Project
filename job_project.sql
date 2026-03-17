--loading data
CREATE TABLE job_postings_fact (
    job_id INT,
    company_id INT,
    job_title_short TEXT,
    job_title TEXT,
    job_location TEXT,
    job_via TEXT,
    job_schedule_type TEXT,
    job_work_from_home BOOLEAN,
    search_location TEXT,
    job_posted_date DATE,
    job_no_degree_mention BOOLEAN,
    job_health_insurance BOOLEAN,
    job_country TEXT,
    salary_rate TEXT,
    salary_year_avg NUMERIC,
    salary_hour_avg NUMERIC
);

SELECT COUNT(*) FROM job_postings_fact;

CREATE TABLE skills_dim (
    skill_id INT PRIMARY KEY,
    skills VARCHAR(100),
    type VARCHAR(100)
);

SELECT COUNT(*) FROM skills_dim;

CREATE TABLE skills_job_dim (
    job_id INT NOT NULL,
    skill_id INT NOT NULL,
    PRIMARY KEY(job_id,skill_id)
);

SELECT COUNT(*) FROM skills_job_dim;

--understand the schema

select * from job_postings_fact
LIMIT 10;

SELECT 
job_id,
job_title,
job_location,
job_schedule_type,
job_work_from_home,
salary_year_avg,
job_posted_date
FROM job_postings_fact
WHERE salary_year_avg is NOT NULL;

--FILTER to relevant roles
--focus on one role with complete salary data:
SELECT
job_id,
job_title,
job_location,
job_work_from_home,
salary_year_avg
FROM job_postings_fact
WHERE salary_year_avg is NOT NULL
AND job_title_short= 'Data Analyst'
AND job_work_from_home= 'True'
ORDER BY
salary_year_avg DESC

-- TOP PAYING DATA ANALYST JOBS
SELECT
job_id,
job_title,
job_location,
job_work_from_home,
salary_year_avg
FROM job_postings_fact
WHERE salary_year_avg is NOT NULL
AND job_title_short= 'Data Analyst'
AND job_work_from_home= 'True'
ORDER BY
salary_year_avg DESC
LIMIT 10

--MOST IN DEMAND SKILLS
select * from job_postings_fact
select * from skills_dim
select * from skills_job_dim 


select 
s.skills,
COUNT (sj.job_id) AS demand_count
FROM job_postings_fact j
INNER JOIN skills_job_dim sj
on j.job_id = sj.job_id
INNER JOIN skills_dim s
on sj.skill_id = s.skill_id
WHERE
j.job_title_short='Data Analyst'
AND j.job_work_from_home='True'
GROUP BY
s.skills
ORDER BY
demand_count DESC
LIMIT 10;


--Highest paying skill
SELECT 
s.skills,
ROUND(AVG(j.salary_year_avg),0) AS avg_salary,
COUNT(sj.job_id) AS job_count
FROM job_postings_fact j
INNER JOIN skills_job_dim sj
on j.job_id = sj.job_id
INNER JOIN skills_dim s
ON sj.skill_id=s.skill_id
WHERE
j.job_title_short='Data Analyst'
AND j.job_work_from_home='True'
AND j.salary_year_avg IS NOT NULL
GROUP BY
s.skills
ORDER BY
avg_salary DESC
LIMIT 25;


--Optimal Skills (Demand+ Salary- The Star Query)
--using CTE to find skills that are both in demand and high paying

WITH skills_demand AS(
	SELECT
	s.skill_id,
	s.skills,
	COUNT(sj.job_id) AS demand_count
	FROM job_postings_fact j
	INNER JOIN skills_job_dim sj
	ON j.job_id = sj.job_id
	INNER JOIN skills_dim s
	ON sj.skill_id = s.skill_id
	WHERE
	j.job_title_short = 'Data Analyst'
	AND j.job_work_from_home ='TRUE'
	GROUP BY
	s.skill_id,s.skills
	),
skills_salary AS(
	SELECT
	s.skill_id,
	s.skills,
	ROUND(AVG(j.salary_year_avg),0) AS avg_salary
FROM job_postings_fact j
	INNER JOIN skills_job_dim sj
	ON j.job_id=sj.job_id
	INNER JOIN skills_dim s
	ON sj.skill_id =s.skill_id
	WHERE
	j.job_title_short='Data Analyst'
	AND j.job_work_from_home='True'
	AND j.salary_year_avg IS NOT NULL
	GROUP BY
	s.skill_id,s.skills
	)
SELECT
d.skills,
d.demand_count,
s.avg_salary,
ROUND((d.demand_count*s.avg_salary/1000),0) AS opportunity_score
FROM skills_demand d
LEFT JOIN skills_salary s
ON d.skill_id=s.skill_id
WHERE
d.demand_count>10
ORDER BY
d.demand_count DESC,
s.avg_salary DESC
LIMIT 25;
