from typing import Protocol

# Define an interface (Protocol) for a service
class DatabaseService(Protocol):
    def connect(self) -> str:
        pass

# Implement concrete services
class MySQLDatabaseService:
    def connect(self) -> str:
        return "Connected to MySQL"

class PostgreSQLDatabaseService:
    def connect(self) -> str:
        return "Connected to PostgreSQL"

# Dependency injection via constructor
class DataProcessor:
    def __init__(self, database_service: DatabaseService):
        self.database_service = database_service

    def process_data(self):
        connection_status = self.database_service.connect()
        print(f"Processing data with {connection_status}")

# Example Usage
mysql_service = MySQLDatabaseService()
postgres_service = PostgreSQLDatabaseService()

# Inject MySQL dependency
processor1 = DataProcessor(mysql_service)
processor1.process_data()  # Output: Processing data with Connected to MySQL

# Inject PostgreSQL dependency
processor2 = DataProcessor(postgres_service)
processor2.process_data()  # Output: Processing data with Connected to PostgreSQL
