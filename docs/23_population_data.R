library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(sf)
library(rmapshaper)

# from stats.govt.nz
sa2_geo <- 
  st_read("data/statistical-area-2-2019-clipped-generalised.gpkg") %>% 
  transmute(code = SA22019_V1_00 %>% as.character() %>% as.integer(),
            name = as.character(SA22019_V1_00_NAME)) %>% 
  ms_simplify(keep = 0.45, keep_shapes = TRUE)

# from stats.govt.nz
sa2_pop <- 
  read_tsv("data/population_by_age.tsv") %>% 
  select(code = AREA,
         age = Age,
         population = `Value  Flags`)

# Millennials are supposedly aged 23-38
# Baby Boomers are supposedly aged 55-73
# Only have 5 years groups, so let's take 25-34 and both
#  55-64 (ten years for comparison) and 55-69
# Also kids (0-19) and retirees (70+)
pop_groups <- 
  tribble(
    ~age, ~generation,
    "0-4 Years", "Kids",
    "5-9 Years", "Kids",
    "10-14 Years", "Kids",
    "15-19 Years", "Kids",
    "25-29 Years", "Millennials",
    "30-34 Years", "Millennials",
    "55-59 Years", "Boomers",
    "60-64 Years", "Boomers",
    "55-59 Years", "Baby Boomers",
    "60-64 Years", "Baby Boomers",
    "65-69 Years", "Baby Boomers",
    "70-74 Years", "Retirees",
    "75-79 Years", "Retirees",
    "80-84 Years", "Retirees",
    "85 Years and over", "Retirees"
  )

sa2_pop_groups <- 
  sa2_pop %>% 
  inner_join(pop_groups, by = "age") %>% 
  group_by(code, generation) %>% 
  summarise(population = sum(population)) %>% 
  ungroup() %>% 
  spread(generation, population)

inner_join(
  sa2_geo,
  sa2_pop_groups,
  by = "code"
) %>% 
  st_write("23_population.gpkg")

