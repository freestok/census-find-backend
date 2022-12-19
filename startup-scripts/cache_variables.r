library(tidycensus)
library(tidyverse)
library(dbplyr)

cache_vars <- function(dataset, year, tab_mod, con) {
  vars <- load_variables(
    year,
    dataset = dataset,
    cache = FALSE
  )
  # find the tab, get labels
  tab_df <- vars %>%
    mutate(
      tab=str_count(label,'!!') - tab_mod,
      label = case_when(
        label == 'Estimate!!Total:' ~ 'Total',
        label == 'Estimate!!Total' ~ 'Total',
        TRUE ~ str_extract(label, '([^!!]*)$') %>% str_replace(':$', '') # else
      ),
      concept = str_to_title(concept) %>% 
        str_replace(' By ', ' by ') %>% 
        str_replace(' And ', ' and ') %>%
        str_replace(' Or ', ' or ') %>%
        str_replace(' For ', ' for ') %>%
        str_replace(' Of ', ' of ')
    )
  
  copy_to(con, tab_df, str_c(dataset,'_',year,'_','vars'), temporary=FALSE, 
          indexes=c('name'), overwrite = TRUE)
}