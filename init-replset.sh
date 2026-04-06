#!/bin/bash
mongod --ipv6 --bind_ip ::,0.0.0.0 --replSet rs0 &

echo "Waiting for MongoDB to start..."
until mongosh --eval "db.adminCommand('ping')" --quiet; do
  sleep 2
done

echo "Initiating replica set..."
mongosh --eval "
  try {
    rs.status();
  } catch(e) {
    rs.initiate({ _id: 'rs0', members: [{ _id: 0, host: 'localhost:27017' }] });
  }
"

echo "Creating admin user..."
mongosh --eval "
  db = db.getSiblingDB('admin');
  if (!db.getUser('$MONGO_INITDB_ROOT_USERNAME')) {
    db.createUser({
      user: '$MONGO_INITDB_ROOT_USERNAME',
      pwd: '$MONGO_INITDB_ROOT_PASSWORD',
      roles: [{ role: 'root', db: 'admin' }]
    });
    print('User created');
  } else {
    print('User already exists');
  }
"

# Restart with auth enabled
kill $(pgrep mongod)
sleep 2
mongod --ipv6 --bind_ip ::,0.0.0.0 --replSet rs0 --auth

wait
