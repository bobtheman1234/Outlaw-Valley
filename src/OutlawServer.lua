-- OUTLAW VALLEY: THE HOLLOW CROWN / SERVER
-- Server-authoritative damage, purchases, inventory, quests, PvP and persistence.
-- This script intentionally does NOT import or depend on Goblin Hunt.
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local DSS = game:GetService('DataStoreService')
local MPS = game:GetService('MarketplaceService')
local Run = game:GetService('RunService')
local Tween = game:GetService('TweenService')
local Debris = game:GetService('Debris')
local Lighting=game:GetService('Lighting')
local C = require(RS:WaitForChild('OutlawConfig'))
local Rules=require(RS:WaitForChild('OutlawRules'))
local Rigs=require(RS:WaitForChild('OutlawRigFactory'))
local world = workspace
local enemiesFolder = world:FindFirstChild('LivingEnemies') or Instance.new('Folder')
enemiesFolder.Name='LivingEnemies'; enemiesFolder.Parent=world
local effectsFolder = world:FindFirstChild('WorldEffects') or Instance.new('Folder')
effectsFolder.Name='WorldEffects'; effectsFolder.Parent=world
local remotes = RS:FindFirstChild('OutlawRemotes') or Instance.new('Folder')
remotes.Name='OutlawRemotes'; remotes.Parent=RS
local function remote(name)
 local r=remotes:FindFirstChild(name) or Instance.new('RemoteEvent')
 r.Name=name;r.Parent=remotes;return r
end
local Action=remote('Action')
local Feedback=remote('Feedback')
local Effects=remote('Effects')
local State=remote('State')
local store = DSS:GetDataStore('OutlawValley_HollowCrown_v1')
local profiles,activeEnemies,dropped={}, {}, {}
local dodgeState={}
local random=Random.new()
local enemySerial=0
local nextBossSpawn=0
local lastRaid=0
local function clock() return os.clock() end
local function ownsPass(p)
 if Run:IsStudio() then return true end -- owner test only; never a live-server grant.
 if C.OwnerUserIds[p.UserId] then return true end
 if game.CreatorType==Enum.CreatorType.User and game.CreatorId==p.UserId then return true end
 if C.PassId<=0 then return false end
 local ok,owns=pcall(function()return MPS:UserOwnsGamePassAsync(p.UserId,C.PassId)end)
 return ok and owns or false
end
local function inTown(pos)
 local d=Vector3.new(pos.X-C.TownCenter.X,0,pos.Z-C.TownCenter.Z)
 return d.Magnitude<C.SafeRadius
end
local function posOf(p)
 local ch=p.Character;local root=ch and ch:FindFirstChild('HumanoidRootPart')
 return root and root.Position or nil
end
local function alivePlayer(p)
 local ch=p.Character
 local h=ch and ch:FindFirstChildOfClass('Humanoid')
 return h and h.Health>0 and ch:FindFirstChild('HumanoidRootPart') and h or nil
end
local function notice(p,message,kind)
 Feedback:FireClient(p,kind or 'NOTICE',tostring(message))
end
local function eventMessage(message)
 Feedback:FireAllClients('WORLD',message)
end
local function sync(p)
 local d=profiles[p];if not d then return end
 State:FireClient(p,{coins=d.coins,bank=d.bank,owned=d.owned,eggs=d.eggs,hatched=d.hatched,
  relics=d.relics, kills=d.kills,warden=d.warden,quests=d.quests,pass=d.godslayer,
  ammo=d.ammo,version=C.Version,now=os.time(),safe=posOf(p) and inTown(posOf(p)) or true})
end
local function save(p)
 local d=profiles[p];if not d then return end
 if not d.persistenceOK then return end
 local savedOwned=table.clone(d.owned)
 savedOwned.Godslayer=nil -- paid passes are checked with MarketplaceService each session
 local copy={coins=d.coins,bank=d.bank,owned=savedOwned,eggs=d.eggs,hatched=d.hatched,
  relics=d.relics,kills=d.kills,warden=d.warden,quests=d.quests,ammo=d.ammo}
 local ok,err=pcall(function()store:SetAsync('u_'..p.UserId,copy)end)
 if not ok then warn('[Outlaw Valley] SAVE FAILED',p.UserId,err)end
end
local function load(p)
 local d={coins=C.StartCoins,bank=0,owned={Rustfang=true},eggs={},hatched=0,relics=0,
  kills=0,warden=0,quests={beacons=0,witch=0},ammo={}}
 local ok,data=pcall(function()return store:GetAsync('u_'..p.UserId)end)
 if ok and type(data)=='table' then
  for k in pairs(d) do
   if type(data[k])==type(d[k]) then d[k]=data[k]end
  end
 elseif not ok then warn('[Outlaw Valley] LOAD FAILED',p.UserId,data)end
 d.owned.Rustfang=true
 d.persistenceOK=ok
 d.godslayer=ownsPass(p)
 d.owned.Godslayer=d.godslayer and true or nil -- do NOT restore Studio free-tests as permanent entitlements
 d.fireTimes={}; d.reloadTimes={}; d.heldAmmo={}
 for id,weapon in pairs(C.Weapons) do
  if type(d.ammo[id])~='number' or d.ammo[id]<0 then d.ammo[id]=weapon.reserve end
  d.heldAmmo[id]=weapon.mag
 end
 profiles[p]=d
 sync(p)
end
local function sound(parent,id,volume,speed)
 local s=Instance.new('Sound');s.SoundId=id;s.Volume=volume or .5;s.PlaybackSpeed=speed or 1;s.Parent=parent
 s:Play();Debris:AddItem(s,3)
end
local function burst(pos,color,size,life)
 local p=Instance.new('Part')
 p.Name='Burst';p.Shape=Enum.PartType.Ball;p.Size=Vector3.new(1,1,1)
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
 p.Material=Enum.Material.Neon;p.Color=color;p.Transparency=.28;p.Position=pos;p.Parent=effectsFolder
 Tween:Create(p,TweenInfo.new(life or .35,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),
  {Size=Vector3.new(size,size,size),Transparency=1}):Play()
 Debris:AddItem(p,(life or .35)+.12)
 local light=Instance.new('PointLight');light.Color=color;light.Range=math.min(90,size*2);light.Brightness=3;light.Parent=p
 local sparks=Instance.new('ParticleEmitter')
 sparks.Name='Arcane shrapnel';sparks.Texture='rbxasset://textures/particles/sparkles_main.dds'
 sparks.Color=ColorSequence.new(color);sparks.Rate=0;sparks.Speed=NumberRange.new(size/2,size*1.6)
 sparks.SpreadAngle=Vector2.new(180,180);sparks.Lifetime=NumberRange.new(.12,.6)
 sparks.LightEmission=.95;sparks.Size=NumberSequence.new(.32);sparks.Parent=p
 sparks:Emit(math.max(8,math.min(80,math.floor(size*3))))
end
local function tracer(a,b,color,diameter,life)
 if (b-a).Magnitude<.01 then return end
 local p=Instance.new('Part')
 p.Name='ArcaneBolt';p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
 p.Material=Enum.Material.Neon;p.Color=color;p.Size=Vector3.new(diameter or .19,diameter or .19,(b-a).Magnitude)
 p.CFrame=CFrame.lookAt((a+b)*.5,b);p.Parent=effectsFolder
 Tween:Create(p,TweenInfo.new(life or .18),{Transparency=1}):Play()
 Debris:AddItem(p,(life or .18)+.05)
