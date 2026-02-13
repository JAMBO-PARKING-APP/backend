import requests
import json

url = "http://127.0.0.1:8000/api/user/parking/start/"
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxODAyNDk1NTk4LCJpYXQiOjE3NzA5NTk1OTgsImp0aSI6ImJlZmE3MjBlOGExMzRjZmM5MzIxNzE1MTgxN2IxNzQ5IiwidXNlcl9pZCI6IjJhMTkxYmZlLTVjOGMtNDc2Zi1iMTIyLWFiNzI0NmNjY2UzNSJ9.zdkk6Ls2yvN70vdWYD1-CfXsgLAerRC3dHcxAVD9hGQ"

headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

scenarios = [
    ("Empty Body", {}),
    ("Missing Vehicle", {"zone_id": "1bbf69b7-266b-4fbb-96e7-25af59491b9f"}),
    ("Missing Zone", {"vehicle_id": "d31a3211-2578-4fb1-8be4-7561a2fab622"}),
    ("Invalid Vehicle UUID", {"vehicle_id": "not-a-uuid", "zone_id": "1bbf69b7-266b-4fbb-96e7-25af59491b9f"}),
    ("Vehicle not found", {"vehicle_id": "00000000-0000-0000-0000-000000000000", "zone_id": "1bbf69b7-266b-4fbb-96e7-25af59491b9f"}),
    ("Zone not found", {"vehicle_id": "d31a3211-2578-4fb1-8be4-7561a2fab622", "zone_id": "00000000-0000-0000-0000-000000000000"}),
    ("Invalid Duration", {"vehicle_id": "d31a3211-2578-4fb1-8be4-7561a2fab622", "zone_id": "1bbf69b7-266b-4fbb-96e7-25af59491b9f", "duration_hours": "invalid"}),
]

for name, data in scenarios:
    try:
        response = requests.post(url, headers=headers, json=data)
        print(f"Scenario: {name}")
        print(f"Status: {response.status_code}, Length: {len(response.content)}")
        print(f"Body: {response.text}\n")
    except Exception as e:
        print(f"Error in {name}: {e}\n")
