"""Static game design contracts. These are NOT engine runtime tests."""
from pathlib import Path
from lxml import etree as E
import re, json, sys
BASE=Path(__file__).resolve().parents[1]
LUA={p.stem:p.read_text() for p in (BASE/'src').glob('*.lua')}
r=E.parse(str(BASE/'Outlaw_Valley_Hollow_Crown_v04_ArtUpgrade.rbxlx')).getroot()
CHECK=[]
def check(title,result):
 CHECK.append((title,bool(result)))
 if not result:print('FAIL',title)

def count_part(name):
 return len(r.xpath('//Item[@class="Part"][Properties/string[@name="Name"]=$n]',n=name))
def count_prompt(name):
 return len(r.xpath('//Item[@class="ProximityPrompt"][Properties/string[@name="Name"]=$n]',n=name))
config=LUA['OutlawConfig'];server=LUA['OutlawServer'];client=LUA['OutlawClient'];bld=(BASE/'tools/build_place.py').read_text()
# Source is wired into the place and belongs to this new game.
for script in ('OutlawClient','OutlawServer','OutlawConfig','OutlawRules','OutlawRigFactory'):
 matches=r.xpath('//Item[Properties/string[@name="Name"]=$n]',n=script)
 check('source embedded: '+script,len(matches)==1 and matches[0].findtext('Properties/ProtectedString[@name="Source"]')==LUA[script])
check('no prior combat engine imported','require(Goblin' not in server and 'GH10' not in server)
check('landscape breadth',count_part('Rolling kingdom grasslands')==1 and count_part('Northern highlands')==1)
check('eight different homes',count_part('House hardwood floor')>=8)
check('gable roofs not solid roof cubes',count_part('Steep slate roof face')>=16 and count_part('Dark tiled roof')==0)
check('accessible canvas tents',count_part('Sloping bandit tent canvas')>=8 and count_part('Bandit canvas tent')==0)
check('three relic locations',count_prompt('OV_RELIC')==3)
check('three defensive shrines',count_prompt('OV_BEACON')==3)
check('real world ammo caches',count_prompt('OV_SUPPLY')==4)
check('shop prompt available',count_prompt('OV_SHOP')==1)
check('bank prompt available',count_prompt('OV_BANK')==1)
check('nursery prompt available',count_prompt('OV_NURSERY')==1)
check('paywall is only a game pass, not fake Robux','price=-1' in config and 'C.PassId = 0' in config)
check('Godslayer requires verified entitlement',all(x in server for x in ('UserOwnsGamePassAsync','game.CreatorId==p.UserId','d.owned.Godslayer=d.godslayer and true or nil','savedOwned.Godslayer=nil')))
check('Godslayer can one-shot a player',"damage=100000" in config and "C.PlayerMaxHealth = 125" in config)
check('server-authoritative shooting',all(x in server for x in ("OnServerEvent:Connect", "getEnemyFromPart(hit.Instance)","d.heldAmmo[id]=d.heldAmmo[id]-1", "h:TakeDamage(damage)")))
check('finite normal magazines',all(re.search(re.escape(key)+r'=\{[^\n]*mag=[1-9][0-9]*,reserve=[1-9][0-9]*',config) for key in ('Crossbow','Blunderbuss','Witchfire','Rattler','Boomstick')))
check('reloading synchronized',"Action:FireServer('Reload',selected)" in client and 'local function reload(p,id)' in server and 'State:FireClient(p,{ammoOnly=id' in server)
check('enemy danger targeting',all(x in server for x in ('damagePlayer(nil,target,e.conf.damage)','damageInZone(point,radius,e.conf.damage)','spawnHostileProjectile(')))
check('dodge server validated',"if action=='Dodge' then dodge(p)" in server and 'dodgeState[victim]' in server and 'nextReady=now+3.0' in server)
check('hostile enemies steer around cover',"Local obstacle feeler" in server and 'workspace:Raycast(e.pos+Vector3.new' in server)
check('wizard teleports',"e.kind=='Wizard'" in server and "e.nextBlink=clock()+13" in server)
check('boss summon and multiphase',all(x in server for x in ("phase=2", "phase=3", "KNEEL BEFORE THE EMPTY THRONE", "THE CROWN WILL HAVE ITS BLOOD")))
check('explosive barrels',count_part('Supply barrel')>=20 and "explodeBarrel(hit.Instance,p)" in server)
check('cooperative boss reward',all(x in server for x in ('contributors={}','BOSS ASSIST: +1 CROWN SHARD','enemy.maxHP*.12')))
check('beacons require 3 fighting rounds',all(x in server for x in ('for wave=1,3 do','trialEnemiesRemain(trial.tag)>0','finishTrial(beacon,true)')))
check('secret sword guardian unlock',"d.owned.Soulrender=true" in server and "giveTool(p,'Soulrender')" in server and 'local function claimRelic' in server)
check('eggs grow over 10 minutes', 'C.EggSeconds = 600' in config and 'Rules.readyEgg(d.eggs,os.time())' in server)
check('treasure banking and 25pct PvP loss',"C.PvPLootDropFraction = 0.25" in config and 'Rules.stolenGold(victim.coins,C.PvPLootDropFraction)' in server)
check('player spawn away from solid fountain',count_part('Central fountain basin')==1 and "((-164,4.0,-122),0)" in bld)
check('map exploration UI',"mapPanel.Visible=not mapPanel.Visible" in client and "local function mapCoordinate" in client)
check('world events occur',all(x in server for x in ('BANDIT RAID!','FALLEN STAR','AN OGRE HAS ESCAPED ITS CHAINS')))
check('data persistence attempted and guarded',all(x in server for x in ('DSS:GetDataStore',"store:GetAsync('u_'..p.UserId)","store:SetAsync('u_'..p.UserId,copy)", 'd.persistenceOK=ok')))
check('built-in texture particle effect',"sparkles_main.dds" in server and 'local function dressWorld()' in server)
check('real grenade travel not hitscan',all(x in server for x in ('launchGrenade(p,barrel,dir,weapon)','local fuse=2.9','velocity=direction.Unit*115','world:Raycast(pos,step,ray)')))
check('camera recoil distinguishes guns', "id=='Godslayer' and 2.8" in client and "id=='Rattler' and .3" in client)
check('store integration present', all(x in (BASE/'src/OutlawAssetInstaller.lua').read_text() for x in ('AssetService:LoadAssetAsync',"child:IsA('LuaSourceContainer')",'model:ScaleTo','CreatorStoreAssetId')))
check('source tool screenshots honest','NOT EXECUTED' in (BASE/'TEST_REPORT.json').read_text())
report={'kind':'offline structural contracts, NOT Roblox engine tests','passed':sum(x[1] for x in CHECK),'failed':sum(not x[1] for x in CHECK),'checks':[{'name':x,'pass':p} for x,p in CHECK]}
(BASE/'GAMEPLAY_CONTRACT_REPORT.json').write_text(json.dumps(report,indent=2))
print(report['passed'],'passing static contracts,',report['failed'],'failed')
sys.exit(1 if report['failed'] else 0)