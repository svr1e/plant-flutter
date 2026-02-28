from fastapi.testclient import TestClient
from main import app
import sys

client = TestClient(app)
try:
    response = client.post("/signup", json={
        "username": "testuser",
        "email": "test@example.com",
        "password": "mypassword"
    })
    print(response.status_code)
    print(response.text)
except Exception as e:
    import traceback
    traceback.print_exc()
