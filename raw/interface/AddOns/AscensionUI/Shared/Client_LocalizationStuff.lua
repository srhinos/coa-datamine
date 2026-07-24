local LOCALE_CLIENT = GetLocale()

--[[locales = {
deDE - German
enGB - British English
enUS - American English
esES - Spanish (European)
esMX - Spanish (Latin American)
frFR - French
koKR - Korean
ruRU - Russian
zhCN - Chinese (simplified; mainland China)
zhTW - Chinese (traditional; Taiwan)
}]]--

function GetLocalization(text)
	local localizedstring = nil
	if not(text[LOCALE_CLIENT]) then
		localizedstring = text["enUS"]
	else
		localizedstring = text[LOCALE_CLIENT]
	end

	return localizedstring
	end


--------------------------------------------------Ascension_Strings. Be carful editing lines.--------------------------------------------------
--------------------------|cffXXXXXX and |r and |T, |t -- color and icon tags, do not touch those symbols.\n tag is next row tag--------------------------------------------------
------------------^ -- begining of the line, $ -- end of the line. (%d+) -- number which will be replaced in text, .* -- symbols to remove--------------------------------------------------

	--TOOLTIPCORRECTOR.LUA--
TOOLTIPCORRECTOR_MANA = {
["enUS"] = "^(%d+) Mana$",
["ruRU"] = "^Мана: (%d+)$",
["frFR"] = "^(%d+) Mana$",
["deDE"] = "^(%d+) Mana$",
["zhCN"] = "^(%d+) 法力$",
["zhTW"] = "^(%d+) 法力$",
["esES"] = "^(%d+) p. de maná$",
["esMX"] = "^(%d+) p. de maná$",
}
TOOLTIPCORRECTOR_ENERGY = {
["enUS"] = "^(%d+) Energy$",
["ruRU"] = "^Энергия: (%d+)$",
["frFR"] = "^(%d+) Energie$",
["deDE"] = "^(%d+) Energie$",
["zhCN"] = "^(%d+) 能量$",
["zhTW"] = "^(%d+) 能量$",
["esES"] = "^(%d+) p. de energía$",
["esMX"] = "^(%d+) p. de energía$",
}
TOOLTIPCORRECTOR_RAGE = {
["enUS"] = "^(%d+) Rage$",
["ruRU"] = "^Ярость: (%d+)$",
["frFR"] = "^(%d+) Rage$",
["deDE"] = "^(%d+) Wut$",
["zhCN"] = "^(%d+) 怒气$",
["zhTW"] = "^(%d+) 怒氣$",
["esES"] = "^(%d+) p. de ira$",
["esMX"] = "^(%d+) p. de ira$",
}
TOOLTIPCORRECTOR_HEALTH = {
["enUS"] = "^(%d+) Health$",
["ruRU"] = "^Здоровье: (%d+)$",
["frFR"] = "^(%d+) Santé$",
["deDE"] = "^(%d+) Gesundheit$",
["zhCN"] = "^(%d+) 生命力$",
["zhTW"] = "^(%d+) 生命力$",
["esES"] = "^Salud (%d+)$",
["esMX"] = "^Salud (%d+)$",
}
TOOLTIPCORRECTOR_RANGE = {
["enUS"] = "^(%d+) yd range$",
["ruRU"] = "^Радиус действия: (%d+) м$",
["frFR"] = "^(%d+) m de portée$",
["deDE"] = "^(%d+) m Entfernung$",
["zhCN"] = "^(%d+) m 射程$",
["zhTW"] = "^(%d+) m 射程$",
["esES"] = "^Alcance de (%d+) m$",
["esMX"] = "^Alcance de (%d+) m$",
}
TOOLTIPCORRECTOR_CASTTIME = {
["enUS"] = "^Instant .*$",
["ruRU"] = "^.*Мгновенное действие.*$",
["frFR"] = "^Instantanée .*$",
["deDE"] = "^Sofort .*$",
["zhCN"] = "^立即 .*$",
["zhTW"] = "^立即 .*$",
["esES"] = "^.*nstantáneo$",
["esMX"] = "^.*nstantáneo$",
}
TOOLTIPCORRECTOR_COOLDOWN = {
["enUS"] = "^(%d+) .* cooldown$",
["ruRU"] = "^Восстановление: (%d+) .*$",
["frFR"] = "^(%d+).*Temps de recharge$",
["deDE"] = "^(%d+).*Abklingkzeit$",
["zhCN"] = "^(%d+) .* 冷却时间$",
["zhTW"] = "^(%d+) .* 冷卻時間$",
["esES"] = "^Reutilización: (%d+) .*$",
["esMX"] = "^Reutilización: (%d+) .*$",
}
TOOLTIPCORRECTOR_UPDATETEXT_MELEERANGE = {
["enUS"] = "Melee range",
["ruRU"] = "Дистанция ближнего боя",
["frFR"] = "Allonge",
["deDE"] = "Nahkampfreichweite",
["zhCN"] = "近战范围",
["zhTW"] = "近戰範圍",
["esES"] = "Distancia cuerpo a cuerpo",
["esMX"] = "Distancia cuerpo a cuerpo",
}
TOOLTIPCORRECTOR_UPDATETEXT_COOLDOWN = {
["enUS"] = " sec cooldown",
["ruRU"] = " сек восстановление",
["frFR"] = " s de recharge",
["deDE"] = " sek Abklinkzeit",
["zhCN"] = " 秒冷却时间",
["zhTW"] = " 秒冷卻時間",
["esES"] = " seg de reutilización",
["esMX"] = " seg de reutilización",
}
TOOLTIPCORRECTOR_UPDATETEXT_CASTTIME = {
["enUS"] = " sec cast",
["ruRU"] = " сек время применения",
["frFR"] = " s d’incantation",
["deDE"] = " sek wirken",
["zhCN"] = " 秒施法时间",
["zhTW"] = " 秒施法時間",
["esES"] = " seg lanzamiento",
["esMX"] = " seg lanzamiento",
}
TOOLTIPCORRECTOR_UPDATETEXT_INSTANT = {
["enUS"] = "Instant",
["ruRU"] = "Мгновенное действие",
["frFR"] = "^(%d+) Instantanée$",
["deDE"] = "Sofort",
["zhCN"] = "立即",
["zhTW"] = "立即",
["esES"] = "Instantáneo",
["esMX"] = "Instantáneo",
}
TOOLTIPCORRECTOR_UPDATETEXT_RAGE = {
["enUS"] = " Rage",
["ruRU"] = " Ярость",
["frFR"] = " Rage",
["deDE"] = " Wut",
["zhCN"] = " 怒气",
["zhTW"] = " 怒氣",
["esES"] = " Ira",
["esMX"] = " Ira",
}
	--ClientEBB.LUA--
