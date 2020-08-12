#### Запуск деплоя с использованием утилиты capistrano
В данной практике мы рассмотрим вариант деплоя приложения с помощью утилиты capistrano.  Capistrano - утилита, написанная на ruby, для деплоя приложений.

#### Подготовка

* Установим глобально на sandbox компоненты ruby для запуска capistrano

```
gem install capistrano:3.10.1 whenever capistrano-rails capistrano-rvm capistrano-dotenv capistrano-bundle_rsync dotenv
```

Capistrano по умолчанию выкачивает исходный код из git. В нашей практике используется модуль, который позволяет использовать в качестве репозитория локальный каталог(capistrano-bundle_rsync). Также в практике используется модуль dotenv, который позволяет capistrano экспортировать переменные из файла .env
 
#### Практика

* Деплой приложения

Для запуска деплоя необходимо запустить capistrano:

```bash
cd ~/xpaste
cap production deploy
```

В результате выполнения этой команды код будет скопирован на сервер, в БД будут выполнены необходимые миграции, сгенерированы статические файлы и установлены необходимые зависимости.

Обратите внимание, в процессе запуска указывается профиль, для которого выполняется деплой. Разные профили могут иметь разные стадии деплоя, разный набор переменных и т.д. 

* Проверяем доступность xpaste

В браузере открываем http://XPASTE_IP

Где XPASTE_IP это IP-адрес сервера xpaste

* Анализ результатов

Подключитесь к xpaste серверу по ssh:

```bash
ssh XPASTE_IP
```

Посмотрите структуру каталогов:

```bash
ll /srv/www/xpaste/
```

Обратите внимание на новый каталог `shared`, в данном каталоге содержатся служебные каталоги, такие как logs, tmp, bundle. В дальнейшем capistrano подключает их в основной каталог через symlink. Данный механизм позволяет увеличить скорость деплоя и реализовать сквозное логирование.