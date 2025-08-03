# ieblan (IPTables Enhanced Blocking Layer for Android Network)

This project is not finished yet, and i'm not sure how frequently i'll be updating it. Also, keep in mind that i'm doing it mostly for myself, so please lower your expectations.
## What is this?

For now, this is just a simple script for blocking internet connection for specific apps on android based on their UIDS (or AIDS). 
https://source.android.com/docs/security/app-sandbox


## Requirements

- iptables binary
- rooted device
- terminal emulator (something like termux)
## How to run it 

You just need to clone this repository and create an additional file which will contain apps (package names) that you want to block an internet access to. Applications must be separated by a newline.
An example file will look something like this:
```
com.whatsapp
org.videolan.vlc
com.termux
``` 

Then you just specify the mode you want to run this script in and the path to this file:

```bash 
sudo ruby block.rb --mode=block --file=targets
```

There are just two modes: "block" and "unblock"

## Demo
https://github.com/user-attachments/assets/7e8436d8-cedb-49b9-9257-1e355f68e5b5

