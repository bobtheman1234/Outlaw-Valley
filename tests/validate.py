"""Offline validation: syntax, executable pure purchase rules, XML wiring, region geometry.
NOT a Roblox Studio playtest, performance profile, or purchase sandbox verification.
"""
from pathlib import Path
from lxml import etree as E
import ctypes,json,collections,sys
BASE=Path(__file__).resolve().parents[1]
L=ctypes.CDLL('liblua5.4.so.0')
L.luaL_newstate.restype=ctypes.c_void_p
L.luaL_loadbufferx.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_size_t,ctypes.c_char_p,ctypes.c_char_p]
L.luaL_loadbufferx.restype=ctypes.c_int
L.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_long,ctypes.c_void_p]
L.lua_pcallk.restype=ctypes.c_int
L.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p]
L.lua_tolstring.restype=ctypes.c_char_p
L.lua_close.argtypes=[ctypes.c_void_p]
L.luaL_openlibs.argtypes=[ctypes.c_void_p]
checks=[]
def check(name,cond):
 checks.append({'name':name,'pass':bool(cond)})
 if not cond: print('FAIL',name)
def runlua(code,label):
 state=L.luaL_newstate();L.luaL_openlibs(state);blob=code.encode();s=L.luaL_loadbufferx(state,blob,len(blob),label.encode(),None)
 if s==0:s=L.lua_pcallk(state,0,-1,0,0,None)
 if s!=0:
  message=L.lua_tolstring(state,-1,None)
  message=message.decode(errors='replace') if message else 'Unknown Lua error'
  print(label,'FAIL',message)
 L.lua_close(state)
 return s==0
for path in sorted((BASE/'src').glob('*.lua')):
 check('syntax: '+path.name,runlua('return function()\n'+path.read_text()+'\nend','parse:'+path.name))
rules=(BASE/'src/OutlawRules.lua').read_text()
tests='''
local function eq(name,a,b) assert(a==b,name..' expected '..tostring(b)..' got '..tostring(a)) end
local w={Rustfang={price=0,mag=0,reserve=0},Crossbow={price=180,mag=6,reserve=48},Godslayer={price=-1,mag=999,reserve=999}}
eq('buy enough',Rules.purchase('Crossbow',180,{},w),true)
eq('buy fail',Rules.purchase('Crossbow',179,{},w),false)
eq('already owned',Rules.purchase('Crossbow',1000,{Crossbow=true},w),false)
eq('pass cannot buy',Rules.purchase('Godslayer',100000,{},w),false)
eq('missing sku',Rules.purchase('Fake',100000,{},w),false)
eq('0 loot',Rules.stolenGold(0,.25),0)
eq('quarter',Rules.stolenGold(150,.25),37)
eq('clamped pvp',Rules.stolenGold(100,2),100)
eq('negative gold',Rules.stolenGold(-300,.25),0)
local ready,left=Rules.readyEgg({},100);eq('empty egg',ready,nil);eq('empty remaining',left,0)
ready,left=Rules.readyEgg({200,300},100);eq('egg not ready',ready,nil);eq('egg seconds',left,100)
ready,left=Rules.readyEgg({200,300},200);eq('egg ready',ready,1);eq('ready seconds',left,0)
eq('ammo refill counted',Rules.refillCost({Crossbow=true,Rustfang=true,Godslayer=true},w,{Crossbow=1}),1)
eq('ammo full',Rules.refillCost({Crossbow=true},w,{Crossbow=48}),0)
'''
check('executed Lua rules: 15 assertions',runlua('local Rules=(function()\n'+rules+'\nend)()\n'+tests,'behavior-tests'))
place=BASE/'Outlaw_Valley_Hollow_Crown_v04_ArtUpgrade.rbxlx'
tree=E.parse(str(place));r=tree.getroot()
check('place xml root',r.tag=='roblox' and r.get('version')=='4')
for name in ('OutlawConfig','OutlawRules','OutlawRigFactory','OutlawClient','OutlawServer','OutlawAssetCatalog','OutlawAssetInstaller','OutlawAssetRuntime'):
 nodes=r.xpath('//Item[Properties/string[@name="Name"]=$v]',v=name)
 check('script embedded: '+name,len(nodes)==1 and nodes[0].find('Properties/ProtectedString[@name="Source"]') is not None)
 if len(nodes)==1:
  source=nodes[0].findtext('Properties/ProtectedString[@name="Source"]')
  check('embedded source exact: '+name,source==(BASE/'src'/f'{name}.lua').read_text())
for name in ('CROOKED CREEK  |  SETTLEMENT','THIEVES WOODS  |  CAMPS & RUINS','WITCHWATER  |  CURSED MARSH','BROKEN CROWN  |  FORTRESS'):
 check('region exists: '+name,len(r.xpath('//Item[Properties/string[@name="Name"]=$v]',v=name))==1)
for name in ('OV_SHOP','OV_BANK','OV_NURSERY','OV_GODSLAYER'):
 check('prompt exists: '+name,len(r.xpath('//Item[@class="ProximityPrompt"][Properties/string[@name="Name"]=$v]',v=name))==1)
check('beacons',len(r.xpath('//Item[@class="ProximityPrompt"][Properties/string[@name="Name"]="OV_BEACON"]'))==3)
check('supply caches',len(r.xpath('//Item[@class="ProximityPrompt"][Properties/string[@name="Name"]="OV_SUPPLY"]'))==4)
check('distinct props',len(r.xpath('//Item[@class="Part"]'))>=3200)
check('Creator Store model references',len(__import__('re').findall(r'assetId=\d+', (BASE/'src/OutlawAssetCatalog.lua').read_text()))==11)
check('automatic asset loader wired',len(r.xpath('//Item[@class="Script"][Properties/string[@name="Name"]="OutlawAssetRuntime"]'))==1)
check('imported model scripts stripped',"child:IsA('LuaSourceContainer')" in (BASE/'src/OutlawAssetInstaller.lua').read_text())
report={'summary':{'passed':sum(x['pass'] for x in checks),'failed':sum(not x['pass'] for x in checks),
 'roblox_studio_runtime':'NOT EXECUTED','creator_store_meshes_embedded_offline':0,'creator_store_models_curated_for_in_game_loading':11},'checks':checks}
(BASE/'TEST_REPORT.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report['summary'],indent=2))
sys.exit(0 if report['summary']['failed']==0 else 1)