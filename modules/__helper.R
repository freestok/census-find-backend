library(pool)
library(RPostgres)
library(dbplyr)
library(glue)

get_con <- function() {
  # readRenviron('.RenvironProd')
  db <- Sys.getenv("postgres_db")
  port <- Sys.getenv("postgres_port")
  user <- Sys.getenv("postgres_user")
  pw <- Sys.getenv("postgres_pw")
  host <- Sys.getenv("host")
  project <- Sys.getenv('project')
  con <- dbPool(
    RPostgres::Postgres(),
    dbname = db,
    port = port,
    user = user,
    password = pw,
    host = host,
    options = glue('project={project}')
  )
  return (con)
}

helper_get_census_key <- function() {
  # readRenviron('.RenvironProd')
  Sys.getenv('census_key')
}

assert_help <- function(x, vals) {
  assertthat::are_equal(x %in% vals, TRUE)
}

helper_valid <- function(regex, value) {
  valid <- grepl(regex, value)
  if (!valid) {
    stop('Invalid parameters')
  }
}