end
local function giveTool(p,id)
 local d=profiles[p];if not d or not d.owned[id] then return end
 local function make()
  local t=Instance.new('Tool');t.Name=C.Weapons[id].label;t.RequiresHandle=true;t.CanBeDropped=false
  t:SetAttribute('WeaponId',id);t.ToolTip=id=='Godslayer' and 'The crown bends to no one.' or 'Outlaw Valley | '..id
  local h=Instance.new('Part');h.Name='Handle';h.Size=Vector3.new(.38,1.25,.48)
  h.Material=Enum.Material.Metal;h.Color=Color3.fromRGB(64,57,49)
  h.CanCollide=false;h.Massless=true;h.Parent=t
  local weapon=C.Weapons[id]
  local function piece(name,size,offset,color,shape,rotation)
   local x=Instance.new('Part');x.Name=name;x.Size=size;x.Color=color;x.Material=Enum.Material.Metal
   x.CanCollide=false;x.Massless=true;x.Shape=shape or Enum.PartType.Block;x.CFrame=h.CFrame*CFrame.new(offset)*(rotation or CFrame.new())
   x.Parent=t;local weld=Instance.new('WeldConstraint');weld.Part0=h;weld.Part1=x;weld.Parent=x
  end
  if id=='Rustfang' then
   piece('Crossguard',Vector3.new(1.7,.14,.19),Vector3.new(0,.78,0),Color3.fromRGB(194,150,69))
   piece('Steel Blade',Vector3.new(.26,3.2,.13),Vector3.new(0,2.35,0),Color3.fromRGB(194,208,214))
  elseif id=='Soulrender' then
   piece('Soulrender Darksteel Guard',Vector3.new(1.9,.24,.4),Vector3.new(0,.86,0),Color3.fromRGB(52,33,67))
   piece('Soulrender Runic Blade',Vector3.new(.34,4.1,.19),Vector3.new(0,2.95,0),Color3.fromRGB(186,105,255))
   piece('Soulrender Moonstone',Vector3.new(.8,.85,.8),Vector3.new(0,4.9,0),Color3.fromRGB(225,173,255),Enum.PartType.Ball)
  elseif id=='Witchfire' then
   piece('Staff',Vector3.new(.26,4.5,.26),Vector3.new(0,2,0),Color3.fromRGB(86,54,102))
   piece('Spell Core',Vector3.new(.95,.95,.95),Vector3.new(0,4.5,0),weapon.color,Enum.PartType.Ball)
  elseif id=='Crossbow' then
   piece('Crossbow Oak Stock',Vector3.new(.62,.65,2.8),Vector3.new(0,.68,-.9),Color3.fromRGB(104,64,38))
   piece('Reinforced Bow Limbs',Vector3.new(3.8,.28,.45),Vector3.new(0,.79,-2.2),Color3.fromRGB(200,168,93))
   piece('String',Vector3.new(3.6,.06,.12),Vector3.new(0,.78,-1.1),Color3.fromRGB(226,224,203))
   piece('Bolt channel',Vector3.new(.2,.12,2.3),Vector3.new(0,1.1,-1.4),Color3.fromRGB(184,196,189))
  else
   local heavy=id=='Godslayer'
   local wide=id=='Blunderbuss'
   local length=heavy and 5.6 or wide and 2.2 or id=='Boomstick' and 3.4 or 3.0
   local dia=heavy and 1.25 or wide and 1.08 or .55
   piece('Machined Barrel',Vector3.new(length,dia,dia),Vector3.new(0,.7,-length*.44),weapon.color,Enum.PartType.Cylinder,CFrame.Angles(0,math.pi/2,0))
   piece('Iron Receiver',Vector3.new(heavy and 1.85 or .95,1,heavy and 2.65 or 1.7),Vector3.new(0,.72,-.6),Color3.fromRGB(61,58,65))
   piece('Magazine',Vector3.new(.62,1.2,.65),Vector3.new(0,-.13,-.5),Color3.fromRGB(38,40,45))
   piece('Barrel Shroud',Vector3.new(1.5,dia*1.35,dia*1.35),Vector3.new(0,.7,-length*.78),Color3.fromRGB(42,46,53),Enum.PartType.Cylinder,CFrame.Angles(0,math.pi/2,0))
   if id=='Rattler' then
    for sx=-1,1,2 do
     piece('Rattler Secondary Barrel',Vector3.new(2.7,.24,.24),Vector3.new(sx*.46,.71,-1.5),Color3.fromRGB(169,189,169),Enum.PartType.Cylinder,CFrame.Angles(0,math.pi/2,0))
    end
    piece('Rattler Ratchet Gear',Vector3.new(1.6,.3,1.2),Vector3.new(0,1.5,-.7),Color3.fromRGB(226,151,57))
   elseif id=='Blunderbuss' then
    piece('Blunderbuss Brass Flare',Vector3.new(.8,1.7,1.7),Vector3.new(0,.7,-2.05),Color3.fromRGB(235,179,78),Enum.PartType.Cylinder,CFrame.Angles(0,math.pi/2,0))
   elseif id=='Boomstick' then
    piece('Explosive Drum',Vector3.new(2.1,1.45,1.45),Vector3.new(0,.68,-1.4),Color3.fromRGB(185,121,57),Enum.PartType.Cylinder,CFrame.Angles(0,math.pi/2,0))
    for step=1,4 do
     piece('Grenade Chamber',Vector3.new(.42,.42,.42),Vector3.new((step-2.5)*.33,1.65,-1.4),Color3.fromRGB(245,149,68),Enum.PartType.Ball)
    end
   elseif heavy then
    piece('Godslayer Reactor',Vector3.new(2.25,2.25,2.25),Vector3.new(0,1.25,-1.6),weapon.color,Enum.PartType.Ball)
    piece('Gilded Crest',Vector3.new(2.6,.28,2.1),Vector3.new(0,1.35,-2.85),Color3.fromRGB(233,174,56))
    for i=1,4 do
     local offset=-.3-i*.9
     piece('Concentric reactor coil '..i,Vector3.new(.23,2.0,2.0),Vector3.new(0,.7,offset),Color3.fromRGB(242,186,72),Enum.PartType.Cylinder,CFrame.Angles(0,math.pi/2,0))
    end
    for side=-1,1,2 do
     piece('Arcane energy vane',Vector3.new(.3,1.2,4.3),Vector3.new(side*1.0,1.2,-2.1),Color3.fromRGB(82,227,151))
    end
   end
  end
  return t
 end
 for _,container in ipairs({p:FindFirstChild('Backpack'),p:FindFirstChild('StarterGear')}) do
  if container then
   local found=false
   for _,t in ipairs(container:GetChildren()) do
    if t:IsA('Tool') and t:GetAttribute('WeaponId')==id then found=true;break end
   end
   if not found then local tool=make();tool.Parent=container end
  end
 end
end
local function grantOwned(p)
 local d=profiles[p];if not d then return end
 for id in pairs(d.owned) do if C.Weapons[id] then giveTool(p,id)end end
end
local function getEnemyFromPart(part)
 local model=part
 while model and model~=world do
  if model:IsA('Model') and model:GetAttribute('OutlawEnemy') then
   return activeEnemies[model]
  end
  model=model.Parent
 end
 return nil
end
local function nearestPlayer(origin,radius)
 local best,bestDist=nil,radius
 for _,p in ipairs(Players:GetPlayers()) do
  if alivePlayer(p) then
   local pos=posOf(p)
   if pos and not inTown(pos) then
    local dist=(pos-origin).Magnitude
    if dist<bestDist then best,bestDist=p,dist end
   end
  end
 end
 return best,bestDist
end
local function damagePlayer(attacker,victim,damage)
 local h=alivePlayer(victim);if not h then return false end
 local dodge=dodgeState[victim]
 if dodge and clock()<dodge.invulnerableUntil then return false end
 if attacker and attacker:IsA('Player') then
  if attacker==victim or inTown(posOf(attacker)) or inTown(posOf(victim)) then return false end
  victim:SetAttribute('LastPvPAttacker',attacker.UserId)
  victim:SetAttribute('LastPvPTime',os.time())
 end
 h:TakeDamage(damage)
 return true
end
local function eyeOffsetEnemy(enemy) return enemy.pos+Vector3.new(0,enemy.scale*3.0,0)end
local function coinDrop(pos,amount,label)
 local orb=Instance.new('Part')
 orb.Name=label or 'Golden Loot';orb.Shape=Enum.PartType.Ball;orb.Anchored=true
 orb.Material=Enum.Material.Neon;orb.Color=Color3.fromRGB(255,194,56);orb.Size=Vector3.new(1.35,1.35,1.35)
 orb.Position=pos+Vector3.new(0,2.3,0);orb.CanCollide=false;orb.Parent=effectsFolder
 local light=Instance.new('PointLight');light.Color=orb.Color;light.Range=12;light.Brightness=2;light.Parent=orb
 local prompt=Instance.new('ProximityPrompt');prompt.ActionText='Take '..amount..' Gold';prompt.ObjectText='Scattered treasure';prompt.HoldDuration=.35;prompt.MaxActivationDistance=12;prompt.Parent=orb
 prompt.Triggered:Connect(function(p)
  local d=profiles[p];if not d or not orb.Parent then return end
  d.coins=d.coins+amount;notice(p,'+'..amount..' GOLD','GOLD');orb:Destroy();sync(p)
 end)
 Debris:AddItem(orb,75)
end
local function eggDrop(pos)
 local egg=Instance.new('Part');egg.Name='HOLLOW EGG';egg.Shape=Enum.PartType.Ball
 egg.Size=Vector3.new(1.7,2.2,1.7);egg.Anchored=true;egg.CanCollide=false
 egg.Material=Enum.Material.Slate;egg.Color=Color3.fromRGB(107,135,175)
 egg.Position=pos+Vector3.new(0,1.6,0);egg.Parent=effectsFolder
 local light=Instance.new('PointLight');light.Color=Color3.fromRGB(133,198,255);light.Range=13;light.Brightness=1.4;light.Parent=egg
 local pr=Instance.new('ProximityPrompt');pr.ObjectText='UNKNOWN CREATURE EGG';pr.ActionText='Collect Egg';pr.MaxActivationDistance=12;pr.HoldDuration=.75;pr.Parent=egg
 pr.Triggered:Connect(function(p)
  local d=profiles[p];if not d or not egg.Parent then return end
  table.insert(d.eggs,os.time()+C.EggSeconds);egg:Destroy()
  notice(p,'MYSTERIOUS EGG! BRING IT TO THE INCUBATOR.','QUEST');sync(p)
 end)
 Debris:AddItem(egg,120)
