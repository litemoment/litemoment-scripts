#!/bin/bash
# ***********************************************************
# * Copyright (c) 2024 litemoment.com. All rights reserved. *
# ***********************************************************
# Contact: webmaster@litemoment.com

curl -X POST https://rest.litemoment.com/events \
--user "$(tr -d '\r\n' < ~/.liteaccount.txt)" \
-H 'Content-Type: application/x-www-form-urlencoded;charset=utf-8' \
-d 'eventType=VAR&eventTS=0&devTS=0&devSN=TERMUX001&batLevel=0&evtSource=0&evtCount=0'

