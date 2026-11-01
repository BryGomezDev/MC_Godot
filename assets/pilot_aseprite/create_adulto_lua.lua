local OUT = "C:/Users/BryDev/OneDrive/Documentos/merry-christmas/assets/pilot_aseprite/adulto.aseprite"
local spr = Sprite(48, 48, ColorMode.INDEXED)
local pal = Palette(16)
pal:setColor(0,  Color{a=0,r=0,g=0,b=0})
pal:setColor(1,  Color{r=232,g=184,b=138})
pal:setColor(2,  Color{r=196,g=140,b=92})
pal:setColor(3,  Color{r=245,g=208,b=169})
pal:setColor(4,  Color{r=61,g=43,b=31})
pal:setColor(5,  Color{r=92,g=61,b=46})
pal:setColor(6,  Color{r=176,g=48,b=48})
pal:setColor(7,  Color{r=122,g=26,b=26})
pal:setColor(8,  Color{r=217,g=64,b=64})
pal:setColor(9,  Color{r=30,g=42,b=58})
pal:setColor(10, Color{r=45,g=63,b=85})
pal:setColor(11, Color{r=26,g=18,b=8})
pal:setColor(12, Color{r=46,g=32,b=16})
pal:setColor(13, Color{r=240,g=234,b=214})
pal:setColor(14, Color{r=224,g=120,b=48})
pal:setColor(15, Color{a=0,r=0,g=0,b=0})
spr:setPalette(pal)
local layer = spr.layers[1]
layer.name = "Character"
for i = 1, 4 do spr:newEmptyFrame() end
local function rect(img, x, y, w, h, c)
  for py = y, y+h-1 do
    for px = x, x+w-1 do
      img:drawPixel(px, py, c)
    end
  end
end
local function drawChar(img, lx, rx, la, ra)
  rect(img, 20, 3, 8, 4, 4)
  img:drawPixel(19, 4, 4) img:drawPixel(28, 4, 4)
  rect(img, 20, 7, 8, 5, 1)
  img:drawPixel(26, 8, 4) img:drawPixel(25, 10, 2)
  img:drawPixel(19, 9, 2) img:drawPixel(28, 9, 2)
  rect(img, 22, 12, 4, 3, 1)
  rect(img, 17, 15, 14, 2, 14)
  rect(img, 18, 17, 12, 13, 6)
  for y = 17, 29 do img:drawPixel(18, y, 8) end
  for y = 17, 29 do img:drawPixel(29, y, 7) end
  rect(img, 14, 17+la, 4, 9, 6) rect(img, 14, 26+la, 4, 2, 1)
  rect(img, 30, 17+ra, 4, 9, 6) rect(img, 30, 26+ra, 4, 2, 1)
  rect(img, 18, 30, 12, 2, 7)
  rect(img, 18, 32, 5, 10, 9)
  for y = 32, 41 do img:drawPixel(22, y, 10) end
  rect(img, 25, 32, 5, 10, 9)
  for y = 32, 41 do img:drawPixel(25, y, 10) end
  rect(img, 16+lx, 42, 8, 4, 11)
  img:drawPixel(16+lx, 42, 12) img:drawPixel(17+lx, 42, 12)
  rect(img, 24+rx, 42, 8, 4, 11)
  img:drawPixel(24+rx, 42, 12) img:drawPixel(25+rx, 42, 12)
end
local img1 = spr:newCel(layer, spr.frames[1]).image
drawChar(img1, 0, 0, 0, 0)
local cel2 = spr:newCel(layer, spr.frames[2])
drawChar(cel2.image, -2, 2, -1, 1)
local cel3 = spr:newCel(layer, spr.frames[3])
drawChar(cel3.image, 0, 0, 0, 0)
local cel4 = spr:newCel(layer, spr.frames[4])
drawChar(cel4.image, 2, -2, 1, -1)
local cel5 = spr:newCel(layer, spr.frames[5])
drawChar(cel5.image, 0, 0, 0, 0)
local t1 = spr:newTag(spr.frames[1], spr.frames[1]) t1.name = "idle"
local t2 = spr:newTag(spr.frames[2], spr.frames[5]) t2.name = "walk"
spr:saveAs(OUT)
