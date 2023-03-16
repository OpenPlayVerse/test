#!/bin/bash

./java-8-openjdk/jre/bin/java -server -Xmx4G -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSIncrementalPacing -XX:MaxPermSize=256M -XX:+AggressiveOpts -jar forge-1.12.2-14.23.5.2860.jar nogui