end
local function enemyDeath(enemy,killer)
 if not enemy.alive then return end
 enemy.alive=false;activeEnemies[enemy.model]=nil
 burst(enemy.pos,enemy.conf.color,enemy.scale*6,.48)
 sound(enemy.model,'rbxasset://sounds/impact_generic.mp3',.65,.75)
 if killer and profiles[killer] then
  local d=profiles[killer];d.kills=d.kills+1;d.coins=d.coins+enemy.conf.coins
  if enemy.kind=='Boss' then
   d.warden=d.warden+1;d.relics=d.relics+1;eventMessage(killer.DisplayName..' SHATTERED THE HOLLOW CROWN!')
   notice(killer,'CROWN SHARD RECOVERED! +1 RELIC','QUEST')
  elseif enemy.kind=='Wizard' and d.quests.witch==0 then
   d.quests.witch=1;notice(killer,'The witchfire over the marsh has weakened.','QUEST')
  end
  notice(killer,'+'..enemy.conf.coins..' GOLD  |  '..enemy.conf.display,'GOLD');sync(killer)
 end
 -- Meaningful co-op credit: helping fight a boss should not be worthless because
 -- your friend happened to land the final shot.
 for userId,total in pairs(enemy.contributors or {}) do
  local teammate=Players:GetPlayerByUserId(userId)
  if teammate and teammate~=killer and profiles[teammate] and total>=enemy.maxHP*.12 then
   local data=profiles[teammate]
   local assistCoins=math.floor(enemy.conf.coins*.48)
   data.coins=data.coins+assistCoins
   data.kills=data.kills+1
   if enemy.kind=='Boss' then
    data.warden=data.warden+1;data.relics=data.relics+1
    notice(teammate,'BOSS ASSIST: +1 CROWN SHARD AND '..assistCoins..' GOLD','SUCCESS')
   else notice(teammate,'COMBAT ASSIST! +'..assistCoins..' GOLD','GOLD')end
   sync(teammate)
  end
 end
 if enemy.kind=='Boss' then
  coinDrop(enemy.pos,300,'WARDEN VAULT')
  eggDrop(enemy.pos+Vector3.new(4,0,0))
  nextBossSpawn=clock()+230
 elseif random:NextNumber()<.12 then
  eggDrop(enemy.pos)
 elseif random:NextNumber()<.26 then
  coinDrop(enemy.pos,random:NextInteger(8,23))
 end
 task.delay(1.8,function()if enemy.model.Parent then enemy.model:Destroy()end end)
 if enemy.kind~='Boss' then
  task.delay(35+random:NextInteger(0,25),function()
   if not enemy.model.Parent then return end
   -- respawn is dispatched by the director on a schedule, independent of corpse cleanup.
  end)
 end
end
local function hurtEnemy(enemy,damage,killer,critical)
 if not enemy or not enemy.alive then return false end
 local attackerPos=killer and posOf(killer)
 if enemy.kind=='Knight' and attackerPos then
  local incoming=(attackerPos-enemy.pos)*Vector3.new(1,0,1)
  if incoming.Magnitude>.5 and enemy.model:GetPivot().LookVector:Dot(incoming.Unit)>.25 then
   damage=math.floor(damage*.52) -- iron shields resist frontal gunfire; circle behind them.
   burst(enemy.pos+Vector3.new(0,3,0),Color3.fromRGB(198,211,221),2.2,.15)
  end
 end
 enemy.staggerUntil=clock()+.16
 if killer and killer:IsA('Player') then
  local credited=math.min(enemy.hp,math.max(0,damage))
  enemy.contributors[killer.UserId]=(enemy.contributors[killer.UserId] or 0)+credited
 end
 enemy.hp=math.max(0,enemy.hp-damage)
 if enemy.healthBar then enemy.healthBar.Size=UDim2.fromScale(enemy.hp/enemy.maxHP,1) end
 if enemy.hp<=0 then enemyDeath(enemy,killer) else
  enemy.flashUntil=clock()+.14
  if killer then Effects:FireClient(killer,'HIT',damage,critical==true)end
 end
 return true
end
local function hostileArea(origin,radius,damage,owner)
 burst(origin,Color3.fromRGB(224,94,255),radius*2,.4)
 for model,enemy in pairs(activeEnemies) do
  if enemy.alive and (enemy.pos-origin).Magnitude<=radius+enemy.scale*2 then
   if owner then hurtEnemy(enemy,damage,owner,false)end
  end
 end
 for _,p in ipairs(Players:GetPlayers()) do
  local pos=posOf(p)
  if pos and (pos-origin).Magnitude<radius and (not owner or p~=owner) then
   damagePlayer(owner,p,damage)
  end
 end
end
local function damageInZone(point,radius,amount)
 for _,p in ipairs(Players:GetPlayers()) do
  local pos=posOf(p)
  if pos and (pos-point).Magnitude<radius then damagePlayer(nil,p,amount)end
 end
end
local function warningCircle(position,radius,delayTime,color)
 local ring=Instance.new('Part');ring.Name='DANGER — MOVE!';ring.Shape=Enum.PartType.Cylinder
 ring.Size=Vector3.new(.16,radius*2,radius*2)
 ring.CFrame=CFrame.new(position.X,position.Y-.42,position.Z)*CFrame.Angles(0,0,math.pi/2)
 ring.Anchored=true;ring.CanCollide=false;ring.CanTouch=false;ring.CanQuery=false
 ring.Material=Enum.Material.Neon;ring.Color=color or Color3.fromRGB(255,76,81)
 ring.Transparency=.55;ring.Parent=effectsFolder
 Tween:Create(ring,TweenInfo.new(delayTime),{Transparency=.18}):Play()
 Debris:AddItem(ring,delayTime+.08)
end
local function spawnHostileProjectile(from,target,color,damage,speed,radius)
 if not target or not alivePlayer(target) then return end
 local aim=posOf(target)+Vector3.new(0,1.7,0)
 local direction=aim-from;if direction.Magnitude<.1 then return end
 direction=direction.Unit
 local orb=Instance.new('Part');orb.Name='Hostile Spell';orb.Shape=Enum.PartType.Ball
 orb.Size=Vector3.new(1.7,1.7,1.7);orb.Anchored=true;orb.CanCollide=false;orb.CanQuery=false
 orb.Material=Enum.Material.Neon;orb.Color=color;orb.Position=from;orb.Parent=effectsFolder
 local glow=Instance.new('PointLight');glow.Color=color;glow.Range=14;glow.Brightness=2;glow.Parent=orb
 task.spawn(function()
  local pos=from;local maxTime=3.4;local start=clock()
  while orb.Parent and clock()-start<maxTime do
   local dt=Run.Heartbeat:Wait();local step=direction*speed*math.min(dt,.12)
   local castParams=RaycastParams.new();castParams.FilterType=Enum.RaycastFilterType.Exclude
   castParams.FilterDescendantsInstances={orb,enemiesFolder,effectsFolder}
   local hit=world:Raycast(pos,step,castParams)
   pos=hit and hit.Position or pos+step;orb.Position=pos
   local playerHit=false
   for _,p in ipairs(Players:GetPlayers()) do
    local pp=posOf(p)
    if pp and (pp-pos).Magnitude<2.5 then
     damagePlayer(nil,p,damage);playerHit=true;break
    end
   end
   if hit or playerHit then
    if radius>0 then damageInZone(pos,radius,math.floor(damage*.6))end
    burst(pos,color,math.max(5,radius*2),.3);break
   end
  end
  orb:Destroy()
 end)
