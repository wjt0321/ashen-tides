from pathlib import Path
from PIL import Image, ImageDraw
import colorsys, hashlib, io, json, zipfile
ROOT=Path(__file__).resolve().parents[1]
ARCHIVE_ROOT=ROOT/'assets/vendor/c01/foozle/source_archives'
OUT=ROOT/'assets/art/c01/runtime';OUT.mkdir(parents=True,exist_ok=True)
SOURCES={
 'salt_shell':('Foozle_2DC0028_Spire_EnemyPack_2_Ground.zip','Foozle_2DC0028_Spire_EnemyPack_2_Ground/Ground/Spritesheets/Magma Crab.png'),
 'mast_rat':('Foozle_2DC0028_Spire_EnemyPack_2_Ground.zip','Foozle_2DC0028_Spire_EnemyPack_2_Ground/Ground/Spritesheets/Scorpion.png'),
 'tower_base':('Foozle_2DS0017_Spire_TowerPack_1.zip','Foozle_2DS0017_Spire_TowerPack_1/Towers bases/PNGs/Tower 01.png'),
 'tower_weapon':('Foozle_2DS0017_Spire_TowerPack_1.zip','Foozle_2DS0017_Spire_TowerPack_1/Towers Weapons/Tower 01/Spritesheets/Tower 01 - Level 01 - Weapon.png'),
 'ships':('Foozle_2DT0013_Scallywag_Ships.zip','Foozle_2DT0013_Scallywag_Ships/Ships tiles.png'),
 'fort':('Foozle_2DT0015_Scallywag_Fort.zip','Foozle_2DT0015_Scallywag_Fort/Fort Tiles.png'),
 'water':('Foozle_2DT0014_Scallywag_WaterAndIslands.zip','Foozle_2DT0014_Scallywag_WaterAndIslands/Water and Island tiles.png'),
}

def load_source(key):
    archive, member=SOURCES[key]
    with zipfile.ZipFile(ARCHIVE_ROOT/archive) as bundle:
        return Image.open(io.BytesIO(bundle.read(member))).convert('RGBA')

def recolor(im, mode):
    out=Image.new('RGBA',im.size); src=im.load(); dst=out.load()
    for y in range(im.height):
      for x in range(im.width):
        r,g,b,a=src[x,y]
        if a==0: dst[x,y]=(0,0,0,0);continue
        h,s,v=colorsys.rgb_to_hsv(r/255,g/255,b/255)
        if mode=='enemy':
          # turn warm/neon highlights into cold tide cyan, keep charcoal shell depth
          if s>.38 and v>.32:
            nh=.49 if (r>g or g>r*1.05) else .55
            ns=min(.72,max(.34,s*.72)); nv=min(.95,v*.96)
            rr,gg,bb=colorsys.hsv_to_rgb(nh,ns,nv)
          else:
            rr,gg,bb=colorsys.hsv_to_rgb(.53,min(.34,s*.55),min(.78,v*.88))
        elif mode=='stone':
          rr,gg,bb=colorsys.hsv_to_rgb(.48,min(.25,s*.42),min(.72,v*.78))
        elif mode=='water':
          rr,gg,bb=colorsys.hsv_to_rgb(.48,min(.42,max(.18,s*.42)),min(.62,v*.62+.05))
        elif mode=='warm':
          # defensive structures: charcoal, weathered wood and coral focal accents
          if s>.42 and (r>g*1.08 or g>b*1.18):
            rr,gg,bb=colorsys.hsv_to_rgb(.035,min(.72,s*.85),min(.96,v*1.05))
          else:
            rr,gg,bb=colorsys.hsv_to_rgb(.08,min(.34,s*.65),min(.82,v*.88))
        else: rr,gg,bb=r/255,g/255,b/255
        dst[x,y]=(int(rr*255),int(gg*255),int(bb*255),a)
    return out

def save_enemy(source, name):
    im=recolor(load_source(source),'enemy'); sheet=Image.new('RGBA',(8*64,3*64))
    # source movement rows: side, down, up -> normalized runtime rows
    for oy,sy in enumerate([5,3,4]):
      for x in range(8): sheet.paste(im.crop((x*64,sy*64,(x+1)*64,(sy+1)*64)),(x*64,oy*64))
    sheet.save(OUT/name)

