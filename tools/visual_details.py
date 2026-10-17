# Injected into the deterministic map build to give Outlaw Valley an art pass
# even when third-party Creator Store assets are unavailable on Roblox servers.
# World detail remains complementary to imported meshes rather than relying on them.

# Miniature wrought iron lanterns in a village with climbing ivy and plaster trim.
for hx,hz in [(-213,-177),(-207,-106),(-116,-104),(-113,-190),(-171,-225),(-247,-142),(-83,-159),(-148,-77)]:
 for sx in (-1,1):
  for layer in range(3):
   ball(settlement,'Ivy cluster / layered leaves',(hx+sx*8.2,7+layer*2.1,hz+6),
        (2.6,1.8,3.2),random.choice(['leaf','leaf2','grass3']),'Grass')
  part(settlement,'Ivy woody strand',(hx+sx*8.3,6.4,hz+6),(.22,5,.25),'bark','Wood',collide=False)
 for sx in (-1,1):
  zz=hz-7;xx=hx+sx*5.8
  for i in range(3):
   part(settlement,'Leaded window mullion',(xx+(i-1)*.8,7.9,zz),(0.15,3.6,.2),'iron','Metal',collide=False)
  part(settlement,'Stone sill',(xx,5.9,zz),(3.7,.3,.75),'wall2','Slate',collide=False)
 part(settlement,'Lichen-covered chimney',(hx+5,16,hz+4),(3.2,7,3.2),'wall2','Brick',collide=False)
 part(settlement,'Soot-black chimney lip',(hx+5,20,hz+4),(4.5,.6,4.5),'dark','Slate',collide=False)
 for k in range(2):
  part(settlement,'House antique lintel trim',(hx+(k*2-1)*5,11.8,hz-7.9),(5,.35,.45),'wood','Wood',collide=False)
 # Basket stacks, distinct window boxes and flowing flower covers.
 for sign in (-1,1):
  xx=hx+sign*5
  part(settlement,'Window flower box',(xx,6.4,hz-7.7),(4,.7,1.1),'wood','WoodPlanks',collide=False)
  for f in range(3):
   ball(settlement,'Hanging flower',(xx+(f-1)*1.1,7,hz-7.8),(.7,.7,.7),random.choice(['gold','purple','ember']),'Neon')

# Blacksmith shop with readable exterior silhouettes instead of anonymous crates.
for i in range(5):
 x=-112+i*3.5
 part(settlement,'Grindle forge awning rib',(x,13.1,-134),(1.0,.9,13),'wood','Wood',collide=False)
 part(settlement,'Grindle forge canvas',(x,13.65,-134),(3.5,.32,13),'roof2','Slate',collide=False)
for i in range(6):
 part(settlement,'Grindle forged sword in rack',(-103.2+i*1.8,7,-139),(.3,7,.2),'iron','Metal',collide=False)
 part(settlement,'Grindle blade edge',(-103.2+i*1.8,10,-139),(.65,3,.2),'stone2','Metal',collide=False)
part(settlement,'Forged anvil altar',(-110,4.7,-135),(5,3,2.8),'iron','Metal',collide=False)
part(settlement,'Forge coal hearth',(-110,3.1,-137),(7,1.3,5),'dark','Slate',collide=False)
for i in range(6):
 ball(settlement,'Dying ember spark',(-110+random.uniform(-3,3),4.5,-137+random.uniform(-2,2)),(.5,.5,.5),'ember','Neon')

# Market awnings, cloth rolls, ropes and stocked stalls in the hub.
for cx,cz,shade in [(-210,-85,'roof2'),(-165,-82,'purple'),(-123,-82,'roof')]:
 for dx in (-1,1):
  for dz in (-1,1):
   part(settlement,'Canvas stall support',(cx+dx*8,8,cz+dz*5),(.52,11,.52),'wood','Wood',collide=False)
 for strip in range(8):
  color=shade if strip%2 else 'wall2'
  part(settlement,'Alternating market awning',(cx-7+strip*2,13.6,cz),(2.1,.38,12),color,'SmoothPlastic',collide=False)
 part(settlement,'Timber vendor counter',(cx,4.8,cz),(15,2.4,6),'wood','WoodPlanks',collide=False)
 for i in range(13):
  x=cx+random.uniform(-6,6);z=cz+random.uniform(-2,2)
  ball(settlement,'Market spices and fruit',(x,6.1,z),(.9,.8,.9),random.choice(['ember','gold','leaf','purple']),'SmoothPlastic')

# Landmarks that are visible from the dirt paths.
for cx,cz in [(-285,-45),(171,87),(-110,150),(175,214)]:
 part(wilderness,'Carved pilgrim signpost',(cx,5,cz),(1,8,1),'wood','Wood',collide=False)
 part(wilderness,'Pilgrim arrow plaque',(cx+1.9,8.2,cz),(7.7,1.5,.65),'wood','WoodPlanks',collide=False)
 part(wilderness,'Rusty nailed trim',(cx,9.1,cz),(.35,2,.7),'iron','Metal',collide=False)
for i in range(16):
 cx=70+random.uniform(-44,45);cz=112+random.uniform(-43,43)
 part(wilderness,'Camp scattered arrow shaft',(cx,3.2,cz),(.2,.2,5.4),'wood','Wood',yaw=random.uniform(0,pi),collide=False)
 ball(wilderness,'Camp arrow feathers',(cx,3.45,cz),(1,.25,.8),'wall','SmoothPlastic')
