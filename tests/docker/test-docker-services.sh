#!/bin/bash

echo "=== Docker Services Connectivity Test ==="
echo ""

# Test 1: Check if containers are running
echo "1. Checking if containers are running..."
docker ps --filter "name=dastern-postgres" --format "{{.Names}}: {{.Status}}"
docker ps --filter "name=dastern-redis" --format "{{.Names}}: {{.Status}}"
echo ""

# Test 2: Check PostgreSQL connectivity
echo "2. Testing PostgreSQL connectivity..."
docker exec dastern-postgres pg_isready -U dastern_user -d dastern
if [ $? -eq 0 ]; then
    echo "✓ PostgreSQL is ready"
else
    echo "✗ PostgreSQL is not ready"
fi
echo ""

# Test 3: Test PostgreSQL query
echo "3. Testing PostgreSQL query..."
docker exec dastern-postgres psql -U dastern_user -d dastern -c "SELECT current_database(), current_user, version();"
echo ""

# Test 4: Check PostgreSQL timezone
echo "4. Checking PostgreSQL timezone..."
docker exec dastern-postgres psql -U dastern_user -d dastern -c "SHOW timezone;"
echo ""

# Test 5: Check Redis connectivity
echo "5. Testing Redis connectivity..."
docker exec dastern-redis redis-cli -a dastern_redis_password ping
if [ $? -eq 0 ]; then
    echo "✓ Redis is ready"
else
    echo "✗ Redis is not ready"
fi
echo ""

# Test 6: Test Redis operations
echo "6. Testing Redis operations..."
docker exec dastern-redis redis-cli -a dastern_redis_password SET test_key "test_value"
docker exec dastern-redis redis-cli -a dastern_redis_password GET test_key
docker exec dastern-redis redis-cli -a dastern_redis_password DEL test_key
echo ""

# Test 7: Check health checks
echo "7. Checking container health status..."
docker inspect dastern-postgres --format '{{.State.Health.Status}}' 2>/dev/null || echo "No health check configured"
docker inspect dastern-redis --format '{{.State.Health.Status}}' 2>/dev/null || echo "No health check configured"
echo ""

# Test 8: Test connection from host
echo "8. Testing connection from host machine..."
echo "PostgreSQL port 5432:"
nc -zv localhost 5432 2>&1 | grep -q succeeded && echo "✓ Port 5432 is accessible" || echo "✗ Port 5432 is not accessible"
echo "Redis port 6379:"
nc -zv localhost 6379 2>&1 | grep -q succeeded && echo "✓ Port 6379 is accessible" || echo "✗ Port 6379 is not accessible"
echo ""

echo "=== Test Complete ==="
