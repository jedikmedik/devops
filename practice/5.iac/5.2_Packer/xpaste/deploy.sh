#!/bin/bash
#
# Deploy xpaste test app
# Southbridge LLC, 2019 A.D.
#

set -o nounset
set -o errtrace
set -o pipefail

# DEFAULTS BEGIN
typeset -i DEBUG=0
typeset rvm_ruby_version=2.5.1
export rvm_ruby_version
typeset deploy_app=xpaste
typeset instance_version=2.5.0
typeset instance_user=$(whoami)
typeset deploy_secret_key_base=jkdf8xlandfkzz99alldlmernzp2mska7bghqp9akamzja7ejnq65ahjnfj
typeset deploy_cache_path=/home/${instance_user}/.cache/vendor
typeset deploy_prod_db_host=localhost4
typeset deploy_prod_db_name=xpaste
typeset deploy_prod_db_user=xpaste
typeset deploy_prod_db_password=frank9Above9Crux
typeset deploy_test_db_host=localhost4
typeset deploy_test_db_name=xpaste_test
typeset deploy_test_db_user=xpaste_test
typeset deploy_test_db_password=socket2Afield4Raft
typeset prod_env_file=/home/${instance_user}/${deploy_app}/.env
typeset test_env_file=/home/${instance_user}/${deploy_app}/.env.test
typeset build_env_file=/home/${instance_user}/${deploy_app}/.env.build
# DEFAULTS END

# CONSTANTS BEGIN
typeset PATH=/bin:/usr/bin:/sbin:/usr/sbin
readonly bn="$(basename "$0")"
readonly BIN_REQUIRED="gpg"
# CONSTANTS END

