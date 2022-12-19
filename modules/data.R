data_acs_post <- function(req) {
  body <- req$body
  print(body$geography)
  print(body$survey)
  # print(body$variables)
  print(body$state)
  print(body$county)
  print(body$year)
  # get acs or decennial (only these for now)
  # geography can be tract, county, state, or place (for now)
  data <- get_acs(
    geography = body$geography,
    survey    = body$survey,
    variables = body$variables,
    state     = body$state,
    county    = body$county,
    year      = body$year,
    cache     = TRUE
  ) %>%
    filter(GEOID == body$geoid) %>%
    mutate(var_group = str_extract(variable, '^[^_]+(?=_)')) %>%
    group_by(var_group) %>%
    mutate(group_max = max(estimate)) %>%
    ungroup() %>%
    mutate(percent = 100 * (estimate / group_max),
           moe_perc = 100 * (moe / estimate)) %>%
    select(-NAME, -group_max, -var_group)

  # grab all variable names and query to get their descriptive names
  variables_collapse = paste(data$variable, collapse = "','")
  new_query = glue("
    SELECT * FROM acs5_2020_vars
    WHERE name IN ('{variables_collapse}');
  ")
  query_res = dbGetQuery(con, new_query) %>% rename(variable = name)

  # return the join with the descriptive information
  left_join(data, query_res, 'variable')
}

data_dec_post <- function(req) {
  body <- req$body

  # now get the data
  data <- get_decennial(
    geography = body$geography,
    survey    = body$survey,
    variables = body$variables,
    state     = body$state,
    county    = body$county,
    year      = body$year
  ) %>% # perform some operations
    filter(GEOID == body$geoid) %>%
    mutate(var_group = str_replace(variable, '(\\d{3})$', '')) %>%
    group_by(var_group) %>%
    mutate(group_max = max(value)) %>%
    ungroup() %>%
    mutate(percent = 100 * (value / group_max), ) %>%
    select(-NAME, -group_max, -var_group)

  print(head(data))
  # grab all variable names and query to get their descriptive names
  variables_collapse = paste(data$variable, collapse = "','")
  new_query = glue("
    SELECT * FROM sf1_2010_vars
    WHERE name IN ('{variables_collapse}');
  ")
  query_res = dbGetQuery(con, new_query) %>% rename(variable = name)

  # return the join with the descriptive information
  left_join(data, query_res, 'variable')
}

# example calls
# {
#     "table": "sf1",
#     "year": 2010,
#     "geography": "tract",
#     "geoid": "26081000200",
#     "state": "MI",
#     "county": "Kent",
#     "variables": [
#         "H007001",
#         "H007002",
#         "H006001",
#         "H006002"
#     ]
# }
#
# {
#     "table": "acs5",
#     "year": 2020,
#     "geography": "tract",
#     "geoid": "26081000200",
#     "state": "MI",
#     "county": "Kent",
#     "variables": [
#         "B01001_001",
#         "B01001_002",
#         "B02001_001",
#         "B02001_002"
#     ]
# }