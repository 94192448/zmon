#!/bin/bash

export PGHOST=localhost
export PGUSER=postgres
export PGPASSWORD=postgres
export PGDATABASE=local_zmon_db

if [ "b$1" = "b" ] || [ "b$1" = "beventlog-service" ] ; then
    docker rm zmon-eventlog-service
    docker run --name zmon-eventlog-service --net host -e POSTGRESQL_USER=$PGUSER -e POSTGRESQL_PASSWORD=$PGPASSWORD -d zmon-eventlog-service

    until curl http://localhost:8081/\?key=alertId\&value=3\&types=212993 &> /dev/null; do
        echo 'Waiting for eventlog service'
        sleep 3
    done
fi

if [ "b$1" = "b" ] || [ "b$1" = "bcontroller" ] ; then

    lroot=/home/vagrant/zmon-controller
    snap=$lroot/target/zmon-controller-1.0.1-SNAPSHOT
    lwebapp=$lroot/src/main/webapp
    croot=/usr/local/tomcat
    cwebapp=$croot/webapps/ROOT

    docker rm zmon-controller
    docker run --name zmon-controller --net host -d \
        -v $snap:$cwebapp \
        -v $lwebapp/asset/:$cwebapp/asset/ \
        -v $lwebapp/js/:$cwebapp/js/ \
        -v $lwebapp/lib/:$cwebapp/lib/ \
        -v $lwebapp/styles/:$cwebapp/styles/ \
        -v $lwebapp/templates/:$cwebapp/templates/ \
        -v $lwebapp/views/:$cwebapp/views/ \
        zmon-controller

    until curl http://localhost:8080/index.jsp &> /dev/null; do
        echo 'Waiting for ZMON Controller..'
        sleep 3
    done
fi

for comp in scheduler worker data-service; do
    if [ "b$1" = "b" ] || [ "b$1" = "b$comp" ] ; then
        docker rm zmon-$comp
        docker run --name zmon-$comp --net host -d zmon-$comp
    fi
done
