## ci/cd практика

### Ссылки на задания

#### [1. Настройка gitlab-runner](practice/4.gitlab_ci_cd/01-gitlab-runner)

#### [2. Настройка gitlab ci/cd](practice/4.gitlab_ci_cd/02-gitlab-ci)

#### [3. Шаблоны gitlab ci/cd](practice/4.gitlab_ci_cd/03-gitlab-ci-teml)


#### SSH setup

Для выполнения практики нам понадобится SSH доступ на:

* sandbox server. 

`Все работы на этом хосте проводятся под учетной записью root`

#### Установка Docker

* Устанавливаем необходимые пакеты

```bash
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
```

* Устанавливаем репозиторий docker

```bash
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

```
* Устанавливаем docker 

```bash
yum install -y docker-ce docker-compose
```

* Запускаем службу и добавляем ее в автостарт

```bash
systemctl enable --now docker
```
