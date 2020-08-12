# ChatOps

## Практика #1

### Slack Workspace

Создаем новый workspace для своего проекта: https://slack.com/create.

Название и другие параметры не имеют значения, развлекайтесь как можете. :)

### Интеграция с GitLab

#### Уведомления

Создаем в Slack канал #gitlab (кнопка `+` над списком каналов). Все настройки, кроме названия, можно оставить по умолчанию.

Для отправки уведомлений из GitLab в Slack откроем проект xpaste в GitLab и перейдем в Settings -> Integrations. В списке "Project services" выберем "Slack notifications" и перейдем по ссылке "Add incoming webhook" на открывшейся странице. Нажимаем "Add to Slack", чтобы перейти в настройки нового webhook.

В настройках выбираем `#gitlab` в "Post to Channel" и копируем полученный Webhook URL. В разделе "Integration Settings" задаем имя: вписываем `GitLab` в "Customize Name". Сохраняем настройки.

Снова перейдем на страницу "Slack notifications". В списке нужно выбрать события, о которых будут отправляться уведомления: оставим push, issue, merge request, pipeline, deployment). В поле "channel" для каждого события вводим gitlab. В поле "Webhook" копируем полученный ранее URL, в поле "Username" вписываем "GitLab", сохраняем настройки.

При сохранении настроек GitLab должен сразу отправить тестовое уведомление в Slack. Можно также попробовать сделать коммит в репозиторий xpaste или открыть новую задачу в issues проекта: уведомления об этих событиях будут приходить в канал #gitlab.

