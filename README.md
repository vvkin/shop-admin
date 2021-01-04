# Shop Admin
Simple administration panel for building materials shop.
## Used tools
* `Python`
* `flask` (with extensions)
* `psycopg2`
* `python-dotenv`
* `bootstrap`
* `JavaScript`
* `HTML/CSS`
* `PostgreSQL`
* `Docker`
* `docker-compose`
## Get started
First of all, you must have installed **docker** and **docker-compose** on your computer.\
After that, if needed, change setting in .env files.
If you deal with it, do the following steps
```
git clone https://github.com/vvkin/store-admin
cd shop-admin
docker-compose up -d --build
```
After that just visit **localhost:5000** to work with application.\
If you run it not for the first time, exclude `--build`.
## About
This application implements simple authentication system that allows admin panel to be used only for users with admin privileges, which are marked on 
the database level. Administrators differ from regular users by value of the **is_admin** attribute in **customers** relation. It is **TRUE**, if user is 
an admin and **FALSE** otherwise. You can access administration panel using GUI (Profile -> Administrate) or directly using the URL (localhost:5000/admin). 
The mentioned panel allows you to list all users in table form with pagination, create new users and products, list products filtered by name, 
category, update and delete products via user-friendly graphical interface. All of relations are in the 3NF (third normal form) and include at least 10 records.
Also application defines user **shop_manager_user**, which have all of the privileges needed to work with admin panel, but is unable to change database schema.
## How it works
The server side of the application, written using Flask with many extensions for it. To access database was used psycopg2 Python library. 
Frontend part was developed with HTML/CSS/JavaScript and Bootstrap to simplify design creation. Application does not use ORM, so all of tools 
like filtering, pagination, CRUD functionality are defined on the database level as procedures, views, functions. Docker and docker-compose make it easy 
to create and manage containers, which are used to separate database and server.
## How to create new administrator
The easiest way to do this is to use psql tool inside a database container.\
To get inside the container and use psql just type
```
docker-compose exec db psql -U [database_owner]
```
And after that execute the following query
```SQL
INSERT INTO users (email, password, is_admin)
VALUES ('your email', 'your password', TRUE);
```
To exit from psql type \q.
## Contributors
Vadym Kichur, vvkin.
