# installed libraries
library(pool)
library(here)
library(RPostgres)
library(dbplyr)
library(glue)

# import custom functions
source("cache_geoms.R")
source("cache_variables.R")
source("cache_materialized_views.R")
source("create_templates.R")

# get the environment variables
readRenviron('.RenvironProd')

# connect to the database
db <- Sys.getenv("postgres_db")
port <- Sys.getenv("postgres_port")
user <- Sys.getenv("postgres_user")
pw <- Sys.getenv("postgres_pw")
host <- Sys.getenv("host")
project <- Sys.getenv('project')
con <- dbPool(
  RPostgres::Postgres(),
  dbname = db,
  port = 5432,
  user = user,
  password = pw,
  host = host,
  options = glue('project={project}')
)

# cache the geoms
cache_geom(con, 'states', tigris::states, 2020, 
           c('GEOID', 'NAME', 'STUSPS'), 0.15)
cache_geom(con, 'counties', tigris::counties, 2020, 
           c('GEOID', 'NAME', 'STUSPS'), 0.3)
cache_geom(con, 'places', tigris::places, 2020, 
           c('GEOID', 'NAME', 'STUSPS'), 0.3)
cache_tracts(con, 0.15)

# cache the variables
cache_vars('acs5', '2020', 1, con)
cache_vars('sf1', '2010', 0, con)
cache_vars('pl', '2020', 1, con)

# create the templates
create_templates(con)

# NO LONGER NEEDED - create the materialized views
cache_views('places', c('name', 'stusps'), con)
cache_views('tracts', c('name', 'stusps'), con)
cache_views('counties', c('name', 'stusps'), con)
cache_views('states', c('name', 'stusps'), con)
