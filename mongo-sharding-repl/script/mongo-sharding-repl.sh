echo "Инициализация кластера MongoDB начата"

echo "Инициализация конфигцрации"
docker compose exec -T  configSrv1 mongosh --port 27017  --quiet <<EOF
rs.initiate({
  _id: "configReplSet",
  configsvr: true,
  members: [
    { _id: 0, host: "configSrv1:27017" },
    { _id: 1, host: "configSrv2:27018" },
    { _id: 2, host: "configSrv3:27019" }
  ]
});
EOF

sleep 5

echo "Инициализация шарда 1"
docker compose exec -T  shard1-master mongosh --port 27021  --quiet <<EOF
rs.initiate({
  _id: "shard1",
  members: [
    { _id: 0, host: "shard1-master:27021" },
    { _id: 1, host: "shard1-replica1:27022" },
    { _id: 2, host: "shard1-replica2:27023" },
    { _id: 3, host: "shard1-replica3:27024" }
  ]
});
EOF

echo "Инициализация шарда 2"
docker compose exec -T  shard2-master mongosh --port 27025  --quiet <<EOF
rs.initiate({
  _id: "shard2",
  members: [
    { _id: 0, host: "shard2-master:27025" },
        { _id: 1, host: "shard2-replica1:27026" },
        { _id: 2, host: "shard2-replica2:27027" },
        { _id: 3, host: "shard2-replica3:27028" }
  ]
});
EOF

sleep 10

echo "Наполнение БД"
docker compose exec -T mongos_router mongosh --port 27020  --quiet <<EOF
sh.addShard("shard1/shard1-master:27021,shard1-replica1:27022,shard1-replica2:27023,shard1-replica3:27024");
sh.addShard("shard2/shard2-master:27025,shard2-replica1:27026,shard2-replica2:27027,shard2-replica3:27028");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" });

use somedb
for (var i = 0; i < 1000; i++) {
  db.helloDoc.insert({ age: i, name: "ly" + i });
}
EOF

echo "Все иницициализации и настройки завершены"