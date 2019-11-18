library(tibble)
library(threejs)
library(widgetframe)

antarctic <- 
  tribble(
    ~country_lat, ~country_long, ~ant_lag, ~ant_long, 
    -43.53, 172.62, -80, 175, # New Zealand
    -35.29, 149.13, -75,  90, # Australia 1
    -35.29, 149.13, -75, 151, # Australia 2
    -34.60, -58.38, -85, -50, # Argentina
    -33.45, -70.67, -80, -70, # Chile
     51.51,  -0.13, -85, -30, # UK
     48.86,   2.35, -75, 139.5, # France
     59.92,  10.73, -75,  12 # Norway
  )

ant_globe <- 
  globejs(arcs=antarctic,
          bodycolor="#aaaaff",
          arcsHeight=0.4,
          arcsLwd=3,
          arcsColor="#ffff00",
          arcsOpacity = 1,
          atmosphere=TRUE)

saveWidget(frameableWidget(ant_globe),
           "18_globe_antarctica.html")

