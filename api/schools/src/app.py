import os
import json
import tempfile
import boto3
from flask import Flask, request, jsonify
import geopandas as gpd
from shapely.geometry import Point
from rtree import index

app = Flask(__name__)

# Environment variables
S3_BUCKET = os.getenv("S3_BUCKET")
S3_KEY = os.getenv("S3_KEY")

if not S3_BUCKET or not S3_KEY:
    raise ValueError("Environment variables S3_BUCKET and S3_KEY must be set")

# Global GeoDataFrame variable and spatial index
gdf = None
spatial_idx = None

# Load geospatial data and spatial index at startup
def load_data():
    global gdf, spatial_idx
    print("Loading geospatial data and spatial index...")

    s3 = boto3.client("s3")
    
    # Create a temporary file to store the Parquet file
    with tempfile.NamedTemporaryFile(suffix=".parquet", delete=False) as temp_file:
        s3.download_fileobj(S3_BUCKET, S3_KEY, temp_file)
        temp_file.flush()  # Ensure data is written
        
        # Load the Parquet file using GeoPandas from the temporary file
        gdf = gpd.read_parquet(temp_file.name)
    
    # Load spatial index files from S3 (idx and dat)
    spatial_index_path = "/tmp/spatial_index"
    
    idx_file_path = f"{spatial_index_path}.idx"
    dat_file_path = f"{spatial_index_path}.dat"

    # Download index files from S3
    s3.download_file(S3_BUCKET, "spatial_index.idx", idx_file_path)
    s3.download_file(S3_BUCKET, "spatial_index.dat", dat_file_path)

    # Load the spatial index from the downloaded files
    spatial_idx = index.Index(spatial_index_path)
    
    print("Data and spatial index loaded successfully")

# Load the geospatial data at startup
load_data()

# Query the district
def query_district(lat, lng):
    point = Point(lng, lat)

    # Get bounding box of the point (for spatial indexing)
    point_bounds = point.bounds

    # Get candidate geometries that intersect with the bounding box of the point
    potential_matches = list(spatial_idx.intersection(point_bounds))

    # Further filter the geometries that actually contain the point
    for idx in potential_matches:
        if gdf.geometry[idx].contains(point):
            # Convert geometry to GeoJSON-like format
            district = gdf.iloc[idx].to_dict()

            # Remove the geometry key
            district.pop('geometry', None)

            # Print the district dictionary after removal
            print("District data after removing geometry:")
            print(json.dumps(district, indent=4))  # Pretty-print the dictionary

            return district  # Return the matching district
    
    return {"error": "No matching district found"}

# Inference endpoint
@app.route("/invocations", methods=["POST"])
def invocations():
    try:
        data = request.json
        lat = float(data["lat"])
        lng = float(data["lng"])
        result = query_district(lat, lng)
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Health check endpoint
@app.route("/ping", methods=["GET"])
def ping():
    return jsonify({"status": "healthy"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
