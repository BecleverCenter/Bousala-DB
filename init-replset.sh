#!/bin/bash

DATA_DIR=/data/db
FLAG="$DATA_DIR/.initialized"
KEYFILE="/data/db/keyfile"

# Generate keyfile once
if [ ! -f "$KEYFILE" ]; then
  openssl rand -base64 756 > "$KEYFILE"
  chmod 400 "$KEYFILE"
fi

if [ ! -f "$FLAG" ]; then
  echo "First run — starting without auth to initialize..."
  mongod --ipv6 --bind_ip ::,0.0.0.0 --replSet rs0 &

  until mongosh --eval "db.adminCommand('ping')" --quiet; do
    sleep 2
  done

  mongosh --eval "
    rs.initiate({ _id: 'rs0', members: [{ _id: 0, host: 'localhost:27017' }] });
  "

  sleep 3

  mongosh --eval "
    db = db.getSiblingDB('admin');
    db.createUser({
      user: '$MONGO_INITDB_ROOT_USERNAME',
      pwd: '$MONGO_INITDB_ROOT_PASSWORD',
      roles: [{ role: 'root', db: 'admin' }]
    });
  "

  touch "$FLAG"
  kill $(pgrep mongod)
  sleep 3
fi

echo "Starting MongoDB with auth and keyfile..."
exec mongod --ipv6 --bind_ip ::,0.0.0.0 --replSet rs0 --auth --keyFile "$KEYFILE"
