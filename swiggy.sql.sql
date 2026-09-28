/* =========================================================
   01. DATA EXPLORATION
   Purpose: Understand the structure and contents of the dataset
   ========================================================= */

-- Q01. Explore fact table
SELECT *
FROM fact_orders;

-- Q02. Explore restaurant dimension
SELECT *
FROM dim_restaurant;

-- Q03. Explore location dimension
SELECT *
FROM dim_location;

--- Explore date dimension
SELECT *
FROM dim_date;

--- Explore dish dimension
SELECT *
FROM dim_dish;

/* =========================================================
   02.Business KPI's 
   ========================================================= */

--Count records in every table
SELECT 'fact_orders' AS table_name,
COUNT(*) AS row_count
FROM fact_orders

UNION ALL

SELECT 'dim_restaurant', COUNT(*)
FROM dim_restaurant

UNION ALL

SELECT 'dim_location', COUNT(*)
FROM dim_location

UNION ALL

SELECT 'dim_dish', COUNT(*)
FROM dim_dish

UNION ALL

SELECT 'dim_date', COUNT(*)
FROM dim_date;

/* =========================================================
   03.Checking Data Type
   ========================================================= */

EXEC sp_help 'dim_date';
/* =========================================================
   04.Convert the Date Values
   ========================================================= */
SELECT 
    date_id,
    CASE
        WHEN order_date LIKE '%-%'
            THEN TRY_CONVERT(DATE, order_date, 5)
        ELSE TRY_CONVERT(DATE, order_date, 103)
    END AS order_date
FROM dim_date;

/* =========================================================
   05.JOIN ALL DIMENSIONS TO FACT TABLE
   ========================================================= */
SELECT
f.order_id,
d.order_date,
l.state,
l.location,
r.restaurant_name,
f.price,f.rating,
f.rating_count
FROM fact_orders f
JOIN dim_date d
 on f.date_id=d.date_id
JOIN dim_location l
 on f.location_id=l.location_id
 JOIN dim_restaurant r
  on f.restaurant_id=r.restaurant_id
   JOIN dim_dish di 
   on f.food_id=di.dish_id;

/* =========================================================
   ADVANCED WINDOW ANALYTICS
   ========================================================= */

 /* =========================================================
  06. RESTAURANT RANKING
   Purpose: Rank restaurants based on revenue across the
            overall business, cities, and other locations
   ========================================================= */

--RANK-Top Restaurant By Revenue 
SELECT 
 r.restaurant_name,
 SUM(f.price)AS Total_revenue,
 RANK()OVER(ORDER BY SUM (f.price)DESC
  )AS revenue_rank
FROM fact_orders f
JOIN dim_restaurant r
 on f.restaurant_id=r.restaurant_id
GROUP BY r.restaurant_id,r.restaurant_name
ORDER BY revenue_rank;

--DENSE_RANK — Top restaurants without ranking gaps
SELECT
    r.restaurant_name,
    SUM(f.price) AS total_revenue,
    DENSE_RANK() OVER (
        ORDER BY SUM(f.price) DESC
    ) AS revenue_rank
FROM fact_orders f
JOIN dim_restaurant r
    ON f.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_id, r.restaurant_name
ORDER BY revenue_rank;

--Rank restaurants within each city
WITH restaurant_sales AS(
SELECT
 l.city,
 r.restaurant_name,
 SUM(f.price)as revenue
FROM fact_orders f
 JOIN dim_location l
 on f.location_id=l.location_id
 JOIN dim_restaurant r
 on f.restaurant_id=r.restaurant_id
GROUP BY l.city,r.restaurant_name
)
SELECT
 city,
 restaurant_name,
 revenue,
 RANK()OVER(PARTITION BY city
 ORDER BY revenue DESC
 )AS city_rank
 FROM restaurant_sales
 ORDER BY city ,city_rank;