end
local function makeEnemyVisual(kind,conf,position)
 if C.UseRiggedEnemies then
  local ok,model,scale,bar,offset=pcall(Rigs.make,kind,conf,position)
  if ok and model then
   model.Parent=enemiesFolder
   return model,scale,bar,offset
  elseif not ok then warn('[Outlaw Valley] R15 rig unavailable, using fallback:',model)end
 end
 enemySerial=enemySerial+1
 local model=Instance.new('Model');model.Name=conf.display..' #'..enemySerial
 model:SetAttribute('OutlawEnemy',true)
 model:SetAttribute('EnemyType',kind)
 local scale=kind=='Boss' and 3.5 or (kind=='Brute' and 1.85 or kind=='Knight' and 1.25 or 1)
 local root=Instance.new('Part');root.Name='Root';root.Anchored=true;root.CanCollide=false;root.CanQuery=false
 root.Transparency=1;root.Size=Vector3.new(1,1,1);root.Position=position;root.Parent=model;model.PrimaryPart=root
 local function bodyPart(name,size,offset,color,material,shape)
  local x=Instance.new('Part');x.Name=name;x.Size=size*scale;x.Anchored=true;x.CanCollide=false;x.CanTouch=false
  x.Material=material or Enum.Material.SmoothPlastic;x.Color=color;x.Shape=shape or Enum.PartType.Block
  x.CFrame=CFrame.new(position+offset*scale);x.Parent=model;return x
 end
 local coat=kind=='Wizard' and Color3.fromRGB(73,46,116) or kind=='Knight' and Color3.fromRGB(73,80,93) or kind=='Boss' and Color3.fromRGB(48,35,61) or kind=='Bandit' and Color3.fromRGB(86,59,51) or Color3.fromRGB(83,80,59)
 bodyPart('ChestPlate',Vector3.new(2.25,2.6,1.2),Vector3.new(0,2.35,0),coat)
 bodyPart('HeadHit',Vector3.new(1.65,1.65,1.55),Vector3.new(0,4.23,0),conf.color,nil,Enum.PartType.Ball)
 bodyPart('LeftArm',Vector3.new(.75,2.2,.75),Vector3.new(-1.53,2.35,0),conf.color)
 bodyPart('RightArm',Vector3.new(.75,2.2,.75),Vector3.new(1.53,2.35,0),conf.color)
 bodyPart('LeftLeg',Vector3.new(.78,1.6,.8),Vector3.new(-.62,.55,0),coat)
 bodyPart('RightLeg',Vector3.new(.78,1.6,.8),Vector3.new(.62,.55,0),coat)
 local eyeColor=kind=='Boss' and Color3.fromRGB(255,40,65) or Color3.fromRGB(255,241,167)
 bodyPart('LeftEye',Vector3.new(.31,.36,.19),Vector3.new(-.43,4.38,-.76),eyeColor,Enum.Material.Neon,Enum.PartType.Ball)
 bodyPart('RightEye',Vector3.new(.31,.36,.19),Vector3.new(.43,4.38,-.76),eyeColor,Enum.Material.Neon,Enum.PartType.Ball)
 if kind=='Goblin' or kind=='Archer' then
  bodyPart('LeftEar',Vector3.new(.95,.43,.4),Vector3.new(-1.17,4.32,0),conf.color)
  bodyPart('RightEar',Vector3.new(.95,.43,.4),Vector3.new(1.17,4.32,0),conf.color)
 end
 if kind=='Wizard' or kind=='Boss' then
  bodyPart('Arcane Hood',Vector3.new(2.2,.8,1.9),Vector3.new(0,5.03,0),coat)
  bodyPart('Staff',Vector3.new(.28,4,.28),Vector3.new(2.1,3.0,0),Color3.fromRGB(122,84,155),Enum.Material.Wood)
  bodyPart('Staff Crystal',Vector3.new(.94,.94,.94),Vector3.new(2.1,5.35,0),Color3.fromRGB(184,99,255),Enum.Material.Neon,Enum.PartType.Ball)
 elseif kind=='Knight' or kind=='Brute' then
  bodyPart('Iron Helmet',Vector3.new(1.9,.62,1.9),Vector3.new(0,5.0,0),Color3.fromRGB(98,107,116),Enum.Material.Metal)
  bodyPart('War Axe',Vector3.new(.38,3.8,.38),Vector3.new(2.1,2.8,0),Color3.fromRGB(154,145,112),Enum.Material.Metal)
 elseif kind=='Archer' then
  bodyPart('Bow',Vector3.new(.22,3,.3),Vector3.new(1.9,2.9,-.2),Color3.fromRGB(120,77,44),Enum.Material.Wood)
 elseif kind=='Wisp' then
  bodyPart('Spectral Flame',Vector3.new(1.2,1.6,1.2),Vector3.new(0,5.1,0),Color3.fromRGB(75,255,215),Enum.Material.Neon,Enum.PartType.Ball)
 else
  bodyPart('Rusty Cleaver',Vector3.new(.4,2.1,.35),Vector3.new(1.7,2.2,-.7),Color3.fromRGB(155,151,139),Enum.Material.Metal)
 end
 if kind=='Boss' then
  bodyPart('Broken Crown',Vector3.new(2.5,.36,2.1),Vector3.new(0,5.48,0),Color3.fromRGB(247,182,56),Enum.Material.Metal)
 end
 local bb=Instance.new('BillboardGui');bb.Name='EnemyHUD';bb.Adornee=model:FindFirstChild('HeadHit')
 bb.Size=UDim2.fromOffset(kind=='Boss' and 260 or 150,46);bb.StudsOffset=Vector3.new(0,2.9,0)
 bb.AlwaysOnTop=true;bb.MaxDistance=150;bb.Parent=model
 local title=Instance.new('TextLabel');title.Size=UDim2.fromScale(1,.45);title.BackgroundTransparency=1
 title.Font=Enum.Font.GothamBold;title.TextSize=13;title.TextColor3=Color3.new(1,1,1)
 title.TextStrokeTransparency=.35;title.Text=conf.display;title.Parent=bb
 local bg=Instance.new('Frame');bg.Position=UDim2.fromScale(.07,.54);bg.Size=UDim2.fromScale(.86,.28)
 bg.BackgroundColor3=Color3.fromRGB(28,25,30);bg.BorderSizePixel=0;bg.Parent=bb
 local hpbar=Instance.new('Frame');hpbar.Size=UDim2.fromScale(1,1)
 hpbar.BackgroundColor3=kind=='Boss' and Color3.fromRGB(236,91,144) or Color3.fromRGB(112,235,127)
 hpbar.BorderSizePixel=0;hpbar.Parent=bg
 model.Parent=enemiesFolder
 return model,scale,hpbar
end
local function spawnEnemy(kind,position,homeTag)
 local conf=C.Enemies[kind];if not conf then return end
 local model,scale,hpbar,offset=makeEnemyVisual(kind,conf,position)
 local enemy={kind=kind,conf=conf,model=model,scale=scale,alive=true,hp=conf.health,maxHP=conf.health,
  pos=position,home=position,tag=homeTag,healthBar=hpbar,rigOffset=offset,nextAttack=clock()+2.0,
  phase=1,strafe=random:NextNumber()<.5 and -1 or 1,flashUntil=0,walk=0,contributors={}}
 activeEnemies[model]=enemy
 return enemy
end
local function npcAttack(e, target, distance)
 if not e.alive or not target or not alivePlayer(target) or clock()<e.nextAttack then return end
 e.nextAttack=clock()+e.conf.cooldown
 local attack=e.conf.attack
 local start=e.pos;local aim=posOf(target)
 if not aim then return end
 if attack=='boss' and e.phase>=2 and random:NextInteger(1,3)==1 then
  -- The Crownless Warden's howl pushes defenders away from the inner arena.
  eventMessage('THE WARDEN: KNEEL BEFORE THE EMPTY THRONE!')
  warningCircle(e.pos,25,1.2,Color3.fromRGB(210,75,252))
  local point=e.pos
  task.delay(1.2,function()
   if not e.alive then return end
   burst(point+Vector3.new(0,2,0),Color3.fromRGB(225,80,248),45,.65)
   for _,victim in ipairs(Players:GetPlayers()) do
    local pp=posOf(victim)
    if pp and (pp-point).Magnitude<24 then
     if damagePlayer(nil,victim,math.floor(e.conf.damage*.85)) then
      local root=victim.Character and victim.Character:FindFirstChild('HumanoidRootPart')
      if root then
       local delta=(pp-point)*Vector3.new(1,0,1)
       if delta.Magnitude>.2 then root.AssemblyLinearVelocity=delta.Unit*55+Vector3.new(0,28,0)end
      end
     end
    end
   end
  end)
 elseif attack=='boss' and e.phase==3 and random:NextInteger(1,2)==1 then
  -- Last stand: three separate warning zones players must navigate.
  eventMessage('WARDEN: THE CROWN WILL HAVE ITS BLOOD!')
  for i=1,3 do
   local angle=i*math.pi*2/3+clock()
   local point=aim+Vector3.new(math.cos(angle)*9,0,math.sin(angle)*9)
   warningCircle(point,8,e.conf.windup+.25*i,Color3.fromRGB(252,94,119))
   task.delay(e.conf.windup+.25*i,function()
    if e.alive then
     burst(point+Vector3.new(0,2,0),Color3.fromRGB(255,113,117),15,.43)
     damageInZone(point,8,math.floor(e.conf.damage*.55))
    end
   end)
  end
 elseif attack=='slash' or attack=='lunge' then
  sound(e.model,'rbxassetid://12222200',.25,random:NextNumber(.75,1.2))
  warningCircle(aim,5,.48,Color3.fromRGB(255,92,73))
  task.delay(e.conf.windup,function()
   if e.alive and attack=='lunge' then
    local finish=posOf(target)
    if finish then
     local dir=(finish-e.pos)*Vector3.new(1,0,1)
     if dir.Magnitude>.1 then e.pos=e.pos+dir.Unit*math.min(6,dir.Magnitude)end
    end
   end
   if e.alive and (posOf(target) and (posOf(target)-e.pos).Magnitude<=e.conf.range+5) then
    damagePlayer(nil,target,e.conf.damage)
    burst(e.pos+Vector3.new(0,3,0),Color3.fromRGB(250,106,88),4,.18)
   end
  end)
 elseif attack=='slam' then
  sound(e.model,'rbxasset://sounds/impact_generic.mp3',.5,.6)
  warningCircle(start,13,e.conf.windup)
  task.delay(e.conf.windup,function()
   if e.alive then burst(e.pos,Color3.fromRGB(243,140,92),23,.4);damageInZone(e.pos,12,e.conf.damage)end
  end)
 elseif attack=='meteor' or attack=='boss' then
  sound(e.model,'rbxasset://sounds/impact_generic.mp3',.34,1.3)
  local point=aim + Vector3.new(random:NextInteger(-5,5),0,random:NextInteger(-5,5))
  local radius=attack=='boss' and 15 or 10
  warningCircle(point,radius,e.conf.windup,Color3.fromRGB(191,78,241))
  task.delay(e.conf.windup,function()
   if e.alive then
    burst(point+Vector3.new(0,2,0),Color3.fromRGB(170,71,244),radius*2,.52)
    damageInZone(point,radius,e.conf.damage)
   end
  end)
  if attack=='boss' then
   if e.hp/e.maxHP<.6 and e.phase==1 then
    e.phase=2;eventMessage('THE WARDEN HAS AWAKENED THE HOLLOW GUARD!')
    for i=1,3 do spawnEnemy('Knight',e.pos+Vector3.new(random:NextInteger(-20,20),0,random:NextInteger(-20,20)),'summoned')end
   end
   if e.hp/e.maxHP<.25 and e.phase==2 then
    e.phase=3;eventMessage('THE WARDEN IS ENRAGED — THE GROUND IS CURSED!')
    e.conf=table.clone(e.conf);e.conf.cooldown=1.65;e.conf.speed=18
   end
  end
 else
  local col=attack=='arrow' and Color3.fromRGB(244,214,132) or attack=='orb' and Color3.fromRGB(86,255,205) or Color3.fromRGB(184,95,244)
  task.delay(e.conf.windup,function()
   if e.alive then sound(e.model,'rbxasset://sounds/impact_generic.mp3',.3,1.5);spawnHostileProjectile(eyeOffsetEnemy(e),target,col,e.conf.damage,attack=='arrow' and 100 or 57,0)end
  end)
 end
