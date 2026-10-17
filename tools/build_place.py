from lxml import etree as E
from pathlib import Path
from math import cos,sin,pi
import random, zipfile, json
random.seed(29071)
BASE=Path('/mnt/data/outlaw_valley')
root=E.Element('roblox',version='4')
E.SubElement(root,'External').text='null';E.SubElement(root,'External').text='nil'
serial=0
counts={}
def item(cls,parent,name,props=None):
 global serial
 serial+=1; counts[cls]=counts.get(cls,0)+1
 x=E.SubElement(parent,'Item',{'class':cls,'referent':'RBX'+format(serial,'08X')})
 p=E.SubElement(x,'Properties');addp(p,'string','Name',name)
 if props:
  for tag,n,value in props:addp(p,tag,n,value)
 return x

def addp(parent,tag,name,val):
 x=E.SubElement(parent,tag,name=name)
 if tag=='Color3uint8':x.text=str(0xFF000000+int(val[0])*65536+int(val[1])*256+int(val[2]))
 elif tag=='Color3':
  for key,number in zip(['R','G','B'],val):E.SubElement(x,key).text=str(float(number)/255)
 elif tag=='Vector3':
  for key,number in zip('XYZ',val):E.SubElement(x,key).text=f'{float(number):.6f}'
 elif tag=='CoordinateFrame':
  pos,yaw=val;cy=cos(yaw);sy=sin(yaw)
  values={'X':pos[0],'Y':pos[1],'Z':pos[2], 'R00':cy,'R01':0,'R02':sy,
          'R10':0,'R11':1,'R12':0,'R20':-sy,'R21':0,'R22':cy}
  for key,num in values.items():E.SubElement(x,key).text=f'{float(num):.8f}'
 elif tag=='bool':x.text='true' if val else 'false'
 else:x.text=str(val)
 return x

palette={
 'grass':(61,103,71),'grass2':(70,113,76),'grass3':(49,90,64),
 'dirt':(101,83,68),'wood':(107,77,54),'roof':(45,83,94),'roof2':(63,96,105),
 'wall':(176,159,125),'wall2':(153,138,115),'stone':(92,106,113),'stone2':(112,118,111),
 'cobble':(115,109,99),'marsh':(60,84,78),'moss':(63,113,83),
 'purple':(145,92,195),'gold':(241,180,74),'ember':(245,133,66),
 'water':(45,125,151),'pine':(44,87,75),'leaf':(64,127,87),'leaf2':(79,143,92),
 'bark':(98,69,54),'dark':(39,43,49),'iron':(85,99,108)
}
material={'Plastic':256,'SmoothPlastic':272,'Neon':288,'Wood':512,'WoodPlanks':528,
          'Slate':800,'Concrete':816,'Granite':832,'Brick':848,'Cobblestone':880,
          'Rock':896,'Sandstone':912,'Grass':1280,'LeafyGrass':1284,'Sand':1296,
          'Mud':1344,'Ground':1360,'Asphalt':1376,'Glass':1568,'Metal':1088}
ws=item('Workspace',root,'Workspace')
land=item('Folder',ws,'VALLEY  |  TERRAIN & PATHS')
flora=item('Folder',ws,'VALLEY  |  FORESTS & WILDLIFE')
settlement=item('Folder',ws,'CROOKED CREEK  |  SETTLEMENT')
wilderness=item('Folder',ws,'THIEVES WOODS  |  CAMPS & RUINS')
marsh=item('Folder',ws,'WITCHWATER  |  CURSED MARSH')
fort=item('Folder',ws,'BROKEN CROWN  |  FORTRESS')
props=item('Folder',ws,'LORE  |  DETAILS & INTERACTIVES')

def part(parent,name,pos,size,color,mat='SmoothPlastic',shape=1,yaw=0,collide=True,trans=0,klass='Part'):
 return item(klass,parent,name,[('bool','Anchored',True),('bool','CanCollide',collide),
 ('bool','CanTouch',False),('bool','CastShadow',True),('token','Material',material.get(mat,272)),
 ('token','Shape',shape),('Color3uint8','Color3uint8',palette.get(color,color)),
 ('CoordinateFrame','CFrame',(pos,yaw)),('Vector3','Size',size),('float','Transparency',trans),
 ('token','TopSurface',0),('token','BottomSurface',0)])

def ball(parent,name,pos,size,color,mat='SmoothPlastic',collide=False):
 return part(parent,name,pos,size,color,mat,shape=0,collide=collide)