for i in range(8):
 a=i*pi/4
 x=82+33*cos(a);z=101+33*sin(a)
 part(wilderness,'Stone campfire surround',(x,2.7,z),(6,1.1,4),'stone2','Rock',yaw=a,collide=False)
ball(wilderness,'Campfire ember bed',(82,3.1,101),(7,1.0,7),'ember','Neon')
for i in range(8):
 a=i*pi/4
 ball(wilderness,'Campfire rock',(82+4.7*cos(a),3.1,101+4.7*sin(a)),(2,1.5,2),'stone','Rock')

# Witchwater landmarks, thorned spines, spores, haunted pond ripples.
for k in range(50):
 x=random.uniform(-320,-138);z=random.uniform(175,347)
 if (x+230)**2+(z-245)**2<50**2:continue
 ht=random.uniform(3,8)
 for n in range(2):
  part(marsh,'Petrified thorn',(x+(n-.5)*1.9,3.1+ht*.5,z),(0.5,ht,.6),'dark','Wood',yaw=(random.uniform(-.6,.6),0,random.uniform(-.5,.5)),collide=False)
 ball(marsh,'Arcane firefly',(x,3+ht,z),(0.55,.55,.55),random.choice(['purple','moss']),'Neon')
for j in range(36):
 th=j*2*pi/36
 x=-230+26*cos(th);z=245+26*sin(th)
 part(marsh,'Broken ritual circle engraved stone',(x,2.6,z),(3.5,.33,1.5),'stone2','Slate',yaw=th,collide=False)
 if j%4==0:
  part(marsh,'Suspended ritual chain',(x,8,z),(.3,11,.3),'iron','Metal',collide=False)
  ball(marsh,'Ritual hovering flame',(x,14,z),(2,3,2),'purple','Neon')
for cx,cz in [(-175,242),(-290,186),(-143,307)]:
 ball(marsh,'Blackwater pond',(cx,2.65,cz),(23,.3,16),'water','Glass')
 for j in range(9):
  theta=j*2*pi/9
  ball(marsh,'Waterlily floating leaves',(cx+7*cos(theta),2.85,cz+4*sin(theta)),(3,.25,2.4),'leaf2','Grass')

# Roof and ruined banner overlays that silhouette the distant fortress.
for x in [208,389]:
 for z in [-199,-21]:
  for tier in range(3):
   y=29+tier*3
   for angle in range(8):
    th=angle*pi/4
    rx=x+(10-tier*1.2)*cos(th);rz=z+(10-tier*1.2)*sin(th)
    part(fort,'Tower carved cornice',(rx,y,rz),(3,.9,2.2),'stone2','Slate',yaw=th,collide=False)
  for j in range(5):
   th=j*2*pi/5
   ball(fort,'Battlement ivy',(x+12*cos(th),23,z+12*sin(th)),(3.5,3.5,3),'grass3','Grass')
for x in range(233,375,12):
 part(fort,'Fortress wall buttress',(x,18,-197),(2.7,23,4),'stone2','Slate',collide=False)
 part(fort,'Battered blue and gold tapestry',(x,16,-192),(3,.25,9),random.choice(['roof','purple']),'SmoothPlastic',collide=False)
 part(fort,'Gold tapestry trim',(x,12,-192),(3,.3,9),'gold','Metal',collide=False)
for x,z in [(232,-66),(355,-64),(232,-155),(355,-155)]:
 for tier in range(4):
  part(fort,'Ruined gothic buttress',(x,7+tier*3,z),(3+tier*.5,5,3+tier*.2),'stone2','Slate',collide=False)
 ball(fort,'Crumbling carved statue helm',(x,22,z),(3.3,4,3.3),'iron','Metal')

# Beacon rings communicate importance: physical tethers and clouds of fireflies.
for bx,bz in [(-315,-10),(-55,85),(260,-47)]:
 for j in range(16):
  a=j*pi/8
  r=9.4
  xx=bx+r*cos(a);zz=bz+r*sin(a)
  part(props,'Radiant beacon runic rim',(xx,2.65,zz),(1.5,.25,2),'gold','Metal',yaw=a,collide=False)
  if j%4==0:
   part(props,'Beacon carved obelisk',(xx,5.9,zz),(2,6,2),'stone','Slate',collide=False)
   ball(props,'Beacon sprite',(xx,9.5,zz),(.9,.9,.9),'gold','Neon')

# The Godslayer altar becomes a recognisable brass-and-malachite reactor.
for j in range(16):
 a=j*2*pi/16
 cx=-173+8.1*cos(a);cz=-194+8.1*sin(a)
 part(props,'Godslayer concentric engraved rune',(cx,2.55,cz),(2.0,.28,1.2),'gold','Metal',yaw=a,collide=False)
 if j%2==0:
  part(props,'Godslayer ion coil',(cx,7.6,cz),(.65,6.8,.65),'iron','Metal',collide=False)
  ball(props,'Godslayer luminous capacitor',(cx,11.4,cz),(1.3,1.3,1.3),'moss','Neon')
for j in range(6):
 a=j*pi/3
 part(props,'Godslayer overhead restraint',(-173+6*cos(a),13,-194+6*sin(a)),(2,1,8),'iron','Metal',yaw=a,collide=False)
for j in range(11):
 ball(props,'Godslayer suspended lightning fragments',(-173+random.uniform(-5,5),13+random.uniform(-2,3),-194+random.uniform(-5,5)),(.65,.65,.65),'moss','Neon')