import os

import testinfra.utils.ansible_runner

import pytest

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_hosts_file(host):
    f = host.file('/etc/hosts')

    assert f.exists
    assert f.user == 'root'
    assert f.group == 'root'


def test_check_host_name(host):
    assert host.ansible.get_variables()["inventory_hostname"] == \
           host.run('hostname').stdout.rstrip()


@pytest.mark.parametrize("name", [
    ("bzip2"),
    ("chrony"),
    ("etckeeper"),
    ("gdisk"),
    ("htop"),
    ("tcping"),
    ("man-db"),
    ("mc"),
    ("rsync"),
    ("tmux"),
    ("tree"),
    ("vim-minimal"),
    ("zsh"),
    ("bash-completion"),
])
def test_pkg_instaleed(host, name):
    pkg = host.package(name)

    assert pkg.is_installed


@pytest.mark.parametrize("name", [
   ("abrt"),
   ("iwl* "),
])
def test_pkg_absent(host, name):
    pkg = host.package(name)

    assert pkg.is_installed is False


def test_selinux_status(host):
    selinux = host.run('/usr/sbin/sestatus')

    assert 'SELinux status:                 disabled' in selinux.stdout


@pytest.mark.parametrize("name", [
    ("chronyd"),
    ("systemd-journald"),

])
def test_service_started(host, name):
    svc = host.service(name)

    assert svc.is_running
    assert svc.is_enabled


@pytest.mark.parametrize("pattern", [
    ("Storage=persistent"),
    ("Compress=yes"),
])
def journald_config_check(host, pattern):
    journald_conf = host.file('/etc/systemd/journald.conf')
    assert journald_conf.contains(pattern)
