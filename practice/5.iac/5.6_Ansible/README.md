# Ansible: IaC
## Форк и клонирование 2-х репозиториев
### Fork
+ Зайти в проект https://gitlab.slurm.io/devops/ansible-inventory ;
  + справа вверху нажать кнопачку 'Fork';
  + на следующей странице выбрать свою группу (`g******`).
+ Повторить то же самое для https://gitlab.slurm.io/devops/terraform-inventory
### git clone
Склонировать на devbox репозитории (**Clone with SSH**!)
+ свой форк **ansible-inventory**
+ свой форк **terraform-inventory**

**[devbox.slurm.io]**
```sh
cd ~
git clone <ansible-inventory>
git clone <terraform-inventory>
```
## Развёртывание тестовой площадки через terraform
```sh
cd ~/terraform-inventory
vim secret.tfvars # Указать данные своего аккаунта Selectel
terraform init
terraform apply -var-file="secret.tfvars"
terraform output -state=terraform.tfstate ansible_inventory > ~/ansible-inventory/hosts/main
```
### Получение доступа к тестовой площадке по ssh
```sh
eval `ssh-agent`
ssh-add
ssh-add -l
ssh-keyscan -t rsa <bastion_host_floatingip_address> >> ~/.ssh/known_hosts
ssh -lroot -A <bastion_host_floatingip_address>
```
**После перелогина на сервер (devbox.slurm.io) по ssh нужно снова запускать** ``eval `ssh-agent` && ssh-add``
## Настройка Ansible
Просмотреть содержимое файла кофигурации Ansible (при его отсутствии -- обратиться к техподдержке)

**[devbox.slurm.io]**
```sh
cat ~/.ansible.cfg
```
Настроить шифрование sensitive data
```sh
pwgen 20 1 > ~/.vpasswd
cat ~/.vpasswd
cd ~/ansible-inventory
ssh-keygen -t ed25519 -N '' -f files/deploy_key/id_ed25519
ansible-vault encrypt files/deploy_key/id_ed25519
ansible-vault view files/deploy_key/id_ed25519
```
### GitLab user key
Добавить содержимое `files/deploy_key/id_ed25519.pub` своему пользователю
- **<Верхний правый угол> -> Settings -> SSH keys**
```sh
ansible-vault encrypt_string <MY_GITLAB_GROUP_TOKEN>
vim group_vars/runners.yml # Отредактировать переменную runner_reg_token
```
- `<MY_GITLAB_GROUP_TOKEN>` брать в GitLab'е (Groups -> <g*****> -> Settings -> CI/CD -> Runners -> Set up a group Runner manually)
- При вставке зашифрованного токена 
  - перевести **vim** в режим вставки: `:se paste`
  - убедиться, что в конце строк не вставились **лишние пробелы**

Подтянуть необходимые роли и запустить плейбук
```sh
ansible-galaxy install -r requirements.yml --force
ansible-playbook --diff site.yml
```
После прохода плейбука пойти в **<Группа> -> Settings -> CI/CD -> Runners** и проверить регистрацию раннеров
## Bootstrap
### SSH
**[bastion]**
```sh
sudo -iu gitlab-runner
echo "<YOUR_VAULT_KEY>" > ~/.vpasswd # Брать его в выводе `cat ~/.vpasswd` (предыдущий блок)
```
**[devbox.slurm.io]**
```sh
ansible-playbook --diff bootstrap.yml
git add hosts/main group_vars/runners.yml host_vars/bastion.yml files/deploy_key
git commit -m 'Try ro run pipeline'
git push
```
Пойти в "Pipelines" проекта **ansible-inventory** и посмотреть на результат.
## Periodic run
+ **ansible-inventory -> CI/CD -> Schedules**
+ [New schedule]
+ Description: `ansible-persist`
+ Custom: `0 * * * *`
# Ansible: deploy
Подготовить файл CI
```
cd ~/xpaste
cp .gitlab-ci.yml.bak .gitlab-ci.yml
git add .gitlab-ci.yml
git commit -m 'CI file added'
git push
```
Пойти в "Pipelines" проекта **xpaste** и посмотреть на выполнение.

После завершения пайплайна зайти на IP балансера и посмотреть на работу приложения
## Broken app
```sh
cd ~/ansible-inventory
vim ~/ansible-inventory/group_vars/www.yml ; Закомментировать строку 'RAILS_ENV: production'
git add group_vars/www.yml
git commit -m 'Puma is broken'
git push
```
**xpaste -> Pipelines -> Run pipeline -> master**

После падения стейджа rolling update (т.е. неудачи обновления) убедиться, что приложение продолжает работать на **puma-2**
# Ansible: Pacemaker + PostgreSQL cluster
```sh
cd ~/terraform-inventory
vim secret.tfvars # db_count = "3"
terraform apply -var-file="secret.tfvars"
terraform output -state=terraform.tfstate ansible_inventory > ~/ansible-inventory/hosts/main
```
```sh
cd ~/ansible-inventory
ansible-playbook --diff bootstrap.yml
```
```sh
vim hosts/pgcluster # Раскомментировать всё
git add hosts/main hosts/pgcluster
git commit -m 'pg 3 nodes'
git push
```
Дождаться завершения пайплайна. Затем выполнить:
```sh
ansible-playbook --diff pg_cluster.yml
```
```sh
ssh pg-1
crm_mon -Afr
```
Дождаться, пока слейвы покажут `STREAMING|ASYNC`

**[devbox.slurm.io]**
Починить и передеплоить приложение, чтобы оно обращалось на виртуальный IP кластера:
```sh
vim group_vars/www.yml # Раскомментировать строку 'RAILS_ENV: production'
vim group_vars/runners.yml # Поменять deploy_db_host на 172.16.100.100
git add group_vars/runners.yml group_vars/www.yml
git commit -m 'Set deploy_db_host to cluster virtual IP'
git push
```
**xpaste -> Pipelines -> New pipeline -> master**
## Pacemaker + PostgreSQL failover
```sh
ssh pg-1
poweroff
ssh pg-2
crm_mon -Afr
```
Подождать промоута несколько секунд и убедиться (в браузере), что приложение работает (например, сохранить пасту).
## Ввод в кластер зафейленого мастера (вручную)
**[devbox.slurm.io]**

Включить ВМ обратно (через terraform)
```sh
cd ~/terraform-inventory
terraform apply -var-file="secret.tfvars"
```
```sh
ssh pg-1
rm /var/lib/pgsql/11/tmp/PGSQL.lock
/srv/southbridge/bin/pgsql-pcmk-slave-copy.sh
pcs resource cleanup PGSQL
crm_mon -Afr # Убедиться, что нода вернулась как слейв
```
## Terraform remote backend
**[devbox.slurm.io]**

Раскомментировать описание pg backend и заменить строку `<bastion_host_floatingip_address>` на свой bastion_host_floatingip_address;
затем выполнить перенос стейта в удалённый бэкенд:
```sh
cd ~/terraform-inventory
vim main.tf
terraform init
```
Запушить изменённый **main.tf** в репозиторий
```sh
git add main.tf
git commit -m 'Enable pg backend'
git push
```
## Caveats
- Если не работает terraform -- проверьте синтаксис файла `secret.tfvars`
