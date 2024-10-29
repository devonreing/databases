select * from city;

create table if not exists actor (
	actor_id int PRIMARY KEY,
    first_name varchar(100),
    last_name varchar(100)
);

create table if not exists country (
	country_id int PRIMARY KEY,
    country varchar(200)
);

create table if not exists category (
	category_id int PRIMARY KEY,
    name varchar(200) CHECK (name='Animation' or name='Comedy' or name='Family' or name='Foreign' or name='Sci-Fi' or name='Travel'
    or name='Children' or name='Drama' or name='Horror' or name='Action' or name='Classics' or name='Games' or name='New' or name='Documentary'
    or name='Sports' or name='Music')
);

create table if not exists language (
	language_id int PRIMARY KEY,
    name varchar(300)
);

create table if not exists city (
	city_id int PRIMARY KEY,
    city varchar(200),
    country_id int,
    
    foreign key(country_id) references country(country_id)
);

create table if not exists address (
	address_id int PRIMARY KEY,
    address varchar(800),
    address2 varchar(500),
    district varchar(500),
    city_id int,
    postal_code varchar(100),
    phone varchar(200),
    
    foreign key(city_id) references city(city_id)
); 
select * from address;

create table if not exists store (
	store_id int PRIMARY KEY,
    address_id int,
    
    foreign key(address_id) references address(address_id)
);

create table if not exists customer (
	customer_id int PRIMARY KEY,
    store_id int,
    first_name varchar(200),
    last_name varchar(200),
    email varchar(200),
    address_id int,
    active int CHECK (active=1 or active=0),
    
    foreign key(store_id) references store(store_id),
    foreign key(address_id) references address(address_id)
);

create table if not exists film (
	film_id int PRIMARY KEY,
    title varchar(500),
    description varchar(800),
    release_year int,
    language_id int,
    rental_duration int CHECK (rental_duration between 2 and 8),
    rental_rate double CHECK (rental_rate between 0.99 and 6.99),
    length int CHECK (length between 30 and 200),
    replacement_cost double CHECK (replacement_cost between 5.00 and 100.00),
    rating varchar(20) CHECK (rating='PG' or rating='G' or rating='NC-17' or rating='PG-13' or rating='R'),
    special_features varchar(500) CHECK (special_features='Behind the Scenes' or special_features='Commentaries' 
		or special_features='Deleted Scenes' or special_features='Trailers'), 
    
    foreign key(language_id) references language(language_id)
    
);
    
create table if not exists film_actor (
	actor_id int,
	film_id int,
	
	foreign key(actor_id) references actor(actor_id),
	foreign key(film_id) references film(film_id)
);

create table if not exists film_category (
	film_id int,
    category_id int,
    
    foreign key(film_id) references film(film_id),
    foreign key(category_id) references category(category_id)
);

create table if not exists inventory (
	inventory_id int PRIMARY KEY,
    film_id int,
    store_id int,
    
    foreign key(film_id) references film(film_id),
    foreign key(store_id) references store(store_id)
);

create table if not exists staff (
	staff_id int PRIMARY KEY,
    first_name varchar(200),
    last_name varchar(200),
    address_id int,
    email varchar(500),
    store_id int,
    active int CHECK (active=1 or active=0), 
    username varchar(200),
    password varchar(500),
    
    foreign key(address_id) references address(address_id),
    foreign key(store_id) references store(store_id)
);

create table if not exists rental (
	rental_id int PRIMARY KEY,
    rental_date datetime, -- data type ensures date is valid
    inventory_id int,
    customer_id int,
    return_date datetime, -- data type ensures date is valid
    staff_id int,
    
    foreign key(inventory_id) references inventory(inventory_id),
    foreign key(customer_id) references customer(customer_id),
    foreign key(staff_id) references staff(staff_id),
    
    UNIQUE (rental_date, inventory_id, customer_id)
);

