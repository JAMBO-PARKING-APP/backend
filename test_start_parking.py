import requests
import json

url = "http://127.0.0.1:8000/api/user/parking/start/"
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxODAyNDk1NTk4LCJpYXQiOjE3NzA5NTk1OTgsImp0aSI6ImJlZmE3MjBlOGExMzRjZmM5MzIxNzE1MTgxN2IxNzQ5IiwidXNlcl9pZCI6IjJhMTkxYmZlLTVjOGMtNDc2Zi1iMTIyLWFiNzI0NmNjY2UzNSJ9.zdkk6Ls2yvN70vdWYD1-CfXsgLAerRC3dHcxAVD9hGQ"

headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

data = {
    "vehicle_id": "d31a3211-2578-4fb1-8be4-7561a2fab622",
    "zone_id": "1bbf69b7-266b-4fbb-96e7-25af59491b9f",
    "duration_hours": 1.0,
    "payment_method": "wallet"
}

try:
    response = requests.post(url, headers=headers, json=data)
    print(f"Status Code: {response.status_code}")
    print(f"Response Body: {response.text}")
except Exception as e:
    print(f"Error: {e}")
