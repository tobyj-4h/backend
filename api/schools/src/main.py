from shapely.geometry import shape
import geopandas as gpd
from rtree import index

def convert_shapefile_to_geoparquet(shapefile_path, output_file_path):
    # Load the shapefile
    gdf = gpd.read_file(shapefile_path)

    # Save to GeoParquet
    gdf.to_parquet(output_file_path, compression="snappy")
    print(f"GeoParquet file created: {output_file_path}")

def build_geoparquet_index(geoparquet_file_path, spatial_index_path):
    # Load GeoParquet file
    gdf = gpd.read_parquet(geoparquet_file_path)

    # Create a persistent R-tree index
    spatial_index = index.Index(spatial_index_path)

    # Populate the index
    for idx, geometry in enumerate(gdf.geometry):
        spatial_index.insert(idx, geometry.bounds)

    print(f"Spatial index created: {spatial_index_path}.dat")   


shapefile_path = "../data/sources/EDGE_SCHOOLDISTRICT_TL_23_SY2223.shp"
parquetfile_path = "../data/output/school_districts.parquet"
spatial_index_path = "../data/output/spatial_index"

convert_shapefile_to_geoparquet(shapefile_path, parquetfile_path)
build_geoparquet_index(parquetfile_path, spatial_index_path)