import requests
import sys

# Usage: python verify_regionalism.py [BASE_URL] [TOKEN]
BASE_URL = "http://localhost:8000" if len(sys.argv) < 2 else sys.argv[1]
TOKEN = "" if len(sys.argv) < 3 else sys.argv[2]

def test_zones(country_code=None):
    headers = {}
    if TOKEN:
        headers["Authorization"] = f"Bearer {TOKEN}"
    if country_code:
        headers["X-Country-Code"] = country_code
    
    url = f"{BASE_URL}/api/v1/parking/zones/" # Check v1 first, then v2
    if "api/v2" in BASE_URL:
        url = f"{BASE_URL}/parking/zones/"
    
    try:
        response = requests.get(url, headers=headers)
        print(f"\n--- Testing with X-Country-Code: {country_code} ---")
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            zones = data.get('results', data) 
            if isinstance(zones, list):
                print(f"Count: {len(zones)}")
                for z in zones[:3]:
                    name = z.get('name') if isinstance(z, dict) else z
                    print(f"- {name}")
            else:
                print(f"Response: {zones}")
        else:
            print(f"Error: {response.text}")
    except Exception as e:
        print(f"Request failed: {e}")

if __name__ == "__main__":
    print(f"Targeting: {BASE_URL}")
    test_zones(None)
    test_zones("UG")
    test_zones("KE")
