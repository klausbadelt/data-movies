-- sqlite3 movies.sqlite3 < 01-movies.sql

CREATE TABLE movies (
  id INTEGER PRIMARY KEY,
  title_index varchar(250),
  year_from integer,
  year_to integer
  -- budget integer,
  -- length integer,
  -- imdb_rating float,
  -- imdb_votes integer,
  -- imdb_rating_votes varchar(10),
  -- mpaa_rating varchar(5)
);

CREATE TABLE distributors (
  id INTEGER PRIMARY KEY,
  movie_id integer,
  distributor varchar(250),
  year integer,
  territory varchar(50),
  rights varchar(50),
  info varchar(50)
);

CREATE TABLE movies_distributors (
  movie_id INTEGER,
  distributor_id INTEGER
);

CREATE TABLE Ratings (
  id INTEGER PRIMARY KEY,
  movie_id integer,
  score varchar(10),
  outof10 float,
  votes integer
);

CREATE TABLE Genres (
  id INTEGER PRIMARY KEY,
  movie_id integer,
  genre varchar(50)
);

CREATE INDEX id on Movies (id);
CREATE INDEX titleIndex on Movies (title_index);

CREATE INDEX did on Distributors (id);
CREATE INDEX dmid on Distributors (movie_id);

CREATE INDEX rid on Ratings (id);
CREATE INDEX rmid on Ratings (movie_id);

CREATE INDEX gid on Genres (id);
CREATE INDEX gmid on Genres (movie_id);