end
local function moveAI(e,dt)
 if not e.alive or not e.model.Parent then return end
 local target,dist=nearestPlayer(e.pos,e.kind=='Boss' and 145 or 110)
 local wanted=e.home
 local immobilized=clock()<(e.staggerUntil or 0)
 if target then
  local tp=posOf(target)
  if tp then
   if dist>e.conf.range*.7 then
    local afraid=(e.kind=='Goblin' and e.hp/e.maxHP<.23)
    local toward=(tp-e.pos)*Vector3.new(1,0,1)*(afraid and -1 or 1)
    if toward.Magnitude>1 then
     wanted=e.pos+toward.Unit*math.min(e.conf.speed*dt*(afraid and 1.25 or 1),toward.Magnitude)
     if not afraid and e.conf.range<15 and dist>e.conf.range*2 then
      local sideways=Vector3.new(-toward.Z,0,toward.X)
      wanted=wanted+sideways.Unit*dt*math.sin(clock()*1.1+e.phase)*e.conf.speed*.27
     end
    end
   elseif e.conf.range>20 then
    local away=(e.pos-tp)*Vector3.new(1,0,1)
    local sideways=Vector3.new(-away.Z,0,away.X)
    if sideways.Magnitude>.1 then wanted=e.pos+sideways.Unit*e.conf.speed*.3*dt*e.strafe end
   end
   if dist<=e.conf.range+8 then npcAttack(e,target,dist) end
  end
 else
  if (e.pos-e.home).Magnitude>3 then
   local dir=e.home-e.pos;wanted=e.pos+dir.Unit*math.min(e.conf.speed*.45*dt,dir.Magnitude)
  end
 end
 -- Wizards blink when cornered, giving ranged fights a positional challenge.
 if e.kind=='Wizard' and target and dist<27 and clock()>(e.nextBlink or 0) then
  e.nextBlink=clock()+13
  local away=Vector3.new(e.pos.X-posOf(target).X,0,e.pos.Z-posOf(target).Z)
  if away.Magnitude>1 then
   local sideways=Vector3.new(-away.Z,0,away.X).Unit*e.strafe
   local destination=e.pos+away.Unit*10+sideways*12
   burst(e.pos+Vector3.new(0,3,0),e.conf.color,7,.22)
   e.pos=Vector3.new(destination.X,e.home.Y,destination.Z)
   burst(e.pos+Vector3.new(0,3,0),e.conf.color,7,.22)
   wanted=e.pos
  end
 end
 if immobilized then wanted=e.pos end
 if (wanted-e.pos).Magnitude>.005 then
  -- Local obstacle feeler: tries a flank instead of clipping directly through walls.
  -- Thin foliage and other enemies are ignored; this is NOT full PathfindingService.
  local travel=Vector3.new(wanted.X-e.pos.X,0,wanted.Z-e.pos.Z)
  if travel.Magnitude>.02 then
   local collision=RaycastParams.new()
   collision.FilterType=Enum.RaycastFilterType.Exclude
   collision.FilterDescendantsInstances={enemiesFolder,effectsFolder}
   local direction=travel.Unit
   local blocked=workspace:Raycast(e.pos+Vector3.new(0,2.5,0),direction*math.min(6,travel.Magnitude+3),collision)
   if blocked and blocked.Instance.CanCollide and math.abs(blocked.Normal.Y)<.6 then
    local sideways=Vector3.new(-direction.Z,0,direction.X)*e.strafe
    local left=workspace:Raycast(e.pos+Vector3.new(0,2.5,0),sideways*5,collision)
    if left and left.Instance.CanCollide then sideways=-sideways end
    wanted=e.pos+sideways*math.min(travel.Magnitude,dt*e.conf.speed)
   end
  end
  e.pos=Vector3.new(wanted.X,e.home.Y,wanted.Z)
  e.walk=e.walk+dt*(e.conf.speed/3)
  local facing=target and posOf(target) or e.home+Vector3.new(0,0,-2)
  local lift=e.rigOffset or 0
  local cf=CFrame.lookAt(e.pos+Vector3.new(0,lift+math.sin(e.walk)*.09,0),Vector3.new(facing.X,e.pos.Y+lift,facing.Z))
  e.model:PivotTo(cf)
  local stride=math.sin(e.walk*2.9)*.46
  if not e.rigOffset then for _,name in ipairs({'LeftLeg','RightLeg','LeftArm','RightArm'}) do
   local limb=e.model:FindFirstChild(name)
   if limb then
    local isLeg=string.find(name,'Leg')~=nil
    local side=string.find(name,'Left') and -1 or 1
    local delta=(isLeg and stride or -stride*.55)*side
    local x=side*(isLeg and .62 or 1.53)
    local y=isLeg and .55 or 2.35
    limb.CFrame=cf*CFrame.new(x*e.scale,y*e.scale,0)*CFrame.Angles(delta,0,0)
   end
  end end
 end
 local head=e.model:FindFirstChild('HeadHit') or e.model:FindFirstChild('Head')
 if head then head.Color=clock()<e.flashUntil and Color3.new(1,1,1) or e.conf.color end
end
-- The camp's red-banded powder barrels are world objects, not decorations.
-- Players can deliberately detonate them to clear enemies or hurt themselves.
local function explodeBarrel(barrel,killer)
 if not barrel or barrel.Name~='Supply barrel' or barrel:GetAttribute('PowderSpent') then return false end
 barrel:SetAttribute('PowderSpent',true)
 local pos=barrel.Position
 barrel:Destroy()
 burst(pos,Color3.fromRGB(255,124,36),26,.46)
 for _,e in pairs(activeEnemies) do
  if e.alive and (e.pos-pos).Magnitude<=17 then hurtEnemy(e,105,killer,false) end
 end
 for _,other in ipairs(Players:GetPlayers()) do
  local where=posOf(other)
  if where and (where-pos).Magnitude<=14 then damagePlayer(nil,other,38)end
 end
 return true
end
local function fireWeapon(p,id,targetPoint)
 local d=profiles[p];if not d then return end
 local h=alivePlayer(p);if not h then return end
 if type(id)~='string' or typeof(targetPoint)~='Vector3' then return end
 if targetPoint.X~=targetPoint.X or targetPoint.Y~=targetPoint.Y or targetPoint.Z~=targetPoint.Z then return end
 local weapon=C.Weapons[id];if not weapon or not d.owned[id] then return end
 local equipped=p.Character and p.Character:FindFirstChildOfClass('Tool')
 if not equipped or equipped:GetAttribute('WeaponId')~=id then return end
 local now=clock();if now<(d.fireTimes[id] or 0)+weapon.cooldown*.91 then return end
 if now<(d.reloadTimes[id] or 0) then return end
 if weapon.mag>0 then
  if (d.heldAmmo[id] or 0)<=0 then notice(p,'OUT OF AMMO — PRESS R','WARN');return end
  d.heldAmmo[id]=d.heldAmmo[id]-1
 end
 d.fireTimes[id]=now
 local origin=posOf(p)+Vector3.new(0,1.6,0)
 local delta=targetPoint-origin
 if delta.Magnitude<.1 then return end
 local dir=delta.Unit
 local aimDist=math.min(weapon.range,delta.Magnitude)
 local barrel=origin+dir*2
 if weapon.category=='melee' then
  local best,dist=nil,weapon.range
  for _,e in pairs(activeEnemies) do
   local dd=(e.pos-origin).Magnitude
   if e.alive and dd<dist and dir:Dot((e.pos-origin).Unit)>.3 then best=e;dist=dd end
  end
  if best then hurtEnemy(best,weapon.damage,p,false)end
  for _,victim in ipairs(Players:GetPlayers()) do
   local pp=posOf(victim)
   if victim~=p and pp and (pp-origin).Magnitude<=weapon.range and dir:Dot((pp-origin).Unit)>.55 then
    damagePlayer(p,victim,weapon.damage)
   end
  end
  Effects:FireAllClients('SWING',origin,dir)
 else
  local shots=weapon.pellets or 1
  for shot=1,shots do
   local shotDir=dir
   if shots>1 then shotDir=(dir+Vector3.new(random:NextNumber(-weapon.spread,weapon.spread),random:NextNumber(-weapon.spread,weapon.spread),random:NextNumber(-weapon.spread,weapon.spread))).Unit end
   local params=RaycastParams.new()
   params.FilterType=Enum.RaycastFilterType.Exclude
   params.FilterDescendantsInstances={p.Character,effectsFolder}
   params.IgnoreWater=true
   local hit=world:Raycast(origin,shotDir*weapon.range,params)
   local impact=hit and hit.Position or (origin+shotDir*weapon.range)
   tracer(barrel,impact,weapon.color,id=='Godslayer' and 3.4 or .18,id=='Godslayer' and .56 or .12)
   if hit then
    if explodeBarrel(hit.Instance,p) then
     Effects:FireAllClients('EXPLOSION',impact,18)
    end
    local enemy=getEnemyFromPart(hit.Instance)
    if enemy then
     local head=hit.Instance.Name=='HeadHit' or hit.Instance.Name=='Head'
     hurtEnemy(enemy,weapon.damage*(head and 1.3 or 1),p,head)
    else
     local victim=Players:GetPlayerFromCharacter(hit.Instance:FindFirstAncestorOfClass('Model'))
     if victim then damagePlayer(p,victim,weapon.damage)end
    end
    if weapon.blast>0 then hostileArea(impact,weapon.blast,weapon.damage,p)
    else burst(impact,weapon.color,2.8,.17)end
   elseif weapon.blast>0 then hostileArea(impact,weapon.blast,weapon.damage,p)end
  end
  Effects:FireAllClients('FIRE',p.UserId,id,barrel,weapon.color)
 end
 State:FireClient(p,{ammoOnly=id,loaded=d.heldAmmo[id],reserve=d.ammo[id]})
