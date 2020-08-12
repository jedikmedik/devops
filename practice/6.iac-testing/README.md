### Тестирование IaC

### Ссылки на задания

#### [1. Статический анализ кода](practice/6.iac-testing/01-lint-test)

#### [2. unit тесты ansible с использованием molecule](practice/6.iac-testing/02-molecule-test)

#### [3. ci/cd для запуска тестов](practice/6.iac-testing/03-cicd-4-test)

#### SSH setup

Для выполнения практики нам понадобится SSH доступ на:

* `bastion`

`Все работы на этом хосте проводятся под учетной записью root`

### Подготовка

* Создаем виртуальное окружение

```bash
ln -s /usr/bin/pip3 /usr/bin/pip
pip install virtualenv 
virtualenv iac-test-env
source iac-test-env/bin/activate
```

* Устанавливаем Lint

```bash
pip install yamllint ansible-lint
```

* Устанавливаем virtualBox
    * Импортируем ключ для репозитория virtualbox
    ```bash
    rpm --import https://www.virtualbox.org/download/oracle_vbox.asc
    ```
    * Добавляем репозиторий virtualbox
    ```bash
    cat << EOF > /etc/yum.repos.d/virtualbox.repo
    [virtualbox]
    name=Oracle Linux / RHEL / CentOS-\$releasever / \$basearch - VirtualBox
    baseurl=http://download.virtualbox.org/virtualbox/rpm/el/\$releasever/\$basearch
    enabled=1
    gpgcheck=1
    repo_gpgcheck=1
    gpgkey=https://www.virtualbox.org/download/oracle_vbox.asc
    EOF
    ```
    * Устанавливаем virtualbox и необходимые пакеты
    ```bash
    dnf upgrade kernel grub2
    dnf install -y kernel-devel VirtualBox-6.0 gcc make perl elfutils-libelf-devel
    reboot
    ```
    + Настраиваем virtualbox
    ```bash
    /sbin/vboxconfig
    ```

* Устанавливаем vagrant и необходимые пакеты
```bash
dnf install -y  python3-devel openssl-devel libselinux-python3
dnf -y install https://releases.hashicorp.com/vagrant/2.2.5/vagrant_2.2.5_x86_64.rpm
```

* Устанавливаем molecule

```bash
source iac-test-env/bin/activate
pip install molecule ansible  python-vagrant selinux paramiko
```

* Установка terraform 

```bash
wget https://releases.hashicorp.com/terraform/0.12.19/terraform_0.12.19_linux_amd64.zip 
unzip terraform_0.12.19_linux_amd64.zip
mv terraform /usr/local/bin/
```

* Устанавливаем packer

```bash
wget https://releases.hashicorp.com/packer/1.5.1/packer_1.5.1_linux_amd64.zip
unzip packer_1.5.1_linux_amd64.zip
mv packer /usr/local/bin/
```