def light(parent,color,brightness=2,range=20):
 return item('PointLight',parent,'Warm Pointlight',[('Color3','Color',palette.get(color,color)),
  ('float','Brightness',brightness),('float','Range',range),('bool','Enabled',True)])

def prompt(parent,kind,obj,action,hold=.5,distance=13):
 return item('ProximityPrompt',parent,'OV_'+kind,[('string','ObjectText',obj),('string','ActionText',action),
 ('float','HoldDuration',hold),('float','MaxActivationDistance',distance),
 ('bool','RequiresLineOfSight',False),('bool','Enabled',True)])

def textplate(parent,display,pos,size=(12,5),color='dark',textcolor='gold'):
 board=part(parent,'Signboard | '+display,pos,(size[0],size[1],.5),color,'Wood')
 ui=item('SurfaceGui',board,'Lettering',[('token','Face',2),('bool','AlwaysOnTop',False)])
 item('TextLabel',ui,'Ink',[('UDim2','dummy','')]) if False else None
 t=item('TextLabel',ui,'Inscription',[('string','Text',display),('token','Font',3),
 ('Color3','TextColor3',palette.get(textcolor,textcolor)),('Color3','BackgroundColor3',palette['dark']),
 ('float','BackgroundTransparency',1),('bool','TextScaled',True)])
 p=t.find('Properties')
 # fill entire SurfaceGui
 frame=E.SubElement(p,'UDim2',name='Size')
 for key,num in [('XS',1),('XO',0),('YS',1),('YO',0)]:E.SubElement(frame,key).text=str(num)
 return board

def tree(x,z,h=10,pine=False):
 y=2
 r=random.uniform(.75,1.2)
 trunk=part(flora,'Old cedar trunk',(x,y+h*.5,z),(1.6*r,h,1.6*r),'bark','Wood')
 if pine:
  for i in range(3):
   ball(flora,'Bluegreen needles',(x,y+h*.8+i*2.8,z),(8.3-i*1.6,5.6,8.3-i*1.6),random.choice(['pine','grass3','leaf']), 'Grass')
 else:
  for a in [-1,1]:
   ball(flora,'Broadleaf canopy',(x+a*2.2,y+h+1.6,z),(9,8,9),random.choice(['leaf','leaf2','grass2']),'Grass')
  ball(flora,'Overlapping crown',(x,y+h+3.5,z),(11,8,10),random.choice(['leaf','grass2']),'Grass')
 if random.random()<.14:
  ball(flora,'Amber mushroom',(x+2,y+1.2,z-1),(.9,1.4,.9),'ember','Neon')

def boulder(x,z,s=4):
 ball(flora,'Lichen boulder',(x,s*.26,z),(s,s*.5,s*.83),random.choice(['stone2','stone','dark']),'Rock',True)
 if random.random()<.2:ball(flora,'Soft moss',(x,s*.56,z),(s*.65,.3,s*.5),'moss','Grass')

def flower(x,z,col='gold'):
 part(flora,'Wildflower stalk',(x,2.2,z),(.12,.7,.12),'moss','Grass',collide=False)
 ball(flora,'Wildflower',(x,2.64,z),(.48,.48,.48),col,'Neon')

def pathtrail(points,width=15):
 for a,b in zip(points,points[1:]):
  ax,az=a;bx,bz=b
  dist=((bx-ax)**2+(bz-az)**2)**.5
  steps=max(1,int(dist/11))
  for i in range(steps+1):
   t=i/steps;x=ax+(bx-ax)*t;z=az+(bz-az)*t
   part(land,'Worn kingdom road',(x,2.11,z),(width,.26,13),'dirt','Ground',yaw=0)
   if i%5==0:
    part(land,'Stone curb',(x+width/2,2.2,z),(1,.25,4),'stone2','Rock')

def lantern(parent,x,z,fire='gold'):
 part(parent,'Forged lantern post',(x,5.7,z),(.55,7.5,.55),'iron','Metal')
 cage=part(parent,'Copper lantern',(x,9.4,z),(2.1,2.2,2.1),'dark','Metal')
 core=ball(parent,'Lantern flame',(x,9.4,z),(1.3,1.7,1.3),fire,'Neon')
 light(core,fire,2.5,28)