save_enemy('salt_shell','enemy_salt_shell.png')
save_enemy('mast_rat','enemy_mast_rat.png')

# Compose six-frame needle-rail tower from a stone/wood base and animated crossbow weapon.
base_src=recolor(load_source('tower_base'),'warm')
weapon=recolor(load_source('tower_weapon'),'warm')
tower=Image.new('RGBA',(6*96,96))
base=base_src.crop((0,64,64,128))
for i in range(6):
 cell=Image.new('RGBA',(96,96));cell.alpha_composite(base,(16,32));cell.alpha_composite(weapon.crop((i*96,0,(i+1)*96,96)),(0,-4));tower.alpha_composite(cell,(i*96,0))
tower.save(OUT/'tower_needle_rail.png')

ship_src=recolor(load_source('ships'),'warm')
fort_src=recolor(load_source('fort'),'stone')
water_src=recolor(load_source('water'),'water')

def lighthouse():
 im=Image.new('RGBA',(128,128));d=ImageDraw.Draw(im)
 # shadowed rock footing
 d.polygon([(24,119),(35,104),(87,102),(106,119)],fill=(20,27,28,255))
 # tapered wet-stone shaft with brick bands and left shadow
 d.polygon([(43,108),(53,38),(79,38),(90,108)],fill=(54,68,67,255),outline=(18,24,27,255))
 d.polygon([(43,108),(53,38),(62,38),(64,108)],fill=(34,45,46,255))
 for y in range(48,104,12):
  width=int((y-38)*.11);d.line((51-width//2,y,82+width//2,y),fill=(94,107,101,255),width=2)
  for x in range(55+(y//12%2)*7,82,14): d.line((x,y-10,x-2,y),fill=(36,48,49,255),width=1)
 # gallery, lantern room and roof
 d.rectangle((39,33,94,40),fill=(24,29,31,255));d.rectangle((46,18,87,35),fill=(43,51,50,255),outline=(17,21,24,255),width=3)
 d.rectangle((54,22,79,32),fill=(255,115,67,255));d.rectangle((59,23,74,31),fill=(255,190,92,255))
 d.polygon([(40,18),(66,3),(94,18)],fill=(25,29,30,255),outline=(12,16,18,255));d.rectangle((64,0,68,6),fill=(21,25,27,255))
 d.rectangle((37,37,96,42),fill=(15,20,22,255));
 for x in [42,53,80,91]:d.rectangle((x,40,x+2,48),fill=(15,20,22,255))
 # door and coral marker
 d.rectangle((59,88,73,108),fill=(25,31,32,255));d.rectangle((61,91,70,105),fill=(93,62,43,255));d.point((69,98),fill=(255,146,75,255))
 return im

# Props atlas: 8 cells of 128x128.
props=Image.new('RGBA',(8*128,128));props.alpha_composite(lighthouse(),(0,0))
# Large ships use two 80x160 tile cells and are scaled to fit without smoothing.
def fit_sprite(src, box=(112,112)):
 b=src.getbbox();src=src.crop(b) if b else src
 scale=min(box[0]//max(1,src.width),box[1]//max(1,src.height))
 if scale<1: scale=min(box[0]/src.width,box[1]/src.height)
 size=(max(1,int(src.width*scale)),max(1,int(src.height*scale)))
 return src.resize(size,Image.Resampling.NEAREST)
for idx,col in enumerate([5,7,6],start=1):
 sp=fit_sprite(ship_src.crop((col*80,0,(col+1)*80,160)))
 props.alpha_composite(sp,(idx*128+(128-sp.width)//2,(128-sp.height)//2))
# rock cluster, dock tile, cannon/buoy and crate/barrel collage
rock=water_src.crop((5*48,0,6*48,48)).resize((96,96),Image.Resampling.NEAREST);props.alpha_composite(rock,(4*128+16,16))
dock=fort_src.crop((4*48,3*48,5*48,4*48)).resize((112,112),Image.Resampling.NEAREST);props.alpha_composite(dock,(5*128+8,8))
cannon=fort_src.crop((7*48,0,8*48,48)).resize((96,96),Image.Resampling.NEAREST);props.alpha_composite(cannon,(6*128+16,16))
barrel=fort_src.crop((6*48,1*48,7*48,2*48)).resize((96,96),Image.Resampling.NEAREST);props.alpha_composite(barrel,(7*128+16,16))
props.save(OUT/'harbor_props.png')

# Tile helpers and authored pixel backgrounds.
water_tile=Image.new('RGBA',(48,48),(48,82,82,255))
wd=ImageDraw.Draw(water_tile)
for x,y,w,c in [(3,8,17,(68,112,108,130)),(27,19,14,(37,67,69,160)),(8,33,23,(78,124,118,115)),(35,42,9,(30,60,63,170))]:
 wd.rectangle((x,y,x+w,y+1),fill=c)
for x,y in [(12,13),(39,6),(22,27),(5,44),(43,31)]:wd.point((x,y),fill=(112,158,150,110))
stone_tile=fort_src.crop((0,0,48,48));wood_tile=fort_src.crop((4*48,3*48,5*48,4*48))
def tile_fill(size,tile,offset=(0,0)):
 im=Image.new('RGBA',size)
 for y in range(offset[1]-(offset[1]//tile.height+1)*tile.height,size[1],tile.height):
  for x in range(offset[0]-(offset[0]//tile.width+1)*tile.width,size[0],tile.width): im.alpha_composite(tile,(x,y))
 return im

def pixel_sky(h=180):
 im=Image.new('RGBA',(640,h));d=ImageDraw.Draw(im)
 bands=[(0,(31,41,43,255)),(32,(43,55,55,255)),(70,(58,70,66,255)),(112,(77,82,73,255)),(150,(91,82,70,255))]
 for i,(y,c) in enumerate(bands):
  y2=bands[i+1][0] if i+1<len(bands) else h;d.rectangle((0,y,639,y2),fill=c)
 # coarse cloud masses and dither
 d.polygon([(0,30),(210,18),(330,34),(455,65),(640,55),(640,98),(385,91),(235,78),(0,91)],fill=(37,48,50,255))
 for y in range(8,h,8):
  for x in range((y//8)%2*6,640,24):
   if (x*13+y*7)%37<9:d.point((x,y),fill=(112,103,85,90))
 return im

def draw_beam(im,origin,end_y=55):
 ov=Image.new('RGBA',im.size);d=ImageDraw.Draw(ov);x,y=origin
 d.polygon([(x,y-4),(640,end_y),(640,end_y+36),(x,y+5)],fill=(255,119,68,44));im.alpha_composite(ov)

def paste_prop(im,index,pos,scale=1.0,flip=False):
 sp=props.crop((index*128,0,(index+1)*128,128));
 if flip: sp=sp.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
 if scale!=1: sp=sp.resize((int(128*scale),int(128*scale)),Image.Resampling.NEAREST)
 im.alpha_composite(sp,(int(pos[0]),int(pos[1])))

def make_battle():
 im=tile_fill((640,360),water_tile);d=ImageDraw.Draw(im)
 # cold tide band and left landing shelf
 d.rectangle((0,0,639,68),fill=(31,48,49,185));d.polygon([(0,130),(58,126),(72,190),(56,255),(0,260)],fill=(100,111,95,255))
 # textured right reef
 mask=Image.new('L',im.size);md=ImageDraw.Draw(mask);md.polygon([(572,0),(640,0),(640,360),(575,360),(546,302),(584,239),(564,170),(580,90)],fill=255)
 st=tile_fill(im.size,stone_tile);im.paste(st,(0,0),mask)
 # routes: pixel black bed then tiled stone/wood texture masks, exact coordinates
 for pts in [[(0,192),(320,192),(320,320),(640,320)],[(0,192),(480,192),(480,80),(640,80)]]:
  d.line(pts,fill=(17,22,23,255),width=26,joint='curve')
  pm=Image.new('L',im.size);pd=ImageDraw.Draw(pm);pd.line(pts,fill=255,width=18,joint='curve')
  tex=tile_fill(im.size,wood_tile);im.paste(tex,(0,0),pm)
  d.line(pts,fill=(166,139,91,150),width=2,joint='curve')
 # landing foam pixels and tide accents
 for y in [166,181,205,222]:
  d.arc((-28,y-18,70,y+18),190,345,fill=(111,190,189,180),width=2)
 for x,y in [(115,86),(212,238),(450,145),(535,270),(385,40)]:
  d.rectangle((x,y,x+10,y+3),fill=(86,145,142,120));d.rectangle((x+4,y-2,x+7,y+1),fill=(126,182,176,100))
 paste_prop(im,0,(500,-5),1.05);draw_beam(im,(564,34),22)
 paste_prop(im,2,(420,7),.62);paste_prop(im,1,(366,20),.48);paste_prop(im,3,(323,31),.36)
 paste_prop(im,4,(75,79),.45);paste_prop(im,4,(185,242),.35);paste_prop(im,4,(485,210),.32)
 return im

def make_poster(mode):
 im=Image.new('RGBA',(640,360));im.alpha_composite(pixel_sky(190));im.alpha_composite(tile_fill((640,170),water_tile),(0,190));d=ImageDraw.Draw(im)
 d.rectangle((0,186,639,194),fill=(96,145,140,100))
 if mode in ('title','briefing'):
  d.polygon([(0,360),(0,265),(82,238),(170,276),(226,250),(320,360)],fill=(23,29,30,255));paste_prop(im,0,(55,112),1.35);draw_beam(im,(145,159),70)
  paste_prop(im,2,(438,176),.72);paste_prop(im,1,(360,196),.52);paste_prop(im,3,(510,214),.42)
 elif mode=='campaign':
  d.polygon([(0,360),(0,246),(92,224),(196,265),(305,360)],fill=(29,37,37,255));paste_prop(im,0,(34,145),.9);draw_beam(im,(92,176),100)
  paste_prop(im,2,(205,175),.5);paste_prop(im,1,(270,149),.38);paste_prop(im,3,(335,124),.3)
  # far tide gate with stone sprite columns and fog
  paste_prop(im,4,(450,91),.78);paste_prop(im,4,(542,91),.78)
  for i in range(5):d.rectangle((410+i*25,128+i%2*8,600,132+i%2*8),fill=(104,165,160,28))
 elif mode.startswith('result'):
  d.polygon([(0,360),(0,305),(122,276),(246,304),(330,360)],fill=(22,29,30,255));lit=mode=='result_win';paste_prop(im,0,(456,130),1.18)
  if lit: draw_beam(im,(534,171),75)
  else:
   ov=Image.new('RGBA',im.size,(10,28,31,92));im.alpha_composite(ov)
  paste_prop(im,2,(371,194),.65);paste_prop(im,1,(315,217),.45);paste_prop(im,3,(414,236),.4)
 return im

make_battle().save(OUT/'battle_background.png')
for mode in ['title','campaign','briefing','result_win','result_lose']:make_poster(mode).save(OUT/f'{mode}_background.png')
# Briefing tactical map as a real raster artifact using the battle background crop and route overlays.
bg=make_battle().resize((336,224),Image.Resampling.NEAREST);frame=Image.new('RGBA',(360,240),(206,191,160,255));frame.alpha_composite(bg,(12,8));fd=ImageDraw.Draw(frame);fd.rectangle((10,6,349,233),outline=(25,29,30,255),width=3);frame.save(OUT/'briefing_map.png')

manifest={}
for p in sorted(OUT.glob('*.png')):manifest[p.name]={'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
(OUT/'DERIVED_MANIFEST.json').write_text(json.dumps({'generated_on':'2026-09-06','builder':'tools/build_c01_foozle_assets.py','source':'Foozle CC0 packs','files':manifest},indent=2),encoding='utf-8')
print(json.dumps(manifest,indent=2))
