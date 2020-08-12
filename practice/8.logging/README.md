# Централизованный сбор логов с EFK

## Добавляем Fluentd в Ansible

Для централизованного сбора логов нам нужны Fluentd (сбор данных), Elasticsearch (поиск и индексация) и Kibana (визуализация и аналитика). Elasticsearch и Kibana уже развернуты на bastion в рамках практики по IaC, поэтому нам осталось развернуть на всех хостах Fluentd. 

Начнём менять конфигурацию Ansible в `~/ansible-inventory` на devbox.

Добавим fluentd в зависимости:

`requirements.yml`

```
[...]

- src: git@gitlab.slurm.io:ansible-roles/mon/fluentd.git
  scm: git
  version: master

[...]
```

Уберем из `site.yml` роль Prometheus: поскольку в предыдущей практике мы вносили изменения в конфигурационный файл вручную, при обновлении Prometheus через Ansible они перезаписались бы.

`site.yml`

```
  tasks:
    - name: Import base role
      include_role:
        name: "{{ role }}"
      loop:
        - base
      loop_control:
        loop_var: role
```

Теперь добавим установку fluentd на все хосты под управлением Ansible. Для этого в `site.yml` добавим ещё одну роль в задание "Apply roles to all hosts":

`site.yml`

```
- name: Apply roles to all hosts
  hosts: all

  tasks:

    [...]

    - name: Include fluentd role
      include_role:
        name: fluentd

[...]
```

Следующее, что нам нужно сделать — сконфигурировать fluentd. Каждый хост с установленным fluentd будет складывать в Elasticsearch события из syslog.

