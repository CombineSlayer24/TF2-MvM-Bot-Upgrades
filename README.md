# TF2 MvM Bot Upgrades
A Team Fortress 2 Plugin that gives Bots (Fake Clients) attributes for MvM. This plugin can be customizeable via notepad or any editor


# Requirements
* [Nosoop's Attributes](https://github.com/nosoop/tf2attributes)
* [TF2Wearables](https://github.com/nosoop/sourcemod-tf2wearables)

# Optional Plugins 
* [Give Bots Weapons](https://forums.alliedmods.net/showthread.php?t=287668) [Gives Bots random weapons, I would recommend Bot Overhual's version]
* [Give Bots Cosmetics](https://forums.alliedmods.net/showthread.php?p=2456267) [Gives bots random cosmetics, I would recommend Bot Overhual's version]
* [Force Bots ready up](https://forums.alliedmods.net/showthread.php?p=1792358) [Instead of waiting 150 seconds, you make make all bots ready up]

# How to change their attirbutes? They are OP.
With any code editor (Notepad++ or your preference), open BotUpgrades.sp, there will be comments explaining how it works, before where the attributes get applied, theres some explaination on how to add/edit attributes for bots.

* You can change/add any attribute you want
* To do, if you want to say, give/edit Sniper's Primary damage
* Go to "case TFClass_Sniper", under "Sniper Primary Attributes"
* You can edit the value from instead +75% to +100%. Just set what it is from "1.75", to "2.0".
* If you see "Client" instead of the weapon slot name, the upgrade will be applied on the Character Upgrades section
* Go to here to find a list of all attributes ( https://wiki.teamfortress.com/wiki/List_of_item_attributes )
