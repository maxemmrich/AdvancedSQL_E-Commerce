
-- Business Case: New Billing page 2 has been tested. Conversion rate of billing page 1 and 2 

-- Step 1: Find the first pageview on /billing-2, to be able to compare the two billing pages
-- Step 2: Find session ids with billing 1 and 2 and look wether the same id has been to thank you page
-- Step 3: Count Sessions and thank you pages and group billing method

SELECT 
	MIN(created_at),
    MIN(website_pageview_id),
    MIN(website_session_id)
FROM website_pageviews
WHERE pageview_url = '/billing-2';
-- RESULT: 2012-09-10 00:13:05,	53550,	25325

-- Store all session id entries with pageviews on billing 1 and 2
DROP TABLE IF EXISTS temp_1;
CREATE TEMPORARY TABLE temp_1
SELECT 
	website_session_id,
    pageview_url
FROM website_pageviews
WHERE created_at >'2012-09-10 00:13:05'
	AND created_at <'2012-11-10'
	AND pageview_url IN ('/billing', '/billing-2')
ORDER BY website_session_id;

-- Add column with either 1 or null depending on wether a customer has completed the checkout (done in subquery with case statement). 
-- Then group rows by session_id, leaving each session id with info on the billing page and wether they have competed the checkout
DROP TABLE IF EXISTS temp_2;
CREATE TEMPORARY TABLE temp_2
SELECT 
	website_session_id,
    pageview_url,
    MAX(order_completed) AS completed
FROM(
SELECT
	t.website_session_id,
	t.pageview_url,
	CASE WHEN w.pageview_url='/thank-you-for-your-order' THEN 1 ELSE NULL END AS order_completed
FROM temp_1 t
	INNER JOIN website_pageviews w
		ON t.website_session_id=w.website_session_id
WHERE
	w.pageview_url IN ('/billing', '/billing-2', '/thank-you-for-your-order')
) AS querry
GROUP BY 1,2;

-- Look at overall conversion rates for each billing page

SELECT
	pageview_url,
    COUNT(completed)/COUNT(pageview_url) AS conv_rate
FROM temp_2
GROUP BY 1
ORDER BY conv_rate DESC;