end
local function reload(p,id)
 local d=profiles[p];if not d then return end
 local w=C.Weapons[id];if not w or not d.owned[id] or w.mag<=0 then return end
 local t=p.Character and p.Character:FindFirstChildOfClass('Tool')
 if not t or t:GetAttribute('WeaponId')~=id then return end
 if d.heldAmmo[id]>=w.mag or d.ammo[id]<=0 or clock()<(d.reloadTimes[id] or 0) then return end
 d.reloadTimes[id]=clock()+w.reload
 notice(p,'RELOADING '..w.label..'...','RELOAD')
 task.delay(w.reload,function()
  if not profiles[p] or d~=profiles[p] then return end
  local need=w.mag-d.heldAmmo[id];local load=math.min(need,d.ammo[id])
  d.heldAmmo[id]=d.heldAmmo[id]+load;d.ammo[id]=d.ammo[id]-load
  State:FireClient(p,{ammoOnly=id,loaded=d.heldAmmo[id],reserve=d.ammo[id]})
 end)
end
local function purchase(p,id)
 local d=profiles[p];if not d then return end
 local pos=posOf(p)
 if not pos or (pos-C.TownCenter).Magnitude>95 then notice(p,'VISIT A MERCHANT TO BUY EQUIPMENT','WARN');return end
 if id=='SUPPLIES' then
  if d.coins<70 then notice(p,'NEED '..(70-d.coins)..' MORE GOLD','WARN');return end
  if Rules.refillCost(d.owned,C.Weapons,d.ammo)==0 then notice(p,'AMMUNITION RESERVES ARE FULL','WARN');return end
  d.coins=d.coins-70
  for key,own in pairs(d.owned) do
   local weapon=C.Weapons[key]
   if own and weapon and weapon.price>=0 and weapon.mag>0 then d.ammo[key]=weapon.reserve end
  end
  notice(p,'EVERY OWNED WEAPON RELOADED AT THE SUPPLY DEPOT','SUCCESS');sync(p);return
 end
 if id=='MEDKIT' then
  local hum=alivePlayer(p)
  if not hum or hum.Health>=hum.MaxHealth then notice(p,'HEALTH ALREADY FULL','WARN');return end
  if d.coins<55 then notice(p,'NEED '..(55-d.coins)..' MORE GOLD','WARN');return end
  d.coins=d.coins-55;hum.Health=math.min(hum.MaxHealth,hum.Health+90)
  notice(p,'PATCHED UP! +90 HP','SUCCESS');sync(p);return
 end
 local ok,why,cost=Rules.purchase(id,d.coins,d.owned,C.Weapons)
 if not ok then notice(p,why,'WARN');return end
 d.coins=d.coins-cost;d.owned[id]=true;giveTool(p,id)
 notice(p,C.Weapons[id].label..' PURCHASED!','SUCCESS');sync(p)
end
local function deposit(p,amount)
 local d=profiles[p];if not d then return end
 local pos=posOf(p)
 if not pos or not inTown(pos) then notice(p,'BANKING IS ONLY AVAILABLE IN TOWN','WARN');return end
 if d.coins<=0 then notice(p,'NO GOLD TO BANK','WARN');return end
 if amount=='ALL' then amount=d.coins else amount=math.floor(tonumber(amount) or 0)end
 if amount<=0 or amount>d.coins then notice(p,'INVALID DEPOSIT','WARN');return end
 d.bank=d.bank+amount;d.coins=d.coins-amount
 notice(p,'BANKED '..amount..' GOLD','SUCCESS');sync(p)
end
local function withdraw(p,amount)
 local d=profiles[p];if not d then return end
 local pos=posOf(p)
 if not pos or not inTown(pos) then return end
 if amount=='ALL' then amount=d.bank else amount=math.floor(tonumber(amount) or 0)end
 if amount<=0 or amount>d.bank then notice(p,'BANK WITHDRAWAL INVALID','WARN');return end
 d.bank=d.bank-amount;d.coins=d.coins+amount
 sync(p)
end
local pets={}
local function summonPet(p)
 if pets[p] and pets[p].model.Parent then return end
 local d=profiles[p];if not d or d.hatched<1 then return end
 local folder=world:FindFirstChild('LivingCompanions')
 if not folder then folder=Instance.new('Folder');folder.Name='LivingCompanions';folder.Parent=world end
 local m=Instance.new('Model');m.Name=p.DisplayName..' — Hollow Fox'
 local function piece(name,size,color,offset,shape)
  local b=Instance.new('Part');b.Name=name;b.Anchored=true;b.CanCollide=false;b.CanTouch=false;b.CanQuery=false
  b.Shape=shape or Enum.PartType.Block;b.Size=size;b.Material=Enum.Material.SmoothPlastic;b.Color=color
  b.Position=Vector3.new(0,1000,0)+offset;b.Parent=m
  return b
 end
 local body=piece('Spirit Body',Vector3.new(2,1.45,3.1),Color3.fromRGB(116,174,216),Vector3.zero,Enum.PartType.Ball)
 piece('Spirit Head',Vector3.new(1.8,1.8,1.75),Color3.fromRGB(141,195,237),Vector3.new(0,.7,-1.45),Enum.PartType.Ball)
 piece('Floating Tail',Vector3.new(.85,.85,2.7),Color3.fromRGB(93,151,218),Vector3.new(0,.5,2.1),Enum.PartType.Ball)
 piece('Left Eye',Vector3.new(.29,.32,.3),Color3.fromRGB(17,36,61),Vector3.new(-.43,.9,-2.22),Enum.PartType.Ball)
 piece('Right Eye',Vector3.new(.29,.32,.3),Color3.fromRGB(17,36,61),Vector3.new(.43,.9,-2.22),Enum.PartType.Ball)
 m.PrimaryPart=body;m.Parent=folder
 pets[p]={model=m,lastAttack=0,phase=random:NextNumber(0,6)}
end
local function updatePets(dt)
 for p,pet in pairs(pets) do
  local pos=posOf(p)
  if not pet.model.Parent then
   pets[p]=nil
  elseif pos then
   local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
   if root then
    local offset=root.CFrame.RightVector*3-root.CFrame.LookVector*3.5
    local spot=pos+offset+Vector3.new(0,2+math.sin(clock()*2+pet.phase)*.45,0)
    local current=pet.model:GetPivot().Position
    pet.model:PivotTo(CFrame.lookAt(current:Lerp(spot,math.clamp(dt*5,0,1)),pos))
   end
   if clock()-pet.lastAttack>2.8 then
    local closest,distance=nil,17
    for _,enemy in pairs(activeEnemies) do
     if enemy.alive then
      local dd=(enemy.pos-pos).Magnitude
      if dd<distance then closest,distance=enemy,dd end
     end
    end
    if closest then
     pet.lastAttack=clock()
     tracer(pos+Vector3.new(3,2,0),closest.pos+Vector3.new(0,3,0),Color3.fromRGB(104,206,255),.35,.2)
     hurtEnemy(closest,12+math.min(35,(profiles[p].hatched or 1)*6),p,false)
    end
   end
  end
 end
end
local function hatch(p)
 local d=profiles[p];if not d then return end
 local pos=posOf(p)
 if not pos or (pos-C.TownCenter).Magnitude>95 then notice(p,'FIND THE CREATURE NURSERY IN TOWN','WARN');return end
 if #d.eggs==0 then notice(p,'YOU HAVE NO EGGS','WARN');return end
 local readyIndex,waitTime=Rules.readyEgg(d.eggs,os.time())
 if not readyIndex then
  notice(p,'EGG INCUBATING: '..waitTime..' SECONDS','QUEST');return
 end
 table.remove(d.eggs,readyIndex);d.hatched=d.hatched+1
 notice(p,'A HOLLOW FOX HATCHED! +1 COMPANION','SUCCESS')
 p:SetAttribute('HollowFoxes',d.hatched);summonPet(p);sync(p)
