#!/bin/bash
set -x
for i in `seq 1 60`;
do
  if timeout 1 bash -c 'cat < /dev/null > /dev/tcp/192.168.0.100/5432'; then
    sleep 5
    cd /home/username/xpaste
    source /etc/profile.d/rvm.sh
    set -o nounset
    bundle config build.nokogiri --use-system-libraries
    bundle install --clean --without development --path vendor/bundle
    bundle exec rake assets:precompile
    bundle exec rake tmp:cache:clear
    source /home/username/xpaste/.env
    bundle exec rake db:migrate
    exit 0
  fi
  sleep 1
done
exit 1
