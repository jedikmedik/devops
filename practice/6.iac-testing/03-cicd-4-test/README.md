### ci/cd для запуска тестов ansible

#### Подготовка

* Установка вирутального окружения для пользователя gitlab-runner

Для запуска тестов необходимо создать виртуальное окружение для пользователя gitlab-runner и установить необходимые пакеты для запуска тестов.

Работы проводятся на сервере `bastion`.

* Переключаемся под пользователя gitlab-runner

```bash
su -l gitlab-runner
```
* Создаем виртуальное окржение

```bash
cd ~ 
virtualenv iac-test-env 
source ~/iac-test-env/bin/activate
```

* Устанавливаем необходимые пакеты

```bash
pip install molecule ansible ansible-lint python-vagrant selinux paramiko
```
Выходим из пользователя gitlab-runner.

* Добавление ci/cd в форк проекта 
    
    * Создаем бранч test
    
    ```bash
    cd ~/base
    git checkout -b test
    ```

    * Создаем gitlab-ci.yml 

    ```bash
    cat << EOF > .gitlab-ci.yml
    ---
    include:
      - project: 'devops/ansible-test-tmpl'
        ref: master
        file: 'ansible-test-tmpl.yml'
    ...
    
    EOF
    ```

    * Пушим изменения

    ```bash
    git add -A
    git commit -am "Add test for role"
    git push origin test:test
    ```
    
    * Создаем merge request

    Переходим на страницу форка проекта xpaste: https://gitlab.slurm.io/GROUP-NAME/base (`GROUP-NAME, необходимо подставить номер своего студента`)и нажимаем кнопку, в правом верхнем углу: `New merge requests`. В качестве `Source branch` выбираем g<номер студента> и ветку test, в `Target branch` выбираем форк нашего репозитория и ветку master.
    После этого нажимаем `Compare branches and continue`. Запполняем `Title` и `Description` и нажимаем `Submit`.
    В итоге, мы получим MR. На данной странице отображаются данные по изменениям в MR, описание данного MR, а так же статус pipline для данного MR.

  * Принимаем MR после окончания тестов

    После окончания тестов принимаем MR. Для этого нажимаем кнопку `Merge`.
