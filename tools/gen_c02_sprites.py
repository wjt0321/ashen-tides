#!/usr/bin/env python3
"""C02 专属像素资产：潮门、余烬喷井、迅捷敌、相位/余烬 FX。"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "art" / "c02" / "runtime"
OUT.mkdir(parents=True, exist_ok=True)
OUTLINE = (13, 21, 28, 255)
STONE_DARK = (49, 67, 70, 255)
STONE = (90, 113, 108, 255)
STONE_LIGHT = (154, 184, 164, 255)
TEAL = (75, 176, 174, 255)
TEAL_LIGHT = (156, 239, 220, 255)
EMBER = (239, 96, 55, 255)
EMBER_LIGHT = (255, 181, 87, 255)
EMBER_CORE = (255, 241, 177, 255)
DASHER = (55, 151, 164, 255)
DASHER_LIGHT = (111, 224, 208, 255)
DASHER_DARK = (27, 72, 91, 255)


def img(w,h):
    im=Image.new("RGBA",(w,h),(0,0,0,0)); return im,ImageDraw.Draw(im)


def remap(im, preset):
    out=im.copy(); px=out.load()
    for y in range(out.height):
        for x in range(out.width):
            r,g,b,a=px[x,y]
            if not a: continue
            rf,gf,bf=r/255,g/255,b/255
            if preset in ("protan","deutan"):
                if rf > bf+0.15 and gf < rf: rf,gf,bf=gf*0.7+0.15,gf,min(bf+0.35,1)
                elif gf > bf+0.15: rf,gf,bf=rf,gf*0.8,min(bf+0.3,1)
            elif preset=="tritan" and bf > rf+0.15:
                rf,gf,bf=min(rf+0.3,1),gf,bf*0.6
            px[x,y]=(round(rf*255),round(gf*255),round(bf*255),a)
    return out


def save(im,name,variants=True):
    p=OUT/name; p.parent.mkdir(parents=True,exist_ok=True); im.save(p)
    if variants:
        for preset in ("protan","deutan","tritan"):
            im2=remap(im,preset); im2.save(p.with_name(p.stem+"_"+preset+p.suffix))
    print("generated",p)


def tower_tier(tier):
    im,d=img(64,64)
    # shadow and octagonal stone plinth
    d.ellipse((7,45,57,59),fill=(8,14,18,180))
    d.polygon([(8,43),(16,27),(48,27),(56,43),(48,54),(16,54)],fill=OUTLINE)
    d.polygon([(11,42),(18,29),(46,29),(53,42),(46,51),(18,51)],fill=STONE_DARK)
    d.line((18,30,46,30),fill=STONE_LIGHT,width=2)
    # tier structure
    height=16 + tier*4
    d.rectangle((20,42-height,44,43),fill=OUTLINE)
    d.rectangle((22,42-height+2,42,42),fill=STONE)
    d.line((23,42-height+3,40,42-height+3),fill=STONE_LIGHT,width=2)
    for i in range(tier):
        x=25+i*5
        d.rectangle((x,42-height+6,x+2,42-height+8),fill=EMBER_LIGHT)
    # well rim / fire bowl
    d.ellipse((17,14,47,31),fill=OUTLINE)
    d.ellipse((19,15,45,29),fill=STONE_DARK)
    d.arc((20,16,44,28),180,360,fill=STONE_LIGHT,width=2)
    d.ellipse((23,18,41,27),fill=EMBER)
    d.ellipse((26,19,38,26),fill=EMBER_LIGHT)
    d.polygon([(32,10),(27,20),(32,18),(37,20)],fill=OUTLINE)
    d.polygon([(32,12),(29,19),(32,17),(35,19)],fill=EMBER_CORE)
    d.point((32,14),fill=(255,255,240,255))
    # braces
    d.line((15,35,22,39),fill=STONE_LIGHT,width=2); d.line((49,35,42,39),fill=STONE_LIGHT,width=2)
    return im



def needle_rail_tier(tier):
    im,d=img(64,64)
    d.ellipse((7,45,57,59),fill=(8,14,18,180))
    d.polygon([(8,43),(14,31),(50,31),(56,43),(48,54),(16,54)],fill=OUTLINE)
    d.polygon([(12,42),(18,32),(46,32),(52,42),(46,50),(18,50)],fill=STONE_DARK)
    d.line((18,33,46,33),fill=STONE_LIGHT,width=2)
    h=15 + tier*4
    d.rectangle((26,43-h,38,43),fill=OUTLINE)
    d.rectangle((28,43-h+2,36,42),fill=STONE)
    for i in range(tier):
        yy=43-h+6+i*4
        d.line((22,yy,42,yy),fill=TEAL_LIGHT if i==tier-1 else TEAL,width=2)
    d.rectangle((30,10,34,35),fill=OUTLINE)
    d.rectangle((31,9,33,34),fill=STONE_LIGHT)
    d.polygon([(32,3),(27,11),(37,11)],fill=OUTLINE)
    d.polygon([(32,5),(29,10),(35,10)],fill=TEAL_LIGHT)
    d.line((24,36,40,36),fill=TEAL,width=2)
    d.rectangle((30,37,34,42),fill=EMBER_LIGHT if tier>=2 else TEAL_LIGHT)
    return im

def enemy_dasher():
    im,d=img(64,64)
    # wake fins behind body
    d.polygon([(9,28),(23,20),(20,29),(6,36)],fill=OUTLINE)
    d.polygon([(11,29),(22,23),(19,30),(9,34)],fill=DASHER_DARK)
    d.polygon([(10,42),(23,35),(20,42),(6,48)],fill=OUTLINE)
    d.polygon([(11,41),(22,37),(19,43),(9,46)],fill=DASHER_DARK)
    # fish body
    body=[(55,32),(43,20),(25,22),(14,32),(25,42),(43,44)]
    d.polygon([(x,y+1) for x,y in body],fill=OUTLINE)
    d.polygon(body,fill=DASHER)
    d.polygon([(42,22),(25,25),(17,32),(25,38),(42,42)],fill=DASHER_LIGHT)
    d.line((25,32,46,32),fill=DASHER_DARK,width=2)
    d.polygon([(28,22),(34,11),(38,23)],fill=OUTLINE)
    d.polygon([(30,22),(34,14),(36,22)],fill=DASHER_LIGHT)
    d.polygon([(30,42),(35,53),(40,42)],fill=OUTLINE)
    d.polygon([(32,42),(35,50),(38,42)],fill=DASHER_DARK)
    d.ellipse((43,26,51,34),fill=OUTLINE); d.rectangle((46,28,49,31),fill=EMBER_LIGHT); d.point((48,29),fill=(255,255,245,255))
    d.line((16,32,4,32),fill=TEAL_LIGHT,width=2)
    d.line((14,35,6,38),fill=TEAL,width=1)
    return im



def enemy_rat_swarm():
    im,d=img(64,64)
    for ox,oy,sc in [(16,30,1.0),(31,23,0.82),(36,42,0.72)]:
        d.polygon([(ox-10*sc,oy+6*sc),(ox-3*sc,oy-6*sc),(ox+8*sc,oy-5*sc),(ox+11*sc,oy+4*sc),(ox+2*sc,oy+9*sc)],fill=OUTLINE)
        d.polygon([(ox-7*sc,oy+4*sc),(ox-2*sc,oy-4*sc),(ox+6*sc,oy-3*sc),(ox+8*sc,oy+3*sc),(ox+1*sc,oy+6*sc)],fill=DASHER_DARK if sc<0.9 else DASHER)
        d.polygon([(ox-1*sc,oy-4*sc),(ox+1*sc,oy-12*sc),(ox+5*sc,oy-3*sc)],fill=OUTLINE)
        d.polygon([(ox,oy-5*sc),(ox+1*sc,oy-9*sc),(ox+3*sc,oy-4*sc)],fill=DASHER_LIGHT)
        d.point((ox+5*sc,oy-1*sc),fill=EMBER_LIGHT)
        d.line((ox-8*sc,oy+6*sc,ox-16*sc,oy+10*sc),fill=TEAL_LIGHT,width=1)
    return im


def enemy_rust_carrier():
    im,d=img(64,64)
    d.ellipse((5,45,59,59),fill=(8,14,18,180))
    d.polygon([(7,42),(13,22),(25,14),(45,17),(55,30),(58,44),(48,52),(15,52)],fill=OUTLINE)
    d.polygon([(12,40),(17,24),(27,18),(42,21),(51,31),(53,42),(45,48),(18,48)],fill=(145, 78, 51, 255))
    d.polygon([(18,25),(29,19),(42,23),(46,32),(28,34)],fill=(198,126,69,255))
    d.line((14,38,50,38),fill=(224,157,82,255),width=2)
    d.line((25,20,21,45),fill=STONE_DARK,width=2); d.line((40,23,44,47),fill=STONE_DARK,width=2)
    d.rectangle((25,31,39,39),fill=OUTLINE); d.rectangle((28,32,37,36),fill=EMBER)
    d.ellipse((20,41,28,50),fill=OUTLINE); d.ellipse((36,41,44,50),fill=OUTLINE)
    d.rectangle((22,43,26,48),fill=STONE_LIGHT); d.rectangle((38,43,42,48),fill=STONE_LIGHT)
    d.point((29,26),fill=TEAL_LIGHT); d.point((35,26),fill=TEAL_LIGHT)
    return im

def tide_gate(opened=False):
    im,d=img(160,112)
    # background fog rings
    for r,a in [(46,35),(34,48),(23,70)]: d.ellipse((80-r,56-r,80+r,56+r),outline=(91,213,197,a),width=2)
    # pillars
    for x in (24,112):
        d.polygon([(x,100),(x+8,20),(x+30,12),(x+38,100)],fill=OUTLINE)
        d.polygon([(x+7,98),(x+14,24),(x+28,18),(x+31,98)],fill=STONE_DARK)
        d.line((x+14,26,x+28,20),fill=STONE_LIGHT,width=2)
        for yy in (42,62,82): d.line((x+10,yy,x+31,yy+1),fill=STONE,width=2)
        d.rectangle((x+7,96,x+33,102),fill=STONE)
    # cross beam and gate teeth
    d.rectangle((35,16,125,30),fill=OUTLINE); d.rectangle((40,18,120,26),fill=STONE)
    for x in range(48,119,12): d.rectangle((x,24,x+6,33),fill=STONE_LIGHT)
    # central aperture
    d.rectangle((62,30,98,102),fill=OUTLINE)
    d.rectangle((67,34,93,101),fill=(20,51,58,255))
    if opened:
        d.rectangle((70,38,90,98),fill=(37,107,113,255))
        for y in range(44,95,12): d.line((70,y,90,y),fill=TEAL_LIGHT,width=1)
        d.ellipse((67,40,93,98),outline=TEAL_LIGHT,width=2)
        d.polygon([(80,40),(74,56),(80,52),(86,56)],fill=EMBER_CORE)
    else:
        d.rectangle((72,38,88,98),fill=STONE_DARK)
        for y in range(42,94,12): d.line((72,y,88,y+5),fill=STONE_LIGHT,width=2)
        d.line((72,40,88,96),fill=STONE_LIGHT,width=2); d.line((88,40,72,96),fill=STONE_DARK,width=2)
    return im


def ember_burst():
    im,d=img(16,16)
    d.polygon([(8,1),(10,6),(15,8),(10,10),(8,15),(6,10),(1,8),(6,6)],fill=OUTLINE)
    d.polygon([(8,3),(9,7),(13,8),(9,9),(8,13),(7,9),(3,8),(7,7)],fill=EMBER)
    d.rectangle((7,6,9,9),fill=EMBER_CORE)
    return im


def tide_fx():
    im,d=img(96,32)
    for i in range(3):
        ox=i*32; c=(16,16)
        for r in range(13,3,-3):
            col=TEAL_LIGHT if r<8 else TEAL
            d.ellipse((ox+16-r,16-r,ox+16+r,16+r),outline=col,width=1)
        d.polygon([(ox+16,4),(ox+12,16),(ox+16,13),(ox+20,16)],fill=EMBER_CORE if i==2 else TEAL_LIGHT)
    return im

for tier in (1,2,3,4):
    save(tower_tier(tier),f"tower_ember_well_tier{tier}.png")
    save(needle_rail_tier(tier),f"tower_needle_rail_tier{tier}.png")
save(enemy_dasher(),"enemy_splitfin_dasher.png")
save(enemy_rat_swarm(),"enemy_mast_rat_swarm.png")
save(enemy_rust_carrier(),"enemy_rust_armor_carrier.png")
save(tide_gate(False),"tide_gate_closed.png",False)
save(tide_gate(True),"tide_gate_open.png",False)
save(ember_burst(),"projectile_ember_burst.png",False)
save(tide_fx(),"fx_tide_gate_strip3.png",False)
