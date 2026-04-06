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
    print('Already initiated');
  } catch(e) {
    rs.initiate({ _id: 'rs0', members: [{ _id: 0, host: 'localhost:27017' }] });
    print('Replica set initiated');
  }
"

echo "Creating admin user..."
mongosh --eval "
  use admin
  db.createUser({
    user: 'mongo',
    pwd: 'yourpassword',
    roles: [{ role: 'root', db: 'admin' }]
  })
" || echo "User already exists"

wait
