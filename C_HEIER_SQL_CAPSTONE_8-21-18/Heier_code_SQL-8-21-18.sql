--1. Get Familiar with CoolTShirts 
-- Get COUNT of Campaigns & Count of Sources in one query. 
SELECT COUNT(DISTINCT utm_campaign) AS 'Campaign Count', 
			 COUNT(DISTINCT utm_source) AS 'Source Count'
FROM page_visits;

---Get COUNT of Campaigns & Sources (individually)
SELECT COUNT(DISTINCT utm_campaign) AS 'Campaign Count'
FROM page_visits;

---Get COUNT of Sources (individually)
SELECT COUNT(DISTINCT utm_source) AS 'Source Count'
FROM page_visits;


--List of sources per campaign. (Shows relationship) 
SELECT DISTINCT utm_campaign AS Campaign,
	utm_source AS Source
FROM page_visits;

--1.a List of Pages on the CoolTShirts website
SELECT DISTINCT page_name AS Webpages
FROM page_visits;

--2. Count how many First touches each campaign is responsible for.
---Create temp table to capture first touch by user id.
WITH first_touch AS (
	SELECT user_id,
  	MIN(timestamp) AS first_touch_at
  FROM page_visits
  GROUP BY user_id),
--Create second temp table called "first_attributes" which adds 
--the campaign and source attributes joins them to the first temp table
--on userid and timestamp. 
first_attributes AS (
	SELECT ft.user_id,
			ft.first_touch_at,
  		pv.utm_source,
  		pv.utm_campaign
	FROM first_touch ft
	JOIN page_visits pv
			ON ft.user_id = pv.user_id
    	AND ft.first_touch_at = pv.timestamp
)
--Count number of rows where first touch is associated 
--with a campaign and source. 
SELECT first_attributes.utm_campaign AS Campaign,
			 first_attributes.utm_source AS Source,
       COUNT(*) AS 'FT Count'
FROM first_attributes
GROUP BY 1
ORDER BY 3 DESC;

--------------------------------------------------------------
--2.a Count how many Last touches each campaign is responsible for.
---Create temp table to capture last touch by user id.
WITH last_touch AS (
	SELECT user_id,
  	MAX(timestamp) AS last_touch_at
  FROM page_visits
  GROUP BY user_id),
--Create second temp table called "last_attributes" which adds 
--the campaign and source attributes and joins them to the 
--first temp table on userid and time stamp. 
last_attributes AS (
	SELECT lt.user_id,
			lt.last_touch_at,
  		pv.utm_source,
  		pv.utm_campaign
	FROM last_touch lt
	JOIN page_visits pv
			ON lt.user_id = pv.user_id
    	AND lt.last_touch_at = pv.timestamp
)
--Count number of rows where first touch is associated 
--with a campaign and source. 
SELECT last_attributes.utm_campaign AS Campaign,
       COUNT(*) AS 'Count'
FROM last_attributes
GROUP BY 1
ORDER BY 2 DESC;

--------------------------------------------------------------
--2.b What is the User Journey  Purchase Page Conversion
--Count how many users visited each page. (Used just for reference)
SELECT page_name, COUNT(DISTINCT user_id) AS 'Unique Count'
FROM page_visits
group by page_name;

--Count how many users visited the purchase page
SELECT COUNT(DISTINCT user_id) AS 'Purchasing Users'
FROM page_visits
WHERE page_name = '4 - purchase';

--Calculate conversion rate. 
--Built temp table "p" to generate count of purchasers
WITH p AS (
  -- COUNT statement is divided by 1.0 to convert result into an integer. 
	SELECT COUNT(DISTINCT user_id) / 1.0 AS purchasing_user
  FROM page_visits
  WHERE page_name = '4 - purchase'
),
--Build second temp table "t" to generate count of users 
--visiting the landing page
t AS (
	SELECT page_name, COUNT(DISTINCT user_id) / 1.0 AS landing
  FROM page_visits
  WHERE page_name = '1 - landing_page'
  
)
--Calculating the conversion rate is Purchasers divided by total count of user
--that visited the landing page. Multipy the result by 100.0 for a percentage format.  
SELECT p.purchasing_user, 
			 t.landing, 
       ROUND(((p.purchasing_user / t.landing ) * 100.0), 2) as 'Conversion %'
