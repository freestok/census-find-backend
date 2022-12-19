library(glue)
library(tidyverse)
library(dbplyr)

# "INSERT INTO template_vars (template_id, var, year, survey) VALUES
#       ({id}, 'B01001_001', 2020, 'acs5'),
#       ({id}, 'B01001_001', 2020, 'acs5'),
#       ({id}, 'B02001_001', 2020, 'acs5'),
#       ({id}, 'B02001_002', 2020, 'acs5');
#     "
create_var_string <- function(variable, number, id, year, survey) {
  # query_str <- 'INSERT INTO template_vars (template_id, var, year, survey) VALUES '
  
  var_list <- vector(mode='list', length=number)
  
  for (i in seq_along(var_list)) {
    var_num <- stringr::str_pad(i, 3, pad='0')
    var <- glue('{variable}_{var_num}')
    query <- glue("({id}, '{var}', {year}, '{survey}')")
    var_list[[i]] = query
  }
  combine_var = paste(var_list, collapse=', ')
  glue("
    INSERT INTO template_vars (template_id, var, year, survey) 
    VALUES {combine_var};
  ")
}
create_templates <- function(con) {
   query <- glue("
    CREATE TABLE templates (
        id serial PRIMARY KEY,
        title text NOT NULL,
        template_type text NOT NULL
    );
    CREATE TABLE template_vars (
        id serial PRIMARY KEY,
        template_id integer,
        var text NOT NULL,
        year smallint NOT NULL,
        survey text NOT NULL,
        CONSTRAINT fk_templates 
            FOREIGN KEY(template_id) 
            REFERENCES templates(id)
    );  
   ") 
    dbExecute(con, query)
}

insert_new_template <- function(con) {
  title <- 'ACS 5-year Demographics'
  year <- 2020
  survey <- 'acs5'
  
  query <-
    glue(
      "INSERT INTO templates (title, template_type) 
         VALUES ('{title}', 'primary') RETURNING id;"
    )
  res <- dbGetQuery(con, query)
  id = res$id
  
  # test <- vector(mode='list', length=49)
  
  # insert_rows <- create_var_string('B01001', 49, 1, 2020, 'acs5')
  insert_list = list(
    B01001 = 49,
    B17001 = 59,
    B19001 = 17,
    B08301 = 21
  )
  
  for (name in names(insert_list)) {
    number = insert_list[[name]]
    insert_rows <- create_var_string(name, number, id, year, survey)
    dbExecute(con, insert_rows);
  }
  # insert_rows <- glue(
  #   "INSERT INTO template_vars (template_id, var, year, survey) VALUES
  #     ({id}, 'B01001_001', 2020, 'acs5'),
  #     ({id}, 'B01001_001', 2020, 'acs5'),
  #     ({id}, 'B02001_001', 2020, 'acs5'),
  #     ({id}, 'B02001_002', 2020, 'acs5');
  #   "
  # )
  # dbExecute(con, insert_rows)
  
  
}