main() {
    local fn=${FUNCNAME[0]}

    trap 'except $LINENO' ERR
    trap _exit EXIT

    checks

    (( DEBUG )) && set -xv

#     if [[ ! -f /etc/yum.repos.d/pgdg-redhat-all.repo ]]; then
# 	echo_info "Install PostgreSQL repo"
# 	sudo yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
#     fi

    if [[ ! -f /etc/yum.repos.d/nodesource-el7.repo ]]; then
	echo_info "Install nodejs repo"
	curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -
    fi

    if [[ ! -f /etc/yum.repos.d/yarn.repo ]]; then
	echo_info "Install yarn repo"
	curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
    fi

    echo_info "Install packages"
    sudo yum -y install \
	postgresql-server postgresql postgresql-contrib postgresql-devel \
	nginx nodejs yarn \
	libxslt-devel libxml2-devel glibc-devel gcc-c++ libxml2-devel

    if ! id nginx | grep -q "$instance_user"
    then
	sudo usermod -aG $instance_user nginx
    fi

    if ! sudo cat /var/lib/pgsql/data/PG_VERSION
    then
	echo_info "Initialize postgresql96-server"
	sudo -iu postgres initdb -D /var/lib/pgsql/data
    fi

    sudo systemctl start postgresql.service

    local reg_pg_dumpall=""
    reg_pg_dumpall=$(sudo -iu postgres pg_dumpall -g)

    if ! echo "$reg_pg_dumpall"|grep -q "$deploy_prod_db_user"
    then
	echo_info "Create $deploy_prod_db_user and database"
	sudo -iu postgres psql -c "CREATE ROLE $deploy_prod_db_user WITH LOGIN PASSWORD '$deploy_prod_db_password'"
	sudo -iu postgres createdb -O $deploy_prod_db_user $deploy_prod_db_name
    fi

    if ! echo "$reg_pg_dumpall"|grep -q "$deploy_test_db_user"
    then
	echo_info "Create $deploy_test_db_user"
	sudo -iu postgres psql -c "CREATE ROLE $deploy_test_db_user WITH LOGIN CREATEDB PASSWORD '$deploy_test_db_password'"
    fi

    local reg_gpg_keys=""
    reg_gpg_keys=$(sudo gpg --list-keys)

    if ! echo "$reg_gpg_keys"|grep -q 'Michal Papis'
    then
	echo_info "Import first gpg key"
	curl -sSL https://rvm.io/mpapis.asc | sudo gpg --import -
    fi

    if ! echo "$reg_gpg_keys"|grep -q 'Piotr Kuczynski'
    then
	echo_info "Import second gpg key"
	sudo gpg2 --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
    fi

    if [[ ! -f /usr/local/rvm/bin/rvm ]]; then
	echo_info "Install rvm"
	curl -L get.rvm.io | sudo bash -s stable
    fi

    if [[ ! -f /usr/local/rvm/rubies/ruby-${rvm_ruby_version}/bin/ruby ]]; then
	echo_info "Install ruby"
	set +o nounset
	sudo bash -c "source /etc/profile.d/rvm.sh && rvm install ${rvm_ruby_version}"
	set -o nounset
    fi

    if [[ ! -f /etc/systemd/system/puma@.service ]]; then
	echo_info "Template instantiated puma@.service"
	cat << EOF | sudo tee /etc/systemd/system/puma@.service
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
User=%i
WorkingDirectory=/home/%i/${deploy_app}/app
# Environment=PUMA_DEBUG=1
EnvironmentFile=/home/%i/${deploy_app}/.env
ExecStart=/bin/bash -c 'source /etc/profile.d/rvm.sh && /home/%I/${deploy_app}/vendor/bundle/ruby/\${PUMA_VERSION}/bin/puma -b tcp://127.0.0.1:9292 ../config.ru'
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    fi

    if [[ ! -f "$prod_env_file" ]]; then
	echo_info "Template puma service environment file"
	mkdir -p "$(dirname "$prod_env_file")"
	cat > "$prod_env_file" << EOF
PUMA_VERSION=${instance_version}
RAILS_ENV=production
SECRET_KEY_BASE="${deploy_secret_key_base}"
DB_HOST="${deploy_prod_db_host}"
DB_NAME="${deploy_prod_db_name}"
DB_USER="${deploy_prod_db_user}"
DB_PASSWORD="${deploy_prod_db_password}"
EOF
    fi

    if [[ ! -f "$build_env_file" ]]; then
	echo_info "Template build environment file"
	cat > "$build_env_file" << EOF
export RAILS_ENV=production
export SECRET_KEY_BASE="${deploy_secret_key_base}"
export BUNDLE_CACHE_PATH="${deploy_cache_path}"
EOF
    fi

    if [[ ! -f "$test_env_file" ]]; then
	echo_info "Template test environment file"
	cat > "$test_env_file" << EOF
export RAILS_ENV=test
export SECRET_KEY_BASE="${deploy_secret_key_base}"
export DB_HOST="${deploy_test_db_host}"
export DB_NAME="${deploy_test_db_name}"
export DB_USER="${deploy_test_db_user}"
export DB_PASSWORD="${deploy_test_db_password}"
EOF
    fi


    if [[ ! -d $deploy_cache_path ]]; then
	mkdir -p "$deploy_cache_path"
    fi

    if true; then
	echo_info "Build application"
	source "$build_env_file"
	set +o nounset
	source /etc/profile.d/rvm.sh
	set -o nounset
	bundle config build.nokogiri --use-system-libraries
	bundle install --clean --without development --path vendor/bundle
	bundle exec rake assets:precompile
	bundle exec rake tmp:cache:clear
	echo_info "Test application"
	source "$test_env_file"
	bundle exec rake db:reset
	bundle exec rake db:migrate
	bundle exec rspec spec
	echo_info "Prod migration"
	source "$prod_env_file"
	bundle exec rake db:migrate
	echo_info "Puma restart"
	sudo systemctl enable puma@${instance_user}.service
	sudo systemctl restart puma@${instance_user}.service
    fi

    sudo systemctl enable nginx.service

    if ! grep -q 16384 /etc/nginx/nginx.conf
    then
	echo_info "Template nginx.conf"
	cat << EOF | sudo tee /etc/nginx/nginx.conf
# This file generated by xpaste/deploy.sh script
user			nginx;
worker_processes	auto;
error_log		/var/log/nginx/error.log;
pid			/run/nginx.pid;
worker_rlimit_nofile	65536;

events {
    worker_connections	16384;
}

http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
		      '\$status \$body_bytes_sent "\$http_referer" '
		      '"\$http_user_agent" \$upstream_addr \$upstream_response_time \$request_time \$host';

    access_log		/var/log/nginx/access.log  main;

    sendfile		on;
    tcp_nopush		on;
    tcp_nodelay		on;
    server_tokens	off;

    large_client_header_buffers		8 8k;

    keepalive_timeout			150;
    reset_timedout_connection		on;

    open_file_cache			max=1000 inactive=300s;
    open_file_cache_errors		off;
    open_file_cache_min_uses		2;
    open_file_cache_valid		300s;

    ssl_session_cache	shared:SSL:20m;
    ssl_session_timeout	180m;

    gzip		on;
    gzip_comp_level	3;
    gzip_min_length	256;
    gzip_proxied	any;
    gzip_types		text/plain text/css text/javascript text/json text/x-component text/xml
			application/javascript application/x-javascript application/json
			application/xml application/xml+rss application/atom+xml
			image/svg+xml;

    include		mime.types;
    default_type	application/octet-stream;

    server {
	listen 80 default_server;
	root /home/${instance_user}/${deploy_app}/public;

	error_page 503 /503.html;
	error_page 500 502 504 /500.html;
	client_max_body_size 2G;

	location / {
	    try_files \$uri @backend;
	}

	location @backend {
	    proxy_pass http://127.0.0.1:9292;
	    proxy_set_header Proxy "";
	    proxy_set_header Host \$host;
	    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
	    proxy_set_header X-Forwarded-Proto \$scheme;
	    proxy_redirect off;
	    proxy_buffer_size 16k;
	    proxy_buffers 32 16k;
	    proxy_read_timeout 300;
	}

	location @static {
	    root /home/${instance_user}/${deploy_app}/public;

	    try_files \$uri =404;

	    error_page 503 /503.html;
	    error_page 500 502 504 /500.html;
	    client_max_body_size 2G;
	}

	location /503.html {
	    try_files /fake_non_existence_location @static;
	}

	location ^~ /stylesheets/ {
	    try_files /fake_non_existence_location @static;
	    expires max;
	}

	location ^~ /assets/ {
	    try_files /fake_non_existence_location @static;
	    expires max;
	}

	location ^~ /system/ {
	    try_files /fake_non_existence_location @static;
	    expires max;
	}

	location /favicon.ico {
	    try_files /fake_non_existence_location @static;
	    expires max;
	}
    }
}
EOF
    fi

    sudo chmod g+rx "/home/$instance_user"

    local scriptdir=""
    scriptdir="$(dirname $(readlink -f "$0"))"
    echo_info "scriptdir: $scriptdir"
    find "$scriptdir" -type d -exec chmod g+rx '{}' \;

    echo_info "Testing Nginx configuration"
    sudo nginx -t
    echo_info "Restart Nginx"
    sudo systemctl restart nginx.service

    exit 0
}