def house(x,z,yaw=0,scale=1,kind='house'):
 w=random.uniform(16,22)*scale;d=random.uniform(14,18)*scale;h=12*scale
 walltone=random.choice(['wall','wall2'])
 block=part(settlement,'House hardwood floor',(x,2.35,z),(w,.7,d), 'wood','WoodPlanks',yaw=yaw)
 for side in [-1,1]:
  part(settlement,'Timber side wall',(x+side*w*.48,2+h*.5,z),(1.1,h,d),walltone,'Brick',yaw=yaw)
 part(settlement,'Plastered back wall',(x,2+h*.5,z+d*.49),(w,h,1.1),walltone,'Brick',yaw=yaw)
 # front wall has a functional doorway; the inside is walkable.
 gap=5.4*scale
 for side in [-1,1]:
  outside=(w-gap)/2
  part(settlement,'Doorway front wall',(x+side*(gap/2+outside/2),2+h*.5,z-d*.49),(outside,h,1.1),walltone,'Brick',yaw=yaw)
 part(settlement,'Doorway lintel',(x,2+h-1,z-d*.49),(gap,2,1.2),'wood','Wood',yaw=yaw)
 roof=part(settlement,'Dark tiled roof',(x,2+h+3*scale,z),(w+2*scale,5*scale,d+3*scale),'roof','Slate',yaw=yaw)
 part(settlement,'Raised eaves',(x,2+h+.7*scale,z),(w+3,1,d+3),'wood','Wood',yaw=yaw)
 # Interior fixtures give an actual reason to enter.
 part(settlement,'Inside oak table',(x+3,4.5,z+2),(6,1.1,4),'wood','WoodPlanks')
 for leg in [-1,1]:part(settlement,'Table support',(x+3+leg*2.2,3.2,z+2),(.7,2.6,.7),'wood','Wood')
 for sy in [-1,1]:
  for sz in [-1,1]:
   xx=x+sy*(w*.45);zz=z+sz*(d*.45)
   part(settlement,'Oak beam',(xx,7*scale+2,zz),(1.1*scale,h,1.1*scale),'wood','Wood')
 for side in [-1,1]:
  for offset in [-.2,.25]:
   part(settlement,'Warm window',(x+side*w*.495,7*scale,z+offset*d*.4),(2.8*scale,3.6*scale,.3),'gold','Glass',yaw=yaw)
 part(settlement,'Door frame',(x,8.6*scale,z-d*.53),(4.5*scale,.5,.4),'dark','Wood',yaw=yaw)
 for i in range(3):
  part(settlement,'Stone step',(x,2.25+i*.25,z-d*.6-i*1.5),(5, .3,2),'stone2','Slate',yaw=yaw)
 if kind=='tavern':
  textplate(settlement,'THE CROOKED CUP',(x,14*scale,z-d*.54),(12,3))
 elif kind=='armory':
  textplate(settlement,'GRINDLE’S ARMORY',(x,14*scale,z-d*.54),(13,3))
 return block

# Base terrain / open world
part(land,'Deep bedrock',(0,-11,0),(1150,22,1050),'stone','Rock')
part(land,'Rolling kingdom grasslands',(0,0,0),(1080,4,990),'grass','Grass')
part(land,'Marsh lowlands',(-228,1,240),(265,3,263),'marsh','Mud')
part(land,'Northern highlands',(306,1,-115),(245,6,245),'stone2','Rock')
part(land,'Shaded woodland',(55,1.2,152),(300,3,290),'grass3','Grass')
# River across western border
for j in range(36):
 z=-420+j*27;x=-360+sin(j*.39)*18
 part(land,'Cold winding river',(x,2.45,z),(48,.35,31),'water','Glass',trans=.22)
 for side in [-1,1]:
  part(land,'Riverbank gravel',(x+side*26,2.4,z),(8,.6,30),'stone2','Rock')
# Old roads; dense hand made stones around populated districts
pathtrail([(-160,-145),(-150,-80),(-125,-35),(-80,20),(-20,65),(90,88),(150,114)],17)
pathtrail([(-80,20),(-135,80),(-190,135),(-225,223)],14)
pathtrail([(-150,-115),(-75,-126),(20,-145),(110,-145),(205,-116),(300,-100)],15)
# Forest trees distinct clusters; leave trails clear
for i in range(190):
 x=random.uniform(-320,415);z=random.uniform(-310,390)
 if ((x+160)**2+(z+145)**2)**.5<125:continue
 if (x>190 and z<55):continue
 if x<-130 and z>135 and random.random()<.75:continue
 if (x-70)**2+(z-86)**2<24**2:continue
 if abs(x+150)<20 and -180<z<65:continue
 if abs(x+75)<27 and -150<z<-110:continue
 tree(x,z,random.uniform(7,17),random.random()<.5)
