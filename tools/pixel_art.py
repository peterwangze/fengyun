"""Raster field maps, terrain objects, and fixed-grid sprite atlas."""
import json
import random
from pathlib import Path

from PIL import Image, ImageColor, ImageDraw

ASSETS = Path(__file__).resolve().parents[1] / "game/assets"
SIZE = (320, 180)
SETS = {
    "hall": ("#262b3b", "#353b48", "#454955", "#161b2a", "#764244", "#4d2b36", "#c68355", "#e7b770"),
    "village": ("#253d37", "#334c41", "#465a49", "#132b30", "#456757", "#2b4948", "#60887b", "#dfbc74"),
    "forge": ("#302a32", "#48363a", "#5b4140", "#201b2a", "#854334", "#452b36", "#dd6d3e", "#f7ba63"),
    "pool": ("#2d293f", "#3e334b", "#52435a", "#1b1a31", "#64446a", "#443054", "#ac6d93", "#e7a5aa"),
    "palace": ("#262f45", "#343d54", "#4a5468", "#181f35", "#485d7b", "#303b57", "#7185a2", "#f0be78"),
    "peak": ("#383148", "#4b3d53", "#665464", "#211e33", "#645072", "#443550", "#a17b98", "#eccc93"),
}
LAYOUTS = {
    "hall": ((31,133),(49,107),(83,139),(130,64),(293,64),[(106,112),(253,94),(223,137)]),
    "village": ((248,146),(252,123),(275,100),(206,80),(28,145),[(223,108),(78,84),(114,142)]),
    "forge": ((39,126),(51,97),(86,141),(109,56),(294,66),[(96,118),(266,98),(233,141)]),
    "pool": ((29,85),(52,112),(51,64),(106,142),(299,78),[(115,66),(229,106),(264,128)]),
    "palace": ((285,149),(257,131),(287,111),(224,66),(23,84),[(210,112),(71,97),(104,143)]),
    "peak": ((43,150),(59,117),(121,149),(57,65),(300,117),[(148,107),(265,90),(230,138)]),
}

def rgba(value, alpha=255):
    return (*ImageColor.getrgb(value), alpha)

def line(draw, coords, color, width=1):
    draw.line(coords, fill=color, width=width, joint="curve")