--Top 3 Restaurent in every city 
WITH Restaurant_sales AS (
 SELECT 
 l.city,
 r.restaurant_name,
 SUM(f.price)as revenue
 FROM fact_orders f
 JOIN dim_location l
 on f.location_id=l.location_id 
 JOIN dim_restaurant r
 on f.restaurant_id=r.restaurant_id
 GROUP BY l.city,
  r.restaurant_name
),
ranked_restaurants AS (
    SELECT
        city,
        restaurant_name,
        revenue,
        DENSE_RANK() OVER (
            PARTITION BY city
            ORDER BY revenue DESC
        ) AS city_rank
    FROM restaurant_sales
)
SELECT *
FROM ranked_restaurants
WHERE city_rank <= 3
ORDER BY city, city_rank; 

/* =========================================================
   07.DISH ANALYSIS
   Purpose: Analyze dish pricing and identify the highest-
            priced dishes within each category
   ========================================================= */

--Find the highest-priced dish in every category
WITH dish_price AS (
 SELECT 
  di.category,
  di.dish_name,
  MAX(f.price)as max_price
FROM fact_orders f
 JOIN dim_dish di 
 on f.food_id=di.dish_id
 GROUP BY di.category,di.dish_name
),
ranked_dish AS (
 SELECT
  category, 
  dish_name,
  max_price,
  RANK ()OVER(PARTITION BY category
  ORDER BY max_price DESC
  )AS category_rank
FROM dish_price
)
SELECT*FROM
ranked_dish
WHERE category_rank=1;

/* =========================================================
   08. ADVANCED WINDOW ANALYTICS
   Purpose: Analyze revenue trends using advanced window
            functions such as LAG and LEAD
   ========================================================= */

--LAG — Calculate day-over-day revenue growth
WITH daily_sales AS (
    SELECT
        d.order_date,
        SUM(f.price) AS revenue
    FROM fact_orders f
    JOIN dim_date d
        ON f.date_id = d.date_id
    GROUP BY d.order_date
),

sales_comparison AS (
    SELECT
        order_date,
        revenue,

        LAG(revenue) OVER (
            ORDER BY order_date
        ) AS previous_revenue
    FROM daily_sales
)

SELECT
    order_date,
    revenue,
    previous_revenue,

    revenue - previous_revenue AS revenue_change,

    ROUND(
        ((revenue - previous_revenue) / NULLIF(previous_revenue, 0)) * 100,
        2
    ) AS growth_percentage

FROM sales_comparison
ORDER BY order_date;

--LEAD - Next-Day Revenue Comparison
WITH daily_sales AS (
    SELECT
        d.order_date,
        SUM(f.price) AS revenue
    FROM fact_orders f
    JOIN dim_date d
        ON f.date_id = d.date_id
    GROUP BY d.order_date
),

sales_comparison AS (
    SELECT
        order_date,
        revenue,
        LEAD(revenue) OVER (
            ORDER BY order_date
        ) AS next_revenue
    FROM daily_sales
)

SELECT
    order_date,
    revenue,
    next_revenue,

    revenue - next_revenue AS revenue_change,

    CAST(
        (
            (revenue - next_revenue)
            / NULLIF(next_revenue, 0)
        ) * 100
        AS DECIMAL(10,2)
    ) AS growth_percentage

FROM sales_comparison
ORDER BY order_date;

/* =========================================================
   09. ADVANCED SQL
   Purpose: Apply advanced SQL techniques such as CTEs
            and subqueries for business analysis
   ========================================================= */

--Subquery — Find restaurants with above-average ratings
SELECT
    r.restaurant_name,
    AVG(f.rating) AS avg_rating
FROM fact_orders f
JOIN dim_restaurant r
    ON f.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_id, r.restaurant_name
HAVING AVG(f.rating) > (
    SELECT AVG(rating)
    FROM fact_orders
)
ORDER BY avg_rating DESC;