for i in range(155):
 x=random.uniform(-390,410);z=random.uniform(-370,390)
 if (x+160)**2+(z+145)**2<88**2:continue
 boulder(x,z,random.uniform(1,5))
for i in range(220):
 x=random.uniform(-320,320);z=random.uniform(-280,340)
 if (x+160)**2+(z+145)**2<90**2:continue
 flower(x,z,random.choice(['gold','purple','ember']))
# Town commons; compact and dense
part(settlement,'Town square cut stone',(-160,2.1,-147),(128,.35,110),'cobble','Cobblestone')
part(settlement,'Central fountain basin',(-166,3.5,-152),(18,2,18),'stone','Slate',shape=2)
ball(settlement,'Clear spring water',(-166,4.65,-152),(14,.35,14),'water','Glass')
part(settlement,'Fountain column',(-166,7,-152),(3,6,3),'stone2','Slate')
ball(settlement,'Fountain crown',(-166,10.2,-152),(3,3,3),'gold','Metal')
for x,z,k in [(-213,-177,'tavern'),(-207,-106,'house'),(-116,-104,'armory'),(-113,-190,'house'),(-171,-225,'house'),(-247,-142,'house'),(-83,-159,'house'),(-148,-77,'house')]:
 house(x,z,scale=random.uniform(.82,1.2),kind=k)
for x,z in [(-217,-145),(-100,-143),(-162,-92),(-160,-219),(-105,-205)]:lantern(settlement,x,z)
for i in range(18):
 x=random.choice([-218,-98])+random.uniform(-6,6);z=random.uniform(-205,-90)
 part(settlement,'Stacked supply crate',(x,3.45,z),(3,3,3),random.choice(['wood','wall2']),'WoodPlanks')
for i in range(8):
 x=-175+i*3.7;part(settlement,'Market awning', (x,13,-82), (3.4,.25,8),'roof2','Fabric' if 'Fabric' in material else 'SmoothPlastic')
# Town perimeter posts and fencing breaks allow varied exits
for z in range(-244,-49,9):
 for x in [-250,-70]:
  if abs(z+145)<20:continue
  part(settlement,'Crooked palisade stake',(x,5,z),(2,8,1.6),'wood','Wood',shape=2)
for x in range(-240,-69,9):
 for z in [-245,-49]:
  if -174<x<-126:continue
  part(settlement,'Village old fence',(x,5,z),(1.6,8,2),'wood','Wood',shape=2)
textplate(props,'CROOKED CREEK  /  SAFE TERRITORY',(-155,10,-48),(34,3))

# Woods - tents, watchtower, bandit camp, breakable-looking detail
part(wilderness,'Old bandit assembly ground',(80,2.3,102),(104,.5,94),'dirt','Ground')
for xx,zz in [(28,79),(49,128),(117,65),(131,118)]:
 part(wilderness,'Bandit canvas tent',(xx,6,zz),(17,8,15),'roof','Fabric' if 'Fabric' in material else 'SmoothPlastic')
 part(wilderness,'Tent seam',(xx,11,zz),(18,2,16),'roof2','Slate')
 lantern(wilderness,xx+8,zz+10,'ember')
for i in range(25):
 theta=random.random()*2*pi;rr=random.uniform(16,40)
 x=80+rr*cos(theta);z=104+rr*sin(theta)
 part(wilderness,'Supply barrel',(x,3,z),(3,3,3),'wood','Wood',shape=2)
for i in range(4):
 a=i*pi/2
 x=80+28*cos(a);z=100+28*sin(a)
 part(wilderness,'Camp stakes',(x,7,z),(2.7,12,2.7),'wood','Wood')
 part(wilderness,'Burning torch',(x,13,z),(2,2,2),'ember','Neon',shape=0)
# Woods elevated rocky lookout
for i in range(9):
 x=130+i*5
 part(wilderness,'Ancient stairs',(x,2.5+i*.5,175),(7,1,12),'stone','Slate')
part(wilderness,'Watch camp overlook',(170,9,175),(35,3,35),'stone2','Rock')
# Marsh ruined wizard circle
for i in range(11):
 a=i*2*pi/11;x=-230+49*cos(a);z=245+49*sin(a)
 pillar=part(marsh,'Cursed ritual monolith',(x,7,z),(5,12,5),'stone','Slate',yaw=a)
 ball(marsh,'Runes',(x,13.5,z),(3,3,3),'purple','Neon')
