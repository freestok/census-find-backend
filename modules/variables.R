variables_get <- function(env, year, dataset, shallow) {
  con = env$con
  print(shallow)

  # just make sure the table is valid
  table <- glue('{dataset}_{year}_vars')
  helper_valid('^[a-zA-Z0-9_]+$', table)

  query = glue('SELECT name, label, concept FROM {table}')
  if (shallow == 'true') {
    query = glue('{query} WHERE tab = 0')
  }
  
  dbGetQuery(con, query)
}