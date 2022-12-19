# library(plumber)

# port <- Sys.getenv('PORT')

# server <- plumb("plumber.R")

# server$run(
# 	host = '0.0.0.0',
# 	port = as.numeric(port),
# 	docs=TRUE
# )

# -------------------------------
library(plumber)
library(here)
# readRenviron(here('.RenvironProd'))

source(here('modules', '__helper.R'))
con <- get_con()

port <- Sys.getenv("plumber_port")
plumb_file <- here('plumber.R')
pr <- plumb(plumb_file) 

pr$registerHooks(
  list(
    "exit" = function() {
      poolClose(con)
    }
  )
)

pr_run(pr, port=strtoi(port))