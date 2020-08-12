# Terraform

**Цель:** создать один сервер приложения и один базы данных из образов с предыдущего шага

Перейдем в домашнию директорию
```bash
cd ~/
```

Перед началом нужно удалить все артефакты с предыдущего шага, данное действие можно сделать из панели управления или удалить через openstack cli, для работы с ним потрубуется скачать rc.sh файл - **Панель управления** - выбрать пользователя и регион - **Скачать**, после чего загрузить rc.sh на devbox

Теперь удалим артефакты с предыдущего шага

Для начала загрузим переменные окружения
```bash
source ~/rc.sh
```

Выполнием пару команд для проверки
```bash
# Список серверов, будет пустой ответ
openstack server list
# Список образов
openstack image list --private
# Список приватных сетей
openstack network list --internal
```

Создадим скрипт для очистки ресурсов
```
cat > ~/clean.sh << 'EOF'
openstack floating ip list
openstack floating ip list -f value -c ID | xargs openstack floating ip delete

openstack router list
for i in `openstack router list -f value -c ID`; do neutron router-port-list -f value -c id ${i} | xargs openstack router remove port ${i}  ; done
openstack router list -f value -c ID | xargs openstack router delete

openstack port list
openstack port list -f value -c ID | xargs openstack port delete

openstack subnet list
openstack subnet list -f value -c ID | xargs openstack subnet delete

openstack network list --internal
openstack network list --internal -f value -c ID | xargs openstack network delete

openstack server list
openstack server list -f value -c ID | xargs openstack server delete

openstack volume list
openstack volume list -f value -c ID | xargs openstack volume delete

openstack keypair list
for key in `openstack keypair list -f value -c Name`; do openstack keypair delete ${key} ; done

openstack floating ip list
openstack router list
openstack port list
openstack subnet list
openstack network list --internal
openstack server list
openstack volume list
openstack keypair list
EOF
```

Запустим очистку
```bash
bash ~/clean.sh
```

Перейдем в каталог 5.4_Terraform:
```bash
cd devops/practice/5.iac/5.4_Terraform
```

Создадим окружение через терраформ, выполняем из 4.Terraform:
```bash
ln -s ../5.1_Terraform/1.one_server/secrets.tfvars .

terraform init
terraform apply -var-file=./secrets.tfvars
```

После можно перейти по ссылке
```bash
echo http://$(terraform output server_external_ip)
```

После проверки перед следующим шагом нужно иметь чистое окружение, поэтому удалим сервера
```bash
terraform destroy -var-file=./secrets.tfvars
```