for i in range(20):
 x=random.uniform(-325,-140);z=random.uniform(155,335)
 if random.random()<.75:
  part(marsh,'Twisted standing reed',(x,6,z),(.3,8,.3),'moss','Grass')
  ball(marsh,'Glowing spore',(x,11,z),(1.5,1.5,1.5),random.choice(['purple','gold']),'Neon')
for x,z in [(-260,205),(-195,303),(-280,295)]:
 part(marsh,'Sunken ancient cottage',(x,5,z),(18,9,15),'wall2','Slate')
 part(marsh,'Pitch dark roof',(x,11,z),(19,5,17),'dark','Slate')
for i in range(30):
 a=i*2*pi/30
 part(marsh,'Ritual circle carved ring',(-230+34*cos(a),2.9,245+34*sin(a)),(5,.15,4),'purple','Neon',yaw=a)
textplate(props,'WITCHWATER : TURN BACK',(-186,10,168),(23,3),'dark','purple')

# Crown fortress large architected compound
part(fort,'Fortress ancient courtyard',(298,4.2,-111),(186,6,173),'cobble','Cobblestone')
for x in [206,390]:
 for z in range(-206,-14,18):
  if z<-139 and x==206:continue
  part(fort,'Battlement side wall',(x,15,z),(8,21,20),'stone','Slate')
  part(fort,'Embrasure merlon',(x,28,z),(8,6,7),'stone2','Slate')
for z in [-203,-18]:
 for x in range(206,398,18):
  if z==-203 and 281<x<319:continue
  part(fort,'Fortress curtain wall',(x,15,z),(20,21,8),'stone','Slate')
  part(fort,'Crenellation',(x,28,z),(7,6,8),'stone2','Slate')
for x in [208,389]:
 for z in [-199,-21]:
  part(fort,'Flanking square bastion',(x,22,z),(23,37,23),'stone2','Slate')
  part(fort,'Tower slate roof',(x,43,z),(27,7,27),'roof','Slate')
  lantern(fort,x+13,z+6,'purple')
for j in range(8):
 z=-181+j*19
 part(fort,'Ruined support column',(257,10,z),(5,12,5),'stone2','Slate')
 part(fort,'Rubble around support',(255+random.uniform(-3,3),4.3,z),(5,2.5,3),'stone','Rock')
# Gates, raised throne stage
part(fort,'Splintered gates',(300,12,-205),(35,19,4),'wood','Wood')
part(fort,'Crown dais',(302,8.6,-123),(44,3,40),'stone2','Slate')
part(fort,'Warden throne',(302,15,-137),(17,13,9),'dark','Slate')
part(fort,'Throne golden teeth',(302,23,-137),(18,2,10),'gold','Metal')
for i in range(12):
 a=i*pi/6;x=302+35*cos(a);z=-123+35*sin(a)
 part(fort,'Crown sigil shard',(x,7,z),(5,.25,5),'purple','Neon',yaw=a)
textplate(props,'BROKEN CROWN FORTRESS',(302,31,-205),(31,4),'dark','gold')
# West beacon hill, south bridge beacon, fort beacon
beacons=[(-315,-10),(-55,85),(260,-47)]
for j,(x,z) in enumerate(beacons):
 base=part(props,'SignalBeacon' + str(j+1),(x,5,z),(8,7,8),'stone2','Slate')
 flame=ball(props,'Beacon core',(x,11,z),(4,4,4),'gold','Neon')
 light(flame,'gold',2.6,24)
 prompt(base,'BEACON','Broken signal beacon','Repair for 50 Gold',1.6,14)
# Supply caches at dangerous milestones. Their inventories replenish per-player.
for index,(x,z) in enumerate([(88,131),(-230,285),(282,-40),(159,165)]):
 box=part(props,'SupplyCache' + str(index+1),(x,3.65,z),(7,3.1,5),'wood','WoodPlanks')
 part(props,'Brass storage hinge',(x,5.3,z),(6,.5,4),'gold','Metal')
 prompt(box,'SUPPLY','ABANDONED SUPPLY CACHE','Scavenge Supplies',1.5,13)
