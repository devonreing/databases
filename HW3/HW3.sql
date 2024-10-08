set SQL_SAFE_UPDATES=0;

-- Create the necessary tables
create table if not exists merchants (
	mid int primary key,
    
	name varchar(100),
    city varchar(100),
    state varchar(100)
);

create table if not exists products (
	pid int primary key,
    
	name varchar(100) 
    CHECK (name='Printer' or name='Ethernet Adapter' or name='Desktop' or 
    name='Hard Drive' or name='Laptop' or name='Router' or name='Network Card' or 
    name='Super Drive' or name='Monitor'),
    
    category varchar(100) CHECK (category='Peripheral' or category='Networking' or category='Computer'),
    description varchar(500)
);

create table if not exists sell (
    mid int, -- FK
    pid int, -- FK
    
    price double CHECK (price>=0 and price<=100000),
    quantity_available int CHECK (quantity_available>=0 and quantity_available<=1000),
    
    foreign key (mid) references merchants(mid),
    foreign key (pid) references products(pid)
);

create table if not exists orders (
	oid int primary key,
    
    shipping_method varchar(100) CHECK (shipping_method='UPS' or shipping_method='FedEx' or shipping_method='USPS'),
    shipping_cost double CHECK (shipping_cost>=0 and shipping_cost<=500)
);

create table if not exists contain (
	oid int, -- FK
    pid int, -- FK
    
    foreign key(oid) references orders(oid),
    foreign key(pid) references products(pid)
);

create table if not exists customers (
	cid int primary key,
    
    fullname varchar(100),
    city varchar(100),
    state varchar(100)
);

create table if not exists place (
	cid int, -- FK
    oid int, -- FK
    
    order_date date not null, -- Date type only accepts dates in YYYY-MM-DD format between 1000-01--01 to 9999-12-31 
						      -- so not null ensures the date is in the correct format and range
    
    foreign key(cid) references customers(cid),
    foreign key(oid) references orders(oid)
);

-- Ensure the right number of columns are returned and it looks correct from csv files
select * from contain;
select * from customers;
select * from merchants;
select* from orders;
select * from place;
select * from products;
select * from sell;

-- Question 1
select products.name, merchants.name
from products 
	join sell on products.pid = sell.pid
    join merchants on merchants.mid = sell.mid
where sell.quantity_available = 0;

-- Question 2
-- query used to check
select *
from products
	left join sell
    on products.pid = sell.pid;
-- query that returns the intended result from question
select products.name, products.description
from products
	left join sell
    on products.pid = sell.pid
where sell.pid is null; -- check if null because that will list products that have no merchants selling them

-- Question 3
select count(
((select DISTINCT customers.cid
from customers 
	join place on customers.cid = place.cid
    join contain on place.oid = contain.oid
    join products on products.pid = contain.pid
where products.description LIKE '%SATA%')
except
(select DISTINCT customers.cid
from customers 
	join place on customers.cid = place.cid
    join contain on place.oid = contain.oid
    join products on products.pid = contain.pid 
where products.name = 'Router')));

-- Question 4
-- alter the table in one query, print out results in another query, keep the changes for the rest of the problems
-- use this query to check previous prices and ensure they changed appropriately
select sell.mid, sell.pid, merchants.name, products.category, sell.price 
from sell
	join merchants on sell.mid = merchants.mid
    join products on products.pid = sell.pid
where merchants.name = 'HP' and products.category = 'Networking';
-- Question 4
START TRANSACTION; -- allows for resetting the prices back to full price incase query was wrong
	UPDATE sell
		join merchants on merchants.mid = sell.mid
        join products on products.pid = sell.pid
	SET sell.price = (sell.price * .8)	
	WHERE merchants.name = 'HP' AND products.category = 'Networking';
	
    SELECT sell.mid, sell.pid, merchants.name, products.category, sell.price
		from sell
		join merchants on sell.mid = merchants.mid
		join products on products.pid = sell.pid
	where merchants.name = 'HP' and products.category = 'Networking';
ROLLBACK; -- incase update goes wrong

-- Question 5
SELECT customers.fullname, products.name, sell.price
from customers
	join place on customers.cid = place.cid
    join contain on place.oid = contain.oid
    join products on contain.pid = products.pid
    join sell on products.pid = sell.pid
    join merchants on sell.mid = merchants.mid
where customers.fullname = 'Uriel Whitney' and merchants.name = 'Acer';

-- Question 6
select merchants.name, YEAR(place.order_date), sum(sell.price)
from merchants
	join sell on merchants.mid = sell.mid
    join contain on contain.pid = sell.pid 
    join place on place.oid = contain.oid
group by merchants.name, YEAR(place.order_date)
order by YEAR(place.order_date) desc;

-- Question 7
select merchants.name, YEAR(place.order_date), sum(sell.price) as total_sales
from merchants
	join sell on merchants.mid = sell.mid
    join contain on contain.pid = sell.pid 
    join place on place.oid = contain.oid
group by merchants.name, YEAR(place.order_date)
having total_sales >= all
	(select sum(sell.price) 
	from merchants
		join sell on merchants.mid = sell.mid
		join contain on contain.pid = sell.pid 
		join place on place.oid = contain.oid
	group by merchants.name, YEAR(place.order_date));
    
-- Question 8
select orders.shipping_method, avg(orders.shipping_cost)
from orders
group by orders.shipping_method
having avg(orders.shipping_cost) <= all 
	(select avg(orders.shipping_cost)
    from orders
    group by orders.shipping_method);
    
-- Question 9
with category_sales as (
    select merchants.mid, merchants.name as merchant_name, products.category, sum(sell.price) as totals
    from merchants
		join sell on merchants.mid = sell.mid
		join products on sell.pid = products.pid
		join contain on contain.pid = products.pid
    group by merchants.mid, products.category
)
select cs.merchant_name, cs.category, cs.totals
from category_sales cs
	join (
    select mid, max(totals) as max
    from category_sales
    group by mid
	) max_sales on cs.mid = max_sales.mid AND cs.totals = max_sales.max;


-- Question 10
-- all customers spending at each company
select merchants.name as company, customers.fullname as fullname, sum(sell.price) as totals
	from merchants
		join sell on merchants.mid = sell.mid
		join products on sell.pid = products.pid
		join contain on products.pid = contain.pid
		join place on contain.oid = place.oid
		join customers on place.cid = customers.cid
	group by merchants.name, customers.fullname;
-- Question 10
-- max and min customer at each company
with customer_spending as (
    select merchants.mid, merchants.name, customers.cid, customers.fullname, SUM(sell.price) as total_spent
    from merchants
		join sell on merchants.mid = sell.mid
		join products on sell.pid = products.pid
		join contain on products.pid = contain.pid
		join place on contain.oid = place.oid
		join customers on place.cid = customers.cid
    group by merchants.mid, customers.cid, customers.fullname
)
select cs.name, cs.fullname, cs.total_spent
from customer_spending cs
where cs.total_spent in (
	select MAX(total_spent)
	from customer_spending
	where mid = cs.mid
	group by mid
)
OR
cs.total_spent in (
	select MIN(total_spent)
	from customer_spending
	where mid = cs.mid
	group by mid
)
order by cs.mid, cs.total_spent;


