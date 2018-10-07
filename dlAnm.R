library(sf)
library(dplyr)

download.file(url = "http://geodpags.skogsstyrelsen.se/geodataport/data/sksAvverkAnm.zip",
              destfile = "temp/anm/anm.zip")
unzip("temp/anm/anm.zip", exdir = "temp/anm")

if(isTRUE(Sys.info()['sysname'] == "Windows")) {
        anm <- read_sf("temp/anm/sksAvverkAnm.shp", options = "ENCODING=latin1")
} else{
        anm <- read_sf("temp/anm/sksAvverkAnm.shp")
}

anm <- select(anm, -Lannr, -Kommunnr)

if(isTRUE(Sys.info()['sysname'] == "Windows")) {
        replaceMisencodings <- function(x) {
                Encoding(x) <- "latin1"
                x <- gsub("Â„", "ä", x)
                x <- gsub("Â”", "ö", x)
                x <- gsub("ÂŽ", "Ä", x)
                x <- gsub("Â†", "å", x)
                x <- gsub("Â™", "Ö", x)
                x <- gsub("Â\u008f", "Å", x)
                x
        }
} else{
        replaceMisencodings <- function(x) {
                x <- gsub("\x94", "ö", x)
                x <- gsub("\x84", "ä", x)
                x <- gsub("\x86", "å", x)
                x <- gsub("\x99", "Ö", x)
                x <- gsub("\x8e", "Ä", x)
                x <- gsub("\x8f", "Å", x)
                x
        }
}

anm$Lan <- replaceMisencodings(anm$Lan)
anm$Avverktyp <- replaceMisencodings(anm$Avverktyp)
anm$Kommun <- replaceMisencodings(anm$Kommun)
anm$Skogstyp <- replaceMisencodings(anm$Skogstyp)
anm <- st_transform(anm, crs = "+proj=longlat +datum=WGS84")

anm$Lan <- gsub("s län", "", anm$Lan)

kommunlista <- sort(unique(anm$Kommun))
for(i in 1:length(kommunlista)) {
        file.remove(dir(paste("data/anm/", kommunlista[i], sep=""), full.names = T))
        filter(anm, Kommun == kommunlista[i]) %>%
                write_sf(dsn = paste("data/anm/", kommunlista[i], sep = ""),
                         layer = paste(kommunlista[i]),
                         driver = "ESRI Shapefile")
}

municipalities <- readRDS("municipalities.rds")

anm <- filter(anm, Inkomdatum >= Sys.Date()-60)

for(i in 2:length(names(municipalities))) {
        file.remove(dir(paste("data/anm/", "Senaste_", names(municipalities)[i], sep=""), full.names = T))
        filter(anm, Lan == names(municipalities)[i]) %>%
                write_sf(dsn = paste("data/anm/", "Senaste_", names(municipalities)[i], sep = ""),
                         layer = paste("Senaste_", names(municipalities)[i], sep = ""),
                         driver = "ESRI Shapefile")
}

file.remove(dir("temp/anm", full.names = T))