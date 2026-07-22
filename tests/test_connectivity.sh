#!/bin/bash
set -euo pipefail

PASS=0
FAIL=0

test_ping() {
    local target=$1
    local expected=$2
    if ping -c 2 -W 3 "$target" &>/dev/null; then
        if [ "$expected" = "reachable" ]; then
            echo "PASS: $target is reachable"
            PASS=$((PASS + 1))
        else
            echo "FAIL: $target should be unreachable"
            FAIL=$((FAIL + 1))
        fi
    else
        if [ "$expected" = "unreachable" ]; then
            echo "PASS: $target is unreachable"
            PASS=$((PASS + 1))
        else
            echo "FAIL: $target should be reachable"
            FAIL=$((FAIL + 1))
        fi
    fi
}

test_port() {
    local host=$1
    local port=$2
    local expected=$3
    if nc -z -w 3 "$host" "$port" 2>/dev/null; then
        if [ "$expected" = "open" ]; then
            echo "PASS: $host:$port is open"
            PASS=$((PASS + 1))
        else
            echo "FAIL: $host:$port should be closed"
            FAIL=$((FAIL + 1))
        fi
    else
        if [ "$expected" = "closed" ]; then
            echo "PASS: $host:$port is closed"
            PASS=$((PASS + 1))
        else
            echo "FAIL: $host:$port should be open"
            FAIL=$((FAIL + 1))
        fi
    fi
}

test_dns() {
    local domain=$1
    local expected=$2
    local result
    result=$(nslookup "$domain" 2>/dev/null | grep -oP 'Address: \K[\d.]+' | head -1)
    if [ "$result" = "$expected" ]; then
        echo "PASS: $domain resolves to $expected"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $domain expected $expected got $result"
        FAIL=$((FAIL + 1))
    fi
}

echo "Running connectivity tests..."

test_ping "10.0.10.1" "reachable"
test_ping "10.0.20.5" "reachable"
test_ping "10.0.20.10" "reachable"
test_ping "10.0.30.1" "reachable"
test_ping "10.0.40.1" "reachable"
test_ping "10.0.50.1" "reachable"

test_port "10.0.20.5" "443" "open"
test_port "10.0.20.5" "1514" "open"
test_port "10.0.20.10" "9090" "open"
test_port "10.0.20.11" "3000" "open"
test_port "10.0.20.15" "9200" "open"

test_dns "wazuh.internal" "10.0.20.5"
test_dns "grafana.internal" "10.0.20.11"

echo "Results: $PASS passed, $FAIL failed"
exit $FAIL
