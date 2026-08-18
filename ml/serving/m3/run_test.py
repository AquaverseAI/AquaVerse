import os
import sys
import json
import asyncio

# Ensure project root and module directory are in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..')))
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from fastapi.testclient import TestClient
from serve_m3 import app, lifespan

def run_test():
    print("--- Initializing M3 Serving Endpoint Test ---")
    with TestClient(app) as client:
        # Load request payload from example_request.json
        req_path = os.path.join(os.path.dirname(__file__), 'example_request.json')
        with open(req_path, 'r') as f:
            payload = json.load(f)
        
        print("\nSending POST request to /v1/reason/m3 with payload:")
        print(json.dumps(payload, indent=2))
        
        response = client.post("/v1/reason/m3", json=payload)
        
        print(f"\nResponse Status Code: {response.status_code}")
        print("Response Body:")
        try:
            print(json.dumps(response.json(), indent=2))
        except Exception:
            print(response.text)

if __name__ == '__main__':
    run_test()
