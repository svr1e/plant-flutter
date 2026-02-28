from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
import motor.motor_asyncio
import asyncio

class User(BaseModel):
    username: str
    email: EmailStr
    full_name: Optional[str] = None
    disabled: Optional[bool] = None

import bson

user_in_db = {
    "username": "testuser",
    "email": "test@example.com",
    "full_name": None,
    "hashed_password": "hashed_password",
    "disabled": False,
    "created_at": datetime.utcnow(),
    "_id": bson.ObjectId()
}

try:
    print(User(**user_in_db))
except Exception as e:
    print("ERROR:", e)
