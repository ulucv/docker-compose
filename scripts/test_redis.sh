#!/bin/bash

redis-cli -h localhost PING | grep -q PONG && \
echo "Redis is working!" || echo "Redis is not responding"
