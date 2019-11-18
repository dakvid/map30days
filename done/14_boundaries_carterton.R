# Update for #30DayMapChallenge
# November 2019

library(readr)
library(magrittr)
library(tibble)
library(dplyr)
library(sf)
library(rmapshaper)
library(ggplot2)
library(gganimate)
library(transformr)
library(showtext)

font_add_google("Bree Serif", "bree")
showtext_auto()
DEFAULT_FONT <- "bree"


# Read in SA2 (2018) data -------------------
sa2_18 <-
  read_sf("statsnzstatistical-area-2-2018-clipped-generalised-GPKG/statistical-area-2-2018-clipped-generalised.gpkg") %>% 
  rename(SA22018_code = SA22018_V1_00,
         SA22018_name = SA22018_V1_00_NAME) %>% 
  mutate(SA22018_code = as.integer(SA22018_code))
sa2_18_simp <-
  sa2_18 %>% 
  ms_simplify(keep_shapes = TRUE, keep = 0.45) # defaults to 5% of points


# Read in AU (2017) data ------------------

au_17 <-
  read_sf("statsnzarea-unit-2017-generalised-version-GPKG/area-unit-2017-generalised-version.gpkg") %>% 
  rename(AU2017_code = AU2017,
         AU2017_name = AU2017_NAME) %>% 
  mutate(AU2017_code = as.integer(AU2017_code))
au_17_simp <-
  au_17 %>%
  ms_simplify(keep_shapes = TRUE, keep = 0.45)

# We need know the parent Territorial authorities for reasonable subsetting ----------

meshblocks <-
  read_tsv("Annual Areas 2018.txt")
names(meshblocks)[23] <- "REGC2018_code"
names(meshblocks)[24] <- "REGC2018_name"
names(meshblocks)[25] <- "CON2018_code"
names(meshblocks)[26] <- "CON2018_name"
meshblocks %<>%
  select(7:12, 15:16, 21:24, 38:43)

map_sa2 <-
  meshblocks %>% 
  distinct(
    SA22018_code,
    SA22018_name,
    UR2018_code,
    UR2018_name,
    TA2018_code,
    TA2018_name
  )

map_au <-
  meshblocks %>% 
  distinct(
    AU2017_code,
    AU2017_name,
    UR2018_code,
    UR2018_name,
    TA2018_code,
    TA2018_name
  )

sa2_18 %<>%
  inner_join(map_sa2)
sa2_18_simp %<>%
  inner_join(map_sa2)

au_17 %<>% 
  inner_join(
    map_au %>% 
      select(starts_with("AU2"), starts_with("TA2")) %>% 
      distinct()
  )
au_17_simp %<>% 
  inner_join(
    map_au %>% 
      select(starts_with("AU2"), starts_with("TA2")) %>% 
      distinct()
  )

theme_map <- function(...) {
  theme_minimal() +
    theme(
      text = element_text(
        family = DEFAULT_FONT,
        size = 12,
        color = "#22211d"),
      axis.line = element_blank(),
      axis.text.x = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks = element_blank(),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      # panel.grid.minor = element_line(color = "#ebebe5", size = 0.2),
      panel.grid.major = element_line(color = "#ebebe5", size = 0.2),
      panel.grid.minor = element_blank(),
      plot.background = element_rect(fill = "#f5f5f2", color = NA), 
      panel.background = element_rect(fill = "#f5f5f2", color = NA), 
      legend.background = element_rect(fill = "#f5f5f2", color = NA),
      panel.border = element_blank(),
      ...
    )
}



# NZ map ------------------------------------------------------------------

nzgeo <- au_17 %>%
  count()
nzgeo_simp <-
  au_17_simp %>% 
  filter(!TA2018_name %in% c("Chatham Islands Territory", "Area Outside Territorial Authority")) %>%
  count()
nzgeo_simp2 <-
  sa2_18_simp %>% 
  filter(!TA2018_name %in% c("Chatham Islands Territory", "Area Outside Territorial Authority")) %>%
  count()
ctgeo <- au_17_simp %>% filter(TA2018_name == "Carterton District") %>% count()

inset_map <- 
  ggplot() +
  theme_map() +
  geom_sf(data = nzgeo_simp2,
          aes(geometry = geom),
          fill = "white", color = "gray80") +
  geom_sf(data = ctgeo,
          aes(geometry = geom),
          fill = "black", color = "black")


# Carterton bit -----------------------------------------------------------

carterton_sa2 <-
  sa2_18 %>% 
  filter(TA2018_name == "Carterton District")

carterton_au <-
  au_17 %>% 
  filter(TA2018_name == "Carterton District")


carterton_mapping <-
  tribble(
    ~ta_id, ~AU2017_name, ~label17, ~SA22018_name, ~label18,
    1L, "Waingawa",      "Waingawa",         "Kokotau",                        "Kokotau",
    2L, "Mt Holdsworth", "Mount Holdsworth", "Mount Holdsworth",               "Mounth Holdsworth",
    3L, "Te Wharau",     "Te Wharau",        "Gladstone (Carterton District)", "Gladstone",
    4L, "Carterton",     "Carterton",        "Carterton North",                "Carterton North",
    5L, "Carterton",     "",                 "Carterton South",                "Carterton South"
  )

carterton_data <-
  rbind(
    au_17 %>% 
      inner_join(
        carterton_mapping %>% 
          select(ta_id, AU2017_name, label = label17)
      ) %>% 
      select(ta_id, label) %>% 
      mutate(type = "2017 Area Unit"),
    sa2_18 %>% 
      inner_join(
        carterton_mapping %>% 
          select(ta_id, SA22018_name, label = label18)
      ) %>% 
      select(ta_id, label) %>% 
      mutate(type = "2018 Statistical Area 2")
  )


ggplot() +
  theme_map() +
  geom_sf(data = carterton_data %>% filter(type == "2018 Statistical Area 2"),
          aes(geometry = geom,
              group = ta_id)) +
  geom_text(
    data = types %>% filter(type == "2018 Statistical Area 2"),
    aes(label = type),
    x = 1809582, #1833727,
    y = 5410822, #5369287,
    hjust = 0,
    family = DEFAULT_FONT
  ) +
  annotation_custom(
    grob = ggplotGrob(inset_map),
    xmin = 1790266, #1814411,
    xmax = 1809582, #1824069,
    ymin = 5410822, #5452434,
    ymax = 5438512 #5466279
  ) +
  labs(title = "Carterton District small areas: ",
       #subtitle = "{closest state}",
       caption = "David Friggens, https://david.frigge.nz")


types <- 
  tibble(type = c("2017 Area Unit", "2018 Statistical Area 2"))


carterton_plot <- 
  ggplot() +
  theme_map() +
  geom_sf(data = carterton_data,
          aes(geometry = geom,
              group = ta_id)) +
  annotation_custom(
    grob = ggplotGrob(inset_map),
    xmin = 1790266, #1814411,
    xmax = 1809582, #1824069,
    ymin = 5410822, #5452434,
    ymax = 5438512 #5466279
  ) +
  transition_states(type, 1, 1) +
  ease_aes("cubic-in-out") +
  labs(title = "Carterton District: {closest_state}s",
       subtitle = "Stats NZ introduced a new geographical classification for New Zealand",
       caption = "David Friggens, https://david.frigge.nz")

carterton_gif <- 
  animate(carterton_plot,
          duration = 6,
          fps = 10,
          width = 600,
          height = 800)

anim_save("done/14_boundaries_carterton.gif", animation = carterton_gif)
