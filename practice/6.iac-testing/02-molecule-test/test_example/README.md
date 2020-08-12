#### Ответы на домашнее задание

* Ошибка индепотентности

Данная ошибка связана с ошибкой модуля в ansible, модуль не является индепотентным. Issue на [Github](https://github.com/ansible/ansible/issues/64963)

Для исправления надо в файле `tasks/packages.yml` после 16 строки, добавить:

```yaml
  tags: [molecule-idempotence-notest] # GH 64963
```

* Ошибка тестов, проверка selinux

В конец файла: необходимо добавить

```yaml
- name: Reboot to apply selinus
  reboot:
    reboot_timeout: 3600
  when: selinux_change is changed

- name: Wait for system to become reachable
  wait_for_connection:
    timeout: 900
  when: selinux_change is changed
```

После `14` строки добавить:

```yaml
  register: selinux_change
```