# Interactable merchant desk, bank and nursery as world props, with sign labels
merchant=part(props,'GRINDLE THE GUNSMITH',(-120,7,-124),(5,9,3),'wall2','SmoothPlastic')
ball(props,'Grindle head',(-120,14,-124),(5,5,5),'moss','SmoothPlastic')
part(props,'Grindle hat',(-120,17,-124),(8,2,8),'roof','Slate')
for sx in [-1,1]:ball(props,'Grindle eye',(-120+sx*1.1,14.4,-126.5),(.6,.7,.5),'gold','Neon')
part(props,'Grindle shop counter',(-119,5,-133),(16,4,6),'wood','WoodPlanks')
prompt(merchant,'SHOP','GRINDLE • ARMORY','Browse Weapons',0.3,20)
textplate(props,'GRINDLE  /  ARMORY',(-120,22,-126),(18,3),'dark','gold')
bank=part(props,'Banker chest',(-195,4.1,-162),(11,5,6),'wood','WoodPlanks')
part(props,'Gold bullion heap',(-195,7,-162),(8,1,4),'gold','Metal')
prompt(bank,'BANK','BURIED TREASURY','Deposit Gold',.6,16)
textplate(props,'BANK YOUR GOLD',(-196,15,-162),(17,3),'dark','gold')
nest=part(props,'Hollow egg incubator',(-139,4.5,-186),(10,5,10),'stone2','Slate')
ball(props,'Incubation rune',(-139,8.8,-186),(5,4,5),'purple','Neon')
prompt(nest,'NURSERY','HOLLOW EGG NURSERY','Hatch Ready Egg',1.2,17)
textplate(props,'EGG NURSERY',(-139,17,-186),(15,3),'dark','purple')
god=part(props,'Godslayer shrine',(-173,6,-194),(12,9,12),'dark','Slate')
ball(props,'The reactor',(-173,12,-194),(7,7,7),'moss','Neon')
prompt(god,'GODSLAYER','GODSLAYER • 100 ROBUX','Claim / Unlock',.9,17)
textplate(props,'THE GODSLAYER  100 R$',(-173,23,-194),(26,3),'dark','gold')
# Several silent world story objects to discover
for i,(x,z,message) in enumerate([
 (-65,171,'THE BANDITS FEARED THE WARDEN FIRST'),(-289,264,'OUR MAGIC KEEPS HIM ASLEEP'),
 (245,-57,'THE CROWN IS HUNGRY'),(-322,-102,'TURN BACK BEFORE SUNDOWN')]):
 tablet=part(props,'Kingdom lore tablet',(x,6,z),(6,8,2),'stone2','Slate')
 prompt(tablet,'LORE',message,'Read Inscription',1,12)
# ---------------------------------------------------------------------------
# Landmark architecture: hand-composed, not generic teleport-room boxes.
# ---------------------------------------------------------------------------
# The Splintered Span — an abandoned toll bridge over the western river
for j in range(13):
 x=-388+j*7
 part(wilderness,'Splintered span old timber',(x,4.5,19),(7.4,1.8,18),'wood','WoodPlanks')
 for sz in [-1,1]:
  part(wilderness,'Bridge rail post',(x,7,19+sz*8),(1.5,5,1.5),'wood','Wood')
for j in range(10):
 part(wilderness,'Broken bridge rail',(-379+j*9,9,10),(8,.6,.7),'wood','Wood')
part(wilderness,'Toll keeper booth',(-300,8,23),(15,12,17),'wall2','Brick')
part(wilderness,'Toll keeper roof',(-300,15,23),(18,6,18),'roof2','Slate')
textplate(props,'THE SPLINTERED SPAN',(-301,17,4),(29,3))

# Stonebreaker windmill and village granary — recognisable silhouette on the ridge
millX,millZ=-45,-219
for k in range(9):
 f=(9-k)*1.1
 part(settlement,'Stonebreaker mill tower',(millX,3+k*2.6,millZ),(22-f,3,22-f),'wall2','Brick')
part(settlement,'Windmill dark cap',(millX,29,millZ),(17,6,17),'roof','Slate')
for theta in [0,pi/2,pi,3*pi/2]:
 rx=millX+cos(theta)*11;ry=25+sin(theta)*11
 part(settlement,'Windmill rotor blade',(rx,ry,millZ-12),(3,17,1),'wood','WoodPlanks',yaw=theta)
part(settlement,'Windmill hub',(millX,25,millZ-12),(5,5,4),'iron','Metal')
for i in range(16):
 th=i*pi/8
 x=millX+33*cos(th);z=millZ+33*sin(th)
 part(settlement,'Grain sack',(x,3.2,z),(3,2,4),'wall','Fabric' if 'Fabric' in material else 'SmoothPlastic')

