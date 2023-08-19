-- First Exercise:
-- Determine whether the total rentals for each film is above or below the average, 
-- you can first compute the average count of rentals across all films. 
-- Then, you can compare each film's rental count to this average.
WITH CTE_TOTAL_RENTALS AS 
(
	SELECT 
		se_film.film_id, 
		COUNT(se_rental.rental_id) as total_rentals
	FROM film as se_film
	INNER JOIN inventory as se_inventory
		ON se_inventory.film_id = se_film.film_id
	INNER JOIN rental as se_rental
		ON se_rental.inventory_id = se_inventory.inventory_id
	GROUP BY se_film.film_id
),
CTE_AVG_RENTALS AS(
SELECT 
	ROUND(AVG(total_rentals), 2) as avg_rentals
FROM CTE_TOTAL_RENTALS)
-- Average = 16.75

SELECT 
	CTE_TOTAL_RENTALS.film_id, 
	CTE_TOTAL_RENTALS.total_rentals, 
	CASE 
		WHEN total_rentals > (SELECT avg_rentals FROM CTE_AVG_RENTALS) THEN 'ABOVE'
		WHEN total_rentals < (SELECT avg_rentals FROM CTE_AVG_RENTALS) THEN 'BELOW'
	END AS comparison_rentals
FROM CTE_TOTAL_RENTALS


-- Second Exercise:
-- Using Query sent on slack, please update self joins to the CTE to come up with 3 addition columns (first, second, third).
-- i didnt use self join, i used row number partition, and conditional case to get them.
WITH CTE_RENTAL_DURATION AS
(
    SELECT 
        rental_id,
        EXTRACT(DAY FROM (return_date - rental_date)) * 24 + EXTRACT(HOUR FROM (return_date - rental_date)) AS duration_hours
    FROM public.rental
),

CTE_TOTAL_REVENUE AS
(
    SELECT 
        rental_id,
        SUM(amount) AS total_revenue
    FROM public.payment
    GROUP BY 
        rental_id
),

-- i used row partition to get the category rank
-- i ordered by count of rentals
-- to get most rented categories
CTE_CATEGORY_RANK AS
(
    SELECT 
        se_rental.customer_id,
        se_category.name AS category_name,
        COUNT(se_rental.rental_id) AS total_rentals,
        ROW_NUMBER() OVER(PARTITION BY se_rental.customer_id ORDER BY COUNT(se_rental.rental_id) DESC) AS category_rank
    FROM public.rental AS se_rental
    INNER JOIN public.inventory AS se_inventory
    ON se_inventory.inventory_id = se_rental.inventory_id
    INNER JOIN public.film AS se_film
    ON se_film.film_id = se_inventory.film_id
    INNER JOIN public.film_category AS se_film_category
    ON se_film_category.film_id = se_film.film_id
    INNER JOIN public.category AS se_category
    ON se_category.category_id = se_film_category.category_id
    GROUP BY
        se_rental.customer_id,
        se_category.name
)
  
SELECT
    se_rental.customer_id,
    ROUND(AVG(CTE_RENTAL_DURATION.duration_hours), 2) AS average_duration_hours,
    SUM(CTE_TOTAL_REVENUE.total_revenue) AS total_revenue,
	-- i used the max function along with the conditional case 
	-- to get the top three most rented categories
    MAX(CASE WHEN category_rank = 1 THEN category_name END) AS top_category_1,
    MAX(CASE WHEN category_rank = 2 THEN category_name END) AS top_category_2,
    MAX(CASE WHEN category_rank = 3 THEN category_name END) AS top_category_3
FROM public.rental se_rental
INNER JOIN CTE_RENTAL_DURATION
ON CTE_RENTAL_DURATION.rental_id = se_rental.rental_id
INNER JOIN CTE_TOTAL_REVENUE
ON CTE_TOTAL_REVENUE.rental_id = se_rental.rental_id
LEFT JOIN CTE_CATEGORY_RANK
ON se_rental.customer_id = CTE_CATEGORY_RANK.customer_id
GROUP BY
    se_rental.customer_id;
