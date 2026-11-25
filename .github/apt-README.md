# Cubbyhole apt repository

This branch is written by the "Linux repository and checksums" workflow each time a release is
published. It holds only the signed index; the .deb files stay on the releases.

Installing the Cubbyhole .deb sets this up for you. To add it by hand on Debian, Ubuntu or Linux Mint:

```
sudo curl -fsSLo /usr/share/keyrings/cubbyhole-archive-keyring.asc https://github.com/semicolonconsulting/cubbyhole-release/raw/apt/cubbyhole-archive-key.asc && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cubbyhole-archive-keyring.asc] https://github.com/semicolonconsulting/cubbyhole-release raw/apt/" | sudo tee /etc/apt/sources.list.d/cubbyhole.list && sudo apt update && sudo apt install cubbyhole
```
