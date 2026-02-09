#!/usr/bin/env python3
import subprocess
import sys

def run_command(cmd, description):
    """Run a command and print the output"""
    print(f"\n{description}")
    print("=" * 60)
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=10
        )
        print(f"Exit code: {result.returncode}")
        if result.stdout:
            print(f"Output:\n{result.stdout}")
        if result.stderr:
            print(f"Errors:\n{result.stderr}")
        return result.returncode == 0
    except subprocess.TimeoutExpired:
        print("Command timed out")
        return False
    except Exception as e:
        print(f"Error: {e}")
        return False

def main():
    print("=" * 60)
    print("Docker Services Connectivity Test")
    print("=" * 60)
    
    tests = [
        ("docker ps --filter 'name=dastern' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'", 
         "1. Checking running containers"),
        
        ("docker exec dastern-postgres pg_isready -U dastern_user -d dastern",
         "2. Testing PostgreSQL connectivity"),
        
        ("docker exec dastern-postgres psql -U dastern_user -d dastern -c 'SELECT current_database(), current_user;'",
         "3. Testing PostgreSQL query"),
        
        ("docker exec dastern-postgres psql -U dastern_user -d dastern -c 'SHOW timezone;'",
         "4. Checking PostgreSQL timezone"),
        
        ("docker exec dastern-redis redis-cli -a dastern_redis_password ping",
         "5. Testing Redis connectivity"),
        
        ("docker exec dastern-redis redis-cli -a dastern_redis_password --no-auth-warning SET test_key 'test_value'",
         "6. Testing Redis SET operation"),
        
        ("docker exec dastern-redis redis-cli -a dastern_redis_password --no-auth-warning GET test_key",
         "7. Testing Redis GET operation"),
        
        ("docker inspect dastern-postgres --format '{{.State.Health.Status}}'",
         "8. Checking PostgreSQL health status"),
        
        ("docker inspect dastern-redis --format '{{.State.Health.Status}}'",
         "9. Checking Redis health status"),
    ]
    
    passed = 0
    failed = 0
    
    for cmd, desc in tests:
        if run_command(cmd, desc):
            passed += 1
        else:
            failed += 1
    
    print("\n" + "=" * 60)
    print(f"Test Summary: {passed} passed, {failed} failed")
    print("=" * 60)
    
    return 0 if failed == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
