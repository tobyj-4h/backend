import json
import os
import geopandas as gpd
from rtree import index
from shapely.geometry import Point

print("In the container")

def print_files():
    print("Files in the current directory:")
    for root, dirs, files in os.walk("."):
        for filename in files:
            print(os.path.join(root, filename))

def print_file_permissions():
    print("Can read spatial_index.idx:", os.access("spatial_index.idx", os.R_OK))
    print("Can read spatial_index.dat:", os.access("spatial_index.dat", os.R_OK))

# Load GeoParquet and spatial index directly from the container image
def load_data():
    print("Loading data...")
    gdf = gpd.read_parquet("school_districts.parquet")
    print("Data loaded")
    return gdf

def load_index():
    print("Loading index...")
    try:
        idx = index.Index("spatial_index")
        print("Index loaded successfully.")
        return idx
    except OSError as e:
        print(f"Error loading index: {e}")

# Print files in this directory
print_files()
print_file_permissions()

# Load data and spatial index
gdf = load_data()
spatial_idx = load_index()

def lambda_handler(event, context):
    print('Received event: ' + json.dumps(event))

    # Parse input latitude and longitude
    lat = float(event["lat"])
    lng = float(event["lng"])
    point = Point(lng, lat)

    print(f"lat: {lat}, lng: {lng}")

    # Query the spatial index for possible matches
    matches = list(spatial_idx.intersection(point.bounds))
    for match in matches:
        if gdf.geometry[match].contains(point):
            # Found the matching district
            district_info = gdf.iloc[match].to_dict()
            return {
                "statusCode": 200,
                "body": district_info
            }

    return {
        "statusCode": 404,
        "body": "No matching district found."
    }
