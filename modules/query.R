query_acs_post <- function(req) {
  body <- req$body

  if (body$geography == 'state') {
    state = NULL
  } else {
    state = body$state
  }
  
  # prep the filter statement from query results
  expressions <- body$queries %>%
    mutate(
      operator_symbol = case_when(
        operator == 'equal' ~ '==',
        operator == 'greater' ~ '>',
        operator == 'less' ~ '<',
        operator == 'greaterThanEqual' ~ '>=',
        operator == 'lessThanEqual' ~ '<='
      ),
      query_column = if_else(numberType == 'percent', 'percent', 'estimate'),
      expression = glue('{query_column}_{variable} {operator_symbol} {value}')
    )
  
  if (body$queryType == 'all') {
    selection_statement = paste(expressions$expression, collapse = ' & ')
  } else { # any
    selection_statement = paste(expressions$expression, collapse = ' | ')
  }

  print('selection statement ----------------')
  print(selection_statement)
  print('selection statement ----------------')
  # get data and prep the data
  data <- get_acs(
    geography = body$geography,
    survey    = body$survey,
    variables = body$variables,
    state     = state,
    year      = body$year,
    cache     = TRUE
  ) %>%
    # filter(GEOID == body$geoid) %>%
    mutate(var_group = str_extract(variable, '^[^_]+(?=_)')) %>%
    group_by(GEOID, var_group) %>%
    mutate(group_max = max(estimate)) %>%
    ungroup() %>%
    mutate(
      percent = 100 * (estimate / group_max),
      moe_perc = 100 * (moe / estimate),
      label = glue('{estimate};{percent};{moe}')
    ) %>%
    select(-NAME,-group_max,-var_group) %>% 
    # pivot wider makes it easier for querying
    pivot_wider(values_from = c(estimate, percent, moe, moe_perc, label), names_from=variable) %>%
    # smoosh the rows together by GEOID
    group_by(GEOID) %>%
    fill(everything(), .direction = "downup") %>%
    slice(1) %>%
    # now do the final query to filter the data we want
    filter(rlang::eval_tidy(rlang::parse_expr(selection_statement))) %>%
    rename(geoid = GEOID)
  
  # print(selection_statement)
  # data <- data %>%
  #   filter(rlang::eval_tidy(rlang::parse_expr(selection_statement)))

  variables <- paste(body$variables, collapse = "','")
  query_res <- dbGetQuery(con, glue("SELECT * FROM acs5_2020_vars WHERE name IN ('{variables}')")) %>%
    mutate(full_label = glue('{concept} - {label}'))
  columns = colnames(data)
  for (column in columns) {
    stripped <- str_replace(column, 'estimate_|percent_|moe_perc_|moe_|label_', '')
    idx <- which(columns == column)
    match <- filter(query_res, name == stripped)
    if (str_starts(column, 'percent')) {
      colnames(data)[idx] = glue('{match$full_label} (%)')
    } else if (str_starts(column, 'estimate')) {
      colnames(data)[idx] = match$full_label
    } else if (str_starts(column, 'moe_perc')) {
      colnames(data)[idx] = glue('{match$full_label} (MoE)')
    } else if (str_starts(column, 'moe_')) {
      colnames(data)[idx] = glue('{match$full_label} (MoE %)')
    } else if (str_starts(column ,'label')) {
      colnames(data)[idx] = glue('{match$full_label} (label)')
    }
  }

  geoids <- paste(data$geoid, collapse="','")
  get_geoids_statement = glue("select * from {body$geographyName} where geoid IN ('{geoids}')")

  sf::st_read(con, query = get_geoids_statement) %>%
    left_join(data, by = 'geoid') %>%
    # select(-geoid, -stusps) %>%
    select(name, contains('label')) %>%
    geojsonsf::sf_geojson(digits=5)
}

query_dec_post <- function(req) {
  body <- req$body

  if (body$geography == 'state') {
    state = NULL
  } else {
    state = body$state
  }
  
  # prep the filter statement from query results
  expressions <- body$queries %>%
    mutate(
      operator_symbol = case_when(
        operator == 'equal' ~ '==',
        operator == 'greater' ~ '>',
        operator == 'less' ~ '<',
        operator == 'greaterThanEqual' ~ '>=',
        operator == 'lessThanEqual' ~ '<='
      ),
      query_column = if_else(numberType == 'percent', 'percent', 'value'),
      expression = glue('{query_column}_{variable} {operator_symbol} {value}')
    )
  
  if (body$queryType == 'all') {
    selection_statement = paste(expressions$expression, collapse = ' & ')
  } else { # any
    selection_statement = paste(expressions$expression, collapse = ' | ')
  }

  print('selection statement ----------------')
  print(selection_statement)
  print('selection statement ----------------')
  # get data and prep the data
  # now get the data
  print('******************')
  print(body$geography)
  print(body$survey)
  print(body$variables)
  print(body$state)
  print(body$year)
  print('******************')
  data <- get_decennial(
    geography = body$geography,
    survey    = body$survey,
    variables = body$variables,
    state     = state,
    year      = body$year,
    cache     = TRUE
  ) %>% # perform some operations
    mutate(var_group = str_replace(variable, '(\\d{3})$', '')) %>%
    group_by(GEOID, var_group) %>%
    mutate(group_max = max(value)) %>%
    ungroup() %>%
    mutate(
      percent = 100 * (value / group_max),
      label = glue('{value};{round(percent, 2)}')
    ) %>%
    select(-NAME, -group_max, -var_group) %>%
    # pivot wider makes it easier for querying
    pivot_wider(values_from = c(value, percent, label), names_from=variable) %>%
    # smoosh the rows together by GEOID
    group_by(GEOID) %>%
    fill(everything(), .direction = "downup") %>%
    slice(1) %>%
    # now do the final query to filter the data we want
    filter(rlang::eval_tidy(rlang::parse_expr(selection_statement))) %>%
    rename(geoid = GEOID)

  print(head(data))

  variables <- paste(body$variables, collapse = "','")
  query_res <- dbGetQuery(con, glue("SELECT * FROM sf1_2010_vars WHERE name IN ('{variables}')")) %>%
    mutate(full_label = glue('{concept} - {label}'))
  columns = colnames(data)
  print(columns)
  for (column in columns) {
    stripped <- str_replace(column, 'label_', '')
    idx <- which(columns == column)
    match <- filter(query_res, name == stripped)
    if (str_starts(column ,'label')) {
      colnames(data)[idx] = glue('{match$full_label} (label)')
    }
  }

  geoids <- paste(data$geoid, collapse="','")
  get_geoids_statement = glue("select * from {body$geographyName} where geoid IN ('{geoids}')")

  sf::st_read(con, query = get_geoids_statement) %>%
    left_join(data, by = 'geoid') %>%
    # select(-geoid, -stusps) %>%
    select(name, contains('label')) %>%
    geojsonsf::sf_geojson(digits=5)
}

# example calls
# {
#     "dataset": "acs5",
#     "activeYear": "2020",
#     "activeGeom": "state",
#     "activeState": "AL",
#     "queryType": "all",
#     "variables": ["B01001_009", "B01001_006"],
#     "queries": [
#         {"variable": "B01001_009", "numberType": "percent", "value": "4", "operator": "greater"},
#         {"variable": "B01001_006", "numberType": "percent", "value": "0", "operator": "greater"}
#     ]
# }