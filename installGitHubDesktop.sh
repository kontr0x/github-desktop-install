#!/bin/bash

installed=0
installed_version="n.A."

if [ -x "$(command -v dpkg)" ]; then
  package_manager="deb"
  if dpkg -s "github-desktop" &> /dev/null; then
    installed=1
    installed_version=$(dpkg -s github-desktop | grep -o -E "Version: [0-9.]*-linux1" | head -n 1 | grep -o -E "[0-9.]*\.[0-9]")
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

if [ $installed -eq 1 ]; then
  echo Another version of Github desktop is already installed \($installed_version\)
  exit 0
  # TODO: implement update functionality
else
  release_url="https://github.com/shiftkey/desktop/releases/latest"
  
  # Extract the link which contains the actual download links
  expanded_assets_url=$(curl -sL $release_url | grep -o -E "https:\/\/github.com\/shiftkey\/desktop\/releases\/expanded_assets\/release-[0-9.]*-linux1")
  
  download_url=$(curl -sL $expanded_assets_url | grep -o -E "\/shiftkey\/desktop\/releases\/download\/release-[0-9.]*-linux1\/GitHubDesktop-linux-.*-linux1\.$package_manager")
  
  filename=$(grep -o -E "GitHubDesktop-linux-[0-9.]*-linux1\.[a-zA-Z]{3,8}" <<< $download_url)
  
  if [ ! -f "$(pwd)/$filename" ]; then
    echo "Downloading $filename ..."
    curl -sLOJ https://github.com$download_url
    echo "Download complete!"
  else
    echo "$filename already exists, skipping download!"
  fi

  if [ ! -f "$(pwd)/$filename" ]; then
    echo "$filename does not exist, check your permissions!"
    exit 1
  fi
  
  echo -n "Should the package be installed? (y/n) "
  
  while read choice; do
    case "$choice" in
      y|Y ) :;;
      n|N ) exit 0;;
      * ) echo -ne "Invalid input!\nPlease enter the correct input: ";;
    esac
  done
  
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
fi

exit 0

