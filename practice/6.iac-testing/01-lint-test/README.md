### Статический анализ кода

В этой практике мы запустим статический анализ кода (Lint) для terraform, packer и ansible.

Вся практика производится на `bastion` сервере.


* Тестирование terraform

    * Клонируем репозиторий с terraform
    
    ```bash
    cd ~
    git clone git@gitlab.slurm.io:devops/terraform-inventory.git
    cd ~/terraform-inventory
    ```

    * lint тест для terraform

    ```bash
    terraform init
    terraform validate
    ```

    В результате проверки не должно быть ошибок и выведено сообщение:
    ```
    Success! The configuration is valid.
    ```

    >
    > :question: В качестве домашнего задания: измените любой файл terraform, что бы проверка не проходила. 
    >

* lint тест для packer

    * Создадим каталог для файлов packer:

    ```bash
    cd ~
    mkdir packer
    cd ~/packer
    ```
    * Создадим файл [packer.json](practice/5.iac/5.2_Packer/packer.json)

    * Запускаем тест

    ```bash
    packer validate -syntax-only packer.json
    ```

* lint тесты для ansible
    
    * Открываем в gitlab проект с ansible ролью [base](https://gitlab.slurm.io/ansible-roles/system/base) и делаем форк.

    * Клонируем форк репозитория ansible роли base
    
    ```bash
    cd ~
    git clone https://gitlab.slurm.io/GROUP-NAME/base.git
    cd ~/base
    ```

    * Запускаем тест ansible
        * ansible-lint

        ```bash
        ansible-lint */*.yml
        ```

        * Yamllint

        ```bash
        yamllint */*.yml
        ```
        В результате будут выведены ошибки. Связано это с тем, что у ansible свое представление на необходимое количество пробелов при объявлении переменых.

        Поведение yamllint может быть изменено с помощью настроек. Создадим файл [.yamllint.yml](practice/6.iac-testing/01-lint-test/lint-configs/.yamllint.yaml) в корне проекта base. И запускаем проверку повторно, теперь у нас осталось несколько предупрежений. Если мы посмотрим task, то там используется yes, а yamllint говорит, что нужно использовать true. 

        Разница в результате заключается в том, что ansible используется более старая спецификация yaml где допускается использовать как true/false так и yes/no. В [новой](https://yaml.org/spec/1.2/spec.html#id2803629), допускается только true/false.
        >
        > :exclamation: Исправьте самостоятельно warnings, чтобы yamllint выполнялся без замечаний. 
        > 
