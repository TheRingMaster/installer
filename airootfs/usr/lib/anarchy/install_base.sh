#!/usr/bin/env bash
###############################################################
### Anarchy Linux Install Script
### install_base.sh
###
### Copyright (C) 2017 Dylan Schacht
###
### By: Dylan Schacht (deadhead)
### Email: deadhead3492@gmail.com
### Webpage: https://anarchylinux.org
###
### Any questions, comments, or bug reports may be sent to above
### email address. Enjoy, and keep on using Arch.
###
### License: GPL v2.0
###############################################################

install_base() {

    op_title="$install_op_msg"
    base_install=$(<<<"$base_install" tr " " "\n" | sort | uniq | tr "\n" " ")
    pacman -Sy --print-format='%s' $(echo "$base_install") | awk '{s+=$1} END {print s/1024/1024}' >/tmp/size &
    pid=$! pri=0.6 msg="\n$pacman_load \n\n \Z1> \Z2pacman -Sy\Zn" load
    download_size=$(</tmp/size) ; rm /tmp/size
    export software_size=$(<<<"$download_size" sed 's/\(\..\)\(.*\)/\1 MiB/')
    cal_rate

    if [ $(wc -w <<<"$base_install") -gt "30" ]; then
        height="24"
    elif [ $(wc -w <<<"$base_install") -gt "25" ]; then
        height="20"
    elif [ $(wc -w <<<"$base_install") -gt "20" ]; then
        height="18"
    else
        height="16"
    fi

    until "$INSTALLED"
      do
        if (yesno "\n${install_var}" "${install}" "${cancel}"); then
            echo "$(date -u "+%F %H:%M") : Begin base install" >> "$log"

            if [ "$kernel" == "linux" ]; then
                base_install="$(pacman -Sqg base linux) $base_install"
            else
                base_install="$(pacman -Sqg base linux | sed 's/^linux$//') $base_install"
            fi

            (pacstrap "$ARCH" --overwrite $(echo "$base_install") ; echo "$?" > /tmp/ex_status) &>> "$log" &
            pid=$! pri=$(echo "$down" | sed 's/\..*$//') msg="\n$install_load_var" load_log

            genfstab -U -p "$ARCH" >> "$ARCH"/etc/fstab

            if [ $(</tmp/ex_status) -eq "0" ]; then
                INSTALLED=true
                echo "$(date -u "+%F %H:%M") : Install Complete" >> "$log"
                echo "$(date -u "+%F %H:%M") : Generate fstab:\n$(<$ARCH/etc/fstab)" >> "$log"
            else
                msg "\n${failed_msg}"
                echo "$(date -u "+%F %H:%M") : Install failed: please report to developer" >> "$log"
                reset ; tail "$log" ; exit 1
            fi

            case "${bootloader}" in
                grub) grub_config ;;
                syslinux) syslinux_config ;;
                systemd-boot) systemd_config ;;
                efistub) efistub_config ;;
                refind) refind_config ;;
            esac

            echo "$(date -u "+%F %H:%M") : Configured bootloader: $bootloader" >> "$log"
        else
            if (yesno "\n${exit_msg}" "${yes}" "${no}"); then
                unset base_install DE
                desktop=false
                main_menu
            fi
        fi
    done

}

# vim: ai:ts=4:sw=4:et