end
-- Signal trials are real timed defense encounters, not instant-click rewards.
local beaconTrials={}
local function finishTrial(beacon,won)
 local trial=beaconTrials[beacon];if not trial then return end
 beaconTrials[beacon]=nil
 for p in pairs(trial.participants) do
  local d=profiles[p]
  if d then
   d.beaconTrial=nil
   if won and not d.quests[trial.key] then
    d.quests[trial.key]=true
    d.coins=d.coins+210
    local count=0
    for key,done in pairs(d.quests) do if string.find(key,'Beacon_')==1 and done then count=count+1 end end
    d.quests.beacons=count
    notice(p,'SIGNAL SURVIVED! +210 GOLD  |  '..count..'/3 BEACONS RESTORED','SUCCESS')
    if count==3 then d.relics=d.relics+1;notice(p,'THE THREE FIRES ARE LIT. THE CROWN SHARD IS YOURS.','SUCCESS') end
   elseif not won then
    notice(p,'THE SIGNAL WENT DARK. RETURN WHEN YOU ARE READY.','WARN')
   end
   sync(p)
  end
 end
 local flame=beacon:FindFirstChild('Restored Fire')
 if flame then flame:Destroy() end
 if won then
  local glow=Instance.new('Part');glow.Name='Signal ignited';glow.Shape=Enum.PartType.Ball
  glow.Color=Color3.fromRGB(252,180,75);glow.Material=Enum.Material.Neon
  glow.Anchored=true;glow.CanCollide=false;glow.CanQuery=false;glow.CanTouch=false
  glow.Size=Vector3.new(3,3,3);glow.Position=beacon.Position+Vector3.new(0,5,0)
  glow.Parent=effectsFolder;Debris:AddItem(glow,22)
  burst(glow.Position,Color3.fromRGB(255,212,97),18,.65)
 end
end
local function trialEnemiesRemain(tag)
 local n=0
 for _,enemy in pairs(activeEnemies) do if enemy.alive and enemy.tag==tag then n=n+1 end end
 return n
end
local function activateBeacon(p,beacon)
 local d=profiles[p];if not d or not beacon then return end
 local key='Beacon_'..beacon.Name
 if d.quests[key] then notice(p,'YOU HAVE ALREADY SAVED THIS SIGNAL','QUEST');return end
 if d.beaconTrial then notice(p,'FINISH YOUR CURRENT DEFENSE FIRST','WARN');return end
 local previous=beaconTrials[beacon]
 if previous then
  previous.participants[p]=true
  d.beaconTrial=key
  notice(p,'YOU HAVE JOINED THE SIGNAL DEFENSE. HOLD THIS GROUND!','WORLD')
  return
 end
 local position=beacon.Position+Vector3.new(0,0,0)
 local trial={participants={[p]=true},key=key,start=clock(),tag='beacon_'..beacon.Name}
 beaconTrials[beacon]=trial;d.beaconTrial=key
 notice(p,'THE BEACON HAS WOKEN SOMETHING. DO NOT LEAVE IT UNDEFENDED!','WORLD')
 eventMessage(p.DisplayName..' LIT AN ANCIENT SIGNAL. THE VALLEY IS ANSWERING...')
 local fire=Instance.new('Part');fire.Name='Restored Fire';fire.Shape=Enum.PartType.Ball
 fire.Size=Vector3.new(3,3,3);fire.Anchored=true;fire.CanCollide=false;fire.CanQuery=false
 fire.CanTouch=false;fire.Color=Color3.fromRGB(255,156,48);fire.Material=Enum.Material.Neon
 fire.Position=position+Vector3.new(0,5,0);fire.Parent=beacon
 local shine=Instance.new('PointLight');shine.Color=fire.Color;shine.Brightness=3;shine.Range=35;shine.Parent=fire
 task.spawn(function()
  -- Three escalations, each must be defeated. Time is used for tension, not idle waiting.
  local types=beacon.Name=='SignalBeacon3' and {'Knight','Knight','Brute'} or
   beacon.Name=='SignalBeacon1' and {'Goblin','Bandit','Archer'} or {'Goblin','Archer','Wizard'}
  local elapsed=0
  for wave=1,3 do
   if beaconTrials[beacon]~=trial then return end
   local waveCount=wave==1 and 3 or wave==2 and 4 or 5
   for i=1,waveCount do
    local angle=(i/waveCount)*math.pi*2+wave
    local distance=29+(i%2)*12
    local spawn=position+Vector3.new(math.cos(angle)*distance,0,math.sin(angle)*distance)
    local e=spawnEnemy(types[wave],Vector3.new(spawn.X,beacon.Name=='SignalBeacon3' and 7.65 or 2.75,spawn.Z),trial.tag)
    if e then e.home=e.pos end
   end
   for member in pairs(trial.participants) do if profiles[member] then notice(member,'SIGNAL WAVE '..wave..'/3  —  '..waveCount..' ENEMIES INCOMING','WORLD')end end
   local deadline=clock()+75
   while trialEnemiesRemain(trial.tag)>0 and clock()<deadline and beaconTrials[beacon]==trial do
    task.wait(1);elapsed=elapsed+1
    local defenders=0
    for member in pairs(trial.participants) do
     local playerPos=posOf(member)
     if not profiles[member] or not alivePlayer(member) or not playerPos or (playerPos-position).Magnitude>95 then
      trial.participants[member]=nil
      if profiles[member] then profiles[member].beaconTrial=nil;notice(member,'YOU ABANDONED THE SIGNAL','WARN')end
     else defenders=defenders+1 end
    end
    if defenders==0 then finishTrial(beacon,false);return end
   end
   if beaconTrials[beacon]~=trial then return end
   if trialEnemiesRemain(trial.tag)>0 then finishTrial(beacon,false);return end
   if wave<3 then
    for _,member in ipairs(Players:GetPlayers()) do if trial.participants[member] then notice(member,'SIGNAL HOLDING. NEXT ATTACK IN 10 SECONDS...','QUEST')end end
    task.wait(10)
   end
  end
  finishTrial(beacon,true)
 end)
end

local function dodge(p)
 local h=alivePlayer(p)
 if not h then return end
 local root=p.Character:FindFirstChild('HumanoidRootPart')
 if not root then return end
 local now=clock();local old=dodgeState[p]
 if old and now<old.nextReady then return end
 local dir=root.CFrame.LookVector
 if typeof(dir)~='Vector3' or dir.Magnitude<.1 then return end
 dodgeState[p]={nextReady=now+3.0,invulnerableUntil=now+.28}
 local impulse=Vector3.new(dir.X,0,dir.Z)
 if impulse.Magnitude<.1 then return end
 root.AssemblyLinearVelocity=impulse.Unit*38+Vector3.new(0,math.max(root.AssemblyLinearVelocity.Y,3),0)
 Effects:FireAllClients('DODGE',p.UserId,root.Position,impulse.Unit)
end
-- The shattered-crown clues are actual guarded world discoveries.
-- Each player earns a clue by clearing its wardens, not by rapidly clicking a sign.
local relicGuardians={}
local function claimRelic(p,altar)
 local d=profiles[p];if not d or not altar then return end
 local name=altar.Name
 local index=tonumber(name:match('RelicAltar(%d+)'))
 if not index then return end
 local key='Relic_'..index
 if d.quests[key] then notice(p,'YOU ALREADY FREED THIS FRAGMENT.','LORE');return end
 local record=relicGuardians[p] or {};relicGuardians[p]=record
 local slot=record[index]
 if not slot then
  local guards=({{'Goblin','Bandit','Archer'},{'Wizard','Wisp','Wisp'},{'Knight','Knight','Brute'}})[index]
  if not guards then return end
  local tag='relic_'..p.UserId..'_'..index
  slot={tag=tag,start=clock()};record[index]=slot
  for i,kind in ipairs(guards) do
   local angle=(i/3)*math.pi*2
   local pos=altar.Position+Vector3.new(math.cos(angle)*18,0,math.sin(angle)*18)
   local enemy=spawnEnemy(kind,Vector3.new(pos.X,index==3 and 7.65 or 2.75,pos.Z),tag)
   if enemy then enemy.home=enemy.pos end
  end
  notice(p,'THE RELIC IS GUARDED. DEFEAT ITS WARDENS, THEN CLAIM IT.','WORLD')
  return
 end
 if trialEnemiesRemain(slot.tag)>0 then
  notice(p,'THE FRAGMENT IS SEALED UNTIL ITS GUARDIANS FALL.','WARN')
  return
 end
 record[index]=nil;d.quests[key]=true;d.relics=d.relics+1;d.coins=d.coins+145
 local total=0
 for i=1,3 do if d.quests['Relic_'..i] then total=total+1 end end
 burst(altar.Position+Vector3.new(0,4,0),Color3.fromRGB(206,122,247),18,.6)
 notice(p,'CROWN FRAGMENT '..total..'/3 RECOVERED!  +145 GOLD','SUCCESS')
 if total==3 and not d.owned.Soulrender then
  d.owned.Soulrender=true
  giveTool(p,'Soulrender')
  notice(p,'THE FRAGMENTS REFORMED SOULRENDER. CHECK YOUR INVENTORY!','SUCCESS')
  eventMessage(p.DisplayName..' REFORGED THE SWORD OF THE HOLLOW KING!')
 end
 sync(p)
