import pyodbc
import json
import os
from datetime import datetime

# 🔧 แก้ค่าตาม DB ของคุณ
server = "10.88.88.200"           # เช่น "localhost\\SQLEXPRESS"
username = "sa"
password = "P@5sw0rd@ADI"
databases_list_file = "databases_list.json"
schema_folder = "schema"

def get_database_schema(server, database_name, username, password):
    """
    Get schema information for a specific database
    
    Args:
        server: SQL Server address
        database_name: Name of the database
        username: SQL Server username
        password: SQL Server password
    
    Returns:
        dict: Dictionary containing schema information
    """
    try:
        # Connect to the specific database
        conn_str = f"DRIVER={{SQL Server}};SERVER={server};DATABASE={database_name};UID={username};PWD={password}"
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        
        # Get schema information
        cursor.execute("""
            SELECT 
                TABLE_SCHEMA,
                TABLE_NAME, 
                COLUMN_NAME, 
                DATA_TYPE,
                CHARACTER_MAXIMUM_LENGTH,
                NUMERIC_PRECISION,
                NUMERIC_SCALE,
                IS_NULLABLE,
                COLUMN_DEFAULT,
                ORDINAL_POSITION
            FROM INFORMATION_SCHEMA.COLUMNS
            ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION;
        """)
        
        # Convert to Dictionary structure
        schema: dict = {}
        for row in cursor.fetchall():
            table_schema = row[0]
            table_name = row[1]
            column_name = row[2]
            data_type = row[3]
            char_max_length = row[4]
            numeric_precision = row[5]
            numeric_scale = row[6]
            is_nullable = row[7]
            column_default = row[8]
            ordinal_position = row[9]
            
            # Create full table name with schema
            full_table_name = f"{table_schema}.{table_name}" if table_schema else table_name
            
            if full_table_name not in schema:
                schema[full_table_name] = {
                    "schema": table_schema,
                    "table_name": table_name,
                    "columns": []
                }
            
            # Build column information
            column_info = {
                "column_name": column_name,
                "data_type": data_type,
                "ordinal_position": ordinal_position,
                "is_nullable": is_nullable,
                "column_default": column_default
            }
            
            # Add type-specific information
            if char_max_length is not None:
                column_info["max_length"] = char_max_length
            if numeric_precision is not None:
                column_info["precision"] = numeric_precision
            if numeric_scale is not None:
                column_info["scale"] = numeric_scale
            
            schema[full_table_name]["columns"].append(column_info)
        
        cursor.close()
        conn.close()
        
        return schema
        
    except Exception as e:
        print(f"❌ Error getting schema for {database_name}: {str(e)}")
        return None

def generate_all_schemas(databases_list_file, server, username, password, schema_folder="schema"):
    """
    Generate schema JSON files for all databases from databases_list.json
    
    Args:
        databases_list_file: Path to databases_list.json file
        server: SQL Server address
        username: SQL Server username
        password: SQL Server password
        schema_folder: Folder to save schema files
    """
    try:
        # Read databases list
        if not os.path.exists(databases_list_file):
            print(f"❌ File not found: {databases_list_file}")
            return
        
        with open(databases_list_file, "r", encoding="utf-8") as f:
            databases_data = json.load(f)
        
        # Create schema folder if it doesn't exist
        if not os.path.exists(schema_folder):
            os.makedirs(schema_folder)
            print(f"📁 Created folder: {schema_folder}")
        
        databases = databases_data.get("databases", [])
        total_databases = len(databases)
        success_count = 0
        error_count = 0
        
        print(f"📊 Found {total_databases} databases to process...")
        print("-" * 60)
        
        # Process each database
        for idx, db_info in enumerate(databases, 1):
            database_name = db_info.get("database_name")
            db_state = db_info.get("state", "UNKNOWN")
            
            print(f"[{idx}/{total_databases}] Processing: {database_name} ({db_state})", end=" ... ")
            
            # Skip offline databases
            if db_state != "ONLINE":
                print(f"⏭️  Skipped (Database is {db_state})")
                continue
            
            # Get schema for this database
            schema = get_database_schema(server, database_name, username, password)
            
            if schema is None:
                error_count += 1
                print(f"❌ Failed")
                continue
            
            # Create output filename
            output_filename = f"Schema_{database_name}.json"
            output_path = os.path.join(schema_folder, output_filename)
            
            # Prepare schema data with metadata
            schema_data = {
                "database_name": database_name,
                "server": server,
                "export_date": datetime.now().isoformat(),
                "total_tables": len(schema),
                "schema": schema
            }
            
            # Save to JSON file
            with open(output_path, "w", encoding="utf-8") as f:
                json.dump(schema_data, f, indent=4, ensure_ascii=False)
            
            success_count += 1
            print(f"✅ Done ({len(schema)} tables)")
        
        print("-" * 60)
        print(f"✅ Successfully exported: {success_count} databases")
        if error_count > 0:
            print(f"❌ Failed: {error_count} databases")
        print(f"📁 Schema files saved to: {schema_folder}/")
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")

if __name__ == "__main__":
    print("🚀 Starting schema generation for all databases...")
    print("=" * 60)
    generate_all_schemas(databases_list_file, server, username, password, schema_folder)
    print("=" * 60)
    print("✨ Process completed!")

