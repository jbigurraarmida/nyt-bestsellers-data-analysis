"""
Collect historical NYT Bestseller data using the
New York Times Books API and save it as a CSV/parquet file
"""

import requests
import time
import os
import pandas as pd
from datetime import datetime

# Load API key
api_key = os.getenv("NYT_API_KEY")
url = "https://api.nytimes.com/svc/books/v3/lists/overview.json"

# Dates to obtain the data from the NYT Bestseller list
date = datetime.strptime("2010-01-01", "%Y-%m-%d")
end = datetime.strptime("2026-01-01", "%Y-%m-%d")

# Initialize rows
rows = []

while date <= end:
    params = {
        "published_date": date.strftime("%Y-%m-%d"),
        "api-key": api_key
    }
    r = requests.get(url, params=params)
    
    # Check if rate limit has been met
    if r.status_code == 429:
        print("Rate limit reached, waiting...")
        time.sleep(10)
        continue
    # Check if we get an error
    if r.status_code != 200:
        print("error", r.status_code)
        break
    
    data = r.json()
    results = data.get("results")
    
    # Break if there's no data found
    if results is None:
        print("No data for: ", date)
        break
    
    # Extract list
    print("Getting data from:", results["published_date"])
    lists = results.get("lists")
    
    # If no data is found for a certain date
    # check the next published date
    if not lists:
        print("No lists for: ", results["published_date"])
        date = datetime.strptime(
            results["next_published_date"],
            "%Y-%m-%d"
        )
        continue
    
    # Extract books
    for l in lists:
        for b in l["books"]:
            # Append rows
            rows.append({
                "date": results["published_date"],
                "list_name": l["display_name"],
                "rank": b["rank"],
                "title": b["title"],
                "author": b["author"],
                "publisher": b["publisher"],
                "weeks_on_list": b["weeks_on_list"],
                "rank_last_week": b["rank_last_week"],
                "isbn13": b["primary_isbn13"]
            })
    date = datetime.strptime(
        results["next_published_date"],
        "%Y-%m-%d"
    )
        
    if date is None:
        break
    time.sleep(2)

# Create a dataframe out of all the rows of books obtained
df = pd.DataFrame(rows)

# Save a CSV and Parquet file for later analysis
df.to_csv("nyt_bestsellers_full.csv", index=False)
df.to_parquet("nyt_bestsellers_full.parquet", index=False)