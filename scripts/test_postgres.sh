#!/bin/bash

PGPASSWORD=devpass psql -h localhost -U devuser -d devdb -c "SELECT NOW();" && \
echo "PostgreSQL is working!" || echo "Failed to connect to PostgreSQL"
