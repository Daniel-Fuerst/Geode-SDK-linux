#!/bin/bash

function mainMenu() {
HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=4
TITLE="GeodeSDK Linux"
MENU="What do you want to do?"

OPTIONS=(1 "Patch"
         2 "Unpatch" )

CHOICE=$(dialog --clear \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
        1)
            patchSteamLaunchOptions
            ;;
        2)
            unPatchSteamLaunchOptions
            ;;
esac
clear
exit 0
}

function patchSteamLaunchOptions() {
    dialog --title "Input Path" \
           --inputbox "Please enter the path with GD installed:" 8 40 2> path.txt

    local gd_installation_path=$(<path.txt)
    rm path.txt

    notify-send $gd_installation_path
    cd "$gd_installation_path"
    files=$(ls -r | grep -i XInput)
    xinputvar=$(echo "$files" | tr '[:upper:]' '[:lower:]' | sed 's/\.dll//')
    text_to_delete='"LaunchOptions"'
    CONFIG_FILES=~/.local/share/Steam/userdata/*/config/localconfig.vdf
    for file in "${CONFIG_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            sed -i "/$text_to_delete/d" "$file"
            echo "Deleted lines containing '$text_to_delete' from $file."
        else
            echo "File '$file' does not exist or is not accessible."
        fi
    done

GAME_ID='"322170"'
INSERT_LINE='                        "LaunchOptions"		"WINEDLLOVERRIDES=\\"'"$xinputvar"'=n,b\\" %command%"'

for file in $CONFIG_FILES; do
    if [[ -f $file ]]; then
        cp "$file" "$file.bak"

        awk -v game_id="$GAME_ID" -v insert="$INSERT_LINE" '
        BEGIN { inside_block = 0; found_game_id = 0; }
        {
            if (!found_game_id && inside_block && $0 ~ /^[ \t]*}$/) {
                printf "%s\n", insert;
                inside_block = 0;
                found_game_id = 1;
            }
            if ($0 ~ game_id) {
                inside_block = 1;
            }
            print $0;
        }
        END {
            if (!found_game_id) {
                print insert;
            }
        }' "$file" > temp && mv temp "$file"
        
        echo "Done inserting lines in $file."
        break
    fi
done
}

mainMenu
