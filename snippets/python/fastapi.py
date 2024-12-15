'''
--- FAST API ---
FastAPI Example: CRUD API with Background Tasks and Error Handling
'''
from fastapi import FastAPI, HTTPException, BackgroundTasks, Query
from pydantic import BaseModel
from typing import List, Optional
import asyncio

app = FastAPI()

# In-memory database for demonstration
fake_db = {}

# Pydantic model for validation
class Item(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
    tags: List[str] = []

# Utility to simulate background processing
async def send_notification(item_id: str):
    await asyncio.sleep(3)  # Simulate delay
    print(f"Notification sent for item: {item_id}")

@app.get("/")
def read_root():
    return {"message": "Welcome to the FastAPI service!"}

@app.post("/items/{item_id}")
async def create_item(item_id: str, item: Item, background_tasks: BackgroundTasks):
    if item_id in fake_db:
        raise HTTPException(status_code=400, detail="Item already exists")
    fake_db[item_id] = item
    background_tasks.add_task(send_notification, item_id)
    return {"message": "Item created successfully", "item": item}

@app.get("/items/{item_id}", response_model=Item)
def read_item(item_id: str):
    item = fake_db.get(item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    return item

@app.put("/items/{item_id}", response_model=Item)
def update_item(item_id: str, item: Item):
    if item_id not in fake_db:
        raise HTTPException(status_code=404, detail="Item not found")
    fake_db[item_id] = item
    return item

@app.delete("/items/{item_id}")
def delete_item(item_id: str):
    if item_id not in fake_db:
        raise HTTPException(status_code=404, detail="Item not found")
    del fake_db[item_id]
    return {"message": "Item deleted successfully"}

@app.get("/items", response_model=List[Item])
def list_items(skip: int = Query(0, ge=0), limit: int = Query(10, ge=1)):
    items = list(fake_db.values())[skip : skip + limit]
    return items
