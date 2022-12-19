library(tidyverse)
library(tigris)
library(sf)
library(rmapshaper)
library(glue)

all_states <-
  c( 'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'DC', 'FL', 'GA', 'HI', 
     'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 'MA', 'MI', 'MN', 
     'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY', 'NC', 'ND', 'OH', 
     'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 
     'WV', 'WI', 'WY' )

geom_write <- function(df, con, name, simplify_factor) {
  print(glue('Writing {name} to database'))
  # st_write(df, con, name, layer_options = "OVERWRITE=true")

  # print(glue('Writing {name}_simple to database'))
  df %>%
    ms_simplify(simplify_factor) %>%
    st_write(con, name, layer_options = "OVERWRITE=true")
}

cache_geom <- function(con, geom, tigris_func, year, selectors, simplify_factor) {
  print(glue('Starting cache {geom}'))
  df <- tigris_func(year = year, cb = TRUE) %>%
    filter(STUSPS %in% all_states) %>%
    select(selectors) %>%
    rename_all(.funs = tolower) %>%
    st_transform(4326)
  
  geom_write(df, con, geom, simplify_factor)
  print(glue('Done caching {geom}'))
}

cache_tracts <- function(con, simplify_factor=0.5) {
  # get tracts
  print('cache tracts')
  tracts_list <- vector('list', length = length(all_states))
  for (i in seq_along(all_states)) {
    tract_df <- tracts(cb = TRUE,
                       year = 2020,
                       state = all_states[[i]]) %>%
      select(GEOID, NAME, STUSPS) %>%
      rename_all(.funs = tolower) %>%
      st_transform(4326)
    
    tracts_list[[i]] <- tract_df
  }
  tracts_sf <- bind_rows(tracts_list)
  geom_write(tracts_sf, con, 'tracts', simplify_factor)
}
