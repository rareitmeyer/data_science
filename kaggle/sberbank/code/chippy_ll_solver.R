# This is an extracted form of Chippy's Lat Long solver
# See his post "Lat and Longitude for all locations/Lat and Longitude for all locations"
# Thanks, Chippy!

# == General == #
library(data.table) # read data with fread()
library(DT)         # display interactive tables
library(xgboost)    # create GBM models
library(doParallel)

# == Spatial == #
library(rgdal)
library(rgeos)
library(sp)
library(raster)
library(spatstat) # fast nearest neighbour
library(maptools) # coercion spdf to ppp



chippy_ll_solver <- function(data)
{
    data <- data.table(data)
    data[, key:= paste(mkad_km, ttk_km, sadovoe_km, sub_area, sep=":")] 
    dt_locations <- data[ , .(mkad_km = mean(mkad_km),ttk_km = mean(ttk_km), 
                              sadovoe_km = mean(sadovoe_km), sub_area = first(sub_area), 
                              count = .N, lat = 0, lon = 0, tolerance_m = 0), 
                          by = 'key' ]
    
    setkey(dt_locations, count)
    setorder(dt_locations, -count)
    
    shp_mkad <- readOGR(dsn = "../input/sberbankmoscowroads", layer = "Rd_mkad_UTM", verbose=FALSE)
    shp_ttk <- readOGR(dsn = "../input/sberbankmoscowroads", layer = "Rd_third_UTM", verbose=FALSE)
    shp_sadovoe <- readOGR(dsn = "../input/sberbankmoscowroads", layer = "Rd_gard_UTM", verbose=FALSE)
    
    ## administrative area
    shp_sub_area <-readOGR(dsn = "../input/sberbankmoscowroads", layer = "moscow_adm", verbose=FALSE)
    
    CRS_planar <- "+proj=utm +zone=36 +ellps=WGS72 +units=m +no_defs"
    CRS_WGS84 <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0 "
    
    # Worker function.
    get_LatLon <- function(i, mySubArea)
    {
        # subset data by sub_area  
        dt_sublocations <- dt_locations[sub_area == mySubArea,]
        
        # identify distances to roads
        buff_mkad <- dt_sublocations[i,mkad_km] * 1000
        buff_ttk <- dt_sublocations[i,ttk_km] * 1000
        buff_sadovoe <- dt_sublocations[i,sadovoe_km] * 1000
        
        # add buffer to roads (already in planar)
        shp_buff_mkad <- gBuffer(shp_mkad, width = buff_mkad)
        shp_buff_ttk <- gBuffer(shp_ttk, width = buff_ttk)
        shp_buff_sadovoe <- gBuffer(shp_sadovoe, width = buff_sadovoe)
        
        # now require a loop to progressively buffer lines until good intersection is formed
        
        # tolerance in meters 
        lst_tolerance <- c(5, 10, 25, 50, 100, 250)
        
        for (intersect_tolerance in lst_tolerance) {
            # extract sub_area shape (with tolerance buffer)
            shp_buff_subarea <- gBuffer(spTransform(shp_sub_area[shp_sub_area@data$RAION == mySubArea,], 
                                                    CRS(CRS_planar)), width=intersect_tolerance)
            
            # clip buffered roads to buffered sub_area
            shp_clip_mkad <- gIntersection(shp_buff_subarea,as(shp_buff_mkad, 'SpatialLines'), byid = TRUE )
            shp_clip_ttk <- gIntersection(shp_buff_subarea,as(shp_buff_ttk, 'SpatialLines') , byid = TRUE)
            shp_clip_sadovoe <- gIntersection(shp_buff_subarea,as(shp_buff_sadovoe, 'SpatialLines'), byid = TRUE)
            
            # if clip didn't work loop round again at next higher tolerance
            if(is.null(shp_clip_mkad) | is.null(shp_clip_ttk) | is.null(shp_clip_sadovoe))  next
            
            # identify the intersection of 3 buffered lines
            shp_intersect <- gIntersection(gBuffer(shp_clip_mkad, width=intersect_tolerance),
                                           gBuffer(shp_clip_ttk, width=intersect_tolerance),
                                           byid = TRUE)
            
            # if intersection couldn't be formed loop round again at next higher tolerance
            if(is.null(shp_intersect)) next
            
            shp_intersect <- gIntersection(shp_intersect,
                                           gBuffer(shp_clip_sadovoe, width=intersect_tolerance),
                                           byid = TRUE)
            
            dt_sublocations[i,tolerance_m:=intersect_tolerance]
            
            # if we have an intersection break out of tolerance loop
            if(!is.null(shp_intersect)) break
        }
        
        # identify the centroid of the intersection zone. 
        shp_latlon <- gCentroid(shp_intersect)
        
        #finally convert to WGS84 from which lat and long can be extracted from @coords
        shp_latlon <- spTransform(shp_latlon, CRS(CRS_WGS84))
        
        dt_sublocations[i,lat:=shp_latlon@coords[[2]]]
        dt_sublocations[i,lon:=shp_latlon@coords[[1]]]
        
        
        return(dt_sublocations[i,])
    }
    
    
    
    
    lst_subarea <- unique(dt_locations$sub_area)
    lst_subarea <- lst_subarea[order(lst_subarea)] # sort for known traveral order
    tmpfilename <- '../input/tmp_lat_lon.csv'
    for (mySubArea in lst_subarea){
        filename <- paste0('../input/', mySubArea, "_lat_lon.csv")
        if (!file.exists(filename)) {
            cl <- makeCluster(4)  # suitable for a 4 core desktop, but perhaps not for a smaller laptop with less RAM. 
            registerDoParallel(cl)
        
            result <- foreach(i=1:nrow(dt_locations[sub_area == mySubArea]), .combine = rbind, 
                              .packages=c("sp", "raster", "rgdal", "rgeos", "data.table")) %dopar% get_LatLon(i, mySubArea)
            
            stopCluster(cl)
            
            # write to a temp filename, then rename, in case there's a crash partway through.
            write.csv(result, tmpfilename, row.names = FALSE)
            file.rename(tmpfilename, filename)
        }
    } 
}