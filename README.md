# bbfone

Second version based on UDP streaming with gstreamer

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
```

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

- Execute bbfone-receiver_install.sh

```
sudo ~/bbfone/bbfone-receiver_install.sh
```

- Reboot

Usefull links:
--------------

https://jerous.org/2014/05/06/network-sound
http://blog.nicolargo.com/gstreamer
https://delog.wordpress.com/2011/05/11/audio-streaming-over-rtp-using-the-rtpbin-plugin-of-gstreamer/