#!/usr/bin/env python3
import os
import sys
import json
import requests
from dotenv import load_dotenv

load_dotenv()

def check_system_health():
    api_url = os.getenv('API_URL', 'http://localhost:4000')
    api_key = os.getenv('API_KEY')
    
    if not api_key:
        print("Error: API_KEY environment variable not set")
        sys.exit(1)
    
    headers = {'Authorization': f'Bearer {api_key}'}
    
    try:
        response = requests.get(f"{api_url}/inspect", headers=headers)
        response.raise_for_status()
        data = response.json()
        
        cpu_usage = data['system']['cpu_used_percent']
        memory_usage = data['system']['memory_used_percent']
        
        if cpu_usage > 70 or memory_usage > 70:
            print(f"WARNING: System resources usage high!")
            print(f"CPU Usage: {cpu_usage}%")
            print(f"Memory Usage: {memory_usage}%")
            sys.exit(1)
        else:
            print("System is healthy!")
            print(f"CPU Usage: {cpu_usage}%")
            print(f"Memory Usage: {memory_usage}%")
            sys.exit(0)
            
    except requests.exceptions.RequestException as e:
        print(f"Error: Failed to connect to the API: {e}")
        sys.exit(1)
    except KeyError as e:
        print(f"Error: Unexpected API response format: {e}")
        sys.exit(1)

if __name__ == "__main__":
    check_system_health() 