# Packer

**Цель:** Добавить к образу consul для динамичного опредения DB-хоста.

За основу возьмем образ собранный на предыдущем этапе.

Перейдем в каталог `5.3.Packer`, команда ниже представлена от корня репозитория
```bash
cd practice/5.iac/5.3_Packer
```

Запустим сборку из каталога 3.Packer
```bash
ln -s ../5.2_Packer/vars.json .

packer build -parallel=false -var-file=vars.json packer.json
```

Во время сборки можно изучить скрипты для установки консула

После успешной сборки 
```bash
==> Builds finished. The artifacts of successful builds are:
--> app-consul: An image was created: 0408cdf8-0d6d-42d6-a7d0-87c3518982fb
--> db-consul: An image was created: e972a460-6d66-4e1f-9d92-45225f4c53b2
```
Можно перейти к следующему шагу с терраформом, и с его помощью будем устанавливать сервера из образов.
