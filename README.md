# bbfone

Install on baby's pi:
---------------------

- Install git

```
sudo apt-get install git
```

- Clone this repo

```
git clone https://github.com/v4l3ri4n/bbfone ~/bbfone
```
    
- Make install script executable

```
sudo chmod +x ~/bbfone/bbfone-diffuser_install.sh
```

- Customize variables in the install scripts

- Execute bbfone-diffuser_install.sh

```
sudo ~/bbfone/bbfone-diffuser_install.sh

- Reboot

Install on daddy's pi:
----------------------

- Install git

```
sudo apt-get install git
```

- Clone this repo

```
git clone https://github.com/v4l3ri4n/bbfone ~/bbfone
```
    
- Make install script executable

```
sudo chmod +x ~/bbfone/bbfone-receiver_install.sh
```

- Customize variables in the install scripts

- Configure baby's room pi IP in bbfone-recevier.sh

- On parent's room pi, execute bbfone-receiver.sh

```
sudo ~/bbfone/bbfone-receiver_install.sh
```

- Reboot