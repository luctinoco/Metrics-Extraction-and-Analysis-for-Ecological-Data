# Clean the environment
rm(list = ls())

# Load necessary libraries
library(raster)
library(landscapemetrics)
library(rgdal)
library(sf)
library(sp)
library(rgeos)
library(stringr)
library(readxl)
library(dplyr)
library(stringi)

# Set working directories
dir <- 'path/to/your/directory'  # Change to your working directory

# Define the name of the Excel table
table_name <- 'your_table.xlsx'  # Update with your file name

# Define coordinate reference systems (CRS)
crs_wgs <- '+proj=longlat +datum=WGS84 +no_defs'
crs_albers <- '+proj=aea +lat_0=-32 +lon_0=-60 +lat_1=-5 +lat_2=-42 +x_0=0 +y_0=0 +ellps=aust_SA +units=m +no_defs'

# Set directory with raster files
raster_dir <- 'path/to/raster/directory'

# List all .tif files in the raster directory
raster_files <- list.files(raster_dir, pattern = "\\.tif$", full.names = TRUE)

# Create a raster stack with all listed raster files
raster_stack <- stack(raster_files)

# Read the Excel file containing points
points <- read_excel(paste0(dir, "/", table_name))

# Convert points to spatial data
spatial_points <- st_as_sf(points, coords = c('LONG', 'LAT'), crs = crs_wgs)
spatial_points <- st_transform(spatial_points, crs = crs_albers)

# Define buffer radius (10 km in this example)
radius <- 10000

# Create buffers around points
buffer <- st_buffer(spatial_points, radius, nQuadSegs = 1000, joinStyle = "MITRE", endCapStyle = "ROUND", mitreLimit = 2.0)

# Split buffers by region (adjust as needed for your project)
buffer_names <- buffer %>%  
  split(buffer$Region)  # Change 'Region' to your relevant column name

# Dissolve the buffers (merge overlapping areas)
buffer_dissolve <- buffer %>%
  st_cast("POLYGON") %>%
  split(.$Region) %>%
  lapply(st_union) %>%
  do.call(c, .)

buffer_dissolve <- bind_cols(buffer_dissolve, names(buffer_names))

# Initialize counters for iteration
counter_area <- 1
counter_raster <- 1

# Initialize an empty data frame for storing metrics
metrics_table <- data.frame()

# Main loop: process each buffer area
while (counter_area <= nrow(buffer_dissolve)) { 
  
  # Extract the current buffer area and transform to spatial object
  current_buffer <- buffer_dissolve[[counter_area, 1]]
  current_buffer <- sf:::as_Spatial(current_buffer)
  current_buffer <- spTransform(current_buffer, crs_wgs)
  
  # Extract the year from the buffer name (adjust pattern as needed)
  year <- gsub("[a-zA-Z_]", "", buffer_dissolve[counter_area, 2])
  year <- as.integer(year)
  
  # Check if the year matches the raster file
  if (year == str_remove(names(raster_stack[[counter_raster]]), 'classification_')) {
    
    # Get the raster corresponding to the current buffer
    current_raster <- raster_stack[[counter_raster]]
    
    # Crop and mask the raster to the buffer area
    clipped_area <- mask(crop(current_raster, current_buffer), current_buffer)
    clipped_area <- projectRaster(clipped_area, crs = crs_albers, method = 'ngb')
    
    # Function for reclassifying raster values (adjust values to your specific classes)
    reclassify_raster <- function(area) {
      # Forest
      area[area %in% c(3, 4, 5, 6, 49)] <- 1
      
      # Non-forest natural formations
      area[area %in% c(11, 12, 32, 29, 50, 13)] <- 10
      
      # Agricultural land
      area[area %in% c(15, 18, 19, 39, 20, 40, 62, 41, 36, 46, 47, 35, 48, 9, 21)] <- 14
      
      # Non-vegetated areas
      area[area %in% c(23, 24, 30, 25)] <- 22
      
      # Water bodies
      area[area %in% c(33, 31)] <- 26
      
      # NA values
      area[area %in% c(0)] <- NA
      
      return(area)
    }
    
    # Apply reclassification to the raster area
    reclassified_area <- reclassify_raster(clipped_area)
    
    # Calculate landscape metrics (replace with the relevant metrics for your analysis)
    metric_edge_density <- lsm_c_ed(reclassified_area, count_boundary = FALSE, directions = 8)
    metric_patch_density <- lsm_c_pd(reclassified_area, directions = 8)
    metric_nearest_neighbor <- lsm_c_enn_cv(reclassified_area, directions = 8, verbose = TRUE)
    metric_like_adjacencies <- lsm_c_pladj(reclassified_area)
    metric_splitting_index <- lsm_c_split(reclassified_area, directions = 8)
    metric_mesh_size <- lsm_c_mesh(reclassified_area, directions = 8)
    metric_fractal_variation <- lsm_c_frac_cv(reclassified_area, directions = 8)
    
    # Combine metrics into a single data frame
    metrics_df <- data.frame(
      metric_edge_density$class, 
      metric_edge_density$value, 
      metric_patch_density$value, 
      metric_nearest_neighbor$value,
      metric_like_adjacencies$value,
      metric_splitting_index$value,
      metric_mesh_size$value,
      metric_fractal_variation$value
    )
    
    # Rename columns
    colnames(metrics_df) <- c('class', 'edge_density', 'patch_density', 'euclidean_nearest_neighbor', 
                              'like_adjacencies', 'splitting_index', 'mesh_size', 'fractal_variation')
    
    # Append metrics to the overall table
    metrics_table <- rbind(metrics_table, data.frame("Area" = buffer_dissolve[counter_area, 2], metrics_df))
    
    # Reset raster counter and move to the next area
    counter_area <- counter_area + 1
    counter_raster <- 1
    
  } else {
    # Move to the next raster if the years don't match
    counter_raster <- counter_raster + 1
  }
  
  print(counter_area)  # Print progress
}

# Save metrics to a CSV file
output_path <- paste0(dir, 'metrics_', radius, 'km.csv')
write.table(metrics_table, output_path, sep = ';', dec = '.', row.names = FALSE, fileEncoding = 'UTF-8')

