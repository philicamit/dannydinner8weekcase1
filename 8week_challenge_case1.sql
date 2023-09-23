create database danny_dinner

use danny_dinner;

create table sales
( customer_id varchar(1),
order_date date,
product_id integer(1)
);

insert into sales (customer_id, order_date, product_id)
values
('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 
create table menu
(
product_id integer(1),
product_name varchar(13),
price integer(5)
);

insert into menu (product_id, product_name, price)
values
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
  
  create table members 
  (
  customer_id varchar(2),
  join_date date
  );
  
  INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  -- What is the total amount each customer spent at the restaurant?
  
  select s.customer_id, sum(m.price) as total_amount
  from sales s
  join menu m on s.product_id=m.product_id
  group by 1;
  
  -- How many days has each customer visited the restaurant?
  
  select customer_id, count(distinct order_date) as days_visited
  from sales 
  group by 1;
  
  -- What was the first item from the menu purchased by each customer?
  
  with first_purchase as
  (
  select customer_id, order_date, product_name,
  rank() over(partition by customer_id order by order_date asc) as rnk,
  row_number() over(partition by customer_id order by order_date asc) ro
  from sales  s
  join menu m on s.product_id=m.product_id)
select customer_id,
product_name
from first_purchase
where ro=1;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?

select product_name, count(order_date) c
from sales s
inner join menu m on s.product_id=m.product_id
group by 1
order by c desc
limit 1;

-- Which item was the most popular for each customer?

With CTE as (select product_name, customer_id, count(order_date) c,
rank() over(partition by customer_id order by count(order_date) asc) as rnk,
 row_number() over(partition by customer_id order by count(order_date) desc) ro
from sales s
inner join menu m on s.product_id=m.product_id
group by 1, customer_id)
select customer_id, Product_name
from CTE
where ro=1;
 
 -- Which item was purchased first by the customer after they became a member?
 
 With CTE as 
 (
   select s.customer_id, Product_name, order_date, Join_date,
 Rank() over(partition by customer_id order by order_date) as rnk,
 row_number() over(partition by customer_id order by order_date) as ro
 from sales s 
 inner join members b on s.customer_id=b.customer_id
 inner join menu m on s.product_id=m.product_id 
 where order_date >= join_date)
 Select customer_id, Product_name
 from cte
 where rnk=1;
 
 -- Which item was purchased just before the customer became a member?
 
 With CTE as 
 (
   select s.customer_id, Product_name, order_date, Join_date,
 Rank() over(partition by customer_id order by order_date desc) as rnk,
 row_number() over(partition by customer_id order by order_date desc) as ro
 from sales s 
 inner join members b on s.customer_id=b.customer_id
 inner join menu m on s.product_id=m.product_id 
 where order_date < join_date)
 Select customer_id, Product_name
 from cte
 where rnk=1;
 
 -- What is the total items and amount spent for each member before they became a member?
 
select s.customer_id, 
count(Product_name) total_item, 
-- order_date, Join_date, 
sum(price) as amt_spent
 from sales s 
 inner join members b on s.customer_id=b.customer_id
 inner join menu m on s.product_id=m.product_id 
 where order_date < join_date
 group by s.customer_id;
 
 -- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
 
 select customer_id,
 sum(case 
 when product_name="sushi" then price*10*2
 Else price*10
 end) as points
 from menu m
 inner join sales s on m.product_id=s.product_id
 group by customer_id;
 
 -- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi
 -- how many points do customer A and B have at the end of January?
 
  select s.customer_id,
 Sum(case 
 when order_date >= join_date AND order_date <= DATE_ADD(join_date, INTERVAL 6 DAY) then price*10*2
 when product_name="sushi" then price*10*2
 Else price*10
 end) as points
 from menu m
 inner join sales s on m.product_id=s.product_id
 inner join members b on b.customer_id=s.customer_id
 Where MONTH(order_date) = 1 AND YEAR(order_date) = 2021
 GROUP BY s.customer_id;
 
-- Bonus question Rank all the things
WITH customers_data AS (
  SELECT 
    s.customer_id, 
    s.order_date,  
    m.product_name, 
    m.price,
    CASE
      WHEN b.join_date > s.order_date THEN 'N'
      WHEN b.join_date <= s.order_date THEN 'Y'
      ELSE 'N' END AS member_status
  FROM sales s
  LEFT JOIN members b
    ON s.customer_id = b.customer_id
  JOIN menu m
    ON s.product_id = m.product_id
  ORDER BY b.customer_id, s.order_date
)
SELECT 
  *, 
  CASE
    WHEN member_status = 'N' then NULL
    ELSE RANK () OVER(
      PARTITION BY customer_id, member_status
      ORDER BY order_date) END AS ranking
FROM customers_data;
 