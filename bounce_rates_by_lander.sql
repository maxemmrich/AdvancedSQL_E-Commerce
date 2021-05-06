-- Business Case: 	Analyse bounce rates on the landing page /lander-1 for the specific campaign 'nonbrand' and the traffic source 'gsearch'.
-- 					Compare bounce rate with /home page.

-- To Dos:

-- Step 1: Find the first instance of /lander-1 to set analysis timeframe
-- Step 2: Identify website pageview ids which are landing pages (Home and lander1)
-- Step 3: Count number of other pages visited within same session as the two landers
-- Step 4: Only look at sessions with one pageview (bounced)
-- Step 5: Compare bounced sessions with total amount of sessions of the landing page

-- find first instance of lander1
SELECT
	MIN(created_at),
    MIN(website_pageview_id)
FROM website_pageviews
WHERE pageview_url = '/lander-1'
	AND created_at IS NOT NULL;
-- 19.06.2012 is the first recordet traffic on pageview id=23504

-- store min pageview id for each session (first page visited)
DROP TABLE IF EXISTS temp_1;
CREATE TEMPORARY TABLE temp_1
SELECT
	wp.website_session_id,
    MIN(wp.website_pageview_id) AS min_pv
FROM website_pageviews wp
	INNER JOIN website_sessions ws -- Inner Join website sessions to filter for campaign and source
		ON ws.website_session_id=wp.website_session_id
        AND wp.website_pageview_id > 23504
        AND ws.utm_source='gsearch'
        AND ws.utm_campaign='nonbrand'
GROUP BY 1;

-- store landing page and corresponding pageview_id for each session
DROP TABLE IF EXISTS temp_2;
CREATE TEMPORARY TABLE temp_2
SELECT
	wp.pageview_url,
    temp_1.website_session_id,
    temp_1.min_pv
FROM temp_1
	LEFT JOIN website_pageviews wp
		ON wp.website_pageview_id=temp_1.min_pv
WHERE wp.pageview_url IN ('/home','/lander-1');

-- store total_pageviews for each session and limit it to views=1 to filter bounced sessions
DROP TABLE IF EXISTS temp_3;
CREATE TEMPORARY TABLE temp_3
SELECT
	temp_2.pageview_url,
    temp_2.website_session_id,
    COUNT(DISTINCT wp.website_pageview_id) AS total_pageviews
FROM temp_2
	LEFT JOIN website_pageviews wp
		ON wp.website_session_id=temp_2.website_session_id
GROUP BY 1,2
HAVING
	total_pageviews = 1;

 -- Show total sessions, bounced sessions and bounce rate by landing page url
SELECT
	temp_2.pageview_url,
    COUNT(DISTINCT temp_3.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT temp_2.website_session_id) AS total_sessions,
    COUNT(DISTINCT temp_3.website_session_id)/COUNT(DISTINCT temp_2.website_session_id)  AS bounce_rate
FROM temp_2
	LEFT JOIN temp_3
		ON temp_2.website_session_id=temp_3.website_session_id
GROUP BY 1;