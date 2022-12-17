# plumber.R
library(tidycensus)

#* @preempt __first__
#* @get /
function(req, res) {
  res$status <- 302
  res$setHeader("Location", "./__docs__/")
  res$body <- "Redirecting..."
  res
}

#* Echo back the input
#* @param msg The message to echo
#* @get /echo
function(msg=""){
  list(msg = paste0("The message is: '", msg, "'"))
}

# #* test the tidyverse
# #* @param msg The message to echo
# #* @get /tidy
# function(msg=""){
#   stringr::str_width(msg)
# }

# #* test tidycensus
# #* @get /census
# function(){
#   get_decennial(geography = "state", 
#                 variables = "P013001", 
#                 year = 2010)
# }

#* Plot a histogram
#* @png
#* @get /plot
function(){
  rand <- rnorm(100)
  hist(rand)
}

#* Return the sum of two numbers
#* @param a The first number to add
#* @param b The second number to add
#* @post /sum
function(a, b){
  as.numeric(a) + as.numeric(b)
}
