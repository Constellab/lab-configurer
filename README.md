<p align="center">
  <img src="https://constellab.space/assets/fl-logo/constellab-logo-text-white.svg" alt="Constellab Logo" width="80%">
</p>

<br/>

# 👋 Welcome to lab server

This repository contains the files and script to configure a lab server.

## 🚀 What is Constellab?

✨ [Gencovery](https://gencovery.com/) is a software company that offers [Constellab](https://constellab.io)., the leading open and secure digital infrastructure designed to consolidate data and unlock its full potential in the life sciences industry. Gencovery's mission is to provide universal access to data to enhance people's health and well-being.

🌍 With our Fair Open Access offer, you can use Constellab for free. [Sign up here](https://constellab.space/). Find more information about the Open Access offer here (link to be defined).

## Lab deployement

### Init

Connect into the constellab (prod or pre-prod) and create a new lab instance with the correct information and the keys and token empty (they will be generated)

### SSH in lab

To deploy a lab, connect into the server in ssh.

 1. ```cd ~```
 2. ```git clone https://github.com/Constellab/lab-configurer.git```
 3. ```cd lab-configurer/utils```
 4. ```bash prepare_server.sh```
 5. Reboot server ```sudo reboot```
 6. Relog and go to lab-configurer ```cd ~/lab-configurer```
 7. ```sudo bash utils/init.sh```
 8. Logout and login for the env variable to be set, then ```cd ~/lab-configurer```
 9. Start the lab manager and reverse proxy. In lab-configurer folder ```docker compose up -d```

### Config in Constellab

Log into the constellab (prod or pre-prod). open the lab created ealier.
There should be 2 containers running :

- Lab manager
- Rever proxy

The status should be containers down.

Configure the lab by adding the necessary bricks. ```gws_core``` and ```gws_biota``` are mandatory.

Clic on ```INIT ALL```. Refresh regularly and the lab should be up after some time.

That's it

## Lab dev environment

This environment is useful to develop within the lab locally. At gencovery we mainly use it to work on the gws_core brick. 

To start this dev environment container folow the steps below.

Create external volume for lab manager (required in the docker-compose file) :

``` bash
docker volume create dev-env-app
docker volume create dev-env-data
docker volume create dev-env-logs
docker volume create lab-manager-home
docker volume create space-db
docker volume create community-db
docker volume create lab-db
docker volume create lab-manager-app
docker volume create lab-manager-biota
docker volume create lab-manager-prod-db
docker volume create lab-manager-dev-db
docker volume create lab-manager-prod-lab
docker volume create lab-manager-prod-data
docker volume create lab-manager-dev-lab
docker volume create lab-manager-dev-data
docker volume create lab-manager-config
```

To create the containers :

 1. create a ```.env``` file in the local folder with ```OPENAI_API_KEY```
 2. [Optional] modify the ```config-file.json``` file in the local folder with the brick you want to install. You can install the brick manually later directly in the lab.
 3. execute the docker-compose file under local folder : ```docker compose --env-file ./.env up -d```

The lab dev environment image is define here : <https://hub.docker.com/repository/docker/constellab/lab-dev-env/general>. If you want to build the lab dev env image see gpm repository.

## Dev environment lab manager

In lab manager folder exec : ```docker build -t local-lab-manager .```

execute the docker-compose file under local folder : ```docker compose --env-file ./.env up -d lab-manager-dev-env```

Pull the code of lab manager in the /home folder (saved in volume)

## Desktop

To build the executable to is used to configure and run the lab on desktop, do the following :

 1. ```pip install pyinstaller```
 2. ```pip install requests```
 3. ```pyinstaller --onefile .\desktop\desktop-start.py```

The result will be in the dist folder. To build exe for mac same command on mac.

## On premise

To deploy the lab on premise, the lab manager and the reverse proxy should be deployed on the server.
If the on premise lab is accessible from the internet, the default config can be used.

Otherwise the certificate must be generated manually and uploaded to the server so the reverse proxy can use it. In this can use the ```on-premise/docker-compose.yml``` file.

### Procedure to deploy an on premise lab not accessible by internet

1. Create the on premise lab in Constellab
2. Add your user to the lab
3. Generate the certificate
4. Connect to the server with ssh
5. Upload the certicifate to the server in the ```/certs``` folder. The certificate file should have read access by the default user. The files should be named :
   1. ```/certs/fullchain.pem```
   2. ```/certs/privkey.pem```
6. Execute the prepare_server.sh script in the lab-configurer/utils folder : ```sudo bash prepare_server.sh```
7. Reboot the server : ```sudo reboot```
8. Clone the lab-configurer repository in the home folder : ```git clone -b master https://github.com/Constellab/lab-configurer.git```
9. Go to the lab-configurer folder
10. Execute the init file to setup default environment variables ```sudo bash utils/init.sh``` .Info can be found in constellab.
11. Exit the session and reconnect to the server to have the environment variables set
12. Go to the lab-configurer folder
13. Start the lab manager and the reverse proxy ```docker compose -f on-premise/docker-compose.yml up -d```
14. Check that the certificate is correctly used by the reverse proxy, the request ```https://lab-manager.${VIRTUAL_HOST}/health-check``` should return true. This can be tester directly on the server or from the another server (or a browser) that can access the on premise lab.

Now the lab manager is ready and can be configured. If constellab server can access the lab thourgh HTTP, you can configurue the lab directly from the constellab. Otherwise see next section 'Configure the lab manager manually'.

### Configure the lab manager manually

1. Configure the brick of the lab
    1. Execute the following command : ```curl -X PUT -H "Authorization: api-key ${LAB_MANAGER_API_KEY}" -H "Content-Type: application/json" -d @config.json  https://lab-manager.${VIRTUAL_HOST}/lab/config```. Replace the values by the values set in the environment variables.
    2. You can find an example of the config file in the lab-configurer repository ```on-premise/config-file-example.json```
    3. The config.json file should be create in ```/app/config/config.json```.
2. Then start the lab
     1. Execute the following command : ```curl -X POST -H "Authorization: api-key ${LAB_MANAGER_API_KEY}" -H "Content-Type: application/json" -d @lab.json https://lab-manager.${VIRTUAL_HOST}/lab/init-all```. Replace the values by the values set in the environment variables.
     2. You can find an example of the lab file in the lab-configurer repository ```on-premise/lab-file-example.json```
     3. Check the logs of the lab manager : ```docker logs lab-manager -f```. The lab should be starting, it can take some time. Once ready check the logs of the glab container to see if the lab is correctly started : ```docker logs glab -f```.
3. Test the lab connection by using your browser and connecting to the ```https://lab.${VIRTUAL_HOST}``` url. You should see the lab interface. Login with your constellab credentials.
     1. If the login doesn't work, check that you've added your user to the lab in the constellab. Once added you will need to restart the lab by calling the init-all endpoint again. You can check the glab logs to see if the user is correctly added with the message (after the start) : ```1 synchronized users from space```.

<br/>

This repository is maintained with ❤️ by [Gencovery](https://gencovery.com/).

<p align="center">
  <img src="https://framerusercontent.com/images/Z4C5QHyqu5dmwnH32UEV2DoAEEo.png?scale-down-to=512" alt="Gencovery Logo"  width="30%">
</p>