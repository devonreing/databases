select *
from foods;

select * 
from serves;

-- Question 1
select restID, avg(foods.price) as foodprice
from serves natural join foods
group by restID
order by foodprice;

-- Question 2
select restID, max(foods.price)
from serves natural join foods
group by restID;

-- Question 3
select restID, count(DISTINCT foods.type)
from serves inner join foods
on foods.foodID = serves.foodID
group by restID;


-- Question 4
select chefID, avg(foods.price)
from works natural join serves natural join foods
group by chefID;

-- helpful queries to run to check work
select *
from works;
select *
from serves;
select *
from (foods natural join serves) natural join works;

-- Question 5
select restID, avg(foods.price) as foodprice
from serves natural join foods
group by restID
having (foodprice) >= all

   -- the subquery is formed here
   (select avg(foods.price)    
    from serves natural join foods 
    group by restID);