def roof(draw, x, y, w, h, p):
    base, mid, light, shade, accent, dark, trim, gold = p
    draw.polygon([(x, y+h-7), (x+8, y+h-10), (x+w//2-13,y+2), (x+w//2+13,y+2),
                  (x+w-8,y+h-10), (x+w,y+h-7), (x+w-4,y+h), (x+4,y+h)], fill=shade)
    draw.polygon([(x+5,y+h-6), (x+16,y+h-13), (x+w//2-12,y+4), (x+w//2+12,y+4),
                  (x+w-16,y+h-13), (x+w-5,y+h-6)], fill=accent)
    for row in range(y+7,y+h-5,3):
        pad=max(9, (y+h-row)//2+6)
        line(draw,[(x+pad,row),(x+w-pad,row)],dark)
        for col in range(x+pad+3+(row%2)*2,x+w-pad,5):
            draw.point((col,row-1),fill=trim if (col+row)%4==0 else light)
    line(draw, [(x,y+h-9),(x+5,y+h-5),(x+w-5,y+h-5),(x+w,y+h-9)], trim)
    line(draw, [(x+w//2-16,y+2),(x+w//2+16,y+2)], trim, 2)
    draw.point((x+w//2,y+1), fill=gold)

def pavilion(draw,x,y,w,p):
    base, mid, light, shade, accent, dark, trim, gold=p
    draw.ellipse((x+4,y+29,x+w-4,y+43),fill=shade)
    draw.rectangle((x+8,y+20,x+w-8,y+37),fill=dark)
    for px in range(x+11,x+w-7,8):
        draw.rectangle((px,y+23,px+2,y+37),fill=accent)
    draw.rectangle((x+w//2-5,y+24,x+w//2+5,y+36),fill=shade)
    draw.rectangle((x+6,y+37,x+w-6,y+39),fill=light)
    roof(draw,x,y,w,24,p)

def lantern(im, x, y, p, phase):
    d=ImageDraw.Draw(im)
    gold=p[-1]
    for r,a in [(12,18),(7,30),(4,47)]:
        overlay=Image.new("RGBA", im.size)
        ImageDraw.Draw(overlay).ellipse((x-r,y-r,x+r,y+r),fill=rgba(gold,a))
        im.alpha_composite(overlay)
    line(d,[(x,y-7),(x,y+5)],p[3])
    d.rectangle((x-2,y-3,x+2,y+2),fill=p[6])
    d.rectangle((x-1,y-2,x+1,y+1),fill=gold)
    if phase%3:
        d.point((x,y),fill="#fff1c1")

def tree(draw,x,y,p,rng,bamboo=False):
    base, mid, light, shade, accent, dark, trim, gold = p
    draw.ellipse((x-7,y-3,x+10,y+2),fill=shade)
    if bamboo:
        for dx,h in [(-5,25),(0,31),(4,23),(7,28)]:
            line(draw,[(x+dx,y),(x+dx-3,y-h)],accent,2)
            line(draw,[(x+dx-1,y),(x+dx-4,y-h)],dark)
            for z in range(9,h,8):
                xx=x+dx-int(3*z/h)
                line(draw,[(xx-6,y-z-4),(xx,y-z),(xx+7,y-z-3)],trim if z>15 else accent)
        return
    line(draw,[(x-2,y),(x-1,y-13),(x+3,y-24)],dark,4)
    for px,py,w,h in [(-5,-17,10,6),(4,-21,12,7),(-4,-25,12,8),(6,-29,10,6)]:
        draw.polygon([(x+px-w,y+py+1),(x+px-5,y+py-h),(x+px+4,y+py-h-2),
                      (x+px+w,y+py-2),(x+px+w+2,y+py+3),(x+px-5,y+py+6)],fill=dark)
        line(draw,[(x+px-w+3,y+py),(x+px-5,y+py-h),(x+px+4,y+py-h-2),(x+px+w-1,y+py-2)],accent)
        for _ in range(13):
            draw.point((x+px+rng.randint(-6,6),y+py+rng.randint(-h+1,2)), fill=rng.choice([accent,dark,trim,mid]))

def rock(draw,x,y,w,h,p,rng):
    base,mid,light,shade,accent,dark,trim,gold=p
    draw.polygon([(x-w,y),(x-w+3,y-h//2),(x-3,y-h),(x+w//2,y-h-2),
                  (x+w,y-h//2),(x+w+3,y)],fill=shade)
    draw.polygon([(x-w+2,y-2),(x-w+4,y-h//2),(x-3,y-h+1),(x+w//2,y-h),
                  (x+w-1,y-h//2),(x+3,y-3)],fill=dark)
    line(draw,[(x-w+4,y-h//2),(x-3,y-h+1),(x+w//2,y-h),(x+w-2,y-h//2)],accent)
    line(draw,[(x-3,y-h),(x+1,y-h//2),(x+9,y-5)],accent)
    for _ in range(w*2):
        draw.point((x+rng.randint(-w//2,w//2),y-rng.randint(3,max(4,h-4))),fill=rng.choice([accent,dark,mid]))

def map_art(index,key,p):
    base, mid, light, shade, accent, dark, trim, gold=p
    rng=random.Random(79+index)
    im=Image.new("RGBA",SIZE,base)
    d=ImageDraw.Draw(im)
    spawn, guide, shrine, chest, exit_point, fights = LAYOUTS[key]
    data = dict(spawn=spawn, guide=guide, shrine=shrine, chest=chest, exit=exit_point,
                fights=fights, walls=[])
    def wall(x,y,w,h):
        data["walls"].append([x,y,w,h])
    def stone_path(coords,width):
        mask=Image.new("1",SIZE)
        ImageDraw.Draw(mask).line(coords,fill=1,width=width,joint="curve")
        surface=Image.new("RGBA",SIZE,mid)
        sd=ImageDraw.Draw(surface)
        for yy in range(18,171,7):
            for xx in range(-8+(yy//7%2)*7,322,14):
                c=rng.choice([mid,mid,mid,base,light])
                sd.rectangle((xx+1,yy+1,xx+12,yy+5),fill=c)
                sd.line((xx+1,yy+5,xx+10,yy+5),fill=base)
                if rng.random()<.29:
                    sd.line((xx+3,yy+1,xx+7,yy+1),fill=light)
        im.paste(surface,(0,0),mask)
    for _ in range(1650):
        x,y=rng.randrange(320),rng.randrange(180)
        if y>25:
            c=rng.choice([base,base,base,mid,light,dark])
            d.rectangle((x,y,x+rng.randrange(1,4),y),fill=c)
    if key in ("village","pool","forge"):
        fluid={"village":("#18363e","#285962","#3d7476"),"pool":("#39233c","#5a314d","#79415d"),
               "forge":("#662b30","#b04734","#df6d3d")}[key]
        x1,x2= (145,185) if key=="village" else (139,185)
        banks=[(x1,18),(x2,18),(x2+8,52),(x2-7,81),(x2+3,114),(x2+15,180),
               (x1+11,180),(x1-5,117),(x1+8,83),(x1-7,53)]
        d.polygon(banks,fill=fluid[0],outline=accent,width=2)
        mask=Image.new("1",SIZE)
        ImageDraw.Draw(mask).polygon(banks,fill=1)
        current=Image.new("RGBA",SIZE)
        cd=ImageDraw.Draw(current)
        for _ in range(370):
            xx,yy=rng.randrange(124,204),rng.randrange(19,180)
            cd.line((xx,yy,xx+rng.randrange(1,9),yy),fill=rgba(rng.choice(fluid),210))
        im.paste(current,(0,0),Image.composite(current.getchannel("A"),Image.new("L",SIZE),mask))
        data["hazards"] = [
            [(x1,18),(x2,18),(x2+8,52),(x2-7,81),(x2-4,94),(x1+4,94),
             (x1+8,83),(x1-7,53)],
            [(x1-4,115),(x2+3,115),(x2+15,180),(x1+11,180)]
        ]
    first, second, optional = fights
    left, right = (139,105), (190,105)
    crossover = [left, right] if first[0] < second[0] else [right, left]
    if key in ("village", "forge", "pool"):
        route = [spawn, first, *crossover, second, exit_point]
    else:
        route = [spawn, first, (162,111), second, exit_point]
    stone_path(route,29)
    chest_branch = first if (chest[0] - 160) * (first[0] - 160) > 0 else second
    side_branch = first if (optional[0] - 160) * (first[0] - 160) > 0 else second
    stone_path([chest_branch,(chest[0],chest[1]+19),chest],17)
    stone_path([side_branch,(optional[0],optional[1]-15),optional],17)
    stone_path([spawn,guide],13)
    stone_path([spawn,(shrine[0],spawn[1]),shrine],12)
    if key in ("hall","palace","peak"):
        stone_path([(160,107),(159,67),(200,50),(295,51)],30)
        buildings = {"hall":[(10,21,60),(76,26,48),(201,23,53),(268,22,49)],
                     "palace":[(15,26,48),(98,25,46),(151,17,70),(259,25,48)],
                     "peak":[(15,24,45),(87,21,46),(194,23,60),(271,25,45)]}
        for x,y,w in buildings[key]:
            pavilion(d,x,y,w,p)
            wall(x+4,y+16,w-8,25)
        for x in range(21,307,21):
            d.rectangle((x,25,x+3,35),fill=accent)
        for x,y in [(17,91),(69,90),(112,74),(200,74),(264,67),(302,89),(118,143),(259,139)]:
            d.rectangle((x-1,y-1,x+1,y+9),fill=shade)
            lantern(im,x,y,p,index)
        if key=="peak":
            for x,y in [(74,71),(154,65),(182,75),(230,148),(293,137)]:
                rock(d,x,y,9,13,p,rng)
        if key != "palace":
            cx,cy = (160,120) if key == "hall" else (218,92)
            d.ellipse((cx-22,cy-11,cx+22,cy+11),outline=accent)
            d.ellipse((cx-17,cy-8,cx+17,cy+8),outline=trim)
            d.polygon([(cx,cy-6),(cx+11,cy),(cx,cy+6),(cx-11,cy)],outline=trim)
            d.line((cx-9,cy,cx+9,cy),fill=trim)
        else:
            for x,y in [(119,84),(184,83),(240,123),(68,125)]:
                line(d,[(x,y),(x,y-17)],trim)
                d.polygon([(x+1,y-16),(x+12,y-16),(x+8,y-11),(x+11,y-6),(x+1,y-7)],
                          fill="#7c4d64")
    elif key=="village":
        for x,y,w in [(14,38,52),(76,27,49),(197,29,52),(249,36,48),(12,76,28),(266,112,49)]:
            pavilion(d,x,y,w,p)
            wall(x+4,y+16,w-8,25)
        for x,y in [(12,113),(49,72),(95,74),(137,83),(211,79),(225,61),(255,145),(298,95),(112,154),(194,153)]:
            tree(d,x,y,p,rng,True)
        for x,y in [(45,76),(86,84),(140,99),(195,99),(263,78),(265,123)]:
            lantern(im,x,y,p,index)
    else:
        for x,y,w,h in [(23,72,18,24),(77,64,21,26),(110,87,11,12),(210,67,16,22),
                          (246,56,20,21),(295,40,15,19),(302,136,12,21),(55,157,15,20),
                          (113,156,11,16),(194,153,10,13),(268,152,15,23)]:
            rock(d,x,y,w,h,p,rng)
            wall(x-w+2,y-8,w*2-4,10)
        for x,y in [(44,79),(68,86),(108,67),(195,79),(226,78),(285,86),(273,126),(126,130)]:
            d.rectangle((x-1,y,x+1,y+8),fill=shade)
            lantern(im,x,y,p,index)
        if key == "forge":
            for x,y in [(36,101),(70,110),(123,140),(209,128),(241,76),(287,112)]:
                line(d,[(x,y),(x+4,y-9)],trim,2)
                line(d,[(x+1,y-6),(x+6,y-5)],gold)
                d.point((x-2,y+1),fill=accent)
        else:
            for x,y in [(32,113),(79,105),(133,70),(196,60),(216,138),(284,105)]:
                d.ellipse((x-7,y-3,x+7,y+3),outline=accent)
                d.ellipse((x-3,y-1,x+3,y+1),fill=trim)
    if key in ("village","pool","forge"):
        for x in range(137,192,4):
            d.rectangle((x,95,x+3,114),fill=accent if x%3==0 else dark)
            d.point((x+1,97),fill=trim)
        line(d,[(136,94),(192,94)],trim,2)
        line(d,[(136,114),(192,114)],trim)
    for x,y in [(25,151),(45,81),(102,65),(117,134),(196,141),(240,70),(279,144),(305,113)]:
        for dx in range(-3,4,2):
            line(d,[(x+dx,y),(x+dx+(dx%3)-1,y-rng.randint(1,4))],accent)
    for y in range(18):
        for x in range(320):
            if y>9 or rng.random()<.15:
                d.point((x,y),fill=shade if y<12 else dark)
    for x in range(1,320,6):
        d.point((x,161),fill=accent)
    d.rectangle((0,163,319,179),fill=shade)
    im.convert("RGB").save(ASSETS / "maps" / (key+".png"))
    (ASSETS / "maps" / (key+".json")).write_text(json.dumps(data),encoding="utf-8")

PALETTES = {
    "wind":("#182b40","#317772","#63c7b9","#a5e3d3","#252533","#dad0bc"),
    "cloud":("#282433","#813e45","#cb6257","#ff9c6e","#211d2b","#a7b9cc"),
    "frost":("#242d44","#445f9a","#819eda","#b4d5fb","#262336","#d3e6ff"),
    "dream":("#362745","#815780","#d792bc","#f2c6cf","#2a2336","#d9d5e9"),
    "sage":("#253442","#617383","#acbbc0","#e4d6aa","#4c4e63","#eadbb7"),
    "guide":("#302636","#716052","#ae885e","#dec481","#3b3045","#b0a597"),
    "guard":("#262d3b","#4a596f","#7c8292","#deb586","#313546","#b4c8cb"),
    "blade":("#29283a","#65545e","#977577","#d2a58a","#362839","#cfb8a1"),
    "captain":("#29293f","#6a3657","#ab566e","#e8988d","#262839","#c9aab5"),
    "shade":("#232539","#424060","#775d80","#c080a4","#302d4b","#b2a5c8"),
    "claw":("#20263d","#554066","#805b99","#cc9fd1","#29223a","#e2cae7"),
    "duan":("#302137","#8f3a3d","#cf5846","#f49157","#3f2a38","#fd9c4e"),
    "juexin":("#251f37","#584275","#a971ad","#e7ade6","#31273b","#d9c2dd"),
    "godless":("#30263e","#684f5f","#ab8858","#f8d980","#3d3446","#f5d692"),
    "boss":("#242134","#62364c","#9f5562","#e5b175","#50414c","#ffce81"),
    "beast":("#331d31","#953548","#d85452","#ffb965","#5b2b41","#fcd897"),
}

def sprite(key,frame):
    im=Image.new("RGBA",(36,42))
    d=ImageDraw.Draw(im)
    dark,mid,main,hi,hair,steel=PALETTES[key]
    ink="#151524"
    step=[0,1,0,-1][frame]
    lift=abs(step)
    if key=="beast":
        d.polygon([(1,29),(5,20),(10,15),(14,8),(17,12),(23,7),(23,14),(30,16),(34,22),
                   (31,31),(28,32),(29,38),(22,38),(20,31),(14,31),(11,38),(5,38),(6,33)],fill=ink)
        d.polygon([(3,29),(8,20),(15,17),(15,10),(20,15),(24,11),(25,17),(30,19),
                   (33,23),(28,28),(26,36),(23,36),(21,29),(12,30),(9,36),(6,36)],fill=mid)
        d.polygon([(6,26),(12,20),(15,14),(18,19),(25,16),(30,21),(29,25),(19,28),(12,26)],fill=main)
        line(d,[(5,26),(13,20),(16,15),(18,18),(25,16),(29,20)],hi,2)
        line(d,[(10,27),(15,24),(20,25),(23,22)],hi)
        d.rectangle((27,21,29,22),fill=steel)
        d.point((31,26),fill=steel)
        return im
    width=2 if key in ("boss","godless","captain") else 0
    for x,y,c in [(13+step,35,main),(22-step,35,mid)]:
        d.rectangle((x-3,y-6+step,x+3,y+4+step),fill=ink)
        d.rectangle((x-2,y-6+step,x+2,y+2+step),fill=dark)
        d.line((x-2,y-3+step,x+1,y-3+step),fill=c)
    # Cloak, raised sleeves, and crossed robe.
    d.polygon([(12-width,17-lift),(23+width,17-lift),(28+width,23-lift),(31+width,31),
               (27,32),(25,37),(17,34),(9,38),(8,32),(4-width,31),(7-width,22)],fill=ink)
    d.polygon([(12-width,19-lift),(23+width,18-lift),(28+width,24),(29+width,30),
               (25,30),(24,35),(16,33),(10,36),(10,30),(6-width,29),(8-width,23)],fill=mid)
    d.polygon([(11-width,21-lift),(16,18-lift),(24+width,19-lift),(27+width,24),
               (22,25),(19,30),(19,34),(12,35),(12,28),(8-width,26)],fill=main)
    d.polygon([(20,19-lift),(23+width,20-lift),(24,23),(17,27),(14,33),(11,34),(13,29),(14,25)],fill=hi)
    line(d,[(11,28),(17,29),(23,27)],dark,2)
    line(d,[(11,27),(17,28),(23,26)],steel)
    d.point((17,28),fill=hi)
    d.rectangle((5-width,28-lift,8-width,31-lift),fill=ink)
    d.rectangle((6-width,28-lift,8-width,30-lift),fill="#d5a181")
    d.rectangle((26+width,27-lift,30+width,31-lift),fill=ink)
    d.rectangle((27+width,28-lift,29+width,30-lift),fill="#d5a181")
    # Face and distinctive hair/headgear.
    d.polygon([(11,8-lift),(15,4-lift),(22,4-lift),(26,8-lift),(26,15-lift),
               (22,20-lift),(14,19-lift),(11,16-lift)],fill=ink)
    d.polygon([(13,8-lift),(22,6-lift),(25,10-lift),(24,15-lift),(21,18-lift),
               (15,17-lift),(13,14-lift)],fill="#b87c73")
    d.polygon([(14,8-lift),(21,7-lift),(24,10-lift),(23,15-lift),(20,17-lift),(16,16-lift),(14,13-lift)],fill="#e1a38c")
    d.rectangle((15,12-lift,16,12-lift),fill=ink)
    d.rectangle((21,12-lift,22,12-lift),fill=ink)
    d.point((19,15-lift),fill="#a26069")
    d.polygon([(11,9-lift),(13,6-lift),(15,5-lift),(22,5-lift),(25,7-lift),
               (25,13-lift),(22,10-lift),(19,8-lift),(16,10-lift),(13,15-lift)],fill=hair)
    line(d,[(13,7-lift),(16,5-lift),(21,5-lift),(24,7-lift)],mid)
    if key in ("wind","dream","duan","sage"):
        d.polygon([(12,10-lift),(15,8-lift),(14,19-lift),(10,24-lift),(7,23-lift),(10,18-lift)],fill=hair)
        line(d,[(10,21-lift),(12,18-lift),(13,12-lift)],mid)
    if key in ("boss","godless","guide","guard","captain"):
        d.polygon([(12,9-lift),(12,5-lift),(15,6-lift),(18,1-lift),(21,6-lift),(24,5-lift),
                   (25,9-lift)],fill=ink)
        line(d,[(13,8-lift),(15,7-lift),(18,3-lift),(21,7-lift),(24,8-lift)],hi)
    if key in ("boss","sage","godless"):
        line(d,[(15,16-lift),(17,20-lift),(20,22-lift),(23,16-lift)],hair,2)
    if key in ("wind","cloud","dream","sage","duan","blade","juexin"):
        line(d,[(25,30-lift),(34,16-lift)],ink,4)
        line(d,[(26,30-lift),(34,17-lift)],steel,2)
        line(d,[(25,29-lift),(28,31-lift)],hi,2)
    if key in ("shade","claw"):
        line(d,[(13,14-lift),(23,14-lift)],mid,2)
    return im

def main():
    (ASSETS/"maps").mkdir(parents=True,exist_ok=True)
    (ASSETS/"sprites").mkdir(exist_ok=True)
    for index,(key,palette) in enumerate(SETS.items()):
        map_art(index,key,palette)
    for key in PALETTES:
        sheet=Image.new("RGBA",(144,42))
        for frame in range(4):
            sheet.paste(sprite(key,frame),(frame*36,0))
        sheet.save(ASSETS/"sprites"/(key+".png"))
    icon=Image.new("RGBA",(64,64),"#141c34")
    d=ImageDraw.Draw(icon)
    d.ellipse((15,8,49,42),fill="#e7c783")
    d.polygon([(0,50),(21,30),(28,35),(36,27),(64,52),(64,64),(0,64)],fill="#26324d")
    d.polygon([(0,55),(17,48),(36,51),(51,39),(64,49),(64,64),(0,64)],fill="#0f172d")
    line(d,[(21,54),(45,23)],"#d1e7de",2)
    line(d,[(21,44),(34,55)],"#eb9a77",2)
    icon.save(ASSETS/"icon.png")

if __name__=="__main__":
    main()

