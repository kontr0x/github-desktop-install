#!/bin/bash
script_version="1.0.0"

release_url="https://github.com/shiftkey/desktop/releases/latest"
installed=0
installed_version="n.A."
architecture=$(uname -m)
mode="install"
verbose=0

print_usage() {
  printf """Usage: bash ./installGitHubDesktop.sh [OPTION]...
  -m [install|uninstall] \t Set the mode of the script
  -v \t\t\t\t Enable verbose mode
  -h \t\t\t\t Display this help and exit \n"""
}

while getopts 'm:vVh' flag; do
  case "${flag}" in
    m) mode="${OPTARG}" ;;
    v) verbose=1 ;;
    V) echo "Script version:" ${script_version} & exit 0 ;;
    h|*) print_usage
       exit 1 ;;
  esac
done

if [ $mode != "install" ] && [ $mode != "uninstall" ]; then
  echo "Invalid mode!"
  print_usage
  exit 1
fi

echo "Starting $mode script..."

if [ $verbose -eq 1 ]; then
  echo "% Verbose mode enabled"
fi

if [ -x "$(command -v dpkg)" ]; then
  package_manager="deb"
  if [[ $(dpkg -s "github-desktop" 2> /dev/null | grep "Status:") == "Status: install ok installed" ]]; then
    installed=1
    installed_version=$(dpkg -s github-desktop | grep -o -E "Version: [0-9.]*-linux[0-9]*" | head -n 1 | grep -o -E "[0-9.]*\.[0-9]")
  fi
elif [ -x "$(command -v rpm)" ]; then
  package_manager="rpm"
  if rpm -q github-desktop &> /dev/null; then
    installed=1
    installed_version=$(rpm -q github-desktop | grep -o -E "[0-9.]*\.[0-9]")
  fi
else
  package_manager="AppImage"
fi

if [[ "$architecture" == *"x86_64"* ]] && [[ "$package_manager" == *"deb"* ]]; then
  architecture="amd64"
fi

if [ $verbose -eq 1 ]; then
  echo "% Architecture: $architecture"
  echo "% Package manager: $package_manager"
  echo "% Installed: $installed"
fi

# Checking if github.com is reachable
ping github.com -c 1 > /dev/null || (echo "Can't reach github.com" & exit 1)

# Caching the source of the release page, to avoid multiple requests. Thus the script is faster.
github_repo_release_source="$(curl -sL $release_url)"
# Extract the link which contains the actual download links
expanded_assets_url=$(grep -o -E "https:\/\/github.com\/shiftkey\/desktop\/releases\/expanded_assets\/release-[0-9.]*-linux[0-9]*" <<< $github_repo_release_source 2> /dev/null)

# Check if the script could crep the assets url
if [ -z ${expanded_assets_url} ]; then 
  echo "Could not get assets url" & exit 1
fi

if [ $verbose -eq 1 ]; then
  echo "% Assets url: $expanded_assets_url"
fi

if [[ $installed -eq 1 ]]; then
  echo GitHub desktop is installed \($installed_version\)

  if [ $mode == "install" ]; then 
    available_version=$(grep -o -E "[0-9.]*\.[0-9]" <<< $expanded_assets_url)

    installed_major_version=$(awk -F  '.' '{print $1}' <<< $installed_version)
    installed_minor_version=$(awk -F  '.' '{print $2}' <<< $installed_version)
    installed_patch_version=$(awk -F  '.' '{print $3}' <<< $installed_version)

    available_major_version=$(awk -F  '.' '{print $1}' <<< $available_version)
    available_minor_version=$(awk -F  '.' '{print $2}' <<< $available_version)
    available_patch_version=$(awk -F  '.' '{print $3}' <<< $available_version)

    if [ $verbose -eq 1 ]; then
      echo "% Installed version: $installed_major_version.$installed_minor_version.$installed_patch_version"
      echo "% Available version: $available_major_version.$available_minor_version.$available_patch_version"
    fi

    if [ $available_major_version -gt $installed_major_version ] || \
        [ $available_major_version -ge $installed_major_version -a $available_minor_version -gt $installed_minor_version ] || \
        [ $available_major_version -ge $installed_major_version -a $available_minor_version -ge $installed_minor_version -a $available_patch_version -gt $installed_patch_version ]; then
      echo "An update to version $available_version is available!"

      echo -ne "Do you want to update? (y/n) "
      while read choice; do
        case "$choice" in
          y|Y ) echo "Starting update!" && break ;;
          n|N ) echo "Have a nice day!" & exit 0 ;;
          * ) echo -ne "Invalid input!\nPlease enter the correct input: " ;;
        esac
      done

    else
      echo "No update available!"
      exit 0
    fi
  fi
  echo -ne "Uninstalling the present GitHub desktop version, do you want to continue? (y/n) "
  while read choice; do
    case "$choice" in
      y|Y ) echo "Uninstalling GitHub desktop..." && break ;;
      n|N ) echo "Have a nice day!" & exit 0 ;;
      * ) echo -ne "Invalid input!\nPlease enter the correct input: " ;;
    esac
  done

  printf "\n"
  if [ $package_manager == "deb" ]; then
    sudo dpkg --purge github-desktop
    echo "Uninstall complete!"
  elif [ $package_manager == "rpm" ]; then
    sudo rpm -e github-desktop
    echo "Uninstall complete!"
  else
    echo "Uninstalling the AppImage is not supported! Please delete the file manually!"
    exit 1
  fi
