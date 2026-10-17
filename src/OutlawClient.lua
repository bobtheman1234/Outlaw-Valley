-- OUTLAW VALLEY / CLIENT
-- Responsive HUD, shop, tool firing and combat feedback. All important actions verified by server.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local StarterGui=game:GetService('StarterGui')
local SoundService=game:GetService('SoundService')
local p=Players.LocalPlayer
local C=require(RS:WaitForChild('OutlawConfig'))
local bus=RS:WaitForChild('OutlawRemotes')
local Action=bus:WaitForChild('Action')
local Feedback=bus:WaitForChild('Feedback')
local State=bus:WaitForChild('State')
local Effects=bus:WaitForChild('Effects')
local mouse=p:GetMouse()
local gui=Instance.new('ScreenGui');gui.Name='HollowCrownHUD';gui.ResetOnSpawn=false
 gui.IgnoreGuiInset=true;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=p:WaitForChild('PlayerGui')
local function create(cls,props,parent)
 local i=Instance.new(cls)
 for k,v in pairs(props or {}) do i[k]=v end
 i.Parent=parent
 return i
end
local colors={panel=Color3.fromRGB(18,23,31),light=Color3.fromRGB(35,43,53),gold=Color3.fromRGB(255,199,95),white=Color3.fromRGB(237,239,235),red=Color3.fromRGB(255,105,111),green=Color3.fromRGB(122,239,165)}
local function rounded(o,r)
 create('UICorner',{CornerRadius=UDim.new(0,r or 10)},o)
end
local function label(parent,txt,sz,font,color)
 return create('TextLabel',{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=txt,
  Font=font or Enum.Font.GothamMedium,TextSize=sz or 16,TextColor3=color or colors.white,
  TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},parent)
end
local top=create('Frame',{Position=UDim2.new(0,22,0,20),Size=UDim2.new(0,392,0,98),
 BackgroundColor3=colors.panel,BackgroundTransparency=.13,BorderSizePixel=0},gui);rounded(top,12)
local title=label(create('Frame',{Size=UDim2.new(1,-26,0,30),Position=UDim2.fromOffset(13,9),BackgroundTransparency=1},top),'OUTLAW VALLEY   /   THE HOLLOW CROWN',16,Enum.Font.GothamBlack,colors.gold)
local line=create('Frame',{Position=UDim2.fromOffset(14,43),Size=UDim2.new(1,-28,0,2),BackgroundColor3=Color3.fromRGB(75,76,69),BorderSizePixel=0},top)
local coins=label(create('Frame',{Position=UDim2.fromOffset(15,51),Size=UDim2.fromOffset(170,29),BackgroundTransparency=1},top),'GOLD   125',18,Enum.Font.GothamBold,colors.gold)
local bank=label(create('Frame',{Position=UDim2.fromOffset(204,51),Size=UDim2.fromOffset(165,28),BackgroundTransparency=1},top),'BANK   0',16,Enum.Font.GothamBold,colors.white)
local area=create('Frame',{Position=UDim2.new(1,-310,0,20),Size=UDim2.fromOffset(290,90),BackgroundColor3=colors.panel,BackgroundTransparency=.17,BorderSizePixel=0},gui);rounded(area,12)
local place=label(create('Frame',{Position=UDim2.fromOffset(12,10),Size=UDim2.fromOffset(269,29),BackgroundTransparency=1},area),'CROOKED CREEK',17,Enum.Font.GothamBold,colors.gold)
local tip=label(create('Frame',{Position=UDim2.fromOffset(12,38),Size=UDim2.fromOffset(265,44),BackgroundTransparency=1},area),'Explore the valley. Survive the Crownless Warden.',12,Enum.Font.GothamMedium,colors.white)
local hudBottom=create('Frame',{Position=UDim2.new(.5,-235,1,-102),Size=UDim2.fromOffset(470,82),BackgroundColor3=colors.panel,BackgroundTransparency=.12,BorderSizePixel=0},gui);rounded(hudBottom,13)
local itemName=label(create('Frame',{Position=UDim2.fromOffset(20,7),Size=UDim2.fromOffset(325,25),BackgroundTransparency=1},hudBottom),'RUSTFANG  /  BLADE',16,Enum.Font.GothamBold,colors.white)
local ammo=label(create('Frame',{Position=UDim2.fromOffset(350,4),Size=UDim2.fromOffset(108,30),BackgroundTransparency=1},hudBottom),'MELEE',17,Enum.Font.GothamBlack,colors.gold)
local hpText=label(create('Frame',{Position=UDim2.fromOffset(20,40),Size=UDim2.fromOffset(82,22),BackgroundTransparency=1},hudBottom),'HP 125',14,Enum.Font.GothamBold,colors.green)
local hpBack=create('Frame',{Position=UDim2.fromOffset(103,47),Size=UDim2.fromOffset(340,12),BackgroundColor3=Color3.fromRGB(72,52,58),BorderSizePixel=0},hudBottom);rounded(hpBack,6)
local hpFill=create('Frame',{Size=UDim2.fromScale(1,1),BackgroundColor3=colors.green,BorderSizePixel=0},hpBack);rounded(hpFill,6)
local reticle=create('TextLabel',{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(34,34),
 BackgroundTransparency=1,Text='+',TextSize=28,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(239,239,220),TextStrokeTransparency=.4},gui)