--CTE — Restaurant performance analysis
WITH restaurant_metrics AS (
    SELECT
        restaurant_id,
        COUNT(*) AS total_orders,
        SUM(price) AS revenue,
        AVG(rating) AS avg_rating
    FROM fact_orders
    GROUP BY restaurant_id
)

SELECT
    r.restaurant_name,
    rm.total_orders,
    rm.revenue,
    ROUND(rm.avg_rating, 2) AS avg_rating
FROM restaurant_metrics rm
JOIN dim_restaurant r
    ON rm.restaurant_id = r.restaurant_id
ORDER BY rm.revenue DESC;

/* =========================================================
   010. ADVANCED SQL
   Purpose: Apply advanced SQL techniques such as
            UNION, and UNION ALL
   ========================================================= */


-- UNION - Combine Restaurant and Dish Information
-- Removes duplicate rows from the combined result

--Union-Combine Restaurenyt and Dish information
SELECT
    restaurant_name AS name,
    'Restaurant' AS type
FROM dim_restaurant

UNION

SELECT
    dish_name AS name,
    'Dish' AS type
FROM dim_dish

ORDER BY type, name;

--Union all- Combine restaurant and dish information
SELECT
    restaurant_name AS name,
    'Restaurant' AS type
FROM dim_restaurant

UNION ALL

SELECT
    dish_name AS name,
    'Dish' AS type
FROM dim_dish

ORDER BY type, name;

/* =========================================================
   011.Purpose: Analyze revenue trends using advanced window
            functions such as moving averages
   ========================================================= */

--7-day moving average
WITH daily_sales AS (
    SELECT
        d.order_date,
        SUM(f.price) AS daily_revenue
    FROM fact_orders f
    JOIN dim_date d
        ON f.date_id = d.date_id
    GROUP BY d.order_date
)

SELECT
    order_date,
    daily_revenue,

    ROUND(
        AVG(daily_revenue) OVER (
            ORDER BY order_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS seven_day_avg

FROM daily_sales
ORDER BY order_date;

/* =========================================================
   012.Purpose: Analyze restaurant performance using advanced
            ranking and comparison window functions
   ========================================================= */

--Find restaurants whose rank improved
WITH daily_restaurant_sales AS (
    SELECT
        r.restaurant_name,
        d.order_date,
        SUM(f.price) AS revenue
    FROM fact_orders f
    JOIN dim_restaurant r
        ON f.restaurant_id = r.restaurant_id
    JOIN dim_date d
        ON f.date_id = d.date_id
    GROUP BY
        r.restaurant_name,
        d.order_date
),

ranked AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY order_date
            ORDER BY revenue DESC
        ) AS current_rank
    FROM daily_restaurant_sales
),

comparison AS (
    SELECT
        *,
        LAG(current_rank) OVER (
            PARTITION BY restaurant_name
            ORDER BY order_date
        ) AS previous_rank
    FROM ranked
)

SELECT
    restaurant_name,
    order_date,
    current_rank,
    previous_rank,

    previous_rank - current_rank AS rank_improvement

FROM comparison
WHERE previous_rank > current_rank
ORDER BY rank_improvement DESC;

/* =========================================================
    013.RESTAURANT RANKING
   Purpose: Rank restaurants based on revenue across
            different geographical locations
   ========================================================= */

--State Wise Revenue Ranking
WITH restaurant_state_sales AS (
    SELECT
        l.state,
        r.restaurant_name,
        SUM(f.price) AS revenue
    FROM fact_orders f
    JOIN dim_location l
        ON f.location_id = l.location_id
    JOIN dim_restaurant r
        ON f.restaurant_id = r.restaurant_id
    GROUP BY l.state, r.restaurant_name
)

SELECT
    state,
    restaurant_name,
    revenue,

    DENSE_RANK() OVER (
        PARTITION BY state
        ORDER BY revenue DESC
    ) AS state_rank

FROM restaurant_state_sales
ORDER BY state, state_rank;

