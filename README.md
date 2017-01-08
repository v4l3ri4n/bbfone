# bbfone

Install :
---------

1. Install git

```
sudo apt-get install git
```

2. Clone this repo

```
git clone https://github.com/v4l3ri4n/bbfone ~/bbfone
```
    
3. Make install scripts executable

```
sudo chmod +x ~/bbfone/bbfone-diffuser_install.sh
sudo chmod +x ~/bbfone/bbfone-receiver_install.sh
```

4. Customize variables in the install scripts

5. Configure baby's room pi ip in bbfone-recevier.sh

6. On baby's room pi, execute bbfone-diffuser_install.sh

```
sudo ~/bbfone/bbfone-diffuser_install.sh
```

7. On parent's room pi, execute bbfone-receiver.sh

```
sudo ~/bbfone/bbfone-receiver_install.sh
```

8. Reboot