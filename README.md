# 🍽️ Swiggy Restaurant & Food Delivery Analytics

![SQL](https://img.shields.io/badge/SQL-Server-blue)
![Data Analysis](https://img.shields.io/badge/Data%20Analysis-SQL-orange)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-yellow)
![GitHub](https://img.shields.io/badge/GitHub-Project-black)

## 📌 Project Overview

**Swiggy Restaurant & Food Delivery Analytics** is an advanced SQL-based data analytics project focused on analyzing restaurant performance, food-delivery revenue, customer ratings, dishes, locations, and time-based revenue trends.

The project uses a **fact-and-dimension data model** consisting of a central `fact_orders` table connected to restaurant, location, dish, and date dimension tables.

The primary objective is to transform food-delivery transaction data into meaningful business insights using **SQL Server and advanced SQL techniques**.

---

## 🎯 Project Objectives

This project focuses on answering business questions such as:

- Which restaurants generate the highest revenue?
- What are the top-performing restaurants in each city?
- Which restaurants perform best in each state?
- Which dishes have the highest prices within their categories?
- Which restaurants have above-average ratings?
- How does revenue change from one day to the next?
- What is the next day's revenue compared with the current day?
- What is the 7-day moving average of revenue?
- Which restaurants improved their rankings over time?
- How does restaurant performance vary across geographical locations?

---

## 🗂️ Dataset

The project contains one fact table and four dimension tables.

### `fact_orders`

The central transaction table.

| Column | Description |
|---|---|
| `order_id` | Unique order identifier |
| `date_id` | Date dimension key |
| `location_id` | Location dimension key |
| `restaurant_id` | Restaurant dimension key |
| `food_id` | Dish dimension key |
| `price` | Order/dish price |
| `rating` | Customer rating |
| `rating_count` | Rating count |

**Records:** 197,430

### `dim_restaurant`

Contains restaurant information.

| Column | Description |
|---|---|
| `restaurant_id` | Unique restaurant identifier |
| `restaurant_name` | Restaurant name |

**Records:** 993

### `dim_location`

Contains geographical information.

| Column | Description |
|---|---|
| `location_id` | Unique location identifier |
| `state` | State |
| `city` | City |
| `location` | Local area |

**Records:** 995

### `dim_dish`

Contains dish information.

| Column | Description |
|---|---|
| `dish_id` | Unique dish identifier |
| `category` | Dish category |
| `dish_name` | Dish name |

**Records:** 82,891

### `dim_date`

Contains date information.

| Column | Description |
|---|---|
| `date_id` | Unique date identifier |
| `order_date` | Order date |

**Records:** 243

---

## 🏗️ Data Model

```text
                    ┌──────────────────┐
                    │   dim_restaurant │
                    │──────────────────│
                    │ restaurant_id    │
                    │ restaurant_name  │
                    └────────┬─────────┘
                             │
                             │
┌──────────────┐      ┌──────▼───────┐      ┌──────────────┐
│  dim_date    │      │ fact_orders  │      │ dim_location │
│──────────────│      │──────────────│      │──────────────│
│ date_id      ├──────► order_id     │◄──────┤ location_id  │
│ order_date   │      │ date_id      │      │ state        │
└──────────────┘      │ location_id  │      │ city         │
                      │ restaurant_id│      │ location     │
                      │ food_id      │      └──────────────┘
                      │ price        │
                      │ rating       │
                      │ rating_count  │
                      └──────┬───────┘
                             │
                             │
                    ┌────────▼────────┐
                    │    dim_dish     │
                    │─────────────────│
                    │ dish_id         │
                    │ category        │
                    │ dish_name       │
                    └─────────────────┘
```

---

## 🛠️ Technologies Used

- **SQL Server**
- **SQL**
- **CSV**
- **GitHub**
- **Power BI** for optional visualization

---

# 📊 SQL Analysis

## 01. Data Exploration

The project starts by exploring all fact and dimension tables:

- `fact_orders`
- `dim_restaurant`
- `dim_location`
- `dim_date`
- `dim_dish`

The purpose is to understand the structure and contents of the dataset.

---

## 02. Business KPIs

The project calculates the number of records in each table using `UNION ALL`.

This provides a quick overview of the dataset size and helps validate the loaded tables.

---

## 03. Data Type Validation

SQL Server metadata is inspected using:

```sql
EXEC sp_help 'dim_date';
```

This helps identify the actual data type of the date column before performing date-based analysis.

---

## 04. Date Conversion

The project handles date values using `TRY_CONVERT()` and conditional logic based on the date format.

This prepares the date data for subsequent time-series analysis.

---

## 05. Joining Fact and Dimension Tables

The project joins the central fact table with the dimension tables to create a comprehensive analytical dataset containing:

- Order information
- Date
- State
- Location
- Restaurant
- Price
- Rating
- Rating count
- Dish information

---

# 🏆 06. Restaurant Ranking

Restaurant performance is analyzed using SQL window functions.

### `RANK()`

Restaurants are ranked according to total revenue.

```sql
RANK() OVER (
    ORDER BY SUM(f.price) DESC
)
```

### `DENSE_RANK()`

Restaurants are ranked by revenue without gaps between ranking numbers.

### City-Level Ranking

Restaurants are ranked separately within each city:

```sql
RANK() OVER (
    PARTITION BY city
    ORDER BY revenue DESC
)
```

### Top 3 Restaurants Per City

A CTE combined with `DENSE_RANK()` is used to identify the top three restaurants in every city.

---

# 🍛 07. Dish Analysis

Dish-level analysis identifies the **highest-priced dish in every category**.

Techniques used:

- CTE
- `MAX()`
- `RANK()`
- `PARTITION BY`

Example:

```sql
RANK() OVER (
    PARTITION BY category
    ORDER BY max_price DESC
)
```

The highest-ranked dish in each category is then selected.

---

# 📈 08. Advanced Window Analytics

## LAG — Day-over-Day Revenue

`LAG()` is used to compare current daily revenue with the previous day's revenue.

The analysis calculates:

- Current revenue
- Previous revenue
- Revenue change
- Growth percentage

```sql
LAG(revenue) OVER (
    ORDER BY order_date
)
```

## LEAD — Next-Day Revenue Comparison

`LEAD()` is used to compare current revenue with the following day's revenue.

The analysis calculates:

- Current revenue
- Next-day revenue
- Revenue change
- Growth percentage

```sql
LEAD(revenue) OVER (
    ORDER BY order_date
)
```

---

# 🧠 09. Advanced SQL

## Subquery — Above-Average Rated Restaurants

A subquery is used to identify restaurants whose average rating is higher than the overall average rating.

```sql
HAVING AVG(f.rating) > (
    SELECT AVG(rating)
    FROM fact_orders
)
```

## CTE — Restaurant Performance

A Common Table Expression calculates restaurant-level performance metrics:

- Total orders
- Revenue
- Average rating

The results are then joined with `dim_restaurant` to display restaurant names.

---

# 🔀 10. UNION & UNION ALL

The project demonstrates the difference between `UNION` and `UNION ALL`.

### `UNION`

Combines restaurant and dish information while removing duplicate rows.

### `UNION ALL`

Combines the datasets while retaining duplicate rows.

Both queries standardize the output into:

| Column | Description |
|---|---|
| `name` | Restaurant or dish name |
| `type` | Restaurant or Dish |

---

# 📊 11. 7-Day Moving Average

A 7-day moving average is calculated using a window frame:

```sql
AVG(daily_revenue) OVER (
    ORDER BY order_date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
)
```

This helps smooth daily revenue fluctuations and provides a clearer view of revenue trends.

---

# 📈 12. Restaurant Rank Improvement

Restaurant rankings are compared over time using:

- `RANK()`
- `LAG()`
- CTEs
- Date-based partitioning

The analysis identifies restaurants whose current rank is better than their previous rank.

```sql
previous_rank - current_rank AS rank_improvement
```

---

# 🌎 13. State-Wise Restaurant Ranking

Restaurant revenue is analyzed at the state level.

`DENSE_RANK()` is used to identify the highest-performing restaurants within each state:

```sql
DENSE_RANK() OVER (
    PARTITION BY state
    ORDER BY revenue DESC
)
```

---

# 🔑 SQL Concepts Demonstrated

### Basic SQL

- `SELECT`
- `WHERE`
- `GROUP BY`
- `HAVING`
- `ORDER BY`
- `JOIN`

### Intermediate SQL

- Aggregate functions
- CTEs
- Subqueries
- `UNION`
- `UNION ALL`
- Date conversion

### Advanced SQL

- `RANK()`
- `DENSE_RANK()`
- `LAG()`
- `LEAD()`
- `PARTITION BY`
- Window frames
- Moving averages
- Ranking comparisons
- Time-series analysis

---

# 📌 Business Questions Answered

| Business Question | SQL Technique |
|---|---|
| Which restaurant has the highest revenue? | `RANK()` |
| Which restaurants are top performers in each city? | `DENSE_RANK()` + CTE |
| Which dishes are most expensive by category? | `RANK()` + CTE |
| What was the previous day's revenue? | `LAG()` |
| What is the next day's revenue? | `LEAD()` |
| Which restaurants have above-average ratings? | Subquery |
| What is each restaurant's revenue and average rating? | CTE |
| What is the 7-day revenue trend? | Moving Average |
| Which restaurants improved their ranking? | `RANK()` + `LAG()` |
| Which restaurants perform best in each state? | `DENSE_RANK()` |
| How can restaurant and dish datasets be combined? | `UNION` / `UNION ALL` |

---

# 📁 Repository Structure

```text
Swiggy-Restaurant-Food-Delivery-Analytics/
│
├── data/
│   ├── fact_orders.csv
│   ├── dim_restaurant.csv
│   ├── dim_location.csv
│   ├── dim_dish.csv
│   └── dim_date.csv
│
├── sql/
│   └── query.sql
│
├── PowerBI/
│   └── dashboard.pbix
│
└── README.md
```

> The `PowerBI` folder is optional if a Power BI dashboard is added to the repository.

---

# 🚀 How to Run the Project

## 1. Clone the Repository

```bash
git clone https://github.com/your-username/Swiggy-Restaurant-Food-Delivery-Analytics.git
```

## 2. Create the Tables

Create the following tables in SQL Server:

```text
fact_orders
dim_restaurant
dim_location
dim_dish
dim_date
```

## 3. Import the CSV Files

Load each CSV file into its corresponding SQL Server table.

## 4. Run the SQL Script

Open:

```text
sql/query.sql
```

Execute the queries section by section in SQL Server Management Studio or another SQL Server-compatible environment.

## 5. Analyze the Results

The SQL outputs can be used for:

- Business analysis
- Data visualization
- Power BI dashboards
- Restaurant performance analysis
- Revenue trend analysis

---

# 📊 Power BI Dashboard

The SQL outputs can be connected to Power BI to build an interactive dashboard.

### Recommended KPI Cards

- 💰 Total Revenue
- 🧾 Total Orders
- ⭐ Average Rating
- 🍽️ Total Restaurants
- 🍛 Total Dishes
- 📍 Total Locations

### Recommended Visualizations

- Revenue by Restaurant
- Top 10 Restaurants
- Revenue by State
- Revenue by City
- Daily Revenue Trend
- 7-Day Moving Average
- Restaurant Ranking
- Dish Category Analysis
- Average Rating by Restaurant

### Dashboard Screenshot

Add your Power BI dashboard screenshot here after creating it:

```text
![Swiggy Analytics Dashboard](images/dashboard.png)
```

---

# 💡 Project Highlights

This project demonstrates progression from basic SQL analysis to advanced analytical SQL.

### Beginner

```text
SELECT
WHERE
GROUP BY
ORDER BY
JOIN
```

### Intermediate

```text
HAVING
CTEs
Subqueries
UNION
UNION ALL
Aggregate Functions
```

### Advanced

```text
RANK()
DENSE_RANK()
LAG()
LEAD()
PARTITION BY
Moving Average
Time-Series Analysis
Rank Comparison
```

---

# 🎓 Key Learning Outcomes

Through this project, I practiced:

- Working with fact and dimension tables
- Writing analytical SQL queries
- Joining multiple datasets
- Performing business KPI analysis
- Using advanced window functions
- Building revenue-ranking analysis
- Performing time-series analysis
- Comparing current and previous values
- Working with CTEs and subqueries
- Using `UNION` and `UNION ALL`
- Handling date conversion
- Preparing SQL outputs for Power BI

---

# 👨‍💻 Author

**Vihan**

### Skills Demonstrated

`SQL` · `SQL Server` · `Data Analysis` · `Advanced SQL` · `Window Functions` · `CTEs` · `Subqueries` · `Power BI` · `Data Visualization`

---

# ⭐ Support

If you find this project useful or interesting, consider giving the repository a ⭐ on GitHub.

---

## 📌 Project Summary

**Swiggy Restaurant & Food Delivery Analytics** demonstrates how SQL can transform raw food-delivery transaction data into meaningful business insights.

The project covers restaurant revenue ranking, city and state analysis, dish analysis, customer ratings, day-over-day revenue comparison, next-day revenue comparison, moving averages, restaurant rank improvement, and advanced SQL techniques such as CTEs, subqueries, `UNION`, `UNION ALL`, `RANK()`, `DENSE_RANK()`, `LAG()`, and `LEAD()`.

This project is designed as a practical **SQL portfolio project** demonstrating real-world analytical SQL skills.
