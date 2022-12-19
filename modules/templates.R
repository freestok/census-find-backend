templates_vars_get <- function(con, id) {
    query <- glue("
        SELECT b.var, b.year, b.survey 
        FROM templates a
        INNER JOIN template_vars b
            ON b.template_id = a.id
        WHERE a.id = {id}
    ")
    dbGetQuery(con, query)
}

templates_get <- function(con, category) {
    if (category == 'primary') {
        query <- "SELECT id, title FROM templates WHERE template_type = 'primary';"
    } else if (category == 'custom') {
        query <- "SELECT id, title FROM templates WHERE template_type = 'custom';"
    } else if (category == 'all') {
        query <- "SELECT id, title FROM templates;"
    } else {
        stop('Invalid parameters')
    }

    dbGetQuery(con, query)
}

templates_post <- function(con, req) {
    body <- req$body

    survey <- body$survey
    title <- body$template
    variable_year <- body$variableYear
    variables <- body$variables
    year <- body$year

    collapsed <- paste(variables, collapse = '%|')
    query <- glue("
            SELECT name FROM {survey}_{variable_year}_vars
            WHERE name SIMILAR TO '{collapsed}%'
        ")

    print('------------')
    print(query)
    print('------------')
    res <- dbGetQuery(con, query)

    print(res)
    var_list <- vector(mode='list', length=length(res$name))

    # actually create template
    query <-
    glue(
        "INSERT INTO templates (title, template_type) 
            VALUES ('{title}', 'custom') RETURNING id;"
    )
    insert_template_res <- dbGetQuery(con, query)
    id = insert_template_res$id

    # insert template vars into template
    for (i in seq_along(var_list)) {
        query <- glue("({id}, '{res$name[[i]]}', {year}, '{survey}')")
        var_list[[i]] = query
    }

    combine_var = paste(var_list, collapse=', ')
    insert_rows <- glue("
            INSERT INTO template_vars (template_id, var, year, survey) 
            VALUES {combine_var};
        ")
    dbExecute(con, insert_rows);
    return ('complete')
}