fi

printf "\n"

download_url="/shiftkey/desktop/releases/download/$(grep -o -E "release-[0-9.]*-linux[0-9]*" <<< $expanded_assets_url)/GitHubDesktop-linux-$architecture-$(grep -o -E "[0-9.]*-linux[0-9]*" <<< $expanded_assets_url).$package_manager"

if [ $verbose -eq 1 ]; then
  echo "% Download URL: $download_url"
fi

filename=$(grep -o -E "GitHubDesktop-linux-$architecture-[0-9.]*-linux[0-9]*\.[a-zA-Z]{3,8}" <<< $download_url)

if [ ! -f "$(pwd)/$filename" ] && [ $mode == "install" ]; then
  echo "Downloading $filename ..."
  curl -LOJ https://github.com$download_url --progress-bar
  echo "Download complete!"
elif [ $mode == "uninstall" ]; then
  if [ $installed -eq 0 ]; then
    echo "GitHub desktop is not installed!"
  fi
  echo "Have a nice day!" & exit 0
else
  echo "$filename already exists, skipping download! Checking for integrity..."
  checksum="$(curl -sL https://github.com$(curl -sL $expanded_assets_url | grep -o -E "\/shiftkey\/desktop\/releases\/download\/release-[0-9.]*-linux[0-9]*\/GitHubDesktop-linux-$architecture-.*-linux[0-9]*\.$package_manager.sha[0-9]*" 2> /dev/null))"
  checksum_file="$(sha256sum ./$filename | grep -o -E "[a-zA-Z0-9]{64}")"

  if [ $verbose -eq 1 ]; then
    echo "% Checksum repo: $checksum"
    echo "% Checksum file: $checksum_file"
  fi

  if [[ $checksum_file != $checksum ]];then
    echo -ne "Checksum mismatch! Removing the file, do you want to continue? (y/n) "
    while read choice; do
      case "$choice" in
        y|Y ) (rm $(pwd)/$filename && echo "File removed, restart the script!") & exit 0 ;;
        n|N ) echo "Please remove the local file and restart the script!" & exit 1 ;;
        * ) echo -ne "Invalid input!\nPlease enter the correct input: " ;;
      esac
    done
  else
    echo "Checksum matches!"
  fi

fi

if [ ! -f "$(pwd)/$filename" ]; then
  echo "$filename does not exist, check your permissions!"
  exit 1
fi

echo -ne "Should the package be installed? (y/n) "
while read choice; do
  case "$choice" in
    y|Y ) break ;;
    n|N ) echo "Have a nice day!" & exit 0 ;;
    * ) echo -ne "Invalid input!\nPlease enter the correct input: " ;;
  esac
done

printf "\n"

if [ $package_manager == "deb" ]; then
  echo "Installing package, this requires sudo privileges!"
  sudo dpkg -i $(pwd)/$filename && echo "Package installed successfully"
elif [ $package_manager == "rpm" ]; then
  echo "Installing package, this requires sudo privileges!"
  sudo rpm -i $(pwd)/$filename && echo "Package installed successfully"
else
  echo "Adding execute permissions on AppImage"
  chmod +x $(pwd)/$filename && echo "The app can now be started by execute the AppImage"
fi

if [[ $package_manager != "AppImage" ]];then
  echo -ne "Clean up downloaded file? (y/n) "
  while read choice; do
    case "$choice" in
      y|Y ) (rm $(pwd)/$filename && echo "File cleaned up!") && break ;;
      n|N ) echo "The script will not clean up any files!" && break ;;
      * ) echo -ne "Invalid input!\nPlease enter the correct input: "  ;;
    esac
  done
fi

echo "Thank you for using the script, have a nice day!"
exit 0