end
Action.OnServerEvent:Connect(function(p,action,a,b)
 if type(action)~='string' then return end
 if action=='Fire' then fireWeapon(p,a,b)
 elseif action=='Dodge' then dodge(p)
 elseif action=='Reload' then reload(p,a)
 elseif action=='Buy' and type(a)=='string' then purchase(p,a)
 elseif action=='Bank' then deposit(p,a)
 elseif action=='Withdraw' then withdraw(p,a)
 elseif action=='Hatch' then hatch(p)
 elseif action=='Sync' then sync(p)
 end
end)
local function attachWorldPrompts()
 for _,obj in ipairs(world:GetDescendants()) do
  if obj:IsA('ProximityPrompt') then
   local purpose=obj.Name:match('^OV_(%u+)$') or obj:GetAttribute('OutlawAction')
   if purpose then
    obj.Triggered:Connect(function(p)
     if purpose=='SHOP' then
      Feedback:FireClient(p,'OPEN_SHOP','')
      local lines={
       'Grindle: If that thing explodes in your hands, the warranty explodes with it.',
       'Grindle: You look alive. That makes you my favorite customer today.',
       'Grindle: The wizard still owes me sixteen gold and a left eyebrow.',
       'Grindle: Never trust a knight who refuses to take off his helmet.'}
      notice(p,lines[random:NextInteger(1,#lines)],'LORE')
     elseif purpose=='BANK' then Feedback:FireClient(p,'OPEN_BANK','')
     elseif purpose=='NURSERY' then hatch(p)
     elseif purpose=='BEACON' then activateBeacon(p,obj.Parent)
     elseif purpose=='LORE' then notice(p,obj.ObjectText or 'There is more to this place than meets the eye.','LORE')
     elseif purpose=='RELIC' then claimRelic(p,obj.Parent)
     elseif purpose=='SUPPLY' then
      local d=profiles[p];if not d then return end
      d.cacheUsed=d.cacheUsed or {}
      if os.time()-(d.cacheUsed[obj.Parent.Name] or 0)<90 then notice(p,'CACHE IS EMPTY. CHECK BACK LATER.','WARN');return end
      d.cacheUsed[obj.Parent.Name]=os.time()
      local hum=alivePlayer(p)
      if hum then hum.Health=math.min(hum.MaxHealth,hum.Health+35)end
      for id,w in pairs(C.Weapons) do if d.owned[id] and w.mag>0 and w.price>=0 then d.ammo[id]=math.min(w.reserve,d.ammo[id]+math.ceil(w.reserve*.3)) end end
      notice(p,'SCAVENGED AMMO AND MEDICAL SUPPLIES','SUCCESS');sync(p)
     elseif purpose=='GODSLAYER' then
      local d=profiles[p];if not d then return end
      if d.godslayer then
       d.owned.Godslayer=true;giveTool(p,'Godslayer');notice(p,'THE GODSLAYER RECOGNIZES ITS MASTER.','SUCCESS')
      elseif C.PassId>0 then
       MPS:PromptGamePassPurchase(p,C.PassId)
      else notice(p,'PASS ID NOT CONFIGURED YET. SET OutlawConfig.PassId.','WARN')end
     end
    end)
   end
  end
 end
end
MPS.PromptGamePassPurchaseFinished:Connect(function(p,passId,purchased)
 if not purchased or passId~=C.PassId or C.PassId<=0 then return end
 local d=profiles[p];if not d then return end
 if not ownsPass(p) then notice(p,'PURCHASE STILL VERIFYING. REJOIN IF NEEDED.','WARN');return end
 d.godslayer=true;d.owned.Godslayer=true;giveTool(p,'Godslayer')
 notice(p,'GODSLAYER UNLOCKED. THE VALLEY IS YOURS.','SUCCESS');sync(p)
end)
local function attachPlayer(p)
 load(p)
 local function characterSpawned(ch)
  local hum=ch:WaitForChild('Humanoid',10);if not hum then return end
  hum.MaxHealth=C.PlayerMaxHealth;hum.Health=C.PlayerMaxHealth
  task.delay(.75,function()if profiles[p] then grantOwned(p);summonPet(p);sync(p)end end)
  hum.Died:Connect(function()
   local killerID=p:GetAttribute('LastPvPAttacker');local time=p:GetAttribute('LastPvPTime')
   local victim=profiles[p]
   if victim and type(killerID)=='number' and type(time)=='number' and os.time()-time<=12 then
    local killer=Players:GetPlayerByUserId(killerID)
    if killer and profiles[killer] then
     local stolen=Rules.stolenGold(victim.coins,C.PvPLootDropFraction)
     victim.coins=victim.coins-stolen;profiles[killer].coins=profiles[killer].coins+stolen
     notice(killer,'STOLE '..stolen..' GOLD FROM '..p.DisplayName,'PVP')
     notice(p,'YOU LOST '..stolen..' UNBANKED GOLD','WARN')
     sync(killer);sync(p)
    end
   end
   p:SetAttribute('LastPvPAttacker',nil);p:SetAttribute('LastPvPTime',nil)
  end)
 end
 p.CharacterAdded:Connect(characterSpawned)
 if p.Character then task.spawn(characterSpawned,p.Character) end
end
Players.PlayerAdded:Connect(attachPlayer)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(attachPlayer,p)end
Players.PlayerRemoving:Connect(function(p)relicGuardians[p]=nil;dodgeState[p]=nil;save(p);profiles[p]=nil;if pets[p] then pets[p].model:Destroy();pets[p]=nil end end)
game:BindToClose(function()
 for p in pairs(profiles) do task.spawn(save,p)end
 task.wait(2)
end)
-- Replicated low-cost environmental particles. These use built-in Roblox textures,
-- not unlicensed third-party asset IDs or unverified external scripts.
local function dressWorld()
 local budget=85
 for _,object in ipairs(world:GetDescendants()) do
  if budget<=0 then break end
  if object:IsA('BasePart') then
   local name=object.Name
   local isFire=(name=='Lantern flame' or name=='Burning torch' or name=='Hollow flame'
      or name=='Embers still warm' or name=='Floating crown shard' or name=='Glowing spore')
   if isFire then
    budget=budget-1
    local sparks=Instance.new('ParticleEmitter');sparks.Name='Flickering embers'
    sparks.Texture='rbxasset://textures/particles/sparkles_main.dds'
    sparks.Color=ColorSequence.new(object.Color)
    sparks.LightEmission=.85
    sparks.Lifetime=NumberRange.new(.3,.9)
    sparks.Speed=NumberRange.new(.5,2.2)
    sparks.Rate=name=='Hollow flame' and 12 or 4
    sparks.SpreadAngle=Vector2.new(65,65)
    sparks.RotSpeed=NumberRange.new(-20,20)
    sparks.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.55),NumberSequenceKeypoint.new(1,0)})
    sparks.Parent=object
   end
  end
 end
end
attachWorldPrompts()
dressWorld()
for _,spawnData in ipairs(C.Spawns) do spawnEnemy(spawnData.type,spawnData.pos,'natural')end
-- Enemies actively fight, signal their attacks, retreat, flank, and respawn in dangerous zones.
local respawnSlots={}
for i,s in ipairs(C.Spawns) do respawnSlots[i]={data=s,next=0}end
Run.Heartbeat:Connect(function(dt)
 dt=math.min(dt,.12)
 for _,e in pairs(activeEnemies) do moveAI(e,dt)end
 updatePets(dt)
end)
task.spawn(function()
 while true do
  task.wait(8)
  for _,slot in ipairs(respawnSlots) do
   local count=0
   for _,e in pairs(activeEnemies) do
    if e.tag=='natural' and e.home==slot.data.pos and e.alive then count=count+1 end
   end
   if count==0 then
    if not slot.next then slot.next=clock()+40 end
    if slot.next==0 then slot.next=clock()+40 end
    if clock()>=slot.next then spawnEnemy(slot.data.type,slot.data.pos,'natural');slot.next=clock()+45 end
   else slot.next=0 end
  end
  local near=nearestPlayer(Vector3.new(290,8,-100),150)
  if near and clock()>=nextBossSpawn then
   local existing=false
   for _,e in pairs(activeEnemies) do if e.kind=='Boss' and e.alive then existing=true;break end end
   if not existing then
    spawnEnemy('Boss',Vector3.new(302,11,-121),'boss')
    eventMessage('THE CROWNLESS WARDEN HAS RISEN AT THE FORTRESS!')
    nextBossSpawn=clock()+300
   end
  end
 end
end)
task.spawn(function()
 task.wait(40)
 while true do
  task.wait(C.RaidInterval)
  local players=Players:GetPlayers()
  if #players>0 then
   local roll=random:NextInteger(1,3)
   if roll==1 then
    eventMessage('BANDIT RAID! THE BRIDGE TO CROOKED CREEK IS UNDER ATTACK!')
    for i=1,5 do
     spawnEnemy(i%2==0 and 'Bandit' or 'Archer',Vector3.new(C.RaidLocation.X+random:NextInteger(-22,22),2.75,C.RaidLocation.Z+random:NextInteger(-22,22)),'raid')
    end
   elseif roll==2 then
    eventMessage('A FALLEN STAR LANDS IN THE WITCHWATER MARSH!')
    coinDrop(Vector3.new(-224,5,235),160,'FALLEN STAR')
    spawnEnemy('Wizard',Vector3.new(-220,2.75,228),'event')
   else
    eventMessage('THE HOLLOW CROWN STIRS. AN OGRE HAS ESCAPED ITS CHAINS!')
    spawnEnemy('Brute',Vector3.new(70,2.75,176),'event')
   end
  end
 end
end)
-- Environmental cycle: twilight gives way to foggy midnight before dawn returns.
task.spawn(function()
 local start=clock()
 while true do
  task.wait(2)
  local phase=((clock()-start)%C.DayCycleSeconds)/C.DayCycleSeconds
  Lighting.ClockTime=(16+phase*24)%24
  local night=Lighting.ClockTime<6 or Lighting.ClockTime>19
  Lighting.Brightness=night and 1.8 or 3
 end
end)
task.spawn(function()
 while true do task.wait(120)
  for _,p in ipairs(Players:GetPlayers()) do
   if profiles[p] then save(p)end
  end
 end
end)
print('[Outlaw Valley] SERVER ONLINE - '..C.Version)