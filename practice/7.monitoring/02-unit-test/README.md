### Тестирование Prometheus

В этой практике мы запустим lint тесты для основного конфигурационного файла Prometheus, для rules и alerts. Также запустим Unit тесты для rules и alerts.

Все работы этой практики проводятся на сервере `bastion`.

#### Подготовка

* Добавляем набор rules

Сохраняем [содержимое](https://gitlab.slurm.io/devops/devops/raw/master/practice/7.monitoring/02-unit-test/configs/rules.yml) в файл: `/etc/prometheus/rules.yml`

* Добавляем набор alerts

Сохраняем [содержимое](https://gitlab.slurm.io/devops/devops/raw/master/practice/7.monitoring/02-unit-test/configs/alerts.yml) в файл: `/etc/prometheus/alerts.yml`

#### Lint тесты

* Проверяем конфигурационный файл

```bash
$ promtool check config /etc/prometheus/prometheus.yml 
```

В результате вы должны получить
```bash
Checking /etc/prometheus/prometheus.yml
  SUCCESS: 2 rule files found

Checking /etc/prometheus/rules.yml
  SUCCESS: 1 rules found

Checking /etc/prometheus/alerts.yml
  SUCCESS: 1 rules found

```

#### Unit тесты для rules и alerts

* Создаем тесты для rules

Сохраняем [содержимое](https://gitlab.slurm.io/devops/devops/raw/master/practice/7.monitoring/02-unit-test/configs/test_rules.yml) в файл: `/etc/prometheus/test_rules.yml`
* Запускаем тест

```bash
$ promtool test rules /etc/prometheus/test_rules.yml        
```
В результате вы должны получить
```bash
Unit Testing:  test_rules.yml
  SUCCESS

```

* Создаем тесты для alerts

Сохраняем [содержимое](https://gitlab.slurm.io/devops/devops/raw/master/practice/7.monitoring/02-unit-test/configs/test_alerts.yml) в файл: `/etc/prometheus/test_alerts.yml`
* Запускаем тест

```bash
$ promtool test rules /etc/prometheus/test_alerts.yml        
```
В результате вы должны получить
```bash
Unit Testing:  test_alerts.yml
  SUCCESS

```
