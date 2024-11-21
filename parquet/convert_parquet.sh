#!/bin/bash

# Define repository and file details
REPO_URL="https://github.com/italia/anpr-opendata.git"
FILE_PATH="data/popolazione_residente_export.csv"
OUTPUT_DIR="parquet_files"

# Create output directory
mkdir -p "$OUTPUT_DIR"

## Clone the repository
#TEMP_REPO_DIR=$(mktemp -d)
#git clone "$REPO_URL" "$TEMP_REPO_DIR"
#cd "$TEMP_REPO_DIR" || exit
#
# Get the history of the file
git log --format='%H %ct' -- "$FILE_PATH" > commit_history.txt

# Process each commit
while read -r commit_hash commit_timestamp; do
    if [ "${commit_hash}" == "239799e14086c715afe4f6776adc74ac97d352bd" ]; then continue; fi
    
    # Checkout the file at the specific commit
    git checkout "$commit_hash" -- "$FILE_PATH"
    

    # Define output Parquet file
    parquet_file="$OUTPUT_DIR/${commit_hash}.parquet"
    
    # Use DuckDB to convert CSV to Parquet, adding the timestamp column
    duckdb <<SQL
    COPY (
        SELECT *, $commit_timestamp AS commit_timestamp
        FROM read_csv_auto('$FILE_PATH')
    ) TO '$parquet_file' (FORMAT 'parquet');
SQL

    echo "Processed commit $commit_hash -> $parquet_file"
done < commit_history.txt

# Cleanup
rm -rf "$TEMP_REPO_DIR"

echo "All versions have been processed and saved as Parquet files in $OUTPUT_DIR."