# Cart wrecks and wagon debris: traversal landmarks where enemies can hide
for cx,cz in [(146,225),(-94,166),(-178,40),(214,-53)]:
 part(wilderness,'Abandoned caravan flatbed',(cx,5,cz),(20,2,10),'wood','WoodPlanks')
 for sx in [-1,1]:
  for sz in [-1,1]:
   ball(wilderness,'Wagon wheel',(cx+sx*7.7,4,cz+sz*5.8),(4.5,4.5,1.3),'dark','Wood',True)
 part(wilderness,'Collapsed wagon rail',(cx,8,cz),(21,2,1),'wood','Wood')
 for i in range(5):part(wilderness,'Split cargo',(cx+random.uniform(-7,7),8,cz+random.uniform(-3,3)),(3,2,3),'wall2','WoodPlanks')

# An old sorcerer's observatory overlooking the woods
ox,oz=174,282
part(wilderness,'Starwatch stone platform',(ox,4,oz),(63,4,63),'stone','Slate')
for k in range(12):
 a=k*2*pi/12
 x=ox+24*cos(a);z=oz+24*sin(a)
 part(wilderness,'Starwatch weathered pillar',(x,13,z),(3,17,3),'stone2','Slate')
 ball(wilderness,'Runic marker',(x,22,z),(2,2,2),'gold','Neon')
part(wilderness,'Collapsed astronomical orrery',(ox,9,oz),(15,6,15),'gold','Metal',shape=2)
textplate(props,'STARWATCH : THE SKY REMEMBERS',(ox,24,oz-27),(32,3),'dark','gold')

# Swamp giant mushroom forest, purple crystals and underground-look cave mouth
for j in range(42):
 mx=random.uniform(-344,-115);mz=random.uniform(159,345)
 if (mx+230)**2+(mz-245)**2<45**2:continue
 ht=random.uniform(4,13)
 part(marsh,'Mycelium stalk',(mx,2.4+ht/2,mz),(1.2,ht,1.2),'wall2','SmoothPlastic')
 ball(marsh,'Bioluminescent cap',(mx,3.4+ht,mz),(random.uniform(5,12),2.8,random.uniform(5,12)),random.choice(['purple','moss','ember']),'Neon')
for j in range(75):
 x=random.uniform(-339,-134);z=random.uniform(175,360)
 ball(marsh,'Violet crystal deposit',(x,3.7,z),(random.uniform(.9,2.4),random.uniform(3,7),random.uniform(.9,2.5)),random.choice(['purple','moss']),'Neon')
part(marsh,'Hollow witch cave',( -335,14,322),(29,28,25),'dark','Rock')
part(marsh,'Cave dark opening',(-335,12,307),(16,21,2),'dark','SmoothPlastic',collide=False)
for xx in [-343,-326]:
 ball(marsh,'Dripping cave ichor',(xx,16,306),(4,8,3),'purple','Neon')
textplate(props,'THE WITCH HAS NO SHADOW',(-330,29,304),(28,3),'dark','purple')

# Ancient skull fossil / boss foreshadowing in the valley floor
sx,sz=41,264
ball(wilderness,'Titan fossil skull',(sx,9,sz),(25,17,17),'wall','Rock')
for j in range(11):
 xx=sx-28+j*6
 part(wilderness,'Titan fossil rib',(xx,11,sz+7),(2,17,3),'wall','Rock',yaw=sin(j)*.4)
for side in [-1,1]:
 ball(wilderness,'Titan empty eye socket',(sx+side*6,12,sz-8),(5,5,2),'dark','SmoothPlastic')
textplate(props,'THE LAST OF THE TITANS',(sx,22,sz-11),(29,3),'dark','gold')

# Fortress broken statues, torn banners, burn braziers, colored windowpanes
for cx in [227,370]:
 for cz in [-166,-64]:
  part(fort,'Crown sentinel plinth',(cx,8,cz),(10,5,10),'stone2','Slate')
  part(fort,'Crown sentinel statue',(cx,16,cz),(6,13,5),'iron','Metal')
  ball(fort,'Sentinel marble head',(cx,25,cz),(6,6,6),'stone','Slate')
  for side in [-1,1]:part(fort,'Sentinel shoulder',(cx+side*5,17,cz),(2.5,10,3),'iron','Metal')
for i in range(12):
 theta=2*pi*i/12;x=302+60*cos(theta);z=-121+60*sin(theta)
 base=part(fort,'Warden ritual brazier',(x,9,z),(5,6,5),'dark','Metal')
 flame=ball(fort,'Hollow flame',(x,13,z),(2.2,4,2.2),'purple','Neon')
 if i%3==0:light(flame,'purple',2.8,24)