local tracker=create('Frame',{Position=UDim2.new(0,22,0,131),Size=UDim2.fromOffset(308,125),BackgroundColor3=colors.panel,BackgroundTransparency=.18,BorderSizePixel=0},gui);rounded(tracker,11)
local quest=label(create('Frame',{Position=UDim2.fromOffset(13,10),Size=UDim2.fromOffset(281,100),BackgroundTransparency=1},tracker),
 'THE HOLLOW CROWN\n• Restore three signal beacons\n• Defeat the Crownless Warden\n• Collect and hatch mysterious eggs',14,Enum.Font.GothamMedium,colors.white)
local toast=create('TextLabel',{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,130),Size=UDim2.fromOffset(620,56),
 BackgroundColor3=colors.panel,BackgroundTransparency=1,TextTransparency=1,TextColor3=colors.gold,
 Text=' ',Font=Enum.Font.GothamBold,TextSize=20,TextWrapped=true},gui);rounded(toast,12)
local shop=create('Frame',{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(515,515),
 BackgroundColor3=colors.panel,Visible=false,BorderSizePixel=0},gui);rounded(shop,15)
create('UIStroke',{Color=Color3.fromRGB(114,95,60),Thickness=2,Transparency=.15},shop)
local shopTitle=label(create('Frame',{Position=UDim2.fromOffset(22,18),Size=UDim2.fromOffset(445,42),BackgroundTransparency=1},shop),
 'THE CROOKED ARMORY',25,Enum.Font.GothamBlack,colors.gold)
local subtitle=label(create('Frame',{Position=UDim2.fromOffset(22,57),Size=UDim2.fromOffset(465,38),BackgroundTransparency=1},shop),
 '“Touch it, break it, buy it. In that order.” — Grindle',13,Enum.Font.GothamMedium,colors.white)
local close=create('TextButton',{Position=UDim2.fromOffset(468,13),Size=UDim2.fromOffset(32,30),BackgroundColor3=colors.red,
 Text='X',TextColor3=Color3.new(1,1,1),TextSize=17,Font=Enum.Font.GothamBold},shop);rounded(close,7)
close.MouseButton1Click:Connect(function()shop.Visible=false end)
local bankPanel=create('Frame',{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(370,310),
 BackgroundColor3=colors.panel,Visible=false,BorderSizePixel=0},gui);rounded(bankPanel,14)
label(create('Frame',{Position=UDim2.fromOffset(20,14),Size=UDim2.fromOffset(300,40),BackgroundTransparency=1},bankPanel),'THE BURIED TREASURY',21,Enum.Font.GothamBlack,colors.gold)
local closeBank=create('TextButton',{Position=UDim2.fromOffset(330,12),Size=UDim2.fromOffset(29,29),BackgroundColor3=colors.red,
 Text='X',TextColor3=colors.white,Font=Enum.Font.GothamBold,TextSize=16},bankPanel);rounded(closeBank,5)
closeBank.MouseButton1Click:Connect(function()bankPanel.Visible=false end)
local buttons={{'DEPOSIT 100','Bank',100},{'DEPOSIT ALL','Bank','ALL'},
 {'WITHDRAW 100','Withdraw',100},{'WITHDRAW ALL','Withdraw','ALL'}}
