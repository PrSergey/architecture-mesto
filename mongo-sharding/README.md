# pymongo-api

## Как запустить

Запускаем mongodb и приложение

```shell
docker compose up -d
```

## Настройка шардирования

Подключение к серверу конфигурации и его инициализация:

```shell
docker exec -it configSrv mongosh --port 27017 <<EOF
rs.initiate(
    {
        _id : "config_server",
          configsvr: true,
        members: [
          { _id : 0, host : "configSrv:27017" }
        ]
    }
);
exit();
EOF
```
Инициализация шардов:
```shell
# Для shard1
docker exec -it shard1 mongosh --port 27018 <<EOF
rs.initiate(
    {
        _id : "shard1",
        members: [
         { _id : 0, host : "shard1:27018" }
        ]
    }
);
exit();
EOF

# Для shard2
docker exec -it shard2 mongosh --port 27019 <<EOF
rs.initiate(
    {
        _id : "shard2",
        members: [
          { _id : 1, host : "shard2:27019" }
        ]
    }
);
exit();
EOF
```

Инцициализируйте роутер и наполните его тестовыми данными
```shell
docker exec -it mongos_router mongosh --port 27020 <<EOF
sh.addShard( "shard1/shard1:27018");
sh.addShard( "shard2/shard2:27019");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );

use somedb;

for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i});

db.helloDoc.countDocuments();
exit();
EOF
```
