library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(sf)
library(rmapshaper)

# stats.govt.nz
regions <- 
  st_read("statsnzregional-council-2018-clipped-generalised-GPKG/regional-council-2018-clipped-generalised.gpkg") %>% 
  transmute(code = as.integer(REGC2018_V1_00),
            name = as.character(REGC2018_V1_00_NAME)) %>% 
  filter(name != "Area Outside Region") %>% 
  mutate(name = name %>% str_replace(" Region", "") %>% str_replace("Wanganui", "Whanganui")) %>% 
  ms_simplify(keep = 0.02, keep_shapes = TRUE)

# https://figure.nz/chart/Wx1iBZzfdBsmVTtk
compost <- 
  read_csv("Society_Neighbourhood_and_environmental_measures_2018.csv") %>% 
  filter(`Response category` == "Compost green waste such as food scraps",
         `Cross analysis variable` == "Region",
         Unit == "Estimate") %>% 
  select(Region = Category,
         CompostPC = Value)


region2group <- 
  bind_cols(compost %>% select(Region),
            compost %>% select(name = Region)) %>% 
  separate_rows(name, sep = ", ")

geo_compost <- 
  regions %>% 
  inner_join(region2group, by = "name") %>% 
  group_by(Region) %>% 
  count() %>% 
  ungroup() %>% 
  inner_join(compost, by = "Region") %>% 
  rename(NumberOfRegions = n)

st_write(geo_compost, "08_green_data.gpkg")

