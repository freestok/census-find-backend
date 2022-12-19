library(glue)
library(tidyverse)
library(dbplyr)

cache_views <- function(tbl, cols, con) {
  # first drop materialized view if it already exists
  tryCatch(
    expr = {
      query <- glue('DROP MATERIALIZED VIEW {tbl}_geojson;')
      dbExecute(con, query)
    },
    error = function(e) {
      print(e)
      print('materialized view does not exist')
    }
  )
  
  # create materialized views
  cols_str <- paste(cols, collapse = ',')
  print(cols_str)
  if (tbl == 'states') {
    query <- glue(
      "CREATE MATERIALIZED VIEW {tbl}_geojson AS
        SELECT 
          Jsonb_build_object(
            'type',
            'FeatureCollection',
            'features',
            Jsonb_agg(
              St_asgeojson(t.*):: json
            )
          )
        FROM (
          SELECT {cols_str}, 
            ST_SimplifyPreserveTopology(geometry, .05) geometry
          FROM {tbl}
        ) AS t
        WITH data;
    ")
  } else {
   query <- glue(
      "CREATE MATERIALIZED VIEW {tbl}_geojson AS
        SELECT stusps,
          Jsonb_build_object(
            'type',
            'FeatureCollection',
            'features',
            Jsonb_agg(
              St_asgeojson(t.*):: json
            )
          )
        FROM (
          SELECT {cols_str}, geometry
          FROM {tbl}
        ) AS t
        GROUP BY stusps
        WITH data;
    ")
  }
  print(query)
  dbExecute(con, query)
}
