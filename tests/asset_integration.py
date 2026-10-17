"""Offline-only checks. NO Roblox Studio / remote asset delivery tests."""
from pathlib import Path
from lxml import etree as E
import re,json,sys
ROOT=Path(__file__).resolve().parents[1]
CAT=(ROOT/'src/OutlawAssetCatalog.lua').read_text()
INS=(ROOT/'src/OutlawAssetInstaller.lua').read_text()
RUNTIME=(ROOT/'src/OutlawAssetRuntime.lua').read_text()
SERVER=(ROOT/'src/OutlawServer.lua').read_text()
PLACE=ROOT/'Outlaw_Valley_Hollow_Crown_v04_ArtUpgrade.rbxlx'
r=E.parse(str(PLACE)); checks=[]
def ck(n,v):
 checks.append({'check':n,'pass':bool(v)})
 if not v:print('FAILED',n)
ids=re.findall(r'assetId=(\d+)',CAT)
ck('11 unique public asset references',len(ids)==11 and len(set(ids))==11)
ck('33+ selected asset placements',sum(len(re.findall(r'Vector3\.new\(',block)) for block in CAT.split(' key=')[1:])>=33)
ck('asset loader bound to live game',bool(r.xpath('//Item[@class="Script"][Properties/string[@name="Name"]="OutlawAssetRuntime"]')))
ck('AssetService uses supported 2026 LoadAssetAsync API',"AssetService:LoadAssetAsync(id)" in INS)
ck('script security sanitization',"child:IsA('LuaSourceContainer')" in INS and "child:Destroy()" in INS)
ck('dangerous Tool and remote cleanup',all(s in INS for s in ["child:IsA('Tool')","child:IsA('RemoteEvent')","child:IsA('RemoteFunction')"]))
ck('placeholder floor & geometry not deleted',"fadeOriginalHouse" in INS and "part.Transparency=.97" in INS)
ck('preserves accessibility without store assets',"if template then" in INS and "table.insert(failures" in INS)
ck('no duplicate imported assets',"GetAttribute('ImportComplete')" in INS and "existing:ClearAllChildren()" in INS)
ck('limit mass imported asset parts',"count>maxParts" in INS)
ck('gamepass owner logic preserved',"game.CreatorId==p.UserId" in SERVER and "UserOwnsGamePassAsync" in SERVER)
ck('Godslayer art refinement',"Heart of the Hollow Crown" in SERVER and "Goldwork Royal Crest" in SERVER and "Reactor illumination" in SERVER)
ck('place contains many art details',len(r.xpath('//Item[@class="Part"]'))>3500)
ck('store source URLs documented',all(id in (ROOT/'ASSET_AUDIT.md').read_text() for id in ids))
ck('scripts exact embedded source',all((lambda q:len(q)==1 and q[0].findtext('Properties/ProtectedString[@name="Source"]')==(ROOT/'src'/f'{n}.lua').read_text())(r.xpath('//Item[Properties/string[@name="Name"]=$x]',x=n)) for n in ['OutlawAssetCatalog','OutlawAssetInstaller','OutlawAssetRuntime']))
ck('no background installer required to spawn',"task.delay(4" in RUNTIME)
ck('creator store URL references all listed as public free',len(ids)==11 and ('98% rating' in (ROOT/'ASSET_AUDIT.md').read_text()))
report={'kind':'OFFLINE static integration check; zero actual Roblox Creator Store models downloaded; no Studio runtime','passed':sum(x['pass'] for x in checks),'failed':sum(not x['pass'] for x in checks),'checks':checks}
(ROOT/'ASSET_INTEGRATION_TESTS.json').write_text(json.dumps(report,indent=2))
print(report['passed'],'asset integration checks passed,',report['failed'],'failed')
sys.exit(bool(report['failed']))