![GitLab test](https://i.imgur.com/2FRLB9d.png)

#### Slash commands

Slash commands — команды в Slack, которые начинаются со слеша (например, `/join` или `/invite`). Воркспейсы Slack поддерживают установку дополнительных команд, которые посылают запрос к сторонним приложениям, в том числе к GitLab.

Пользуясь документацией [Slack Slash Commands для GitLab](https://docs.gitlab.com/ce/user/project/integrations/slack_slash_commands.html), настройте интеграцию репозитория xpaste с воркспейсом Slack.

В качестве trigger term используйте `xpaste`, остальные параметры — по документации.

После настройки проверьте работоспособность в Slack: `/xpaste help`.

### App Directory

[Slack App Directory](https://slack.com/apps) — библиотека готовых интеграций с SaaS и облачными сервисами. Выберите любые три сервиса, которые используете в работе, и подключите к своему воркспейсу.

Несколько примеров:

* [Google Hangouts](https://slack.com/services/BMX05B9B6)
* [Google Calendar](https://slack.com/apps/ADZ494LHY-google-calendar)
* [Simple Poll](https://slack.com/apps/A0HFW7MR6-simple-poll)
* [Giphy](https://slack.com/services/BMZ9XTEDD)
* [Trello](https://slack.com/apps/A074YH40Z-trello)
* [Asana](https://slack.com/apps/AA16LBCH2-asana)
* [JIRA Cloud](https://slack.com/apps/A2RPP3NFR-jira-cloud)
* [GitHub](https://slack.com/apps/A8GBNUWU8-github)

Доступ к вашему воркспейсу на протяжении всего курса будет только у вас, поэтому можно добавлять интеграцию с личными аккаунтами.

## Практика #2

### API-токен для Slack

Создаем интеграцию с Hubot: [Hubot в Slack Apps Directory](https://slack.com/apps/A0F7XDU93-hubot?next_id=0). Имя пользователя и прочие настройки бота — любые. Развлекайтесь как можете. :)

После добавления интеграции нужно скопировать полученный API-токен из Setup Instructions:

![API token](https://i.imgur.com/OHmGDJC.png)

### API-токен для Grafana

Авторизуемся в веб-интерфейсе Grafana: `http://<Bastion IP>:3000/`. Если пользователь не был сконфигурирован, логин и пароль по умолчанию — admin/admin.

В разделе Configuration -> API Keys создаем новый ключ ("Add API Key"):

Key name: не имеет значения.
Role: Viewer.
Time to live: оставить пустым.

![Grafana API token](https://i.imgur.com/QG5SxkD.png)

Полученный ключ из окна API Key Created нужно скопировать сразу, его нельзя будет посмотреть в дальнейшем.

### График нагрузки CPU

Чтобы боту было, что отображать, создадим график нагрузки на CPU в наших серверах приложений.

Входим в Grafana, выбираем Create -> Dashboard в меню. Выбираем Add Query и заполняем два поля:

1. Метрика в поле `metric` во вкладке `Queries`. Нужная нам метрика — `node_load1` (если `node_load1` выдает пустой график, можно попробовать `instance:node_cpu_utilisation:rate1m`).

![Setting the metric](https://i.imgur.com/4hDfwCz.png)

2. Заголовок (`Title`) во вкладке `General`. Название нашей панели — `Node CPU Utilization`.

![Setting the panel title](https://i.imgur.com/CThvFlH.png)

Сохраняем график: `Save Dashboard` в верхнем меню. Любуемся. Всё готово!

### Alertmanager

Для интеграции Alertmanager и Slack создадим в воркспейсе канал #monitoring.

После создания канала добавляем ещё один [incoming webhook](https://slack.com/apps/A0F7XDUAZ-incoming-webhooks) в Slack. Выбираем `#monitoring` в "post to channel", копируем полученный Webhook URL. На открывшейся странице задаем интеграции имя: вписываем `Alertmanager` в "Customize Name". Сохраняем настройки.

После этого заходим на Bastion и расширяем конфигурацию Alertmanager, которая хранится в `/etc/alertmanager/alertmanager.yml`:

```yaml
global:
[...]
  slack_api_url: '<Webhook URL, полученный ранее>'

route:
[...]
  routes:
   - match:
       severity: 'warning'
     group_wait: 10s
     group_interval: 10s
     repeat_interval: 1h
     receiver: 'slack'
     continue: true
   [...]

receivers:
[...]
- name: slack
  slack_configs:
    - channel: '#monitoring'
      send_resolved: True
```

Таким образом, полный конфиг примет подобный вид:

```yaml
global:
  resolve_timeout: 5m
  slack_api_url: 'https://hooks.slack.com/services/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'
route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'
  routes:
   - match:
       severity: 'warning'
     group_wait: 10s
     group_interval: 10s
     repeat_interval: 1h
     receiver: 'slack'
     continue: true
receivers:
- name: 'web.hook'
  webhook_configs:
  - url: 'http://127.0.0.1:5001/'
- name: slack
  slack_configs:
    - channel: '#monitoring'
      send_resolved: True
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
```

Перезапускаем Alertmanager:

```bash
systemctl restart alertmanager
```

Создадим искусственную нагрузку на сервер bastion:

```bash
yes > /dev/null &
yes > /dev/null &
yes > /dev/null &
yes > /dev/null &
yes > /dev/null &
```

Через несколько минут в канале #monitoring появится предупреждение:

![Bastion load alert](https://i.imgur.com/9J3btgT.png)

Уберем нагрузку на bastion:

```bash
pkill yes
```

Alertmanager скажет нам о том, что ошибка устранена:

![Bastion load alert resolved](https://i.imgur.com/Hagnd3L.png)

### Установка Hubot

_Все команды в этой секции выполняются на сервере Bastion._

Hubot требует для работы Node и NPM. Они уже должны быть установлены на бастионе после настройки CI/CD, но если бот ставится на «чистый» сервер, то их нужно установить отдельно:

```bash
yum install nodejs -y
```

Установим плагин для Grafana, необходимый для экспорта графиков в png:

```bash
yum install alsa-lib libX11-xcb chromium libXScrnSaver libXtst libXdamage libXcomposite
grafana-cli plugins install grafana-image-renderer
service grafana-server restart
```

Клонируем наш форк Hubot с необходимыми плагинами и устанавливаем зависимости:

```bash
git clone git@gitlab.slurm.io:devops/hubot-chatops
cd hubot-chatops && npm install
```

Добавляем полученные ранее токены в окружение и запускаем бота:

```bash
export HUBOT_GRAFANA_HOST=http://bastion:3000
export HUBOT_GRAFANA_API_KEY=<токен Grafana>
export HUBOT_SLACK_TOKEN=<токен Slack>
./bin/hubot --adapter slack
```

### Работа с Hubot

_Все команды в этой секции выполняются внутри Slack. `@Bender` в командах — имя бота, замените на ваше._

Приглашаем бота в канал #general:

```
/invite @bender #general
```

В #general проверяем работоспособность командой help:

```
@bender help
```

![Slack bot test](https://i.imgur.com/N5Xx3Af.png)

Выводим наш свежесозданный график из Grafana:

```
@bender graf db node-cpu-utilization
```

![Grafana bot test](https://i.imgur.com/Gvfut9M.png)

#### Скейлинг инфраструктуры

_В этой части мы дадим бастион-серверу доступ к девбоксу по SSH для запуска Terraform. Не делайте так в продакшн! Это брешь в безопасности, и правильнее (но дольше) делать это через terraform-api._

**На Bastion** создаем новый ключ для Hubot:

```bash
ssh-keygen -m PEM -t rsa -b 2048 -f /root/.ssh/hubot_rsa
$ cat ~/.ssh/hubot_rsa.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGc+qNHbA8AcldMbL7tqK2t99JSedSQvQuFEjumd3y3Kx6KP2jJVCoTNV3JBjimkd+Y4HSxPNjhqcTX/aoJlPLvseDgsG3gRULNv2vIke3FuSfSuWmaxhvMJd1uCKMcwc+6QL9uSRQchoLxWkntyXpJ4nCwNuj2S+7gvEe1htxJydFpGZXCyatv8njGN9OHK3XZ6MYFwt827YXtzlaE8B1wQyAYfrpF41UMKmJPiR+N5N9edPjKm/1uyL/Yq1AGT/1/qc4Rz+TAgsbqIjPB5HlPWW/Hz0qw9pqjpXhnI9Ly1zag7Gzgvnalw6bMeQ279VbNVfP321BFXXii+seAj4X bastion
```

**На девбоксе** добавьте полученный ключ в ~/.ssh/authorized_keys:

```bash
$ echo '<ключ>' >> ~/.ssh/authorized_keys
$ chmod 600 ~/.ssh/authorized_keys
```

Теперь бот может присоединиться к девбоксу через SSH без пароля. **В Slack** попробуем увеличить количество серверов приложений до трех:

```
@bender ssh <имя пользователя> devbox.slurm.io export TF_VAR_server_count=3; cd ~/terraform-inventory; terraform apply -var-file="secret.tfvars" -auto-approve
```

![Scale up](https://i.imgur.com/2PyOdqd.png)

Вернем всё к исходным настройкам (два сервера):

```
@bender ssh <имя пользователя> devbox.slurm.io cd ~/terraform-inventory; terraform apply -var-file="secret.tfvars" -auto-approve
```

![Scale down](https://i.imgur.com/8hucZCX.png)

Можно подробнее раскрыть stdout обоих команд, чтобы убедиться, что конфигурация действительно изменилась.

#### Ограничение доступа к командам

После того, как мы протестировали доступ по SSH, поставим ограничение на выполнение SSH-команд. В нашу сборку бота уже включен плагин `hubot-auth`, поэтому теперь нам нужно добавить проверку доступа в плагин для SSH и настроить группы пользователей.

Внутри `hubot-chatops` отредактируем файл `node_modules/hubot-ssh2/scripts/ssh2.js`. После строчки `robot.respond(/ssh (.+?) (.+?) (.+)/i, (msg) => {` добавим код для проверки роли:

`node_modules/hubot-ssh2/scripts/ssh2.js`

```js
  [...]

  robot.respond(/ssh (.+?) (.+?) (.+)/i, (msg) => {

    let authuser = robot.brain.userForName(msg.message.user.name);
    if (!robot.auth.hasRole(authuser, 'ssh')) {
      msg.reply('Access denied! You need the "ssh" role to perform this action.');
      return;
    }

  [...]
```

Теперь укажем администратора `hubot-auth`, который сможет назначать роли. Для этого нужно узнать ID вашего пользователя в Slack: на странице [Slack API users.list](https://api.slack.com/methods/users.list/test) введём токен в поле `provide your own token` и отправим запрос кнопкой "Test method". В полученном ответе найдём своего пользователя и скопируем поле "id":

![API response](https://i.imgur.com/r28BQVW.png)

На bastion выключим бота, добавим новую переменную окружения и запустим бота снова:

```bash
export HUBOT_AUTH_ADMIN=<ваш id>
./bin/hubot --adapter slack
```

Проверим, назначена ли роль:

```
@bender what roles do I have?
```

Если бот отвечает, что вам назначена роль "admin", настройка прошла корректно. Теперь попробуем снова запустить скейлинг:

![Access denied](https://i.imgur.com/ew1KG2z.png)

Ура! Поскольку мы не находимся в группе "ssh", теперь нам запрещено удаленное выполнение команд. 

Добавим себе нужную роль:

```
@bender @<ваше имя в Slack> has ssh role
```

Теперь на вопрос "what roles do I have?" бот должен ответить "admin, ssh", а команды `ssh` снова должны выполняться.

#### Создание коротких команд

Чтобы не запоминать полный синтаксис команд для бота, для наиболее частых команд можно задать короткие алиасы (за это отвечает плагин `hubot-alias`, который входит в нашу сборку Hubot):

```
@bender alias CPU=graf db node-cpu-utilization
```

Теперь наш график можно вывести короткой командой `CPU`:

![CPU alias test](https://i.imgur.com/7qmce9v.png)

Создадим алиасы `peak load` и `normal load` для масштабирования серверов приложений:

```
@bender alias peak load=ssh <имя пользователя> devbox.slurm.io export TF_VAR_server_count=3; cd ~/terraform-inventory; terraform apply -var-file="secret.tfvars" -auto-approve
@bender alias normal load=ssh <имя пользователя> devbox.slurm.io cd ~/terraform-inventory; terraform apply -var-file="secret.tfvars" -auto-approve
```

![Load aliases](https://i.imgur.com/ws9Su1d.png)

Теперь мы можем временно отмасштабировать серверы командой `peak load` в моменты пиковой нагрузки, а затем командой `normal load` вернуть их в исходное состояние.

Поздравляю! Практика закончена.

![ChatOps final](https://i.imgur.com/mU1514a.png)