for i,b in ipairs(buttons) do
 local button=create('TextButton',{Position=UDim2.fromOffset(24,68+(i-1)*56),Size=UDim2.fromOffset(318,44),
 BackgroundColor3=i<=2 and Color3.fromRGB(79,110,86) or Color3.fromRGB(113,94,66),
 Text=b[1],TextColor3=colors.white,Font=Enum.Font.GothamBold,TextSize=16},bankPanel);rounded(button,8)
 button.MouseButton1Click:Connect(function()Action:FireServer(b[2],b[3])end)
end
local scroller=create('ScrollingFrame',{Position=UDim2.fromOffset(21,106),Size=UDim2.fromOffset(472,390),
 BackgroundTransparency=1,ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,0),BorderSizePixel=0},shop)
local layout=create('UIListLayout',{Padding=UDim.new(0,9),SortOrder=Enum.SortOrder.LayoutOrder},scroller)
local ids={'Crossbow','Blunderbuss','Witchfire','Rattler','Boomstick','SUPPLIES','MEDKIT'}
local profile={coins=125,bank=0,owned={Rustfang=true},eggs={},hatched=0,quests={},kills=0,warden=0,relics=0,ammo={}}
local selected='Rustfang'
local counts={}
local function refillShop()
 for _,old in ipairs(scroller:GetChildren()) do if old:IsA('Frame') then old:Destroy()end end
 for i,id in ipairs(ids) do
  local w=C.Weapons[id]
  local consumable=id=='SUPPLIES' or id=='MEDKIT'
  local labelText=consumable and (id=='SUPPLIES' and 'AMMO DEPOT' or 'FIELD MEDKIT') or w.label
  local price=consumable and (id=='SUPPLIES' and 70 or 55) or w.price
  local description=consumable and (id=='SUPPLIES' and 'REFILL ALL WEAPON RESERVES' or 'RECOVER UP TO 90 HEALTH') or
   w.damage..' DAMAGE  ·  '..(w.mag>0 and w.mag..' SHOTS' or 'MELEE')
  local row=create('Frame',{Size=UDim2.new(1,-10,0,65),BackgroundColor3=colors.light,BorderSizePixel=0,LayoutOrder=i},scroller);rounded(row,9)
  label(create('Frame',{Position=UDim2.fromOffset(14,5),Size=UDim2.fromOffset(300,25),BackgroundTransparency=1},row),labelText,16,Enum.Font.GothamBold,consumable and colors.green or w.color)
  label(create('Frame',{Position=UDim2.fromOffset(14,30),Size=UDim2.fromOffset(268,25),BackgroundTransparency=1},row),description,12,Enum.Font.GothamMedium,colors.white)
  local owned=not consumable and profile.owned and profile.owned[id]
  local btn=create('TextButton',{Position=UDim2.fromOffset(316,13),Size=UDim2.fromOffset(142,38),BackgroundColor3=owned and Color3.fromRGB(65,93,80) or colors.gold,
   Text=owned and 'OWNED' or price..' GOLD',Font=Enum.Font.GothamBlack,TextSize=14,
   TextColor3=owned and colors.white or colors.panel},row);rounded(btn,7)
  btn.MouseButton1Click:Connect(function() if not owned then Action:FireServer('Buy',id)end end)
 end
 scroller.CanvasSize=UDim2.fromOffset(0,#ids*74)
end
local function currentAmmo()
 local w=C.Weapons[selected];if not w then return end
 itemName.Text=w.label
 if w.mag==0 then ammo.Text='MELEE'
 else
  local n=counts[selected] or {loaded=w.mag,reserve=profile.ammo and profile.ammo[selected] or w.reserve}
  ammo.Text=n.loaded..' / '..n.reserve
 end
end
local function localSound(id,vol,speed)
 local so=Instance.new('Sound');so.SoundId=id;so.Volume=vol or .35;so.PlaybackSpeed=speed or 1
 so.Parent=SoundService;so:Play();task.delay(3,function()so:Destroy()end)
end
-- Actually navigable world map, not an inert 'map' key hint.
local mapPanel=create('Frame',{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
 Size=UDim2.fromOffset(590,570),BackgroundColor3=Color3.fromRGB(24,36,36),
 BackgroundTransparency=.04,BorderSizePixel=0,Visible=false},gui);rounded(mapPanel,14)
create('UIStroke',{Color=Color3.fromRGB(135,151,109),Thickness=2},mapPanel)
label(create('Frame',{Position=UDim2.fromOffset(28,15),Size=UDim2.fromOffset(440,36),BackgroundTransparency=1},mapPanel),
 "THE HOLLOW VALLEY  /  EXPLORER'S MAP",21,Enum.Font.GothamBlack,colors.gold)
local mapClose=create('TextButton',{Position=UDim2.fromOffset(544,16),Size=UDim2.fromOffset(31,31),
 Text='X',BackgroundColor3=colors.red,TextColor3=colors.white,Font=Enum.Font.GothamBlack,TextSize=16},mapPanel);rounded(mapClose,7)
mapClose.MouseButton1Click:Connect(function()mapPanel.Visible=false end)
local mapSurface=create('Frame',{Position=UDim2.fromOffset(26,64),Size=UDim2.fromOffset(538,467),
 BackgroundColor3=Color3.fromRGB(59,91,70),BorderSizePixel=0},mapPanel);rounded(mapSurface,8)
for i=1,6 do
 create('Frame',{Position=UDim2.fromScale(0,i/7),Size=UDim2.new(1,0,0,1),BackgroundColor3=Color3.fromRGB(82,115,87),BorderSizePixel=0},mapSurface)
 create('Frame',{Position=UDim2.fromScale(i/7,0),Size=UDim2.new(0,1,1,0),BackgroundColor3=Color3.fromRGB(82,115,87),BorderSizePixel=0},mapSurface)
end
local function mapCoordinate(x,z)
 return UDim2.fromScale((x+540)/1080,(z+490)/980)
end
for _,region in ipairs({
 {'CROOKED CREEK',-160,-145,'◆',colors.gold},
 {'THIEVES WOODS',75,115,'⚔',Color3.fromRGB(235,182,109)},
 {'WITCHWATER',-230,245,'✦',Color3.fromRGB(213,135,245)},
 {'HOLLOW FORTRESS',302,-121,'♛',Color3.fromRGB(255,107,123)},
 {'STARWATCH',174,282,'✦',Color3.fromRGB(201,222,241)},
 {'THE SPAN',-336,19,'⌂',Color3.fromRGB(211,211,194)}
 })do
 local icon=create('TextLabel',{AnchorPoint=Vector2.new(.5,.5),Position=mapCoordinate(region[2],region[3]),
 Size=UDim2.fromOffset(145,36),BackgroundTransparency=1,Text=region[4]..'  '..region[1],
 TextColor3=region[5],TextStrokeTransparency=.4,Font=Enum.Font.GothamBold,TextSize=12},mapSurface)
end
local playerDot=create('TextLabel',{AnchorPoint=Vector2.new(.5,.5),Position=mapCoordinate(-160,-145),Size=UDim2.fromOffset(20,20),
 BackgroundColor3=colors.white,Text='▲',TextColor3=Color3.fromRGB(27,42,58),Font=Enum.Font.GothamBlack,TextSize=18},mapSurface);rounded(playerDot,10)
label(create('Frame',{Position=UDim2.fromOffset(30,538),Size=UDim2.fromOffset(530,24),BackgroundTransparency=1},mapPanel),
 'WHITE ARROW: YOU   •   RED: DANGER   •   M: MAP   •   Q: DODGE',12,Enum.Font.GothamMedium,colors.white)
local showThread=0
local function notify(text,kind)
 showThread=showThread+1;local key=showThread
 toast.Text=text
 toast.TextColor3=kind=='WARN' and colors.red or kind=='SUCCESS' and colors.green or colors.gold
 Tween:Create(toast,TweenInfo.new(.14),{BackgroundTransparency=.1,TextTransparency=0}):Play()
 task.delay(3.1,function()
  if key==showThread then Tween:Create(toast,TweenInfo.new(.3),{BackgroundTransparency=1,TextTransparency=1}):Play()end
 end)
end
Feedback.OnClientEvent:Connect(function(kind,message)
 if kind=='OPEN_SHOP' then bankPanel.Visible=false;shop.Visible=true;refillShop();return end
 if kind=='OPEN_BANK' then shop.Visible=false;bankPanel.Visible=true;return end
 if kind=='WORLD' then notify(message,kind);return end
 notify(message,kind)
end)
State.OnClientEvent:Connect(function(d)
 if d.ammoOnly then
  counts[d.ammoOnly]={loaded=d.loaded,reserve=d.reserve};currentAmmo();return
 end
 for k,v in pairs(d) do profile[k]=v end
 coins.Text='GOLD   '..tostring(profile.coins)
 bank.Text='BANK   '..tostring(profile.bank)
 local eggs=profile.eggs or {};local hatch='NO EGGS'
 if #eggs>0 then hatch='EGG READY!'
  local left=math.max(0,math.floor(eggs[1]-(profile.now or os.time())))
  if left>0 then hatch='EGG HATCHES IN '..math.ceil(left/60)..' MIN' end
 end
 local q=profile.quests or {}
 local fragments=0
 for i=1,3 do if q['Relic_'..i] then fragments=fragments+1 end end
 quest.Text='THE HOLLOW CROWN\n• Signal trials: '..(q.beacons or 0)..'/3\n• Lost relics: '..fragments..'/3  (secret weapon)\n• Warden defeated: '..(profile.warden or 0)..'\n• '..hatch..'   |  Foxes: '..(profile.hatched or 0)
 refillShop();currentAmmo()
end)
local function connectTool(t)
 if not t:IsA('Tool') or not t:GetAttribute('WeaponId') or t:GetAttribute('OutlawClientConnected') then return end
 t:SetAttribute('OutlawClientConnected',true)
 local id=t:GetAttribute('WeaponId')
 local held=false
 t.Equipped:Connect(function()
  selected=id;currentAmmo()
 end)
 t.Unequipped:Connect(function() held=false end)
 t.Activated:Connect(function()
  held=true
  local function fire()
   if p.Character and t.Parent==p.Character then
    local hit=mouse.Hit
    local aim=(hit and hit.Position) or (workspace.CurrentCamera.CFrame.Position+workspace.CurrentCamera.CFrame.LookVector*300)
    Action:FireServer('Fire',id,aim)
    if id=='Rustfang' then localSound('rbxassetid://12222200',.32,1.03)
    elseif id=='Godslayer' then localSound('rbxasset://sounds/impact_generic.mp3',1,.5)
    elseif id=='Boomstick' or id=='Blunderbuss' then localSound('rbxasset://sounds/impact_generic.mp3',.75,.8)
    else localSound('rbxasset://sounds/impact_generic.mp3',.22,1.65)end
    reticle.TextColor3=C.Weapons[id].color
    task.delay(.17,function()reticle.TextColor3=Color3.fromRGB(239,239,220)end)
   end
  end
  fire()
  if id=='Rattler' then
   task.spawn(function()
    while held and t.Parent==p.Character do
     task.wait(C.Weapons[id].cooldown)
     if held then fire()end
    end
   end)
  end
 end)
 t.Deactivated:Connect(function()held=false end)
end
local function watchInventory()
 local backpack=p:WaitForChild('Backpack')
 backpack.ChildAdded:Connect(connectTool)
 for _,tool in ipairs(backpack:GetChildren()) do connectTool(tool)end
 local function onCharacter(ch)
  ch.ChildAdded:Connect(connectTool)
  for _,tool in ipairs(ch:GetChildren()) do connectTool(tool)end
  local hum=ch:WaitForChild('Humanoid',10)
  if hum then
   local function updateHealth()
    local ratio=math.clamp(hum.Health/math.max(1,hum.MaxHealth),0,1)
    hpText.Text='HP '..math.ceil(hum.Health)
    Tween:Create(hpFill,TweenInfo.new(.18),{Size=UDim2.fromScale(ratio,1)}):Play()
    hpFill.BackgroundColor3=ratio>.35 and colors.green or colors.red
   end
   hum.HealthChanged:Connect(updateHealth);updateHealth()
  end
 end
 p.CharacterAdded:Connect(onCharacter)
 if p.Character then task.spawn(onCharacter,p.Character)end
end
watchInventory()
UIS.InputBegan:Connect(function(inp,processed)
 if processed then return end
 if inp.KeyCode==Enum.KeyCode.Q then
  if os.clock()-dodgeLast>=3 then
   dodgeLast=os.clock();Action:FireServer('Dodge')
   dodgeInfo.Text='DODGE RECHARGING...';dodgeInfo.TextColor3=Color3.fromRGB(241,186,109)
   task.delay(3,function() if dodgeInfo then dodgeInfo.Text='Q  ·  DODGE / EVADE';dodgeInfo.TextColor3=Color3.fromRGB(192,240,210)end end)
  end
 elseif inp.KeyCode==Enum.KeyCode.R then Action:FireServer('Reload',selected)
 elseif inp.KeyCode==Enum.KeyCode.Escape then shop.Visible=false;bankPanel.Visible=false;mapPanel.Visible=false
 elseif inp.KeyCode==Enum.KeyCode.M then
  shop.Visible=false;bankPanel.Visible=false;mapPanel.Visible=not mapPanel.Visible
 end
end)
local dodgeInfo=create('TextLabel',{AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-95),
 Size=UDim2.fromOffset(245,28),BackgroundTransparency=.32,BackgroundColor3=Color3.fromRGB(28,40,38),
 Text='Q  ·  DODGE / EVADE',TextColor3=Color3.fromRGB(192,240,210),Font=Enum.Font.GothamBold,TextSize=13},gui)
