# GitHub desktop installation script

This script will download the most recent GitHub desktop version for your Linux and, if desired, has the ability to install it as well. 
If your system does not use deb or rpm packages, it will fall back to the available AppImage.

## Usage
The installation script will be downloaded with curl and afterward executed.
| Tool | Command                                                                                                                        |
|:-----|:-------------------------------------------------------------------------------------------------------------------------------|
| curl | `bash -c "$(curl -fsSL https://raw.githubusercontent.com/kontr0x/github-desktop-install/main/installGitHubDesktop.sh)" `       |
| wget | `bash -c "$(wget -O- https://raw.githubusercontent.com/kontr0x/github-desktop-install/main/installGitHubDesktop.sh)"`          |

### Manuel execution
It is always a good idea to inspect the script you are getting from the internet. 
Please feel free to first inspect the script and execute the script manually with bash.
```bash
# --------------------
# curl method
curl -fsSL https://raw.githubusercontent.com/kontr0x/github-desktop-install/main/installGitHubDesktop.sh -o installGitHubDesktop.sh
# wget method
wget https://raw.githubusercontent.com/kontr0x/github-desktop-install/main/installGitHubDesktop.sh
# --------------------
bash ./installGitHubDesktop.sh
```

Tested the script on:
- Ubuntu 22.04.2 LTS
- Fedora 37 Workstation
- Mint 21

The project came to life as a result of [berkorbay](https://gist.github.com/berkorbay)'s presumably discontinued gist page, which can be viewed [here](https://gist.github.com/berkorbay/6feda478a00b0432d13f1fc0a50467f1).

The script will be updated to remove all the todos. Please feel free to contribute.
