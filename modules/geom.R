geom_get <- function(env, type, state) {
  con = env$con

  helper_valid('^[a-zA-Z]+$', type)

  query <- glue("select name, geoid, geometry from {type}")
  if (type != "states") {
    helper_valid('^[a-zA-Z]{2}$', state)
    query <- glue("{query} WHERE stusps = '{state}'")
  }
  dbGetQuery(con, query) %>%
    geojsonsf::sf_geojson(digits=5)
}

geom_get_names <- function(env, type) {
  helper_valid('^[a-zA-Z]+$', type)

  query <- glue("
    SELECT name, geoid, stusps FROM {type}
  ")
  dbGetQuery(env$con, query)
}