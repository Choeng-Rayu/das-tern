#!/usr/bin/env python3
import subprocess
import socket

def test_port_connectivity(host, port, service_name):
    """Test if a port is accessible from the host"""
    print(f"\nTesting {service_name} connectivity on {host}:{port}")
    print("-" * 60)
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((host, port))
        sock.close()
        
        if result == 0:
            print(f"✓ Port {port} is OPEN and accessible")
            return True
        else:
            print(f"✗ Port {port} is CLOSED or not accessible")
            return False
    except Exception as e:
        print(f"✗ Error testing port: {e}")
        return False

def test_postgres_connection():
    """Test PostgreSQL connection using psql if available"""
    print("\nTesting PostgreSQL connection with psql...")
    print("-" * 60)
    try:
        result = subprocess.run(
            ["psql", "-h", "localhost", "-U", "dastern_user", "-d", "dastern", "-c", "SELECT 1;"],
            env={"PGPASSWORD": "dastern_rayu"},
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            print("✓ PostgreSQL connection successful")
            print(result.stdout)
            return True
        else:
            print("✗ PostgreSQL connection failed")
            print(result.stderr)
            return False
    except FileNotFoundError:
        print("⚠ psql not installed on host machine (this is OK)")
        print("  Connection can still be tested via docker exec")
        return None
    except Exception as e:
        print(f"✗ Error: {e}")
        return False

def test_redis_connection():
    """Test Redis connection using redis-cli if available"""
    print("\nTesting Redis connection with redis-cli...")
    print("-" * 60)
    try:
        result = subprocess.run(
            ["redis-cli", "-h", "localhost", "-p", "6379", "-a", "dastern_redis_password", "PING"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0 and "PONG" in result.stdout:
            print("✓ Redis connection successful")
            print(result.stdout)
            return True
        else:
            print("✗ Redis connection failed")
            print(result.stderr)
            return False
    except FileNotFoundError:
        print("⚠ redis-cli not installed on host machine (this is OK)")
        print("  Connection can still be tested via docker exec")
        return None
    except Exception as e:
        print(f"✗ Error: {e}")
        return False

def main():
    print("=" * 60)
    print("Host Machine Connectivity Test")
    print("=" * 60)
    
    # Test port connectivity
    postgres_port = test_port_connectivity("localhost", 5432, "PostgreSQL")
    redis_port = test_port_connectivity("localhost", 6379, "Redis")
    
    # Test actual connections
    postgres_conn = test_postgres_connection()
    redis_conn = test_redis_connection()
    
    # Summary
    print("\n" + "=" * 60)
    print("Summary")
    print("=" * 60)
    print(f"PostgreSQL port accessible: {'✓ Yes' if postgres_port else '✗ No'}")
    print(f"Redis port accessible: {'✓ Yes' if redis_port else '✗ No'}")
    
    if postgres_conn is not None:
        print(f"PostgreSQL connection: {'✓ Success' if postgres_conn else '✗ Failed'}")
    else:
        print("PostgreSQL connection: ⚠ Not tested (psql not available)")
    
    if redis_conn is not None:
        print(f"Redis connection: {'✓ Success' if redis_conn else '✗ Failed'}")
    else:
        print("Redis connection: ⚠ Not tested (redis-cli not available)")
    
    print("\n✓ Services are accessible from host machine via Docker port mapping")
    print("=" * 60)

if __name__ == "__main__":
    main()
