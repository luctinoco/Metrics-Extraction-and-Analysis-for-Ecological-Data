
# Landscape Metrics Extraction Script

This R script performs the extraction and calculation of landscape metrics for spatial areas using a stack of raster files and a set of geographic points provided in an Excel table. It buffers the points, processes the rasters within the buffered areas, reclassifies the land cover classes, and calculates various landscape metrics.

## Prerequisites

Before running the script, ensure you have the following R packages installed:

- `raster`
- `landscapemetrics`
- `rgdal`
- `sf`
- `sp`
- `rgeos`
- `stringr`
- `readxl`
- `dplyr`
- `stringi`

You can install any missing packages using the following command in R:

```r
install.packages(c("raster", "landscapemetrics", "rgdal", "sf", "sp", "rgeos", "stringr", "readxl", "dplyr", "stringi"))
```

## Script Functionality

The script performs the following tasks:

1. **Load Raster and Spatial Data**: It reads all `.tif` raster files from the specified directory and an Excel table containing geographic points (with latitude and longitude).

2. **Coordinate Reference Systems (CRS)**: Defines two CRS systems:
   - WGS 84 (`EPSG:4326`)
   - Albers Equal Area (`proj=aea`).

3. **Buffer Creation**: Buffers are created around the input points with a specified radius (10 km by default).

4. **Raster Processing**: For each buffer area, the script:
   - Crops and masks the corresponding raster to the buffer.
   - Reclassifies the raster values into specific land use categories (forest, non-forest natural formations, agricultural land, non-vegetated areas, and water bodies).

5. **Landscape Metrics Calculation**: The script calculates several landscape metrics for the reclassified rasters within each buffer area:
   - Edge Density
   - Patch Density
   - Euclidean Nearest Neighbor
   - Like Adjacencies
   - Splitting Index
   - Effective Mesh Size
   - Fractal Dimension Variation

6. **Results Output**: The calculated metrics are stored in a CSV file named according to the buffer radius (e.g., `metrics_10000km.csv`), which is saved in the working directory.

## Configuration

Update the following variables at the beginning of the script to match your project setup:
- `dir`: Set to the path of your working directory where your files are located.
- `table_name`: Name of the Excel file containing the geographic points.
- `raster_dir`: Path to the directory containing the raster files.

## Example

To run the script:

1. Set the working directory and file names in the script.
2. Run the R script, and it will generate the buffer areas, process the rasters, calculate landscape metrics, and export the results as a CSV file.

## License

This script is provided "as is" without warranty of any kind.
