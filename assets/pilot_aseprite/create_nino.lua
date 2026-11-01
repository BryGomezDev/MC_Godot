local OUT = "C:/Users/BryDev/OneDrive/Documentos/merry-christmas/assets/pilot_aseprite/nino.aseprite"
local spr = Sprite(32, 32, ColorMode.INDEXED)
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
local function drawChild(img, lx, rx, la, ra)
  rect(img, 12, 2, 8, 3, 4)
  img:drawPixel(11, 3, 4) img:drawPixel(20, 3, 4)
  rect(img, 12, 5, 8, 6, 1)
  img:drawPixel(18, 6, 4) img:drawPixel(17, 8, 2)
  img:drawPixel(11, 7, 2) img:drawPixel(20, 7, 2)
  rect(img, 14, 11, 4, 2, 1)
  rect(img, 11, 13, 10, 2, 14)
  rect(img, 12, 15, 8, 9, 6)
  for y = 15, 23 do img:drawPixel(12, y, 8) end
  for y = 15, 23 do img:drawPixel(19, y, 7) end
  rect(img, 9, 15+la, 3, 7, 6) rect(img, 9, 22+la, 3, 2, 1)
  rect(img, 20, 15+ra, 3, 7, 6) rect(img, 20, 22+ra, 3, 2, 1)
  rect(img, 12, 24, 8, 1, 7)
  rect(img, 12, 25, 4, 5, 9)
  rect(img, 17, 25, 4, 5, 9)
  rect(img, 11+lx, 30, 6, 2, 11)
  img:drawPixel(11+lx, 30, 12)
  rect(img, 17+rx, 30, 6, 2, 11)
  img:drawPixel(17+rx, 30, 12)
end
local img1 = spr:newCel(layer, spr.frames[1]).image
drawChild(img1, 0, 0, 0, 0)
local cel2 = spr:newCel(layer, spr.frames[2])
drawChild(cel2.image, -1, 1, -1, 1)
local cel3 = spr:newCel(layer, spr.frames[3])
drawChild(cel3.image, 0, 0, 0, 0)
local cel4 = spr:newCel(layer, spr.frames[4])
drawChild(cel4.image, 1, -1, 1, -1)
local cel5 = spr:newCel(layer, spr.frames[5])
drawChild(cel5.image, 0, 0, 0, 0)
local t1 = spr:newTag(spr.frames[1], spr.frames[1]) t1.name = "idle"
local t2 = spr:newTag(spr.frames[2], spr.frames[5]) t2.name = "walk"
spr:saveAs(OUT)