local dodgeLast=0
local region=''
Run.RenderStepped:Connect(function()
 local ch=p.Character;local root=ch and ch:FindFirstChild('HumanoidRootPart')
 if not root then return end
 local x,z=root.Position.X,root.Position.Z
 if mapPanel.Visible then playerDot.Position=mapCoordinate(x,z)end
 local name,detail
 if (Vector3.new(x,0,z)-Vector3.new(C.TownCenter.X,0,C.TownCenter.Z)).Magnitude<C.SafeRadius then
  name='CROOKED CREEK';detail='SAFE TERRITORY  ·  BANK / ARMORY / NURSERY'
 elseif x>195 and z<40 then name='BROKEN CROWN FORTRESS';detail='DANGER LEVEL: EXTREME  ·  THE WARDEN'
 elseif x< -120 and z>110 then name='WITCHWATER MARSH';detail='DANGER LEVEL: HIGH  ·  WIZARDS / WISPS'
 elseif z>25 then name='THIEVES WOODS';detail='DANGER LEVEL: MODERATE  ·  BANDITS / GOBLINS'
 else name='THE OLD KINGDOM';detail='UNCLAIMED TERRITORY  ·  WANDER CAREFULLY' end
 if name~=region then region=name;place.Text=name;tip.Text=detail end
end)
Effects.OnClientEvent:Connect(function(kind,a,b,c)
 if kind=='HIT' then
  local amount=a
  local mark=create('TextLabel',{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.43),
    Size=UDim2.fromOffset(100,45),BackgroundTransparency=1,Text=(b and '✦ ' or '')..math.floor(amount),
    TextColor3=b and colors.gold or colors.white,TextSize=24,Font=Enum.Font.GothamBlack},gui)
  Tween:Create(mark,TweenInfo.new(.5),{Position=UDim2.fromScale(.5,.36),TextTransparency=1}):Play()
  task.delay(.55,function()mark:Destroy()end)
 elseif kind=='EXPLOSION' then
  local ch=p.Character
  local root=ch and ch:FindFirstChild('HumanoidRootPart')
  local point=a
  if root and typeof(point)=='Vector3' then
   local dist=(root.Position-point).Magnitude
   if dist<95 then
    local camera=workspace.CurrentCamera
    if camera then
     local strength=math.clamp((95-dist)/95,0,1)
     camera.CFrame=camera.CFrame*CFrame.Angles(math.rad(-1.9)*strength,math.rad(.9)*strength,0)
    end
   end
  end
 elseif kind=='DODGE' then
  if a==p.UserId then
   local camera=workspace.CurrentCamera
   if camera then camera.CFrame=camera.CFrame*CFrame.Angles(math.rad(.7),0,math.rad(1.5))end
  end
 elseif kind=='FIRE' then
  local uid,id,from=a,b,c
  -- Visual tracers are server replicated, so only camera impulse is client-side.
  if uid==p.UserId and workspace.CurrentCamera and id=='Godslayer' then
   local camera=workspace.CurrentCamera
   camera.CFrame=camera.CFrame*CFrame.Angles(math.rad(-1.5),0,0)
  end
 end
end)
Action:FireServer('Sync')
print('[Outlaw Valley] HUD READY')