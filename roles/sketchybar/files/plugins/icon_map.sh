#!/bin/bash

# This script maps application names to their corresponding icons
# It's used by other plugins to display the appropriate icon for each app

__icon_map() {
  case "$1" in
    "1Blocker- Ad Blocker & Privacy" | "1Blocker" | "1Blocker: Ad Blocker & Privacy")
      echo ":1blocker:"
      ;;
    "1Password 7 - Password Manager" | "1Password")
      echo ":1password:"
      ;;
    "2Do")
      echo ":2do:"
      ;;
    "Activity Monitor")
      echo ":activity_monitor:"
      ;;
    "AdBlock Pro")
      echo ":adblock_pro:"
      ;;
    "Adobe Acrobat Reader DC")
      echo ":adobe_acrobat:"
      ;;
    "Adobe After Effects 2020" | "Adobe After Effects 2021" | "Adobe After Effects 2022" | "Adobe After Effects 2023")
      echo ":adobe_after_effects:"
      ;;
    "Adobe Illustrator")
      echo ":adobe_illustrator:"
      ;;
    "Adobe Lightroom")
      echo ":adobe_lightroom:"
      ;;
    "Adobe Photoshop 2020" | "Adobe Photoshop 2021" | "Adobe Photoshop 2022" | "Adobe Photoshop 2023")
      echo ":adobe_photoshop:"
      ;;
    "Adobe Premiere Pro 2020" | "Adobe Premiere Pro 2021" | "Adobe Premiere Pro 2022" | "Adobe Premiere Pro 2023")
      echo ":adobe_premiere_pro:"
      ;;
    "AirBuddy")
      echo ":airbuddy:"
      ;;
    "Amphetamine")
      echo ":amphetamine:"
      ;;
    "Android Studio")
      echo ":android_studio:"
      ;;
    "App Store")
      echo ":app_store:"
      ;;
    "AppShelf")
      echo ":appshelf:"
      ;;
    "Arc")
      echo ":arc:"
      ;;
    "Archiver 4")
      echo ":archiver_4:"
      ;;
    "Asana")
      echo ":asana:"
      ;;
    "Atom")
      echo ":atom:"
      ;;
    "Audacity")
      echo ":audacity:"
      ;;
    "Backup and Sync from Google")
      echo ":backup_and_sync:"
      ;;
    "Bezel • Phone Mirror")
      echo ":bezel:"
      ;;
    "Brave Browser")
      echo ":brave_browser:"
      ;;
    "Calculator")
      echo ":calculator:"
      ;;
    "Calendar")
      echo ":calendar:"
      ;;
    "Canva")
      echo ":canva:"
      ;;
    "ChatGPT")
      echo ":chatgpt:"
      ;;
    "Chrome")
      echo ":google_chrome:"
      ;;
    "CleanMyMac X")
      echo ":cleanmymac:"
      ;;
    "CleanMyMac X Business")
      echo ":cleanmymac:"
      ;;
    "Code")
      echo ":visual_studio_code:"
      ;;
    "Contacts")
      echo ":contacts:"
      ;;
    "Dash")
      echo ":dash:"
      ;;
    "DataGrip")
      echo ":datagrip:"
      ;;
    "Discord")
      echo ":discord:"
      ;;
    "Docker Desktop")
      echo ":docker:"
      ;;
    "Dropbox")
      echo ":dropbox:"
      ;;
    "Elytra")
      echo ":elytra:"
      ;;
    "Facetime")
      echo ":facetime:"
      ;;
    "Figma")
      echo ":figma:"
      ;;
    "Final Cut Pro")
      echo ":final_cut_pro:"
      ;;
    "Finder")
      echo ":finder:"
      ;;
    "Firefox")
      echo ":firefox:"
      ;;
    "Franz")
      echo ":franz:"
      ;;
    "GIMP")
      echo ":gimp:"
      ;;
    "GitHub Desktop")
      echo ":github_desktop:"
      ;;
    "GitKraken")
      echo ":gitkraken:"
      ;;
    "Google Chrome")
      echo ":google_chrome:"
      ;;
    "Google Drive")
      echo ":google_drive:"
      ;;
    "IINA")
      echo ":iina:"
      ;;
    "Insomnia")
      echo ":insomnia:"
      ;;
    "Instagram")
      echo ":instagram:"
      ;;
    "IntelliJ IDEA")
      echo ":intellij_idea:"
      ;;
    "Itsycal")
      echo ":itsycal:"
      ;;
    "iTerm")
      echo ":iterm2:"
      ;;
    "Keka")
      echo ":keka:"
      ;;
    "Keynote")
      echo ":keynote:"
      ;;
    "KeePassXC")
      echo ":keepassxc:"
      ;;
    "Linear")
      echo ":linear:"
      ;;
    "Logic Pro X")
      echo ":logic_pro_x:"
      ;;
    "Logitech G HUB")
      echo ":logitech_g_hub:"
      ;;
    "LoopBack")
      echo ":loopback:"
      ;;
    "Mail")
      echo ":mail:"
      ;;
    "Maps")
      echo ":maps:"
      ;;
    "Microsoft Excel")
      echo ":microsoft_excel:"
      ;;
    "Microsoft PowerPoint")
      echo ":microsoft_powerpoint:"
      ;;
    "Microsoft Word")
      echo ":microsoft_word:"
      ;;
    "Minecraft")
      echo ":minecraft:"
      ;;
    "Music")
      echo ":music:"
      ;;
    "Neovim")
      echo ":neovim:"
      ;;
    "Netflix")
      echo ":netflix:"
      ;;
    "Notion")
      echo ":notion:"
      ;;
    "Notes")
      echo ":notes:"
      ;;
    "Numbers")
      echo ":numbers:"
      ;;
    "OBS Studio")
      echo ":obs:"
      ;;
    "OmniGraffle 7")
      echo ":omnigraffle:"
      ;;
    "OneDrive")
      echo ":onedrive:"
      ;;
    "Pages")
      echo ":pages:"
      ;;
    "Paw")
      echo ":paw:"
      ;;
    "Photos")
      echo ":photos:"
      ;;
    "Pixelmator Pro")
      echo ":pixelmator_pro:"
      ;;
    "Plex")
      echo ":plex:"
      ;;
    "Postman")
      echo ":postman:"
      ;;
    "Prism")
      echo ":prism:"
      ;;
    "PyCharm")
      echo ":pycharm:"
      ;;
    "Quill Chat")
      echo ":quill_chat:"
      ;;
    "Sol")
      echo ":sol:"
      ;;
    "Reminders")
      echo ":reminders:"
      ;;
    "Rider")
      echo ":rider:"
      ;;
    "Safari")
      echo ":safari:"
      ;;
    "Sequel Pro")
      echo ":sequel_pro:"
      ;;
    "Skype")
      echo ":skype:"
      ;;
    "Slack")
      echo ":slack:"
      ;;
    "Spotify")
      echo ":spotify:"
      ;;
    "Steam")
      echo ":steam:"
      ;;
    "Sublime Text")
      echo ":sublime_text:"
      ;;
    "System Preferences")
      echo ":system_preferences:"
      ;;
    "TablePlus")
      echo ":tableplus:"
      ;;
    "Terminal")
      echo ":terminal:"
      ;;
    "TextEdit")
      echo ":textedit:"
      ;;
    "The Unarchiver")
      echo ":the_unarchiver:"
      ;;
    "Toggl Track")
      echo ":toggl_track:"
      ;;
    "Transmit 5")
      echo ":transmit:"
      ;;
    "Trash (Full)")
      echo ":trash_full:"
      ;;
    "Trash (Empty)")
      echo ":trash_empty:"
      ;;
    "VLC")
      echo ":vlc:"
      ;;
    "Visual Studio Code")
      echo ":visual_studio_code:"
      ;;
    "Warp")
      echo ":warp:"
      ;;
    "WebStorm")
      echo ":webstorm:"
      ;;
    "WhatsApp")
      echo ":whatsapp:"
      ;;
    "Xcode")
      echo ":xcode:"
      ;;
    "Zoom")
      echo ":zoom:"
      ;;
    "alacritty")
      echo ":alacritty:"
      ;;
    "kitty")
      echo ":kitty:"
      ;;
    "nvim")
      echo ":neovim:"
      ;;
    "vim")
      echo ":vim:"
      ;;
    *)
      echo ":default:"
      ;;
  esac
}

# Call the function with the provided argument
__icon_map "$1"