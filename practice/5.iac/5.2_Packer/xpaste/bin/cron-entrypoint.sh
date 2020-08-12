#!/bin/sh

bundle exec whenever --update-crontab x --set environment=production --roles=web,app,db && \
printenv >> /etc/environment && \
crond -f

