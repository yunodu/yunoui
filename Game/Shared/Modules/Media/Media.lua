-- LSM fonts/textures (drop files into yunoUI\Media\Fonts and Textures)
local MUI = unpack(yunoUI)
MUI.Media = MUI.Media or {}

local LSM = LibStub("LibSharedMedia-3.0", true)
if not LSM then return end

local base = "Interface\\AddOns\\yunoUI\\Media\\"

LSM:Register("font", "AvantGarde", base .. "Fonts\\AvantGarde.ttf")
LSM:Register("font", "AvantGarde Bold", base .. "Fonts\\AvantGardeBold.ttf")
LSM:Register("font", "AvantGarde Book", base .. "Fonts\\AvantGardeBook.ttf")
LSM:Register("font", "AvantGarde Medium", base .. "Fonts\\AvantGardeMedium.ttf")
LSM:Register("font", "GothamNarrowUltra", base .. "Fonts\\GothamNarrowUltra.ttf")

LSM:Register("statusbar", "Melli", base .. "Textures\\Melli")
LSM:Register("statusbar", "bar1", base .. "Textures\\bar1")
LSM:Register("statusbar", "bar2", base .. "Textures\\bar2")
LSM:Register("statusbar", "bar3", base .. "Textures\\bar3")
LSM:Register("statusbar", "bar4", base .. "Textures\\bar4")
LSM:Register("statusbar", "bar5", base .. "Textures\\bar5")
LSM:Register("statusbar", "bar6", base .. "Textures\\bar6")
LSM:Register("statusbar", "bar7", base .. "Textures\\bar7")
LSM:Register("statusbar", "EthricArrow", base .. "Textures\\EthricArrow")
LSM:Register("statusbar", "EthricArrow2", base .. "Textures\\EthricArrow2")
LSM:Register("statusbar", "EthricArrow3", base .. "Textures\\EthricArrow3")
LSM:Register("statusbar", "EthricArrow4", base .. "Textures\\EthricArrow4")
LSM:Register("statusbar", "EthricArrow5", base .. "Textures\\EthricArrow5")
LSM:Register("statusbar", "EthricArrow6", base .. "Textures\\EthricArrow6")
LSM:Register("statusbar", "EthricArrow7", base .. "Textures\\EthricArrow7")
LSM:Register("statusbar", "EthricArrow8", base .. "Textures\\EthricArrow8")
LSM:Register("statusbar", "EthricArrow9", base .. "Textures\\EthricArrow9")
LSM:Register("statusbar", "EthricArrow10", base .. "Textures\\EthricArrow10")
LSM:Register("statusbar", "mouseover-2", base .. "Textures\\mouseover-2")
LSM:Register("statusbar", "mouseover-3", base .. "Textures\\mouseover-3")
LSM:Register("statusbar", "mouseover-3-inwards", base .. "Textures\\mouseover-3-inwards")
