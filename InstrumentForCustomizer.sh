#!/bin/bash
#
# Instrumentalization
#

#
# Getting user password fron plain text inside home directory
#
export var_manual_sudopsw=$(cat ~/.psw)
#
# Some vaiables to use
#
export dconfdir=/org/gnome/terminal/legacy/profiles:

function create_new_profile() {
    local profile_ids
    profile_ids=$(dconf list $dconfdir/ | grep ^: | sed 's/\///g' | sed 's/://g')
    local profile_name
    profile_name="$1"
    local profile_ids_old
    profile_ids_old="$(dconf read "$dconfdir"/list | tr -d "]")"
    local profile_id
    profile_id="$(uuidgen)"

    [ -z "$profile_ids_old" ] && local profile_ids_old="["  # if there's no `list` key
    [ ${#profile_ids[@]} -gt 0 ] && local delimiter=,  # if the list is empty
    dconf write $dconfdir/list "${profile_ids_old}${delimiter} '$profile_id']"
    dconf write "$dconfdir/:$profile_id"/visible-name "'$profile_name'"
    echo $profile_id
}

function get_profile_uuid() {
    # Print the UUID linked to the profile name sent in parameter
    local profile_ids
    profile_ids=($(dconf list $dconfdir/ | grep ^: | sed 's/\///g' | sed 's/://g'))
    local profile_name
    profile_name="$1"
    for i in ${!profile_ids[*]}; do
        if [[ "$(dconf read $dconfdir/:${profile_ids[i]}/visible-name)" == \
            "'$profile_name'" ]]; then
            echo "${profile_ids[i]}"
            return 0
        fi
    done
}

function check_for_root_user () {
if [ "$EUID" -eq 0 ]; then
  return 0
else
  return 1
fi
}

function is_app_installed () {
  local was_found
  was_found=$(apt list --installed $1 2>&1 | grep $1 | wc -l)
  if [[ $was_found -gt 0 ]]; then
    return 0
  else
    return 1
  fi
}

function is_flatpak_installed () {
  local was_found
  was_found=$(flatpak list | grep $1 | wc -l)
  if [[ $was_found -gt 0 ]]; then
    return 0
  else
    return 1
  fi
}

function is_snap_installed () {
  local was_found
  was_found=$(snap list | grep $1 | wc -l)
  if [[ $was_found -gt 0 ]]; then
    return 0
  else
    return 1
  fi
}

function clean_my_system () {
    echo "#"
    echo "# Cleaning too many dependencies off unnecessary resources"
    echo "#"
    echo "$var_manual_sudopsw" | sudo -S apt clean -y
    echo "$var_manual_sudopsw" | sudo -S apt autoclean -y
    echo "$var_manual_sudopsw" | sudo -S apt autoremove -y
    echo "$var_manual_sudopsw" | sudo -S apt update
    echo "$var_manual_sudopsw" | sudo -S apt upgrade
}

function all_keys_from_all_children_from_all_schemas () {
  for current_schema in $(gsettings list-schemas); do
    for current_children in $(gsettings list-children $current_schema); do
      for current_key in $(gsettings list-keys $current_children 2>/dev/null); do
        if [ $? -eq 0 ]; then
          echo "$current_schema"' ---> '"$current_children"' key: '"$current_key"' Descript: '"$(gsettings describe "$current_children" "$current_key" 2>/dev/null)"
        else
          echo 'ERR'
        fi
      done
    done
  done
}