create table if not exists payment (
	payment_id int PRIMARY KEY,
    customer_id int,
    staff_id int,
    rental_id int,
    amount double CHECK (amount>=0),
    payment_date datetime, -- data type ensures date is valid
    
    foreign key(customer_id) references customer(customer_id),
    foreign key(staff_id) references staff(staff_id),
    foreign key(rental_id) references rental(rental_id)
);


-- Question 1
-- find the average film length in minutes for each category
select film_category.category_id, category.name, avg(film.length) 
from film join film_category on film.film_id = film_category.film_id
	join category on film_category.category_id = category.category_id
group by film_category.category_id
order by category.name; -- order alphabetically

-- Question 2
-- selects the film categories with the longest and shortest avg length
select film_category.category_id, category.name, avg(film.length) 
from film join film_category on film.film_id = film_category.film_id
	join category on film_category.category_id = category.category_id
group by film_category.category_id 
having avg(film.length) <= all -- select shortest
(
	select avg(film.length) 
	from film join film_category on film.film_id = film_category.film_id
		join category on film_category.category_id = category.category_id
	group by film_category.category_id
) 
OR avg(film.length) >= all -- select longest
(
	select avg(film.length) 
	from film join film_category on film.film_id = film_category.film_id
		join category on film_category.category_id = category.category_id
	group by film_category.category_id
) 
order by category.name;

-- Question 3
-- selects customers who have rented action movies but not comedy or classics
-- selects the customers that rented action first
select customer.first_name, customer.last_name
from customer join rental on customer.customer_id = rental.customer_id
	join inventory on rental.inventory_id = inventory.inventory_id
    join film on inventory.film_id = film.film_id
    join film_category on film.film_id = film_category.film_id
    join category on film_category.category_id = category.category_id
where category.name = 'Action'
EXCEPT -- removes the customers that have also rented comedy and classics
select customer.first_name, customer.last_name
from customer join rental on customer.customer_id = rental.customer_id
	join inventory on rental.inventory_id = inventory.inventory_id
    join film on inventory.film_id = film.film_id
    join film_category on film.film_id = film_category.film_id
    join category on film_category.category_id = category.category_id
where category.name = 'Comedy' or category.name = 'Classics';

-- Question 4
-- selects the actor who has been in the most english films
select actor.first_name, actor.last_name, count(film.film_id)
from actor join film_actor on actor.actor_id = film_actor.actor_id
	join film on film_actor.film_id = film.film_id
    join language on film.language_id = language.language_id
where language.name = 'English'
group by actor.first_name, actor.last_name
having count(film.film_id) >= all -- finds the max
(
	select count(film.film_id)
	from actor join film_actor on actor.actor_id = film_actor.actor_id
		join film on film_actor.film_id = film.film_id
		join language on film.language_id = language.language_id
	where language.name = 'English'
	group by actor.first_name, actor.last_name
);

-- Question 5
-- selects only the movies rented from Mike's store for exactly 10 days
select count(distinct film.film_id)
from film join inventory on film.film_id = inventory.film_id
	join rental on inventory.inventory_id = rental.inventory_id
	join store on inventory.store_id = store.store_id
    join staff on store.store_id = staff.store_id
where staff.first_name = 'Mike' and datediff(rental.return_date, rental.rental_date) = 10;

-- Question 6
-- selects the movie with the largest cast of actors
with largest_movie as (
	select film.film_id, count(actor.actor_id)
	from film join film_actor on film.film_id = film_actor.film_id
		join actor on film_actor.actor_id = actor.actor_id
	group by film.film_id
	having count(actor.actor_id) >= all 
	(
	select count(actor.actor_id)
	from film join film_actor on film.film_id = film_actor.film_id
		join actor on film_actor.actor_id = actor.actor_id
	group by film.film_id
	)
)
-- lists the actors from the movie found above
select actor.first_name, actor.last_name
from actor join film_actor on actor.actor_id = film_actor.actor_id
	join film on film_actor.film_id = film.film_id
	join largest_movie on largest_movie.film_id = film.film_id
order by actor.first_name, actor.last_name;