for z in range(-188,-25,17):
 part(fort,'Royal hanging tapestry',(392,20,z),(1.1,12,8),'purple','Fabric' if 'Fabric' in material else 'SmoothPlastic')
 part(fort,'Heraldic gold trim',(392,27,z),(1.2,1.2,8),'gold','Metal')

# Terrain boundary silhouettes. These hills are scenery, not progression walls.
for j in range(38):
 x=-510+j*28
 h=random.uniform(15,60)
 part(land,'Western cliffs ridge',(x,h/2-1,458),(33,h,64),'stone2','Rock')
for j in range(36):
 z=-490+j*27
 h=random.uniform(16,64)
 part(land,'Eastern hills ridge',(516,h/2-1,z),(41,h,38),'stone','Rock')

# Simple spawn
spawn=item('SpawnLocation',ws,'Outlaw Valley Player Spawn',[
 ('bool','Anchored',True),('bool','CanCollide',True),('bool','Neutral',True),('bool','Enabled',True),
 ('token','Material',material['Neon']),('Color3uint8','Color3uint8',palette['gold']),
 ('CoordinateFrame','CFrame',((-165,4.0,-150),0)),('Vector3','Size',(7,1,7)),
 ('float','Transparency',.72)])
# Lighting
lighting=item('Lighting',root,'Lighting',[
 ('float','ClockTime',16.2),('float','Brightness',3),('float','ExposureCompensation',.13),
 ('float','FogStart',90),('float','FogEnd',680),('Color3','FogColor',(102,139,141)),
 ('Color3','Ambient',(116,124,133)),('Color3','OutdoorAmbient',(135,153,149)),('bool','GlobalShadows',True)])
item('Atmosphere',lighting,'Valley Mist',[('float','Density',.27),('float','Offset',.08),
 ('Color3','Color',(151,193,189)),('Color3','Decay',(85,104,128)),('float','Glare',.3),('float','Haze',1.6)])
item('BloomEffect',lighting,'Arcane Bloom',[('bool','Enabled',True),('float','Intensity',.3),('float','Size',28),('float','Threshold',1.25)])
item('ColorCorrectionEffect',lighting,'Cinematic Color Grade',[('bool','Enabled',True),('float','Brightness',.02),('float','Contrast',.13),('float','Saturation',.13),('Color3','TintColor',(246,245,235))])
item('SunRaysEffect',lighting,'Late Sunbeams',[('bool','Enabled',True),('float','Intensity',.06),('float','Spread',.67)])
rs=item('ReplicatedStorage',root,'ReplicatedStorage')
ssc=item('ServerScriptService',root,'ServerScriptService')
sp=item('StarterPlayer',root,'StarterPlayer')
scripts=item('StarterPlayerScripts',sp,'StarterPlayerScripts')
for path,cls,parent in [
 ('OutlawConfig.lua','ModuleScript',rs),('OutlawRules.lua','ModuleScript',rs),('OutlawRigFactory.lua','ModuleScript',rs),('OutlawServer.lua','Script',ssc),('OutlawClient.lua','LocalScript',scripts)]:
 script=item(cls,parent,path[:-4]);addp(script.find('Properties'),'ProtectedString','Source',(BASE/'src'/path).read_text())
# Player defaults
addp(sp.find('Properties'),'float','CharacterWalkSpeed',19)
addp(sp.find('Properties'),'float','CharacterJumpPower',48)
# Camera sound ambient via SoundService not externally sourced, intentionally no unverified audio.
service=item('SoundService',root,'SoundService')
# Build, log, package
out=BASE/'Outlaw_Valley_Hollow_Crown_0_1.rbxlx'
E.ElementTree(root).write(str(out),encoding='utf-8',xml_declaration=True,pretty_print=True)
manifest={"version":"0.1.0-first-playable","place":out.name,"world":{
 "settlements":1,"combat_regions":3,"interactables":10,"scenic_parts":counts.get('Part',0),
 "enemy_types":8,"weapons":7,"bosses":1},"instances":serial,"classes":counts,
 "notes":"Original static hand-built world. No Goblin Hunt assets or scripts reused. Creator Store imports still pending manual vetting."}
(BASE/'BUILD_MANIFEST.json').write_text(json.dumps(manifest,indent=2))
print(json.dumps(manifest,indent=2))
print('Place generated',out,'size',out.stat().st_size)