Мы будем использовать [High Availability Config](https://docs.fluentd.org/deployment/high-availability) — вместо выгрузки логов в Elasticsearch напрямую, все хосты под управлением fluentd будут отправлять их на bastion, где настроен fluentd forwarder. Оттуда логи будут централизованно выгружаться в Elastic. 

В `templates` создаем папку `fluentd` и два конфигурационных файла внутри: `aggregator.conf.j2` и `forwarder.conf.j2`.

`templates/fluentd/aggregator.conf.j2`

```
<source>
  @type forward
  port 24224
</source>

<source>
  @type syslog
  port 5140
  tag system
  severity_key severity
  facility_key facility
  <transport tcp>
  </transport>
</source>

<match system.**>
  @type elasticsearch
  host localhost
  port 9200
  logstash_format true
</match>
```

`templates/fluentd/forwarder.conf.j2`

```
<source>
  @type syslog
  port 5140
  tag system
  severity_key severity
  facility_key facility
  <transport tcp>
  </transport>
</source>

<match system.**>
  @type forward

  <server>
    host {{ hostvars['bastion']['ansible_host'] }}
    port 24224
  </server>

  <buffer>
    flush_interval 60s
  </buffer>
</match>
```

Теперь добавим конфигурационные файлы в переменные. `forwarder.conf.j2` используется всеми хостами, кроме bastion, поэтому добавим его в `group_vars/all.yml`:

`group_vars/all.yml`

```
[...]
fluentd_custom_conf: [ "templates/fluentd/forwarder.conf" ]
[...]
```

`aggregator.conf.j2` используется только на bastion-хосте, поэтому изменим `host_vars/bastion.yml`:

`host_vars/bastion.yml`

``` 
[...]
fluentd_custom_conf: [ "templates/fluentd/aggregator.conf" ]
[...]
```

_На заметку:_ В случае с bastion, мы получаем разные значения одной и той же переменной из двух источников: переменных группы all и переменных хоста bastion. Ansible [отдает приоритет переменным хоста](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable), поэтому в результате bastion использует `aggregator.conf.j2`.

Итак, мы настроили fluentd получать события syslog на порту 5140. Последнее, что нам нужно сделать — сконфигурировать rsyslogd (syslog daemon, установленный по умолчанию на всех наших хостах) для отправки событий на этот порт.

Для этого в `site.yml` добавим задание, которое будет устанавливать `rsyslog` и настраивать отправку логов в fluentd:

`site.yml`

```
[...]

- name: Set up syslog forwarding
  hosts: all

  tasks:

    - name: Restart td-agent service
      service: 
        name: td-agent.service 
        enabled: yes 
        state: restarted

    - name: Add syslog forwarding to Fluentd
      become: yes
      become_user: root
      lineinfile:
        state: present
        path: /etc/rsyslog.conf
        line: '*.* action(type="omfwd" target="127.0.0.1" port="5140" protocol="tcp")'

    - name: Enable rsyslog service
      service: 
        name: rsyslog.service 
        enabled: yes 
        state: restarted

```

Загружаем изменения `ansible-inventory` в git:

```
git add .
git commit -m 'Add Fluentd to all hosts'
git push
```

Обновляем зависимости и применяем изменения:

```
ansible-galaxy install -r requirements.yml --force
ansible-playbook --diff site.yml
```

Теперь Fluentd должен быть сконфигурирован на всех хостах, а Elasticsearch и Kibana — доступны на bastion.

## Kibana

Если всё прошло хорошо, Kibana должна быть доступна на `http://<bastion IP>:5601`. Поток логов должен быть виден через десять-пятнадцать минут после применения новой конфигурации Ansible (из-за буферизации fluentd это происходит не сразу).

Теперь отобразим в Kibana несложную аналитику по нескольким видам данных, которые можно узнать из syslog. Вся работа проводится в веб-интерфейсе: `http://<bastion IP>:5601/`.

### Добавляем данные fluentd

Для начала нужно добавить index pattern: фильтр, который будет выбирать все индексы elasticsearch, в которых хранятся наши логи. Поскольку мы задали для fluentd режим совместимости с logstash, он создает в elasticsearch индексы формата `logstash-<дата>`; в index pattern это будет выглядеть как `logstash-*`.

1. В левом меню выбираем **Management**.
2. На появившейся странице выбираем **Kibana** -> **Index Patterns**.
3. Нажимаем на кнопку **Create index pattern**.
4. Задаём `logstash-*` в текстовом поле **Index pattern**, нажимаем **Next step**.
5. В поле **Time Filter field name** выбираем `@timestamp` — поскольку у нас нет других полей с датой, это единственное поле, доступное для выбора.
6. Нажимаем **Create index pattern**.

Готово! Теперь Kibana работает с данными из fluentd. На странице **Discover** можно посмотреть уже загруженные логи.

### Количество хостов

Для начала добавим простую числовую метрику: количество хостов, которые отправляют логи в Elasticsearch.

1. В левом меню выбираем **Vizualize**.
2. На появившейся странице нажимаем **+** для добавления новой визуализации.
3. В появившемся окне выбираем **Metric**.
4. На появившейся странице выбираем наш индекс: **logstash-***.

Теперь выберем данные, которые мы будем использовать для новой метрики. Раскрываем **Metric** в левой панели нажатием на кнопку со стрелкой.

Нам нужно посчитать уникальные значения поля `host`, поэтому в **Aggregation** мы выбираем **Unique Count**, а затем задаём `host.keyword` в **Field**. В поле **Custom Label** пишем "Hosts", а затем нажимаем на **Save** в верхнем меню, чтобы сохранить визуализацию.

![Host count](https://i.imgur.com/JFw8oPg.png)

В появившемся поп-апе задаём имя "Host Count". Сохраняем.

### Критические сообщения

Kibana позволяет сохранять поисковые запросы (вместе с параметрами отображения), чтобы иметь к ним быстрый доступ, а также использовать в визуализациях и дэшбордах. Создадим фильтр для наиболее важных записей, чтобы отделить ошибки от простых информационных сообщений.

Каждая запись syslog имеет свой уровень критичности (severity):

- 0: Emergency (`emerg`)
- 1: Alert (`alert`)
- 2: Critical (`crit`)
- 3: Error (`err`)
- 4: Warning (`warning`)
- 5: Notice (`notice`)
- 6: Informational (`info`)
- 7: Debug (`debug`)

Потенциально нас могут интересовать записи уровня error и серьёзнее (0–3). Fluentd настроен так, что сохраняет уровень критичности в поле severity как строку (`emerg`, `alert` и так далее), поэтому создадим поисковый запрос, пользуясь [языком запросов Kibana](https://www.elastic.co/guide/en/kibana/current/kuery-query.html):

1. В левом меню выбираем **Discover**.
2. В поле **Search** задаём наш фильтр: `severity:(err OR crit OR alert OR emerg)`.
3. Сохраняем запрос кнопкой **Save** в верхней панели, зададим имя "Errors (severity 0–3)".

Настроим отображение запроса: нас интересуют не все поля, хранящиеся в elasticsearch. В **Available fields** в левой панели выберем поля `@timestamp`, `host`, `facility`, `ident`, `severity` и `message`. В таблице со списком результатов нажмём серую стрелку возле заголовка **@timestamp**, чтобы отсортировать записи по дате. Ещё раз сохраняем запрос.

Теперь всё готово, но на моём инстансе этот запрос захламляют записи от nginx-balancer, которые появляются из-за враждебного сканирования на уязвимости:

![Nginx scan errors](https://i.imgur.com/DVmJPam.png)

Отфильтруем его — изменим запрос на `severity:(err OR crit OR alert OR emerg) AND NOT message:kex_exchange_identification`.

Ещё раз сохраним запрос кнопкой **Save**.

### Неудачные попытки входа по SSH

Попробуем отследить попытки сканирования нашего сервиса: добавим столбчатую диаграмму, которая будет отображать неудачные попытки входа по SSH каждый час.

Для начала создадим ещё один сохранённый запрос: аналогично инструкциям в предыдущей части, задаем фильтр `message:"Failed password" AND facility:authpriv AND ident:sshd` и сохраняем его под заголовком "Failed SSH login attempts". 

Теперь визуализируем этот запрос в форме гистограммы:

1. В левом меню выбираем **Vizualize**.
2. На появившейся странице нажимаем **+** для добавления новой визуализации.
3. В появившемся окне выбираем **Vertical bar**.
4. На появившейся странице выбираем наш сохранённый запрос из списка в правой колонке.

Настроим визуализацию через панель слева. В **Metrics** раскрываем **Y-Axis** и задаем `Count` в поле **Aggregation** и `Failed Attempts` в поле **Custom Label**. В **Buckets** добавляем **X-Axis**, задаем `Date Histogram` в поле **Aggregation**, `@timestamp` в поле **Field**, `Hourly` в поле **Interval** и `Datetime` в поле **Custom Label**.

Как и всегда, сохраняем визуализацию кнопкой **Save**. Задаём название — например, **Failed SSH login attempts**.

![Failed SSH login attempts](https://i.imgur.com/sU0oBO6.png)

Для проверки вы можете несколько раз неудачно зайти по SSH самостоятельно, но если ваш стенд находился онлайн хотя бы несколько часов после начала сборки логов, это вряд ли потребуется.

### Dashboard

Теперь соберем всю нашу статистику в один дэшборд. 

1. В левом меню выбираем **Dashboard**.
2. На появившейся странице нажимаем **Create new dashboard** для добавления нашего дэшборда.
3. Кнопкой **Add** в верхнем меню добавляем метрику `Hosts` и гистограмму `Failed SSH login attempts
` со вкладки **Visualization**, а также фильтр `Errors (severity 0–3)` со вкладки **Saved Search**.
4. Будим внутреннего дизайнера и двигаем панели по дэшборду так, чтобы получилось красиво.
5. Сохраняем кнопкой **Save**.

У нас готов дэшборд, отображающий некоторую информацию из syslog: количество хостов, с которых собираются логи; критичные ошибки; график с попытками перебора паролей SSH.

![Dashboard](https://i.imgur.com/ZmLYUNQ.png)

В качестве самостоятельной практики можно добавить другие запросы и графики, а также настроить Fluentd на получение информации не только из syslog, но и из других источников — например, из nginx для хоста nginx-balancer.

Практика пройдена. Вы восхитительны!
