#!/bin/bash

clean () {
        echo_info "Remove application artifacts"
        rm -rf vendor app/assets
        rm -rf public/assets
        echo_ok "Remove application artifacts"
}

build_app () {
        echo_info "Build dependency"
        export $(grep -v '^#' .env | xargs -d '\n')
        bundle config build.nokogiri --use-system-libraries
        bundle install --clean --without development --path vendor/bundle
        echo_ok "Build dependency"
        echo_info "Build assets"
        bundle exec rake assets:precompile
        echo_ok "Build assets"
}

deploy_app () {
        echo_info "Sync app with target host"
        timestamp=`date +%s`
        export $(grep -v '^#' .env | xargs -d '\n')
        ssh $HOST "mkdir -p /srv/www/xpaste/releases/$timestamp;"
        rsync -aH --no-perms --no-owner --no-group --omit-dir-times ./ $HOST:/srv/www/xpaste/releases/$timestamp
        echo_info "Install dependency"
        ssh $HOST "cd /srv/www/xpaste/releases/$timestamp;\
                  bundle config --local build.pg --with-pg="/usr/pgsql-9.6"; \
                  bundle install --clean --without development --path vendor/bundle --quiet; \
                  export $(grep -v '^#' .env | xargs -d '\n'); bundle exec rake assets:precompile;"
        ssh $HOST "ln -nfs /srv/www/xpaste/releases/$timestamp /srv/www/xpaste/current"
        echo_info "Sync app with target host"
        ssh $HOST "cd /srv/www/xpaste/releases/$timestamp; export $(grep -v '^#' .env | xargs -d '\n'); bundle exec rake db:migrate;"
        ssh $HOST "systemctl restart xpaste"
}

rollback_app () {
        echo_info "Rollback application"
        export $(grep -v '^#' .env | xargs -d '\n') &&\
                ssh $HOST "ln -nfs $(ls -trd /srv/www/xpaste/releases/*| tail -2| head -1) /srv/www/xpaste/current; \
                rm -rf $(ls -trd /srv/www/xpaste/releases/*| tail -1);"
        echo_ok "Rollback application"

}
echo_err()      { tput bold; tput setaf 7; echo "* ERROR: $*" ; tput sgr0; }
echo_fatal()    { tput bold; tput setaf 1; echo "* FATAL: $*" ; tput sgr0; }
echo_warn()     { tput bold; tput setaf 3; echo "* WARNING: $*" ; tput sgr0; }
echo_info()     { tput bold; tput setaf 6; echo "* INFO: $*" ; tput sgr0; }
echo_ok()       { tput bold; tput setaf 2; echo "* OK" ; tput sgr0; }

main() {
        case $action in
                "--build")
                        build_app
                        ;;
                "--deploy")
                        deploy_app
                        ;;
                "--clean")
                        clean
                        ;;
                "--rollback")
                        rollback_app
                        ;;
                "--help")
                        echo "--clear - Сlear build artifacts"
                        echo "--build - Build application local"
                        echo "--deploy - Deploy application on remote server"
                        echo "--rollback - Rollback last deploy of application"
                        ;;
                "Quit")
                        break
                        ;;
                *) echo "invalid option $REPLY";;
        esac
}

action=$1
main 
