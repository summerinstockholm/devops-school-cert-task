# devops-school-cert-task

## Сертификационное задание для Школы Девопс

[https://devops-school.ru/devops_engineer.html](https://devops-school.ru/devops_engineer.html)

Jenkins паплайн который создает и развертывает веб-приложение на ресурсах AWS EC2. Первый экземпляр создает его, второй запускает веб-приложение на Python.

## Описание стадий пайплайна Jenkins

### Деплой

* 0 - Jenkins извлекает этот репозиторий c гита и обрабатывает Jenkinsfile.
* 1 - Через Terraform деплоим инфру на AWS EC2. Поднимаем два инстанса для билда и собственно самого веб-сервера.
* 2 - Конфигуриуем поднятые инстансы через Ansible.
* 3 - Через Docker билдим приложение на инстансе для билда.
* 4 - Пушим полученный артефакт в AWS ECR repository.
* 5 - Чистим контейнеры Docker на экземпляре веб-сервера.
* 6 - Docker пуллит артефакт из AWS ECR репозитория и стартует его.

## Файлы

* *Jenkinsfile* пайплайн
* *\*.tf* Terraform файлы
* *prepare-instances.yml* Ansible плейбук
* *Dockerfile, app.py, requirements.txt* Python-web-приложение

## Инструкция

1. Установить **aws cli**, **terraform**, **ansible**, **Jenkins** (c плагинами)
2. Сгенерировать ключи и заимпортить их в AWS EC2.

    ```bash
    ssh-keygen -t rsa -C "aws-ec2-key" -f ~/.ssh/aws-ec2-key
    aws ec2 import-key-pair --key-name devops-school-cert-task-key \
        --public-key-material fileb://~/.ssh/aws-ec2-key.pub
    ```

3. Создадим ECR репу для хранения артефактов

    ```bash
    aws ecr create-repository --repository-name cert_task
    ```

4. Создадим Jenkins джобу

   Dashboard -> New job -> type Pipeline, name *devops-school-cert-task*  
   Pipeline Definition: Pipeline script from SCM, Git  
   Repository URL: [https://github.com/summerinstockholm/devops-school-cert-task](https://github.com/summerinstockholm/devops-school-cert-task)

5. Создадим креды SSH в Jenkins

   Kind: SSH Username with private key  
   ID: *AWS_UBUNTU_INSTANCE_SSH_KEY*  
   Username: *ubuntu*  
   Key:

    ```bash
    cat ~/.ssh/aws-ec2-key
    ```

6. Создадим креды для AWS EC2 в Jenkins

   Kind: SSH Username with private key  
   ID: *AWS_ECR_CREDENTIALS*
   Username: *AWS*  
   Password:

    ```bash
    aws ecr get-login-password
    ```

7. Создадим креды для AWS API в Jenkins

   Kind: Secret text  
   ID: *AWS_ACCESS_KEY_ID*  
   Secret: \<Your AWS Access Key ID\>  

   Kind: *Secret text*  
   ID: *AWS_SECRET_ACCESS_KEY*  
   Secret: \<AWS Secret Access Key\>  

8. Стартуем Jenkins джобу:

    ```bash
    java -jar jenkins-cli.jar build -v -f devops-school-cert-task \
        -p autoApprove=true -p appVersion=1.0 \
        -p ecrHost=657846124098.dkr.ecr.eu-central-1.amazonaws.com
    ```

9. Проверяем все ли работает через curl:

    ```bash
    cutl http://curl http://<host name>.<region>.compute.amazonaws.com
    ```