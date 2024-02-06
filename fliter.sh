#!/bin/bash
# from
# https://github.com/oneclickvirt/pve_lxc_images

url="http://download.proxmox.com/images/system/"
images=()
# fixed_images=($(curl -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/oneclickvirt/pve_lxc_images/releases/tags/images" | grep -oP '"name": "\K[^"]+' | grep -v "images" | awk 'NR%2==1' | sed 's/_amd64\..*//'))
fixed_images=(
"centos-7-default_20171212_amd64.tar.zst"
"centos-7-default_20190926_amd64.tar.zst"
"centos-8-stream-default_20220327_amd64.tar.zst"
"centos-9-stream-default_20221109_amd64.tar.zst"
"debian-10-standard_10.7-1_amd64.tar.zst"
"debian-10.0-standard_10.0-1_amd64.tar.zst"
"debian-11-standard_11.0-1_amd64.tar.zst"
"debian-11-standard_11.3-0_amd64.tar.zst"
"debian-11-standard_11.3-1_amd64.tar.zst"
"debian-11-standard_11.6-1_amd64.tar.zst"
"debian-11-standard_11.7-1_amd64.tar.zst"
"debian-12-standard_12.0-1_amd64.tar.zst"
"debian-12-standard_12.2-1_amd64.tar.zst"
"debian-6.0-standard_6.0-7_amd64.tar.zst"
"debian-7.0-standard_7.11-1_amd64.tar.zst"
"debian-8.0-standard_8.11-1_amd64.tar.zst"
"debian-8.0-standard_8.6-1_amd64.tar.zst"
"debian-8.0-standard_8.7-1_amd64.tar.zst"
"debian-9.0-standard_9.0-2_amd64.tar.zst"
"debian-9.0-standard_9.3-1_amd64.tar.zst"
"debian-9.0-standard_9.5-1_amd64.tar.zst"
"debian-9.0-standard_9.7-1_amd64.tar.zst"
"devuan-4.0-standard_4.0_amd64.tar.zst"
"rockylinux-8-default_20210929_amd64.tar.zst"
"rockylinux-9-default_20221109_amd64.tar.zst"
"ubuntu-14.04-standard_14.04-1_amd64.tar.zst"
"ubuntu-14.04-standard_14.04.5-1_amd64.tar.zst"
"ubuntu-16.04-standard_16.04-1_amd64.tar.zst"
"ubuntu-16.04-standard_16.04.5-1_amd64.tar.zst"
"ubuntu-16.10-standard_16.10-1_amd64.tar.zst"
"ubuntu-17.04-standard_17.04-1_amd64.tar.zst"
"ubuntu-17.10-standard_17.10-1_amd64.tar.zst"
"ubuntu-18.04-standard_18.04-1_amd64.tar.zst"
"ubuntu-18.04-standard_18.04.1-1_amd64.tar.zst"
"ubuntu-18.10-standard_18.10-1_amd64.tar.zst"
"ubuntu-18.10-standard_18.10-2_amd64.tar.zst"
"ubuntu-19.04-standard_19.04-1_amd64.tar.zst"
"ubuntu-20.04-standard_20.04-1_amd64.tar.zst"
"ubuntu-20.10-standard_20.10-1_amd64.tar.zst"
"ubuntu-21.04-standard_21.04-1_amd64.tar.zst"
"ubuntu-21.10-standard_21.10-1_amd64.tar.zst"
"ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
"ubuntu-22.10-standard_22.10-1_amd64.tar.zst"
"ubuntu-23.04-standard_23.04-1_amd64.tar.zst"
"ubuntu-23.10-standard_23.10-1_amd64.tar.zst"
)
while IFS= read -r line; do
  fixed_image=false
  for fa in "${fixed_images[@]}"; do
    if [[ $line == *"$fa"* ]]; then
        fixed_image=true
        break
    fi
  done
  if [ "$fixed_image" == false ]; then
    if [[ ! $line =~ \.aplinfo && $line != '../' ]]; then
      images+=("$line")
    fi
  fi
done < <(curl -s "$url" | grep -oP '(?<=href=")[^"]+')
length=${#images[@]}
for image in "${images[@]}"; do
  echo "$image"
done