CLIENTEXTRABUTTONS_ABILITYESSENCEMAIN = {
["enUS"] = "|cffE1AB18Ability Essence: |cffFFFFFF",
["ruRU"] = "|cffE1AB18Эссенция способностей: |cffFFFFFF",
["frFR"] = "|cffE1AB18Essence de technique: |cffFFFFFF",
["deDE"] = "|cffE1AB18Fähigkeiten Essenz: |cffFFFFFF",
["zhCN"] = "|cffE1AB18技能结晶: |cffFFFFFF",
["zhTW"] = "|cffE1AB18技能結晶: |cffFFFFFF",
["esES"] = "|cffE1AB18Esencia de Habilidad: |cffFFFFFF",
["esMX"] = "|cffE1AB18Esencia de Habilidad: |cffFFFFFF",
}
CLIENTEXTRABUTTONS_TALENTESSENCEMAIN = {
["enUS"] = "|cffE1AB18Talent Essence: |cffFFFFFF",
["ruRU"] = "|cffE1AB18Эссенция Талантов: |cffFFFFFF",
["frFR"] = "|cffE1AB18Essence de talent: |cffFFFFFF",
["deDE"] = "|cffE1AB18Talent Essenz: |cffFFFFFF",
["zhCN"] = "|cffE1AB18天赋结晶: |cffFFFFFF",
["zhTW"] = "|cffE1AB18天賦結晶: |cffFFFFFF",
["esES"] = "|cffE1AB18Esencia de Talento: |cffFFFFFF",
["esMX"] = "|cffE1AB18Esencia de Talento: |cffFFFFFF",
}
CLIENTEXTRABUTTONS_ABILITYRESETMAIN = {
["enUS"] = "|cffE1AB18Ability Resets: |cffFFFFFF",
["ruRU"] = "|cffE1AB18Сброс способностей: |cffFFFFFF",
["frFR"] = "|cffE1AB18Réinitialisations des techniques: |cffFFFFFF",
["deDE"] = "|cffE1AB18Fähigkeiten zurücksetzen: |cffFFFFFF",
["zhCN"] = "|cffE1AB18技能重置: |cffFFFFFF",
["zhTW"] = "|cffE1AB18技能重置: |cffFFFFFF",
["esES"] = "|cffE1AB18Reset de Habilidades: |cffFFFFFF",
["esMX"] = "|cffE1AB18Reset de Habilidades: |cffFFFFFF",
}
CLIENTEXTRABUTTONS_TALENTRESETMAIN = {
["enUS"] = "|cffE1AB18Talent Resets: |cffFFFFFF",
["ruRU"] = "|cffE1AB18Сброс талантов: |cffFFFFFF",
["frFR"] = "|cffE1AB18Réinitialisations des talents: |cffFFFFFF",
["deDE"] = "|cffE1AB18Talente zurücksetzen: |cffFFFFFF",
["zhCN"] = "|cffE1AB18天赋重置: |cffFFFFFF",
["zhTW"] = "|cffE1AB18天赋重置: |cffFFFFFF",
["esES"] = "|cffE1AB18Reset de Talentos: |cffFFFFFF",
["esMX"] = "|cffE1AB18Reset de Talentos: |cffFFFFFF",
}
CLIENTEXTRABUTTONS_UPGRADESTITLE = {
["enUS"] = "|cff230d21Character Upgrades|r",
["ruRU"] = "|cff230d21Улучшения Персонажа|r",
["frFR"] = "|cff230d21Améliorations du personnage|r",
["deDE"] = "|cff230d21Charakter Erweiterungen|r",
["zhCN"] = "|cff230d21角色升级|r",
["zhTW"] = "|cff230d21角色升級|r",
["esES"] = "|cff230d21Mejoras de Personaje|r",
["esMX"] = "|cff230d21Mejoras de Personaje|r",
}
CLIENTEXTRABUTTONS_QUICKACCESSHINT = {
["enUS"] = "Enable/disable quick access to\ncharacter progression menu",
["ruRU"] = "Быстрый доступ к меню\nулучшений персонажа",
["frFR"] = "Activer/désactiver l’accès rapide au menu de progression du \npersonnage",
["deDE"] = "Aktiviere/Deaktiviere schnellen Zugriff zum\nCharakter Erweiterungsmenü",
["zhCN"] = "开启/关闭角色升级\n快捷浮窗",
["zhTW"] = "開啟/關閉角色升級\n快捷浮窗",
["esES"] = "Activar/desactivar acceso rápido a\nmenú de progresión de personaje",
["esMX"] = "Activar/desactivar acceso rápido a\nmenú de progresión de personaje",
}
CLIENTEXTRABUTTONS_DISPLAYSPELLS = {
["enUS"] = "Click to display spells",
["ruRU"] = "Нажмите для отображения заклинаний",
["frFR"] = "Cliquer pour afficher les sorts",
["deDE"] = "Klicken um Zauber anzuzeigen.",
["zhCN"] = "点击显示技能",
["zhTW"] = "點擊顯示技能",
["esES"] = "Pulsa para mostrar hechizos",
["esMX"] = "Pulsa para mostrar hechizos",
}
CLIENTEXTRABUTTONS_DISPLAYTALENTS = {
["enUS"] = "Click to display talents",
["ruRU"] = "Нажмите для отображения талантов",
["frFR"] = "Cliquer pour afficher les talents",
["deDE"] = "Klicken um Talente anzuzeigen.",
["zhCN"] = "点击显示天赋",
["zhTW"] = "點擊顯示天賦",
["esES"] = "Pulsa para mostrar talentos",
["esMX"] = "Pulsa para mostrar talentos",
}
CLIENTEXTRABUTTONS_UPGRADESHINT = {
["enUS"] = "Using this menu you'll be\nable to reset your spells or talents,\nto get new abilities and allocate\nstats of your character",
["ruRU"] = "Используя это меню вы получите доступ к\nсбросу ваших талантов и способностей\nполучению новых знаний и распределению\nхарактеристик вашего персонажа",
["frFR"] = "A l’aide de ce menu vous \npourrez réinitialiser vos sorts et talents, \nacquérir de nouvelles techniques et allouer les points de \nstatistique de votre personnage",
["deDE"] = "Die Benutzung dieses Menüs \nerlaubt es dir deine Zauber und Talente zurückzusetzen, \nsowie deinem Charakter neue Fähigkeiten und\nCharaktereigenschaften zuzuweisen.",
["zhCN"] = "使用此菜单\n可重置技能与天赋,\n学习新技能与天赋\n更改基本属性",
["zhTW"] = "使用此菜單\n可重置技能與天賦,\n學習新技能與天賦\n更改基本屬性",
["esES"] = "Usando esté menú \nserás capaz de restaurar tus hechizos o talentos,\npara conseguir nuevas habilidades y colocar\nestadísticas de tu personaje",
["esMX"] = "Usando esté menú \nserás capaz de restaurar tus hechizos o talentos,\npara conseguir nuevas habilidades y colocar\nestadísticas de tu personaje",
}
CLIENTEXTRABUTTONS_OPENUPGRADES = {
["enUS"] = "|cffFFFFFFOpen Character Upgrades|r",
["ruRU"] = "|cffFFFFFFОткрыть Прогресс Персонажа|r",
["frFR"] = "|cffFFFFFFOuvrir les Améliorations du Personnage|r",
["deDE"] = "|cffFFFFFFÖffne Charakter Erweiterungen|r",
["zhCN"] = "|cffFFFFFF角色升级菜单|r",
["zhTW"] = "|cffFFFFFF角色升級菜單|r",
["esES"] = "|cffFFFFFFAbrir Mejoras de Personaje|r",
["esMX"] = "|cffFFFFFFAbrir Mejoras de Personaje|r",
}
CLIENTEXTRABUTTONS_ADVANCEMENTTITLE = {
["enUS"] = "Character Advancement",
["ruRU"] = "Совершенствование Персонажа",
["frFR"] = "Progression du Personnage",
["deDE"] = "Charakter Erweiterung",
["zhCN"] = "角色提升",
["zhTW"] = "角色提升",
["esES"] = "Progreso del personaje",
["esMX"] = "Progreso del personaje",
}
CLIENTEXTRABUTTONS_ADVANCEMENTHINT = {
["enUS"] = "|cffFFFFFFCharacter Advancement|r",
["ruRU"] = "|cffFFFFFFСовершенствование Персонажа|r",
["frFR"] = "|cffFFFFFFProgression du Personnage|r",
["deDE"] = "|cffFFFFFFCharakter Erweiterung|r",
["zhCN"] = "|cffFFFFFF角色提升|r",
["zhTW"] = "|cffFFFFFF角色提升|r",
["esES"] = "|cffFFFFFFProgreso de Personaje|r",
["esMX"] = "|cffFFFFFFProgreso de Personaje|r",
}
CLIENTEXTRABUTTONS_TOOLTIPADD = {
["enUS"] = "Learn new skills, or allocate skill points\nto improve existing ones.",
["ruRU"] = "Изучайте новые заклинания или распределяйте очки заклинаний\nдля улучшения уже изученных.",
["frFR"] = "Apprendre de nouveaux sorts, ou allouer des points de compétence \nafin d’améliorer ceux appris..",
["deDE"] = "Lerne neue Zauber, oder weise Charaktereigenschaftspunkte \nzu um bestehende zu verbessern.",
["zhCN"] = "学习新技能, 或分配天赋\n强化现有技能.",
["zhTW"] = "學習新技能, 或分配天賦\n強化現有技能.",
["esES"] = "Aprender nuevos hechizos, o asignar puntos de habilidad\npara mejorar los existentes.",
["esMX"] = "Aprender nuevos hechizos, o asignar puntos de habilidad\npara mejorar los existentes.",
}
CLIENTEXTRABUTTONS_STATALLOCATIONTITLE = {
["enUS"] = "Stat Allocation",
["ruRU"] = "Характеристики",
["frFR"] = "Distribution des points de Statistique",
["deDE"] = "Charaktereigenschaftszuweisung",
["zhCN"] = "更改属性点",
["zhTW"] = "更改屬性點",
["esES"] = "Asignación de Estadísticas",
["esMX"] = "Asignación de Estadísticas",
}
CLIENTEXTRABUTTONS_ALLOCATIONHINT = {
["enUS"] = "|cffFFFFFFStat Allocation|r",
["ruRU"] = "|cffFFFFFFРаспределение Характеристик|r",
["frFR"] = "|cffFFFFFFDistribution des points de Statistique|r",
["deDE"] = "|cffFFFFFFCharaktereigenschaftszuweisung|r",
["zhCN"] = "|cffFFFFFF更改属性|r",
["zhTW"] = "|cffFFFFFF更改屬性|r",
["esES"] = "|cffFFFFFFAsignación de Estadísticas|r",
["esMX"] = "|cffFFFFFFAsignación de Estadísticas|r",
}
CLIENTEXTRABUTTONS_ALLOCATIONHINT_TOOLTIP = {
["enUS"] = "Manage allocation of your attribute\npoints.",
["ruRU"] = "Управляйте распределением ваших очков\nхарактеристик.",
["frFR"] = "Gérer la distribution de vos \npoints d’attribut.",
["deDE"] = "Verwalte die Zuweisung deiner Attribute",
["zhCN"] = "自由分配基本属性点.",
["zhTW"] = "自由分配基本屬性點.",
["esES"] = "Controlar la asignación de tus\npuntos de atributos.",
["esMX"] = "Controlar la asignación de tus\npuntos de atributos.",
}
CLIENTEXTRABUTTONS_RESETHINT = {
["enUS"] = "|cffFFFFFFReset Spells/Talents|r",
["ruRU"] = "|cffFFFFFFСброс Заклинаний/Талантов|r",
["frFR"] = "|cffFFFFFFRéinitialisation Sorts/Talents|r",
["deDE"] = "cffFFFFFFZurücksetzung von Zauber/Talente|r",
["zhCN"] = "|cffFFFFFF重置技能/天赋|r",
["zhTW"] = "|cffFFFFFF重置技能/天賦|r",
["esES"] = "|cffFFFFFFRestablecer Hechizos/Talentos|r",
["esMX"] = "|cffFFFFFFRestablecer Hechizos/Talentos|r",
}
CLIENTEXTRABUTTONS_RESETHINT_TOOLTIP = {
["enUS"] = "Use your tokens or gold to refund\nyour Spells or Talents.",
["ruRU"] = "Используйте очки сброса или золото для сброса\nваших Заклинаний или Талантов.",
["frFR"] = "Utilisez vos tokens ou or pour rembourser\nvos Sorts ou Talents.",
["deDE"] = "Benutze deine Tokens oder Gold um \ndeine Zauber oder Talente zurückzusetzen",
["zhCN"] = "使用徽章或者金币重置技能与天赋.",
["zhTW"] = "使用徽章或者金幣重置技能與天賦.",
["esES"] = "Usa tus fichas u oro para reembolsar\ntus Hechizos o Talentos.",
["esMX"] = "Usa tus fichas u oro para reembolsar\ntus Hechizos o Talentos.",
}
CLIENTEXTRABUTTONS_RESETS = {
["enUS"] = "Resets Spells/Talents",
["ruRU"] = "Забыть умения",
["frFR"] = "Resets Spells/Talents",
["deDE"] = "Setzt Zauber/Talente zurück",
["zhCN"] = "重置技能/天赋",
["zhTW"] = "重置技能/天賦",
["esES"] = "Restablecer Hechizos/Talentos",
["esMX"] = "Restablecer Hechizos/Talentos",
}
CLIENTEXTRABUTTONS_RESETSYOUHAD = {
["enUS"] = "|cffE1AB18Resets you had on level |cffFF4E00[",
["ruRU"] = "|cffE1AB18Вы имели сбросов на уровне |cffFF4E00[",
["frFR"] = "|cffE1AB18Réinitialisations réalisées au niveau|cffFF4E00[",
["deDE"] = "|cffE1AB18Zurücksetzungen die du auf  Level  |cffFF4E00[",
["zhCN"] = "|cffE1AB18重置等级 |cffFF4E00[",
["zhTW"] = "|cffE1AB18重置等級 |cffFF4E00[",
["esES"] = "|cffE1AB18Resets que has tenido en este nivel |cffFF4E00[",
["esMX"] = "|cffE1AB18Resets que has tenido en este nivel |cffFF4E00[",
}
CLIENTEXTRABUTTONS_RESETTOKEN = {
["enUS"] = "|cffE1AB18Reset: |TInterface\\Icons\\inv_custom_talentpurge.blp:14:14:0:0|t|cffFFFFFFx1",
["ruRU"] = "|cffE1AB18Сброс: |TInterface\\Icons\\inv_custom_talentpurge.blp:14:14:0:0|t|cffFFFFFFx1",
["frFR"] = "|cffE1AB18Réinitialisation: |TInterface\\Icons\\inv_custom_talentpurge.blp:14:14:0:0|t|cffFFFFFFx1",
["deDE"] = "|cffE1AB18Zurücksetzung: |TInterface\\Icons\\inv_custom_talentpurge.blp:14:14:0:0|t|cffFFFFFFx1",
["zhCN"] = "|cffE1AB18重置: |TInterface\\Icons\\inv_custom_talentpurge.blp:14:14:0:0|t|cffFFFFFFx1",
["zhTW"] = "|cffE1AB18重置: |TInterface\\Icons\\inv_custom_talentpurge.blp:14:14:0:0|t|cffFFFFFFx1",
["esES"] = "|cffE1AB18Restablecer: |TInterface\\Icons\\inv_custom_talentpurge.blp:14:14:0:0|t|cffFFFFFFx1",
["esMX"] = "|cffE1AB18Restablecer: |TInterface\\Icons\\inv_custom_talentpurge.blp:14:14:0:0|t|cffFFFFFFx1",
}
CLIENTEXTRABUTTONS_RESETMAIN = {
["enUS"] = "|cffE1AB18Reset: |cffFFFFFF",
["ruRU"] = "|cffE1AB18Сброс: |cffFFFFFF",
["frFR"] = "|cffE1AB18Réinitialisation: |cffFFFFFF",
["deDE"] = "|cffE1AB18Zurücksetzung: |cffFFFFFF",
["zhCN"] = "|cffE1AB18重置: |cffFFFFFF",
["zhTW"] = "|cffE1AB18重置: |cffFFFFFF",
["esES"] = "|cffE1AB18Restablecer: |cffFFFFFF",
["esMX"] = "|cffE1AB18Restablecer: |cffFFFFFF",
}
CLIENTEXTRABUTTONS_NEXTRESETTOKEN = {
["enUS"] = "|cffE1AB18Next Reset: |TInterface\\Icons\\inv_custom_talentpurge.blp:14:14:0:0|t|cffFFFFFFx1",
["ruRU"] = "|cffE1AB18Следующий сброс: |TInterface\\Icons\\inv_custom_talentpurge.blp:14:14:0:0|t|cffFFFFFFx1",
["frFR"] = "|cffE1AB18Prochaine Réinitialisation: |TInterface\\Icons\\inv_custom_talentpurge.blp:14:14:0:0|t|cffFFFFFFx1",
["deDE"] = "|cffE1AB18Nächste Zurücksetzung: |TInterface\\Icons\\inv_custom_talentpurge.blp:14:14:0:0|t|cffFFFFFFx1",
["zhCN"] = "|cffE1AB18下一次重置: |TInterface\\Icons\\inv_custom_talentpurge.blp:14:14:0:0|t|cffFFFFFFx1",
["zhTW"] = "|cffE1AB18下一次重置: |TInterface\\Icons\\inv_custom_talentpurge.blp:14:14:0:0|t|cffFFFFFFx1",
["esES"] = "|cffE1AB18Sig. Reset: |TInterface\\Icons\\inv_custom_talentpurge.blp:14:14:0:0|t|cffFFFFFFx1",
["esMX"] = "|cffE1AB18Sig. Reset: |TInterface\\Icons\\inv_custom_talentpurge.blp:14:14:0:0|t|cffFFFFFFx1",
}
CLIENTEXTRABUTTONS_NEXTRESET = {
["enUS"] = "|cffE1AB18Next Reset: |cffFFFFFF",
["ruRU"] = "|cffE1AB18Следующий сброс: |cffFFFFFF",
["frFR"] = "|cffE1AB18Prochaine Réinitialisation: |cffFFFFFF",
["deDE"] = "|cffE1AB18Nächste Zurücksetzung: |cffFFFFFF",
["zhCN"] = "|cffE1AB18下一次重置: |cffFFFFFF",
["zhTW"] = "|cffE1AB18下一次重置: |cffFFFFFF",
["esES"] = "|cffE1AB18Sig. Reset: |cffFFFFFF",
["esMX"] = "|cffE1AB18Sig. Reset: |cffFFFFFF",
}
CLIENTEXTRABUTTONS_RESETTITLE = {
["enUS"] = "Reset Menu",
["ruRU"] = "Меню Сброса",
["frFR"] = "Menu de Réinitialisation",
["deDE"] = "Zurücksetzungsmenü",
["zhCN"] = "重置菜单",
["zhTW"] = "重置菜單",
["esES"] = "Menú de Restablecimiento",
["esMX"] = "Menú de Restablecimiento",
}
CLIENTEXTRABUTTONS_RESETTALENTSTITLE = {
["enUS"] = "|cff6b625bReset Talents|r",
["ruRU"] = "|cff6b625bСбросить Таланты|r",
["frFR"] = "|cff6b625bRéinitialisation de Talents|r",
["deDE"] = "|cff6b625bTalente zurücksetzen",
["zhCN"] = "|cff6b625b重置天赋|r",
["zhTW"] = "|cff6b625b重置天賦|r",
["esES"] = "|cff6b625bRestablecer Talentos|r",
["esMX"] = "|cff6b625bRestablecer Talentos|r",
}
CLIENTEXTRABUTTONS_RESETTALENTS = {
["enUS"] = "Reset Talents",
["ruRU"] = "Сбросить Таланты",
["frFR"] = "Réinitialisation de Talents",
["deDE"] = "Talente zurücksetzen",
["zhCN"] = "重置天赋",
["zhTW"] = "重置天賦",
["esES"] = "Restablecer Talentos",
["esMX"] = "Restablecer Talentos",
}
CLIENTEXTRABUTTONS_RESETSPELLS = {
["enUS"] = "Reset Spells",
["ruRU"] = "Сбросить Заклинания",
["frFR"] = "Réinitialisation de Sorts",
["deDE"] = "Zauber zurücksetzen",
["zhCN"] = "重置技能",
["zhTW"] = "重置技能",
["esES"] = "Restablecer Hechizos",
["esMX"] = "Restablecer Hechizos",
}
CLIENTEXTRABUTTONS_RESETSPELLSTITLE = {
["enUS"] = "|cff6b625bReset Spells|r",
["ruRU"] = "|cff6b625bСбросить Заклинания|r",
["frFR"] = "|cff6b625bRéinitialisation de Sorts|r",
["deDE"] = "|cff6b625bZauber zurücksetzen|r",
["zhCN"] = "|cff6b625b重置技能|r",
["zhTW"] = "|cff6b625b重置技能|r",
["esES"] = "|cff6b625bRestablecer Hechizos|r",
["esMX"] = "|cff6b625bRestablecer Hechizos|r",
}
CLIENTEXTRABUTTONS_RESETSPELLSDIALOG = {
["enUS"] = "|cffE1AB18You are going to reset spells|r",
["ruRU"] = "|cffE1AB18Вы собираетесь сбросить заклинания|r",
["frFR"] = "|cffE1AB18Vous êtes sur le point de réinitialiser vos sorts|r",
["deDE"] = "|cff6b625bDu wirst deine Zauber zurücksetzen|r",
["zhCN"] = "|cffE1AB18您将重置您的技能|r",
["zhTW"] = "|cffE1AB18您將重置您的技能|r",
["esES"] = "|cffE1AB18Estás a punto de restablecer los hechizos|r",
["esMX"] = "|cffE1AB18Estás a punto de restablecer los hechizos|r",
}
CLIENTEXTRABUTTONS_RESETYES = {
["enUS"] = "Yes",
["ruRU"] = "Да",
["frFR"] = "Oui",
["deDE"] = "Ja",
["zhCN"] = "是",
["zhTW"] = "是",
["esES"] = "Sí",
["esMX"] = "Sí",
}
CLIENTEXTRABUTTONS_RESETNO = {
["enUS"] = "No",
["ruRU"] = "Нет",
["frFR"] = "Non",
["deDE"] = "Nein",
["zhCN"] = "否",
["zhTW"] = "否",
["esES"] = "No",
["esMX"] = "No",
}
CLIENTEXTRABUTTONS_RESETSPELLSHINT = {
["enUS"] = "|cffFFFFFFReset Spells|r\nUse your tokens to refund your Spells.",
["ruRU"] = "|cffFFFFFFСброс Заклинаний|r\nИспользуйте очки сброса для сброса Заклинаний.",
["frFR"] = "|cffFFFFFFRéinitialisation des Sorts|r\nUtilisez vos tokens pour rembourser vos Sorts.",
["deDE"] = "|cffFFFFFFZauber zurücksetzen|r\nrBenutze deine Tokens um deine Zauber zurück zu erstatten.",
["zhCN"] = "|cffFFFFFF重置技能|r\n使用您的徽章重置技能.",
["zhTW"] = "|cffFFFFFF重置技能|r\n使用您的徽章重置技能.",
["esES"] = "|cffFFFFFFRestablecer Hechizos|r\nUsa tus fichas para reembolsar tus Hechizos.",
["esMX"] = "|cffFFFFFFRestablecer Hechizos|r\nUsa tus fichas para reembolsar tus Hechizos.",
}
CLIENTEXTRABUTTONS_RESETTALENTSDIALOG = {
["enUS"] = "|cffE1AB18You are going to reset talents|r",
["ruRU"] = "|cffE1AB18Вы собираетесь сбросить таланты|r",
["frFR"] = "|cffE1AB18Vous êtes sur le point de réinitialiser vos talents|r",
["deDE"] = "|cffE1AB18Du wirst deine Talente zurücksetzen|r",
["zhCN"] = "|cffE1AB18您将重置您的天赋|r",
["zhTW"] = "|cffE1AB18您將重置您的天賦|r",
["esES"] = "|cffE1AB18Estás a punto de restablecer los talentos|r",
["esMX"] = "|cffE1AB18Estás a punto de restablecer los talentos|r",
}
CLIENTEXTRABUTTONS_RESETTALENTSHINT = {
["enUS"] = "|cffFFFFFFReset Talents|r\nUse your tokens to refund your Talents.",
["ruRU"] = "|cffFFFFFFСброс Талантов|r\nИспользуйте очки сброса для сброса талантов.",
["frFR"] = "|cffFFFFFFRéinitialisation de Talents|r\nUtilisez vos tokens pour rembourser vos Talents.",
["deDE"] = "|cffFFFFFFTalente zurücksetzen|r\nrBenutze deine Tokens um deine Talente zurück zu erstatten.",
["zhCN"] = "|cffFFFFFF重置天赋|r\n使用您的徽章重置天赋.",
["zhTW"] = "|cffFFFFFF重置天賦|r\n使用您的徽章重置天賦.",
["esES"] = "|cffFFFFFFRestablecer Talentos|r\nUsa tus fichas para reembolsar tus Talentos.",
["esMX"] = "|cffFFFFFFRestablecer Talentos|r\nUsa tus fichas para reembolsar tus Talentos.",
}
CLIENTEXTRABUTTONS_RESETSLASTTEN = {
["enUS"] = "|cffFFFFFFResets you had on last 10 levels|r",
["ruRU"] = "|cffFFFFFFУ вас было сбросов на последних 10 уровнях|r",
["frFR"] = "|cffFFFFFFRéinitialisations réalisées au cours des 10 derniers niveaux|r",
["deDE"] = "|cffFFFFFFZurücksetzungen die du die letzten 10 Level hattest|r",
["zhCN"] = "|cffFFFFFF这10级的重置次数|r",
["zhTW"] = "|cffFFFFFF這10級的重置次數|r",
["esES"] = "|cffFFFFFFResets que has tenido en los últimos 10 niveles|r",
["esMX"] = "|cffFFFFFFResets que has tenido en los últimos 10 niveles|r",
}
CLIENTEXTRABUTTONS_ALLOCATIONSTR = {
["enUS"] = "|cffFFFFFFStrength|r",
["ruRU"] = "|cffFFFFFFСила|r",
["frFR"] = "|cffFFFFFFForce|r",
["deDE"] = "|cffFFFFFFStärke|r",
["zhCN"] = "|cffFFFFFF力量|r",
["zhTW"] = "|cffFFFFFF力量|r",
["esES"] = "|cffFFFFFFStrength|r",
["esMX"] = "|cffFFFFFFStrength|r",
}
CLIENTEXTRABUTTONS_ALLOCATIONSTAM = {
["enUS"] = "|cffFFFFFFStamina|r",
["ruRU"] = "|cffFFFFFFВыносливость|r",
["frFR"] = "|cffFFFFFFEndurance|r",
["deDE"] = "|cffFFFFFFAusdauer|r",
["zhCN"] = "|cffFFFFFF耐力|r",
["zhTW"] = "|cffFFFFFF耐力|r",
["esES"] = "|cffFFFFFFStamina|r",
["esMX"] = "|cffFFFFFFStamina|r",
}
CLIENTEXTRABUTTONS_ALLOCATIONAG = {
["enUS"] = "|cffFFFFFFAgility|r",
["ruRU"] = "|cffFFFFFFЛовкость|r",
["frFR"] = "|cffFFFFFFAgilité|r",
["deDE"] = "|cffFFFFFFBeweglichkeit|r",
["zhCN"] = "|cffFFFFFF敏捷|r",
["zhTW"] = "|cffFFFFFF敏捷|r",
["esES"] = "|cffFFFFFFAgility|r",
["esMX"] = "|cffFFFFFFAgility|r",
}
CLIENTEXTRABUTTONS_ALLOCATIONINT = {
["enUS"] = "|cffFFFFFFIntellect|r",
["ruRU"] = "|cffFFFFFFИнтеллект|r",
["frFR"] = "|cffFFFFFFIntelligence|r",
["deDE"] = "|cffFFFFFFIntelligenz|r",
["zhCN"] = "|cffFFFFFF智力|r",
["zhTW"] = "|cffFFFFFF智力|r",
["esES"] = "|cffFFFFFFIntellect|r",
["esMX"] = "|cffFFFFFFIntellect|r",
}
CLIENTEXTRABUTTONS_ALLOCATIONSPIRIT = {
["enUS"] = "|cffFFFFFFSpirit|r",
["ruRU"] = "|cffFFFFFFДух|r",
["frFR"] = "|cffFFFFFFEsprit|r",
["deDE"] = "|cffFFFFFFWillenskraft|r",
["zhCN"] = "|cffFFFFFF精神|r",
["zhTW"] = "|cffFFFFFF精神|r",
["esES"] = "|cffFFFFFFSpirit|r",
["esMX"] = "|cffFFFFFFSpirit|r",
}