FROM p, t;

--------------------------------------------------------------
--2.c Count how many last touches each campaign is responsible for on the Purchase Page.
---Create temp table to capture last touch by user id for only the Purchase Page.
WITH last_touch AS (
		SELECT user_id,
  			MAX(timestamp) AS last_touch_at
  	FROM page_visits
 	WHERE page_name = '4 - purchase'
  	GROUP BY user_id),
--Create second temp table called "last_attributes" which adds the campaign and source attributes
--and joins them to the first temp table on userid and time stamp. 
last_attributes AS (
	SELECT lt.user_id,
		lt.last_touch_at,
  	pv.utm_source,
  	pv.utm_campaign
	FROM last_touch lt
	JOIN page_visits pv
			ON lt.user_id = pv.user_id
    	AND lt.last_touch_at = pv.timestamp
), campaign_count AS (
--Count number of rows where last touch is associated with a campaign and source.
SELECT fa.utm_campaign AS Campaign,
			 fa.utm_source AS Source,
       COUNT(fa.utm_campaign)  AS LT_COUNT
	FROM last_attributes fa
  JOIN last_touch pv
  	ON fa.user_id = pv.user_id
	GROUP BY 1
 )
SELECT Source,
			 Campaign,
       LT_COUNT,
       ROUND((LT_COUNT / sumLTotal.LT * 100.0), 1) AS 'LT %'
FROM campaign_count
CROSS JOIN  ( 
    			SELECT (
      			SUM(LT_COUNT)* 1.0) AS LT
    			FROM campaign_count
  ) sumLTotal
GROUP BY 1
ORDER BY 3 DESC;

--Research query
SELECT utm_campaign, utm_source, COUNT(*) AS Count
FROM page_visits
where page_name = '4 - purchase'
group by 2
order by Count DESC;


---------------------------------------------
--3.Typical User Journey - First/Last Touch Campaign Count + Percent
---Create temp table to capture first touch by user id.
WITH first_touch AS (
	SELECT user_id,
  	MIN(timestamp) AS first_touch_at
  FROM page_visits
  GROUP BY user_id),
--Create second temp table called "first_attributes" which adds 
--the campaign and source attributes joins them to the first temp table
--on userid and timestamp. 
first_attributes AS (
	SELECT ft.user_id,
			ft.first_touch_at,
  		pv.utm_source,
  		pv.utm_campaign
	FROM first_touch ft
	JOIN page_visits pv
			ON ft.user_id = pv.user_id
    	AND ft.first_touch_at = pv.timestamp
), campaign_count AS (
--Count number of rows where first touch is associated 
--with a campaign and source. 
	SELECT fa.utm_campaign AS Campaign,
			 fa.utm_source AS Source,
       COUNT(fa.utm_campaign)  AS FT_COUNT
	FROM first_attributes fa
  JOIN first_touch pv
  	ON fa.user_id = pv.user_id
	GROUP BY 1
) 
--Build our SELECT statement with a cross join to capture the total Count on our aggregate Campaign to use in our Percentage division.
	SELECT Campaign, 
  			 Source, 
         FT_COUNT, 
         ROUND((FT_COUNT / sumTotal.TT * 100.0), 1) AS 'FT %'
  FROM campaign_count
  CROSS JOIN  ( 
    			SELECT (
      			SUM(FT_COUNT)* 1.0) AS TT
    			FROM campaign_count
  ) sumTotal
  
	GROUP BY 1
    ORDER BY 4 DESC;
  
