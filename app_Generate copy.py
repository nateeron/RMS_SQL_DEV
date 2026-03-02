import pyodbc
import json
from datetime import datetime

# 🔧 แก้ค่าตาม DB ของคุณ
server = "10.88.88.200"           # เช่น "localhost\\SQLEXPRESS"
database = "ADI_Human"
username = "sa"
password = "P@5sw0rd@ADI"

def get_all_databases(server, username, password, output_file="databases_list.json", include_system=False):
    """
    Get list of all databases from SQL Server and save to JSON file
    
    Args:
        server: SQL Server address
        username: SQL Server username
        password: SQL Server password
        output_file: Output JSON file name
        include_system: If True, include system databases (master, tempdb, model, msdb)
    
    Returns:
        dict: Dictionary containing database information
    """
    try:
        # Connect to master database to query all databases
        conn_str = f"DRIVER={{SQL Server}};SERVER={server};DATABASE=master;UID={username};PWD={password}"
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        
        # Query all databases with details
        query = """
            SELECT 
                name AS database_name,
                database_id,
                create_date,
                collation_name,
                compatibility_level,
                state_desc,
                recovery_model_desc,
                user_access_desc
            FROM sys.databases
        """
        
        if not include_system:
            query += " WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb')"
        
        query += " ORDER BY name;"
        
        cursor.execute(query)
        
        # Fetch all results
        databases = []
        for row in cursor.fetchall():
            db_info = {
                "database_name": row[0],
                "database_id": row[1],
                "create_date": row[2].isoformat() if row[2] else None,
                "collation_name": row[3],
                "compatibility_level": row[4],
                "state": row[5],
                "recovery_model": row[6],
                "user_access": row[7]
            }
            databases.append(db_info)
        
        # Create result dictionary
        result = {
            "server": server,
            "export_date": datetime.now().isoformat(),
            "total_databases": len(databases),
            "databases": databases
        }
        
        # Save to JSON file
        with open(output_file, "w", encoding="utf-8") as f:
            json.dump(result, f, indent=4, ensure_ascii=False)
        
        cursor.close()
        conn.close()
        
        print(f"✅ Exported {len(databases)} databases to {output_file}")
        return result
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return None

# Execute function to get all databases
databases_list = get_all_databases(server, username, password)

# ดึงข้อมูล Schema (existing functionality)
conn_str = f"DRIVER={{SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password}"
conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

# ดึงข้อมูล Schema
cursor.execute("""
    SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS
    ORDER BY TABLE_NAME, ORDINAL_POSITION;
""")

# แปลงเป็น Dictionary
schema: dict = {}
for table_name, column_name, data_type in cursor.fetchall():
    if table_name not in schema:
        schema[table_name] = {"columns": []}
    schema[table_name]["columns"].append(f"{column_name}:{data_type}")

# บันทึกเป็น JSON
output_file = "db_schema.json"
with open(output_file, "w", encoding="utf-8") as f:
    json.dump(schema, f, indent=4)

print(f"✅ Exported schema to {output_file}")

cursor.close()
conn.close()