CLIENTEXTRABUTTONS_ALLOCATIONSTR_TOOLTIP = {
["enUS"] = "Strength increases |cffFFFFFFattack power|r and is the most important\nstat for plate armor-wearing classes in the |cffFFFFFFdamage-dealing|r or |cffFFFFFFtank|r role.\nStrength also converts into |cffFFFFFFparry|r.\n\nChoosing this specialization will give you bonus |cffFFFFFFStrength|r and make each point of |cffFFFFFFStrength|r give you one additional |cffFFFFFFAttack Power|r.",
["ruRU"] = "Сила увеличивает |cffFFFFFFсилу атаки|r и это важнейшая\nхарактеристика для носящих латы |cffFFFFFFбойцов|r или |cffFFFFFFтанков|r.\nСила также конвертируется в |cffFFFFFFпарирование|r.",
["frFR"] = "La Force augmente le |cffFFFFFFpouvoir d’attaque|r et est la \nstatistique la plus importante pour les classes portant des armures de plate dans le rôle de |cffFFFFFFDPS|r ou de |cffFFFFFFtank|r.\nLa Force se convertit également en|cffFFFFFFparade|r.",
["deDE"] = "Stärke erhöht die |cffFFFFFFAngriffskraft|r und ist das wichtigste\nAttribut für Plattenträger Klassen in der |cffFFFFFFSchadensverteilungs|r oder cffFFFFFFTank|r Rolle. \nStärke wird außerdem zu |cffFFFFFFParieren|r. Konvertiert",
["zhCN"] = "力量提升 |cffFFFFFF强度|r 并且\n对于 |cffFFFFFF物理输出|r 或者 |cffFFFFFF坦克|r 角色来说是重属性.\n力量同时也提升 |cffFFFFFF招架|r.",
["zhTW"] = "力量提升 |cffFFFFFF強度|r 並且\n對於 |cffFFFFFF物理輸出|r 或者 |cffFFFFFF坦克|r 角色來說是重屬性.\n力量同時也提升 |cffFFFFFF招架|r.",
["esES"] = "La Fuerza aumenta |cffFFFFFFpoder de ataque|r y es el\nstat más importante para las clases que llevan equipo de placas que|cffFFFFFFinflingen daño|r o |cffFFFFFFtienen la|r función de tanque.\nLa Fuerza se convierte también en |cffFFFFFFparada|r.",
["esMX"] = "La Fuerza aumenta |cffFFFFFFpoder de ataque|r y es el\nstat más importante para las clases que llevan equipo de placas que|cffFFFFFFinflingen daño|r o |cffFFFFFFtienen la|r función de tanque.\nLa Fuerza se convierte también en |cffFFFFFFparada|r.",
}
CLIENTEXTRABUTTONS_ALLOCATIONSTAM_TOOLTIP = {
["enUS"] = "Stamina is the source of all |cffFFFFFFhealth|r.\nMost armor has stamina on it, and all classes\nand specializations wear armor with stamina on it,\nbut |cffFFFFFFtanks|r generally have the most.",
["ruRU"] = "Выносливость это источник всего вашего |cffFFFFFFздоровья|r.\nБольшинство брони имеет выносливость, и все классы\nи специализации носят броню с выносливостью,\nно в основном |cffFFFFFFтанки|r нуждаются в этой характеристике больше всего.",
["frFR"] = "L’Endurance est la seule source de|cffFFFFFFPoints de Vie|r.\nLa plupart des armures donnent de l’Endurance, et toutes les classes\net toutes les spécialisations portent des armures apportant de l’Endurance,\nmais les |cffFFFFFFtanks|r en ont en général le plus.",
["deDE"] = "Ausdauer ist die Quelle aller |cffFFFFFFGesundheit|r.\nDie meisten Rüstungen haben Ausdauer und alle Klassen\nsowie Spezialisierungen tragen Rüstung mit Ausdauer,\naber |cffFFFFFFTanks|r haben generell am meisten.",
["zhCN"] = "耐力提升 |cffFFFFFF生命力|r.\n大多数护甲都有耐力,\n所以职业都需要耐力,\n但是对于 |cffFFFFFF坦克|r 来说是很重要的.",
["zhTW"] = "耐力提升 |cffFFFFFF生命力|r.\n大多數護甲都有耐力,\n所以職業都需要耐力,\n但是對於 |cffFFFFFF坦克|r 來說是很重要的.",
["esES"] = "El aguante es la fuente de toda la |cffFFFFFFsalud|r.\nMuchas armaduras tienen aguante, y todas las clases\ny especializaciones llevan armadura con aguante,\npero |cffFFFFFFlos tanques|r generalmente tienen la mayoría.",
["esMX"] = "El aguante es la fuente de toda la |cffFFFFFFsalud|r.\nMuchas armaduras tienen aguante, y todas las clases\ny especializaciones llevan armadura con aguante,\npero |cffFFFFFFlos tanques|r generalmente tienen la mayoría.",
}
CLIENTEXTRABUTTONS_ALLOCATIONAG_TOOLTIP = {
["enUS"] = "Agility increases |cffFFFFFFmelee|r and |cffFFFFFFranged attack power|r,\nand is the most important stat for leather armor\nand mail armor-wearing classes in the\n|cffFFFFFFdamage-dealing|r or |cffFFFFFFtank|r role.\n\nChoosing this specialization will give you bonus |cffFFFFFFAgility|r and make each point of |cffFFFFFFAgility|r give you one |cffFFFFFFAttack Power.|r",
["ruRU"] = "Ловкость повышает силу атаки |cffFFFFFFближнего|r и |cffFFFFFFдальнего боя|r,\nи это наиболее важная для носящих кожу и\nкольчугу персонажей, сконцентрированных на роли\n|cffFFFFFFбойца|r или |cffFFFFFFтанка|r.",
["frFR"] = "L’Agilité augmente les dégâts de |cffFFFFFFmélée|r et le|cffFFFFFFpouvoir d’attaque à distance|r,\net est la statistique la plus importante pour portantes des armures en cuir ou en maille dans le rôle de\n|cffFFFFFFDPS|r ou de |cffFFFFFFtank|r.",
["deDE"] = "Beweglichkeit erhöht die |cffFFFFFFNahkampf|r und  |cffFFFFFFFern Angriffskraft|r,\nund ist das Wichtigste Attribut für Leder\nund Ketten Rüstungsträger Klassen in der \n|cffFFFFFFdSchadensverteilungs|r oder |cffFFFFFFTank|r Rolle.",
["zhCN"] = "敏捷提升 |cffFFFFFF近战|r 和 |cffFFFFFF远程攻击强度|r,\n对于|cffFFFFFF物理输出|r 很重要\n同时 |cffFFFFFF坦克|r 也需要因为敏捷提升闪躲.",
["zhTW"] = "敏捷提升 |cffFFFFFF近戰|r 和 |cffFFFFFF遠程攻擊強度|r,\n對於|cffFFFFFF物理輸出|r 很重要\n同時 |cffFFFFFF坦克|r 也需要因為敏捷提升閃躲",
["esES"] = "La Agilidad aumenta el |cffFFFFFFpoder de ataque cuerpo a cuerpo y a distancia|r,\ny es la estadística más importante en las clases que llevan armadura de cuero\ny malla en el rol de\n|cffFFFFFFdaño|r o |cffFFFFFFtanque.",
["esMX"] = "La Agilidad aumenta el |cffFFFFFFpoder de ataque cuerpo a cuerpo y a distancia|r,\ny es la estadística más importante en las clases que llevan armadura de cuero\ny malla en el rol de\n|cffFFFFFFdaño|r o |cffFFFFFFtanque.",
}
CLIENTEXTRABUTTONS_ALLOCATIONINT_TOOLTIP = {
["enUS"] = "Intellect increases |cffFFFFFFspell critical chance|r, |cffFFFFFFamount of mana|r and is the most\nimportant stat for mana-using classes\nwearing any armor type in the\n|cffFFFFFFdamage-dealing|r (ranged spell caster) or |cffFFFFFFhealer|r role.\n\nChoosing this specialization will give you bonus |cffFFFFFFIntellect|r and |cffFFFFFFSpirit|r and make each point of |cffFFFFFFSpell Power|r give you one additional |cffFFFFFFSpell Damage|r.",
["ruRU"] = "Интеллект повышает |cffFFFFFFшанс критического удара заклинаний|r, |cffFFFFFFколичество маны|r и это наиболее важная\nхарактеристика для классов, использующих ману\nпригодитя в любом типе брони и роли\n|cffFFFFFFбойца|r (боец дальнего боя) или |cffFFFFFFцелителя|r.",
["frFR"] = "L’Intelligence augmente les |cffFFFFFFchances de coups critiques des sorts|r, le |cffFFFFFFmontant de mana maximal|r et est la statistique la plus \nimportante pour les classes utilisant de la mana \nportantes tous types d’armures dans le rôle de\n|cffFFFFFFDPS|r (mage à distance) ou de |cffFFFFFFsoigneur.",
["deDE"] = "Intelligenz erhöht die  |cffFFFFFFkritische  ZauberTrefferchance|r, |cffFFFFFFMenge an Mana|r und ist das \nwichtigste Attribut für Mana Klassen die alle Rüstungs Typen /anziehen in der\n|cffFFFFFFSchadensverteilungs oder |cffFFFFFFHeiler|r Rolle",
["zhCN"] = "智力提升 |cffFFFFFF法术暴击率|r, |cffFFFFFF法力值|r \n适用于|cffFFFFFF输出|r (远程法伤职业) \n或者 |cffFFFFFF治疗|r 职业.",
["zhTW"] = "智力提升 |cffFFFFFF法術暴擊率|r, |cffFFFFFF法力值|r \n適用於|cffFFFFFF輸出|r (遠程法傷職業) \n或者 |cffFFFFFF治療|r 職業.",
["esES"] = "El Intelecto aumenta |cffFFFFFFel daño crítico con hechizos|r, |cffFFFFFFla cantidad de maná|r y es la estadística más\nimportante para las clases que usan maná y\nen el rol de\n|cffFFFFFFdaño inflingido|r (a distancia con hechizos) o |cffFFFFFFsanador.",
["esMX"] = "El Intelecto aumenta |cffFFFFFFel daño crítico con hechizos|r, |cffFFFFFFla cantidad de maná|r y es la estadística más\nimportante para las clases que usan maná y\nen el rol de\n|cffFFFFFFdaño inflingido|r (a distancia con hechizos) o |cffFFFFFFsanador.",
}
CLIENTEXTRABUTTONS_ALLOCATIONSPIRIT_TOOLTIP = {
["enUS"] = "Spirit is the |cffFFFFFFhealer-only|r stat,\nand increases their mana regeneration.\n\n Choosing this specialization will give you bonus |cffFFFFFFIntellect|r and |cffFFFFFFSpirit|r and make each point of |cffFFFFFFSpell Power|r give you one additional |cffFFFFFFHealing Power|r.",
["ruRU"] = "Дух - характеристика, используемая |cffFFFFFFтолько целителями|r,\nона повышает вашу скорость восстановления маны.",
["frFR"] = "L’Esprit est la statistique dédiée aux |cffFFFFFFsoigneurs|r,\net augmente leur taux de régénération de mana",
["deDE"] = "Willenskraft ist nur ein |cffFFFFFFHeiler|r Attribut,\nund erhöt die Mana-Regeneration.",
["zhCN"] = "精神是 |cffFFFFFF治疗专用|r 的属性,\n同时提高魔法恢复速度.",
["zhTW"] = "精神是 |cffFFFFFF治療專用|r 的屬性,\n同時提高魔法恢復速度.",
["esES"] = "El Espíritu es la|restadística única para |cffFFFFFFsanadores,\ny aumenta la regeneración del maná.",
["esMX"] = "El Espíritu es la|restadística única para |cffFFFFFFsanadores,\ny aumenta la regeneración del maná.",
}
CLIENTEXTRABUTTONS_ALLSTR = {
["enUS"] = "|cffE1AB18Strength|r",
["ruRU"] = "|cffE1AB18Сила|r",
["frFR"] = "|cffE1AB18Force|r",
["deDE"] = "|cffE1AB18Stärke|r",
["zhCN"] = "|cffE1AB18力量|r",
["zhTW"] = "|cffE1AB18力量|r",
["esES"] = "|cffE1AB18Fuerza|r",
["esMX"] = "|cffE1AB18Fuerza|r",
}
CLIENTEXTRABUTTONS_ALLOCATIONSHIFT = {
["enUS"] = "|cffE1AB18Hold |cffFFFFFFShift|cffE1AB18 to allocate 10 points per stat|r",
["ruRU"] = "|cffE1AB18Удерживайте |cffFFFFFFShift|cffE1AB18 для распределения 10 очков|r",
["frFR"] = "|cffE1AB18Maintenez |cffFFFFFFMaj|cffE1AB18 pour allouer 10 points de statistique|r",
["deDE"] = "|cffE1AB18Halte |cffFFFFFFShift|cffE1AB18 um 10 Punkte pro Attribut zu setzen|r",
["zhCN"] = "|cffE1AB18按住 |cffFFFFFFShift|cffE1AB18 可同时分配 10 点属性|r",
["zhTW"] = "|cffE1AB18按住 |cffFFFFFFShift|cffE1AB18 可同時分配 10 點屬性|r",
["esES"] = "|cffE1AB18Mantén pulsado |cffFFFFFFShift|cffE1AB18 para asignar 10 puntos por estadística|r",
["esMX"] = "|cffE1AB18Mantén pulsado |cffFFFFFFShift|cffE1AB18 para asignar 10 puntos por estadística|r",
}
CLIENTEXTRABUTTONS_ALLSTM = {
["enUS"] = "|cffE1AB18Stamina|r",
["ruRU"] = "|cffE1AB18Выносливость|r",
["frFR"] = "|cffE1AB18Endurance|r",
["deDE"] = "|cffE1AB18Ausdauer|r",
["zhCN"] = "|cffE1AB18耐力|r",
["zhTW"] = "|cffE1AB18耐力|r",
["esES"] = "|cffE1AB18Aguante|r",
["esMX"] = "|cffE1AB18Aguante|r",
}
CLIENTEXTRABUTTONS_ALLAG = {
["enUS"] = "|cffE1AB18Agility|r",
["ruRU"] = "|cffE1AB18Ловкость|r",
["frFR"] = "|cffE1AB18Agilité|r",
["deDE"] = "|cffE1AB18Beweglichkeit|r",
["zhCN"] = "|cffE1AB18敏捷|r",
["zhTW"] = "|cffE1AB18敏捷|r",
["esES"] = "|cffE1AB18Agilidad|r",
["esMX"] = "|cffE1AB18Agilidad|r",
}
CLIENTEXTRABUTTONS_ALLINT = {
["enUS"] = "|cffE1AB18Intellect|r",
["ruRU"] = "|cffE1AB18Интеллект|r",
["frFR"] = "|cffE1AB18Intelligencet|r",
["deDE"] = "|cffE1AB18Intelligenz|r",
["zhCN"] = "|cffE1AB18智力|r",
["zhTW"] = "|cffE1AB18智力|r",
["esES"] = "|cffE1AB18Intelecto|r",
["esMX"] = "|cffE1AB18Intelecto|r",
}
CLIENTEXTRABUTTONS_ALLSPIRIT = {
["enUS"] = "|cffE1AB18Spirit|r",
["ruRU"] = "|cffE1AB18Дух|r",
["frFR"] = "|cffE1AB18Espritr",
["deDE"] = "|cffE1AB18Willenskraft|r",
["zhCN"] = "|cffE1AB18精神|r",
["zhTW"] = "|cffE1AB18精神|r",
["esES"] = "|cffE1AB18Espíritu|r",
["esMX"] = "|cffE1AB18Espíritu|r",
}
CLIENTEXTRABUTTONS_ALLOCATIONAVAILABLEPOINTS = {
["enUS"] = "|cffE1AB18Available Stat Points:|r",
["ruRU"] = "|cffE1AB18Доступных очков характеристик:|r",
["frFR"] = "|cffE1AB18Points de Statistique disponibles:|r",
["deDE"] = "|cffE1AB18Verfügbare Attributspunkte:|r",
["zhCN"] = "|cffE1AB18未分配属性点|r",
["zhTW"] = "|cffE1AB18未分配屬性點|r",
["esES"] = "|cffE1AB18Puntos de estadísticas disponibles:|r",
["esMX"] = "|cffE1AB18Puntos de estadísticas disponibles:|r",
}
CLIENTEXTRABUTTONS_PROGRESSIONMAIN = {
["enUS"] = "|cffFFC125Specialization List",
["ruRU"] = "|cffFFC125Список специализаций",
["frFR"] = "|cffFFC125Specialization List",
["deDE"] = "|cffFFC125Specialization List",
["zhCN"] = "|cffFFC125Specialization List|r",
["zhTW"] = "|cffFFC125Specialization List|r",
["esES"] = "|cffFFC125Specialization List|r",
["esMX"] = "|cffFFC125Specialization List|r",
}
CLIENTEXTRABUTTONS_BALDRU = {
["enUS"] = "Balance Druid",
["ruRU"] = "Друид Баланс",
["frFR"] = "Druide Equilibre",
["deDE"] = "Gleichgewichts Druide",
["zhCN"] = "平衡德鲁伊",
["zhTW"] = "平衡德魯伊",
["esES"] = "Druida Equilibrio",
["esMX"] = "Druida Equilibrio",
}
CLIENTEXTRABUTTONS_FERDRU = {
["enUS"] = "Feral Druid",
["ruRU"] = "Друид Неистовство",
["frFR"] = "Druide Farouche",
["deDE"] = "Wildheits Druide",
["zhCN"] = "野性德鲁伊",
["zhTW"] = "野性德魯伊",
["esES"] = "Druida Feral",
["esMX"] = "Druida Feral",
}
CLIENTEXTRABUTTONS_RESTDRU = {
["enUS"] = "Restoration Druid",
["ruRU"] = "Друид Восстановление",
["frFR"] = "Druide Restauration",
["deDE"] = "Wiederherstellungs Druide",
["zhCN"] = "恢复德鲁伊",
["zhTW"] = "恢復德魯伊",
["esES"] = "Druida Restauración",
["esMX"] = "Druida Restauración",
}
CLIENTEXTRABUTTONS_BMHUNT = {
["enUS"] = "Beast Mastery Hunter",
["ruRU"] = "Охотник Повелитель Зверей",
["frFR"] = "Chasseur Maîtrise des Bêtesr",
["deDE"] = "Tierherrschafts Jäger",
["zhCN"] = "兽王猎人",
["zhTW"] = "獸王獵人",
["esES"] = "Cazador Bestias",
["esMX"] = "Cazador Bestias",
}
CLIENTEXTRABUTTONS_MARKHUNT = {
["enUS"] = "Marksmanship Hunter",
["ruRU"] = "Охотник Стрельба",
["frFR"] = "Chasseur Précisionr",
["deDE"] = "Treffsicherheits Jäger",
["zhCN"] = "射击猎人",
["zhTW"] = "射擊獵人",
["esES"] = "Cazador Puntería",
["esMX"] = "Cazador Puntería",
}
CLIENTEXTRABUTTONS_SURVHUNT = {
["enUS"] = "Survival Hunter",
["ruRU"] = "Охотник Выживание",
["frFR"] = "Chasseur Survie",
["deDE"] = "Überlebens Jäger",
["zhCN"] = "生存猎人",
["zhTW"] = "生存獵人",
["esES"] = "Cazador Supervivencia",
["esMX"] = "Cazador Supervivencia",
}
CLIENTEXTRABUTTONS_ARCMAGE = {
["enUS"] = "Arcane Mage",
["ruRU"] = "Маг Тайная Магия",
["frFR"] = "Mage Arcanes",
["deDE"] = "Arkan Magier",
["zhCN"] = "奥术法师",
["zhTW"] = "奧術法師",
["esES"] = "Mago Arcano",
["esMX"] = "Mago Arcano",
}
CLIENTEXTRABUTTONS_FIREMAGE = {
["enUS"] = "Fire Mage",
["ruRU"] = "Маг Огонь",
["frFR"] = "Mage Feu",
["deDE"] = "Feuer Magier",
["zhCN"] = "火焰法师",
["zhTW"] = "火焰法師",
["esES"] = "Mago Fuego",
["esMX"] = "Mago Fuego",
}
CLIENTEXTRABUTTONS_FROSTMAGE = {
["enUS"] = "Frost Mage",
["ruRU"] = "Маг Лед",
["frFR"] = "Mage Givre",
["deDE"] = "Frost Magier",
["zhCN"] = "冰霜法师",
["zhTW"] = "冰霜法師",
["esES"] = "Mago Escarcha",
["esMX"] = "Mago Escarcha",
}
CLIENTEXTRABUTTONS_HOLYPAL = {
["enUS"] = "Holy Paladin",
["ruRU"] = "Паладин Святость",
["frFR"] = "Paladin Sacré",
["deDE"] = "Heilig Paladin",
["zhCN"] = "神圣圣骑士",
["zhTW"] = "神聖聖騎士",
["esES"] = "Paladín Sagrado",
["esMX"] = "Paladín Sagrado",
}
CLIENTEXTRABUTTONS_PROTOPAL = {
["enUS"] = "Protection Paladin",
["ruRU"] = "Паладин Защита",
["frFR"] = "Paladin Protection",
["deDE"] = "Schutz Paladin",
["zhCN"] = "防御圣骑士",
["zhTW"] = "防禦聖騎士",
["esES"] = "Paladín Protección",
["esMX"] = "Paladín Protección",
}
CLIENTEXTRABUTTONS_RETROPAL = {
["enUS"] = "Retribution Paladin",
["ruRU"] = "Паладин Возмездие",
["frFR"] = "Paladin Vindicte",
["deDE"] = "Vegeltungs Paladin",
["zhCN"] = "惩戒圣骑士",
["zhTW"] = "懲戒聖騎士",
["esES"] = "Paladín Reprensión",
["esMX"] = "Paladín Reprensión",
}
CLIENTEXTRABUTTONS_DISCPRI = {
["enUS"] = "Discipline Priest",
["ruRU"] = "Жрец Послушание",
["frFR"] = "Prêtre Discipline",
["deDE"] = "Disziplin Priester",
["zhCN"] = "戒律牧师",
["zhTW"] = "戒律牧師",
["esES"] = "Sacerdote Disciplina",
["esMX"] = "Sacerdote Disciplina",
}
CLIENTEXTRABUTTONS_HOLYPRI = {
["enUS"] = "Holy Priest",
["ruRU"] = "Жрец Святость",
["frFR"] = "Prêtre Sacré",
["deDE"] = "Heilig Priester",
["zhCN"] = "神圣牧师",
["zhTW"] = "神聖牧師",
["esES"] = "Sacerdote Sagrado",
["esMX"] = "Sacerdote Sagrado",
}
CLIENTEXTRABUTTONS_SHADOWPRI = {
["enUS"] = "Shadow Priest",
["ruRU"] = "Жрец Тьма",
["frFR"] = "Prêtre Ombre",
["deDE"] = "Schatten Priester",
["zhCN"] = "黑暗牧师",
["zhTW"] = "黑暗牧師",
["esES"] = "Sacerdote Sombras",
["esMX"] = "Sacerdote Sombras",
}
CLIENTEXTRABUTTONS_ASSROGUE = {
["enUS"] = "Assassination Rogue",
["ruRU"] = "Разбойник Убийца",
["frFR"] = "Voleur Assassinat",
["deDE"] = "Meucheln Schurke",
["zhCN"] = "刺杀潜行者",
["zhTW"] = "刺殺潛行者",
["esES"] = "Pícaro Asesinato",
["esMX"] = "Pícaro Asesinato",
}
CLIENTEXTRABUTTONS_COMBATROGUE = {
["enUS"] = "Combat Rogue",
["ruRU"] = "Разбойник Бой",
["frFR"] = "Voleur Combat",
["deDE"] = "Kampf Schurke",
["zhCN"] = "战斗潜行者",
["zhTW"] = "戰鬥潛行者",
["esES"] = "Pícaro Combate",
["esMX"] = "Pícaro Combate",
}
CLIENTEXTRABUTTONS_SUBROGUE = {
["enUS"] = "Subtlety Rogue",
["ruRU"] = "Разбойник Скрытность",
["frFR"] = "Voleur Finesse",
["deDE"] = "Täuschungs Schurke",
["zhCN"] = "敏锐潜行者",
["zhTW"] = "敏銳潛行者",
["esES"] = "Pícaro Sutileza",
["esMX"] = "Pícaro Sutileza",
}
CLIENTEXTRABUTTONS_ELSHAM = {
["enUS"] = "Elemental Shaman",
["ruRU"] = "Шаман Стихии",
["frFR"] = "Chaman Elémentaire",
["deDE"] = "Elementar Schamane",
["zhCN"] = "元素萨满",
["zhTW"] = "元素薩滿",
["esES"] = "Chamán Elemental",
["esMX"] = "Chamán Elemental",
}
CLIENTEXTRABUTTONS_ENCHSHAM = {
["enUS"] = "Enhancement Shaman",
["ruRU"] = "Шаман Совершенствование",
["frFR"] = "Chaman Amélioration",
["deDE"] = "Verstäker Schamane",
["zhCN"] = "增强萨满",
["zhTW"] = "增強薩滿",
["esES"] = "Chamán Mejora",
["esMX"] = "Chamán Mejora",
}
CLIENTEXTRABUTTONS_RESTSHAM = {
["enUS"] = "Restoration Shaman",
["ruRU"] = "Шаман Восстановление",
["frFR"] = "Chaman Restauration",
["deDE"] = "Wiederherstellungs Schamane",
["zhCN"] = "恢复萨满",
["zhTW"] = "恢復薩滿",
["esES"] = "Chamán Restauración",
["esMX"] = "Chamán Restauración",
}
CLIENTEXTRABUTTONS_AFFLOCK = {
["enUS"] = "Affliction Warlock",
["ruRU"] = "Чернокнижник Осквернение",
["frFR"] = "Démoniste Affliction",
["deDE"] = "Gebrechen Hexenmeister",
["zhCN"] = "痛苦术士",
["zhTW"] = "痛苦術士",
["esES"] = "Brujo Aflicción",
["esMX"] = "Brujo Aflicción",
}
CLIENTEXTRABUTTONS_DEMLOCK = {
["enUS"] = "Demonology Warlock",
["ruRU"] = "Чернокнижник Демонология",
["frFR"] = "Démoniste Démonologie",
["deDE"] = "Dämonologie Hexenmeister",
["zhCN"] = "恶魔术士",
["zhTW"] = "惡魔術士",
["esES"] = "Brujo Demonología",
["esMX"] = "Brujo Demonología",
}
CLIENTEXTRABUTTONS_DESTROLOCK = {
["enUS"] = "Destruction Warlock",
["ruRU"] = "Чернокнижник Разрушение",
["frFR"] = "Démoniste Destruction",
["deDE"] = "Zerstörungs Hexenmeister",
["zhCN"] = "毁灭术士",
["zhTW"] = "毀滅術士",
["esES"] = "Brujo Destrucción",
["esMX"] = "Brujo Destrucción",
}
CLIENTEXTRABUTTONS_ARMSWAR = {
["enUS"] = "Arms Warrior",
["ruRU"] = "Воин Оружие",
["frFR"] = "Guerrier Armes",
["deDE"] = "Waffen Krieger",
["zhCN"] = "武器战士",
["zhTW"] = "武器戰士",
["esES"] = "Guerrero Armas",
["esMX"] = "Guerrero Armas",
}
CLIENTEXTRABUTTONS_FURYWAR = {
["enUS"] = "Fury Warrior",
["ruRU"] = "Воин Ярость",
["frFR"] = "Guerrier Furie",
["deDE"] = "Furor Krieger",
["zhCN"] = "狂暴战士",
["zhTW"] = "狂暴戰士",
["esES"] = "Guerrero Furia",
["esMX"] = "Guerrero Furia",
}
CLIENTEXTRABUTTONS_PROTOWAR = {
["enUS"] = "Protection Warrior",
["ruRU"] = "Воин Защита",
["frFR"] = "Guerrier Protection",
["deDE"] = "Schutz Krieger",
["zhCN"] = "防御战士",
["zhTW"] = "防禦戰士",
["esES"] = "Guerrero Protección",
["esMX"] = "Guerrero Protección",
}
CLIENTEXTRABUTTONS_GENERALSPELLS = {
["enUS"] = "General",
["ruRU"] = "Общие заклинания",
["frFR"] = "Général",
["deDE"] = "Generell",
["zhCN"] = "综合",
["zhTW"] = "綜合",
["esES"] = "General",
["esMX"] = "General",
}
CLIENTEXTRABUTTONS_LEARNGRAY = {
["enUS"] = "|cff6b625bUnlearn|r",
["ruRU"] = "|cff6b625bЗабыть|r",
["frFR"] = "|cff6b625bApprendre|r",
["deDE"] = "|cff6b625bLernen|r",
["zhCN"] = "|cff6b625b学习|r",
["zhTW"] = "|cff6b625b學習|r",
["esES"] = "|cff6b625bAprender|r",
["esMX"] = "|cff6b625bAprender|r",
}
CLIENTEXTRABUTTONS_REQUIRESLEVEL = {
["enUS"] = "Requires: Level |cffFFFFFF",
["ruRU"] = "Требуетя: Уровень |cffFFFFFF",
["frFR"] = "Requiert: Niveau |cffFFFFFF",
["deDE"] = "Benötigt Level |cffFFFFFF",
["zhCN"] = "需要: 等级 |cffFFFFFF",
["zhTW"] = "需要: 等級 |cffFFFFFF",
["esES"] = "Requiere: Nivel |cffFFFFFF",
["esMX"] = "Requiere: Nivel |cffFFFFFF",
}
CLIENTEXTRABUTTONS_COST = {
["enUS"] = "Cost: |cffFFFFFF",
["ruRU"] = "Стоимость: |cffFFFFFF",
["frFR"] = "Coût: |cffFFFFFF",
["deDE"] = "Kosten |cffFFFFFF",
["zhCN"] = "花费: |cffFFFFFF",
["zhTW"] = "花費: |cffFFFFFF",
["esES"] = "Cuesta: |cffFFFFFF",
["esMX"] = "Cuesta: |cffFFFFFF",
}
CLIENTEXTRABUTTONS_AETIP = {
["enUS"] = " |TInterface\\Icons\\inv_custom_abilityessence.blp:12:12:0:0|t ",
["ruRU"] = " |TInterface\\Icons\\inv_custom_abilityessence.blp:12:12:0:0|t ",
["frFR"] = " |TInterface\\Icons\\inv_custom_abilityessence.blp:12:12:0:0|t ",
["deDE"] = " |TInterface\\Icons\\inv_custom_abilityessence.blp:12:12:0:0|t ",
["zhCN"] = " |TInterface\\Icons\\inv_custom_abilityessence.blp:12:12:0:0|t ",
["zhTW"] = " |TInterface\\Icons\\inv_custom_abilityessence.blp:12:12:0:0|t ",
["esES"] = " |TInterface\\Icons\\inv_custom_abilityessence.blp:12:12:0:0|t ",
["esMX"] = " |TInterface\\Icons\\inv_custom_abilityessence.blp:12:12:0:0|t ",
}
CLIENTEXTRABUTTONS_TETIP = {
["enUS"] = " |TInterface\\Icons\\inv_custom_talentessence.blp:12:12:0:0|t",
["ruRU"] = " |TInterface\\Icons\\inv_custom_talentessence.blp:12:12:0:0|t",
["frFR"] = " |TInterface\\Icons\\inv_custom_talentessence.blp:12:12:0:0|t",
["deDE"] = " |TInterface\\Icons\\inv_custom_talentessence.blp:12:12:0:0|t",
["zhCN"] = " |TInterface\\Icons\\inv_custom_talentessence.blp:12:12:0:0|t ",
["zhTW"] = " |TInterface\\Icons\\inv_custom_talentessence.blp:12:12:0:0|t ",
["esES"] = " |TInterface\\Icons\\inv_custom_talentessence.blp:12:12:0:0|t",
["esMX"] = " |TInterface\\Icons\\inv_custom_talentessence.blp:12:12:0:0|t",
}
CLIENTEXTRABUTTONS_MAXOUT = {
["enUS"] = "Maxed Out",
["ruRU"] = "Достигнут Максимум",
["frFR"] = "Maximum Atteint",
["deDE"] = "Maximum erreicht",
["zhCN"] = "满级",
["zhTW"] = "滿級:",
["esES"] = "Agotado",
["esMX"] = "Agotado",
}
CLIENTEXTRABUTTONS_MAX = {
["enUS"] = "|cff6b625bMax|r",
["ruRU"] = "|cff6b625bМаксимум|r",
["frFR"] = "|cff6b625bMaximum|r",
["deDE"] = "|cff6b625bMaximum|r",
["zhCN"] = "|cff6b625b满|r",
["zhTW"] = "|cff6b625b滿|r",
["esES"] = "|cff6b625bMáximo|r",
["esMX"] = "|cff6b625bMáximo|r",
}
CLIENTEXTRABUTTONS_LEARNNORMAL = {
["enUS"] = "Learn",
["ruRU"] = "Изучить",
["frFR"] = "Apprendre",
["deDE"] = "Lernen",
["zhCN"] = "学习",
["zhTW"] = "學習",
["esES"] = "Aprender",
["esMX"] = "Aprender",
}
CLIENTEXTRABUTTONS_SCROLLOFUNLHINT = {
["enUS"] = "\n|cffFF0000Click on the icon to use |cff00FF00[Scroll of Unlearning]|r",
["ruRU"] = "\n|cffFF0000Нажмите на иконку, чтобы использовать |cff00FF00[Свиток Потери Знания]|r",
["frFR"] = "\n|cffFF0000Cliquez sur l’icône pour utiliser un |cff00FF00[Parchemin d’Oubli]|r",
["deDE"] = "\n|cffFF0000 Klicke auf das Icon um die |cff00FF00[Schriftrolle des Verlernens]|r zu benuzten|r",
["zhCN"] = "\n|cffFF0000点击图像使用 |cff00FF00[忘却卷轴]|r",
["zhTW"] = "\n|cffFF0000點擊圖像使用 |cff00FF00[忘卻卷軸]|r",
["esES"] = "\n|cffFF0000Pulsa en el icono para usar |cff00FF00[Pergamino de Olvido]|r",
["esMX"] = "\n|cffFF0000Pulsa en el icono para usar |cff00FF00[Pergamino de Olvido]|r",
}
CLIENTEXTRABUTTONS_SCROLLOFFORTUNEHINT = {
["enUS"] = "\n|cffFF0000Click on the icon to use |cff00FF00[Scroll of Fortune]|r",
["ruRU"] = "\n|cffFF0000Click on the icon to use |cff00FF00[Scroll of Fortune]|r",
["frFR"] = "\n|cffFF0000Click on the icon to use |cff00FF00[Scroll of Fortune]|r",
["deDE"] = "\n|cffFF0000Click on the icon to use |cff00FF00[Scroll of Fortune]|r",
["zhCN"] = "\n|cffFF0000Click on the icon to use |cff00FF00[Scroll of Fortune]|r",
["zhTW"] = "\n|cffFF0000Click on the icon to use |cff00FF00[Scroll of Fortune]|r",
["esES"] = "\n|cffFF0000Click on the icon to use |cff00FF00[Scroll of Fortune]|r",
["esMX"] = "\n|cffFF0000Click on the icon to use |cff00FF00[Scroll of Fortune]|r",
}
CLIENTEXTRABUTTONS_RANK = {
["enUS"] = "\nRank ",
["ruRU"] = "\nРанк ",
["frFR"] = "\nRang ",
["deDE"] = "\nRang ",
["zhCN"] = "\n等级 ",
["zhTW"] = "\n等級 ",
["esES"] = "\nRango ",
["esMX"] = "\nRango ",
}
CLIENTEXTRABUTTONS_UPGRADE = {
["enUS"] = "|cffE1AB18Upgrade|r",
["ruRU"] = "|cffE1AB18Улучшить|r",
["frFR"] = "|cffE1AB18Amélioration|r",
["deDE"] = "|cffE1AB18Erweitern|r",
["zhCN"] = "|cffE1AB18升级|r",
["zhTW"] = "|cffE1AB18升級|r",
["esES"] = "|cffE1AB18Mejorar|r",
["esMX"] = "|cffE1AB18Mejorar|r",
}
CLIENTEXTRABUTTONS_TALENT = {
["enUS"] = "Talent",
["ruRU"] = "Талант",
["frFR"] = "Talent",
["deDE"] = "Talente",
["zhCN"] = "天赋",
["zhTW"] = "天賦",
["esES"] = "Talento",
["esMX"] = "Talento",
}
CLIENTEXTRABUTTONS_UNLEARNTALENTDIALOG = {
["enUS"] = "Are you sure you want to\nunlearn the following talent?\n\n",
["ruRU"] = "Вы уверены, что хотите\nотменить изучение этого таланта?\n\n",
["frFR"] = "|cffFFFFFFApprendre|r",
["deDE"] = "Bist du sicher, dass du das folgende \nTalent verlernen  wills?",
["zhCN"] = "你确定要忘却\n此天赋?\n\n",
["zhTW"] = "你確定要忘卻\n此天賦?\n\n",
["esES"] = "Estás seguro de que quieres\nolvidar el siguiente talento?\n\n",
["esMX"] = "Estás seguro de que quieres\nolvidar el siguiente talento?\n\n",
}
CLIENTEXTRABUTTONS_LEARNWHITE = {
["enUS"] = "|cffFFFFFFLearn|r",
["ruRU"] = "|cffFFFFFFИзучить|r",
["frFR"] = "Are you sure you want to\nunlearn the following talent?\n\n",
["deDE"] = "|cffFFFFFFLernen|r",
["zhCN"] = "|cffFFFFFF学习|r",
["zhTW"] = "|cffFFFFFF學習|r",
["esES"] = "|cffFFFFFFAprender|r",
["esMX"] = "|cffFFFFFFAprender|r",
}
CLIENTEXTRABUTTONS_KNOWN = {
["enUS"] = "Click to unlearn that spell",
["ruRU"] = "Нажмите чтобы забыть заклинание",
["frFR"] = "Click to unlearn that spell",
["deDE"] = "Click to unlearn that spell",
["zhCN"] = "Click to unlearn that spell",
["zhTW"] = "Click to unlearn that spell",
["esES"] = "Click to unlearn that spell",
["esMX"] = "Click to unlearn that spell",
}
CLIENTEXTRABUTTONS_EMPTY = {
["enUS"] = "|cff6b625bEmpty|r",
["ruRU"] = "|cff6b625bПусто|r",
["frFR"] = "|cff6b625bVide|r",
["deDE"] = "|cff6b625bLeer|r",
["zhCN"] = "|cff6b625b空|r",
["zhTW"] = "|cff6b625b空|r",
["esES"] = "|cff6b625bVacío|r",
["esMX"] = "|cff6b625bVacío|r",
}
CLIENTEXTRABUTTONS_UNLEARNSPELLDIALOG = {
["enUS"] = "Are you sure you want to\nunlearn the following spell?\n\n",
["ruRU"] = "Вы уверены, что хотите\nотменить изучение этого заклинания?\n\n",
["frFR"] = "Etes-vous sûr de vouloir \noublier le sort suivant?\n\n",
["deDE"] = "Bist du sicher, dass du den \nfolgenden Zauber verlernen möchtest?\n\n",
["zhCN"] = "你确定要忘却\n此技能?\n\n",
["zhTW"] = "你確定要忘卻\n此技能?\n\n",
["esES"] = "Estás seguro de que quieres\nolvidar el siguiente hechizo?\n\n",
["esMX"] = "Estás seguro de que quieres\nolvidar el siguiente hechizo?\n\n",
}
CLIENTEXTRABUTTONS_AECOUNT = {
["enUS"] = "|cffE1AB18AE: |cffFFFFFF",
["ruRU"] = "|cffE1AB18ЭС: |cffFFFFFF",
["frFR"] = "|cffE1AB18ETe: |cffFFFFFF",
["deDE"] = "|cffE1AB18ETa: |cffFFFFFF",
["zhCN"] = "|cffE1AB18技能点: |cffFFFFFF",
["zhTW"] = "|cffE1AB18技能點: |cffFFFFFF",
["esES"] = "|cffE1AB18EH: |cffFFFFFF",
["esMX"] = "|cffE1AB18EH: |cffFFFFFF",
}
CLIENTEXTRABUTTONS_TECOUNT = {
["enUS"] = " |cffE1AB18TE: |cffFFFFFF",
["ruRU"] = " |cffE1AB18ЭТ: |cffFFFFFF",
["frFR"] = " |cffE1AB18ETa: |cffFFFFFF",
["deDE"] = " |cffE1AB18ETa: |cffFFFFFF",
["zhCN"] = " |cffE1AB18天赋点: |cffFFFFFF",
["zhTW"] = " |cffE1AB18天賦點: |cffFFFFFF",
["esES"] = " |cffE1AB18ET: |cffFFFFFF",
["esMX"] = " |cffE1AB18ET: |cffFFFFFF",
}
CLIENTEXTRABUTTONS_UNLEARNABILITYDIALOG = {
["enUS"] = "Are you sure you want to\nunlearn the following ability?\n",
["ruRU"] = "Вы уверены, что хотите\nотменить изучение этой способности?\n",
["frFR"] = "Etes-vous sûr de vouloir \noublier la technique suivante?\n",
["deDE"] = "Bist du sicher, dass du die folgendende Fähigkeit \nverlernen möchstest?\n",
["zhCN"] = "你确定要忘却\n此技能?\n",
["zhTW"] = "你確定要忘卻\n此技能?\n",
["esES"] = "Estás seguro de que quieres\nolvidar la siguiente habilidad?\n",
["esMX"] = "Estás seguro de que quieres\nolvidar la siguiente habilidad?\n",
}
CLIENTEXTRABUTTONS_ACCEPT = {
["enUS"] = "Accept",
["ruRU"] = "Принять",
["frFR"] = "Accepter",
["deDE"] = "Annehmen",
["zhCN"] = "确定",
["zhTW"] = "確定",
["esES"] = "Aceptar",
["esMX"] = "Aceptar",
}
CLIENTEXTRABUTTONS_CANCEL = {
["enUS"] = "Cancel",
["ruRU"] = "Отмена",
["frFR"] = "Annuler",
["deDE"] = "Abbrechen",
["zhCN"] = "取消",
["zhTW"] = "取消",
["esES"] = "Cancelar",
["esMX"] = "Cancelar",
}
CLIENTEXTRABUTTONS_LEARNGRAY2 = {
["enUS"] = "|cff6b625bLearn|r",
["ruRU"] = "|cff6b625bИзучить|r",
["frFR"] = "|cff6b625bApprendre|r",
["deDE"] = "|cff6b625bLernen|r",
["zhCN"] = "|cff6b625b学习|r",
["zhTW"] = "|cff6b625b學習|r",
["esES"] = "|cff6b625bAprender|r",
["esMX"] = "|cff6b625bAprender|r",
}
CLIENTEXTRABUTTONS_NEXTRESETABILITYP = {
["enUS"] = "|cffE1AB18Next Reset: |TInterface\\Icons\\inv_custom_abilitypurge.blp:14:14:0:0|t|cffFFFFFFx1",
["ruRU"] = "|cffE1AB18Следующий сброс: |TInterface\\Icons\\inv_custom_abilitypurge.blp:14:14:0:0|t|cffFFFFFFx1",
["frFR"] = "|cffE1AB18Prochaine Réinitialisationt: |TInterface\\Icons\\inv_custom_abilitypurge.blp:14:14:0:0|t|cffFFFFFFx1",
["deDE"] = "|cffE1AB18Nächste Zurücksetzung: |TInterface\\Icons\\inv_custom_abilitypurge.blp:14:14:0:0|t|cffFFFFFFx1",
["zhCN"] = "|cffE1AB18下一次重置: |TInterface\\Icons\\inv_custom_abilitypurge.blp:14:14:0:0|t|cffFFFFFFx1",
["zhTW"] = "|cffE1AB18下一次重置: |TInterface\\Icons\\inv_custom_abilitypurge.blp:14:14:0:0|t|cffFFFFFFx1",
["esES"] = "|cffE1AB18Siguiente Reset: |TInterface\\Icons\\inv_custom_abilitypurge.blp:14:14:0:0|t|cffFFFFFFx1",
["esMX"] = "|cffE1AB18Siguiente Reset: |TInterface\\Icons\\inv_custom_abilitypurge.blp:14:14:0:0|t|cffFFFFFFx1",
}
CLIENTEXTRABUTTONS_RESETABILITYP = {
["enUS"] = "|cffE1AB18Reset: |TInterface\\Icons\\inv_custom_abilitypurge.blp:14:14:0:0|t|cffFFFFFFx1",
["ruRU"] = "|cffE1AB18Сброс: |TInterface\\Icons\\inv_custom_abilitypurge.blp:14:14:0:0|t|cffFFFFFFx1",
["frFR"] = "|cffE1AB18Réinitialisation: |TInterface\\Icons\\inv_custom_abilitypurge.blp:14:14:0:0|t|cffFFFFFFx1",
["deDE"] = "|cffE1AB18Zurücksetzung: |TInterface\\Icons\\inv_custom_abilitypurge.blp:14:14:0:0|t|cffFFFFFFx1",
["zhCN"] = "|cffE1AB18重置: |TInterface\\Icons\\inv_custom_abilitypurge.blp:14:14:0:0|t|cffFFFFFFx1",
["zhTW"] = "|cffE1AB18重置: |TInterface\\Icons\\inv_custom_abilitypurge.blp:14:14:0:0|t|cffFFFFFFx1",
["esES"] = "|cffE1AB18Restablecer: |TInterface\\Icons\\inv_custom_abilitypurge.blp:14:14:0:0|t|cffFFFFFFx1",
["esMX"] = "|cffE1AB18Restablecer: |TInterface\\Icons\\inv_custom_abilitypurge.blp:14:14:0:0|t|cffFFFFFFx1",
}

	--NewbieHelp_Client.LUA--