checks() {
    local fn=${FUNCNAME[0]}
    # Required binaries check
    for i in $BIN_REQUIRED; do
        if ! command -v "$i" >/dev/null
        then
            echo_err "Required binary '$i' is not installed" >&2
            false
        fi
    done

    if [[ ! -f /etc/centos-release ]]; then
	echo_err "Only CentOS is supported"
	false
    elif ! grep -q 'CentOS Linux release 7' /etc/centos-release
    then
	echo_err "Only CentOS 7 is supported"
	false
    fi
}

except() {
    local ret=$?
    local no=${1:-no_line}

    echo_fatal "error occured in function '$fn' near line ${no}."

    exit $ret
}

_exit() {
    local ret=$?

    exit $ret
}

usage() {
    echo -e "\\n    Usage: $bn OPTION(S)\\n
    Options:

    -i, --install-composer	install composer.phar if not exists
"
}
# Getopts
getopt -T; (( $? == 4 )) || { echo "incompatible getopt version" >&2; exit 4; }

if ! TEMP=$(getopt -o d --longoptions \
    debug,help -n "$bn" -- "$@")
then
    echo "Terminating..." >&2
    exit 1
fi

eval set -- "$TEMP"
unset TEMP

while true; do
    case $1 in
	-d|--debug)		DEBUG=1 ;		shift	;;
	-h|--help)		usage ;			exit 0	;;
	--)			shift ;			break	;;
	*)			usage ;			exit 1
    esac
done

echo_err()	{ tput bold; tput setaf 7; echo "* ERROR: $*" ; tput sgr0;		}
echo_fatal()	{ tput bold; tput setaf 1; echo "* FATAL: $*" ; tput sgr0;		}
echo_warn()	{ tput bold; tput setaf 3; echo "* WARNING: $*" ; tput sgr0;	}
echo_info()	{ tput bold; tput setaf 6; echo "* INFO: $*" ; tput sgr0;		}
echo_ok()	{ tput bold; tput setaf 2; echo "* OK" ; tput sgr0;		}

main

## EOF ##