NEWBIEHELP_TIP_MAIN = {
["enUS"] = "|cffFFFFFFWelcome! |rAscension|cffFFFFFF is a progressive |rclassless|cffFFFFFF game. Over the course of your progression, you'll receive important tutorials that will help you understand how Ascension works. |rMake sure to read your tutorials!|cffFFFFFF No matter how you decide to play, you can expect to be able to fully live out your fantasy of a hero truly unique to you!|r",
}
NEWBIEHELP_TIP_ADDONSETTINGS = {
["enUS"] = "|cffFFFFFFPlease, check your |raddons|cffFFFFFF enabled. Ascension |rrequires|cffFFFFFF you to use |rAscension AIO|cffFFFFFF and Ascension Resources addons. You can |rset|cffFFFFFF them as you wish, that is why you have two of Ascension Resources addons, |rone|cffFFFFFF is for using with default User Interface and the |rsecond|cffFFFFFF if you're experienced and have a lot of custom addons in your UI.|r",
}
NEWBIEHELP_TIP_CHARUPGRADES = {
["enUS"] = "|cffFFFFFFOn Ascension, you have a lot of |rnew|cffFFFFFF features. You can access them using the |rHero Creator|cffFFFFFF on your |rMain Menu Bar|cffFFFFFF or through the |rquick access|cffFFFFFF frame on your screen.|r",
}
NEWBIEHELP_TIP_STATALLOCATION = {
["enUS"] = "|cffFFFFFFIn Ascension you are able to allocate stat points into any of base stat. Typically, as a rule: |rStrength|cffFFFFFF is for attack power, |rAgility|cffFFFFFF is less attack power but gives critical strike for physical abilities, |rstamina|cffFFFFFF is how much health you can have, |rspirit|cffFFFFFF is your mana regeneration and |rintellect|cffFFFFFF is your spell power and spell crit. With our classless system, however you will discover many more possibilities!|r",
}
NEWBIEHELP_TIP_PORTRAIT = {
["enUS"] = "|cffFFFFFFThe Classless system means that every user is able to use all three |rresources|cffFFFFFF: |rmana|cffFFFFFF, |rrage|cffFFFFFF and |renergy|cffFFFFFF. To make it clear and easy to control, we include all three on your |rplayer portrait|cffFFFFFF. The |rhorizontal|cffFFFFFF bar is for energy and the |rvertical|cffFFFFFF bar is for rage.|r",
}
NEWBIEHELP_TIP_FFAPVP = {
["enUS"] = "|cffFFFFFFHigh-risk |rFFA|cffFFFFFF PVP, this means that you can attack players basically anytime you are outside of a town. The stakes are high. Be |rcareful|cffFFFFFF out there!|r",
}
NEWBIEHELP_TIP_CHARPROGRESSION = {
["enUS"] = "|cffFFFFFFDing! You now have 2 |rability essences|cffFFFFFF! Now you can choose any |rability|cffFFFFFF from the Hero Creator. Click on the book, then on the |rclass|cffFFFFFF which has the |rability|cffFFFFFF you would like and finally on the left side of the window. Think of the possibilities!|r",
}
NEWBIEHELP_TIP_RESETMAIN = {
["enUS"] = "|cffFFFFFFIt is time to choose your first talent and a new ability. Choose wisely, but don't fret you can always reset and try new things through the Hero Creator!|r",
}
NEWBIEHELP_TIP_FREERESETS = {
["enUS"] = "|cffFFFFFFNeed a |rchange|cffFFFFFF? Up until level 10 you have |rfree spell resets|cffFFFFFF to ensure you can play around with different play styles and discover what is right for you.|r",
}
NEWBIEHELP_TIP_RES = {
["enUS"] = "|cffFFFFFF|rRandom Enchants|cffFFFFFF! Using a Mystic Altar, you can augment your weapons and armor with these unique effects to alter your playstyle. You will also discover gear that has powerful enchants that you like. These can be extracted and stored for continual use at a Mystic Altar. Enchants take your hero crafting to the next level!|r",
}
NEWBIEHELP_TIP_FREEOVER = {
["enUS"] = "|cffFFFFFFFreedom isn’t free! The free resets are now over but fear not as you can reset your spell or talent choices by simply using |r[Ability purge]|cffFFFFFF or |r[Talent Purge]|cffFFFFFF. You start off with |r3 of each|cffFFFFFF but after you run out you can use gold to reset further but the cost increases over time.|r",
}
NEWBIEHELP_TIP_PVPLOOT = {
["enUS"] = "|cffFFFFFFHigh Risk mode means loot drop on death. For You and your Enemies. |cffFFFFFF With increased gear drops in the world, including dungeon and raid gear, you will find gear just as quick as you might lose it!  |cffFFFFFF! You only lose loot to players within your level range.|r",
}
NEWBIEHELP_TIP_FFAENABLED = {
["enUS"] = "|cffFFFFFF|rFFA|cffFFFFFF PVP is |renabled|cffFFFFFF at level 20! Soon you will be able to kill and be killed by ANYONE, even your |rown faction,|cffFFFFFF if they are willing to become a criminal. May the odds be ever in your favor!|r",
}
NEWBIEHELP_TITLE = {
["enUS"] = "Ascension Survival Guide",
["ruRU"] = "Ascension - инструкция по выживанию",
}
NEWBIEHELP_NEXT = {
["enUS"] = "Next",
["ruRU"] = "Далее",
}
NEWBIEHELP_PREV = {
["enUS"] = "Prev",
["ruRU"] = "Назад",
}
