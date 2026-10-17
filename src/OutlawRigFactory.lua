-- Procedurally costumed R15 NPCs; if Roblox avatar creation is unavailable,
-- OutlawServer falls back to its self-contained hand-assembled creatures.
local Players=game:GetService('Players')
local Factory={}
local function addPart(model,part,name,size,offset,color,shape,material)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.Shape=shape or Enum.PartType.Block
 p.Color=color;p.Material=material or Enum.Material.SmoothPlastic;p.CanCollide=false
 p.CanTouch=false;p.Massless=true;p.CFrame=part.CFrame*CFrame.new(offset);p.Parent=model
 local joint=Instance.new('WeldConstraint');joint.Part0=part;joint.Part1=p;joint.Parent=p
 return p
end
function Factory.make(kind,conf,position)
 local description=Instance.new('HumanoidDescription')
 local base=conf.color
 description.HeadColor=base;description.LeftArmColor=base;description.RightArmColor=base
 description.LeftLegColor=Color3.fromRGB(57,56,66);description.RightLegColor=Color3.fromRGB(57,56,66)
 description.TorsoColor=kind=='Wizard' and Color3.fromRGB(79,57,117) or kind=='Knight' and Color3.fromRGB(89,109,122) or
  kind=='Bandit' and Color3.fromRGB(120,76,67) or kind=='Boss' and Color3.fromRGB(54,38,80) or Color3.fromRGB(92,84,63)
 description.BodyTypeScale=.2;description.ProportionScale=.1
 description.HeadScale=1;description.HeightScale=1;description.WidthScale=1;description.DepthScale=1
 local success,rig=pcall(function()return Players:CreateHumanoidModelFromDescription(description,Enum.HumanoidRigType.R15)end)
 if not success or not rig then return nil end
 local root=rig:FindFirstChild('HumanoidRootPart')
 local hum=rig:FindFirstChildOfClass('Humanoid')
 local head=rig:FindFirstChild('Head')
 if not root or not hum or not head then rig:Destroy();return nil end
 rig.Name=conf.display
 rig:SetAttribute('OutlawEnemy',true);rig:SetAttribute('EnemyType',kind)
 hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 hum.Health=conf.health;hum.MaxHealth=conf.health
 root.Anchored=true;root.CanCollide=false;root.CanTouch=false;root.CanQuery=false
 for _,p in ipairs(rig:GetDescendants()) do
  if p:IsA('BasePart') then p.CanCollide=false;p.CanTouch=false;p.Massless=true end
 end
 local armored=kind=='Knight' or kind=='Brute' or kind=='Boss'
 local scale=kind=='Boss' and 2.8 or kind=='Brute' and 1.75 or kind=='Knight' and 1.2 or 1
 rig.PrimaryPart=root
 rig:ScaleTo(scale)
 local torso=rig:FindFirstChild('UpperTorso') or rig:FindFirstChild('Torso') or root
 local rhand=rig:FindFirstChild('RightHand') or rig:FindFirstChild('RightLowerArm') or torso
 if armored then
  addPart(rig,torso,'Forged breastplate',Vector3.new(2.2,2,.9)*scale,Vector3.new(0,0,-.48)*scale,
   kind=='Boss' and Color3.fromRGB(59,40,86) or Color3.fromRGB(92,112,126),nil,Enum.Material.Metal)
  addPart(rig,head,'Visored war helm',Vector3.new(2.1,.72,2)*scale,Vector3.new(0,.75,0)*scale,
   Color3.fromRGB(99,104,112),nil,Enum.Material.Metal)
 else
  addPart(rig,torso,'Traveling jerkin',Vector3.new(1.7,1.8,.35)*scale,Vector3.new(0,-.1,-.45)*scale,
   kind=='Wizard' and Color3.fromRGB(71,40,118) or Color3.fromRGB(98,69,53),nil,Enum.Material.Fabric)
 end
 if kind=='Wizard' or kind=='Boss' then
  addPart(rig,head,'Hood',Vector3.new(2.45,.8,2.35)*scale,Vector3.new(0,.75,0)*scale,
   Color3.fromRGB(53,37,94))
  addPart(rig,rhand,'Enchanted staff',Vector3.new(.3,3.5,.3)*scale,Vector3.new(0,-.8,-.7)*scale,
   Color3.fromRGB(101,64,142),nil,Enum.Material.Wood)
  local gem=addPart(rig,rhand,'Runestone',Vector3.new(.8,.8,.8)*scale,Vector3.new(0,.8,-.7)*scale,
   Color3.fromRGB(186,94,255),Enum.PartType.Ball,Enum.Material.Neon)
  local li=Instance.new('PointLight');li.Color=gem.Color;li.Brightness=1.5;li.Range=10*scale;li.Parent=gem
 elseif kind=='Archer' then
  addPart(rig,rhand,'Longbow',Vector3.new(.2,2.9,.4)*scale,Vector3.new(0,-.3,-.6)*scale,
   Color3.fromRGB(146,98,57),nil,Enum.Material.Wood)
 elseif kind=='Brute' or kind=='Knight' then
  addPart(rig,rhand,'Battered war axe',Vector3.new(.5,3,.6)*scale,Vector3.new(0,-.7,-.5)*scale,
   Color3.fromRGB(128,139,140),nil,Enum.Material.Metal)
 else
  addPart(rig,rhand,'Cutlass',Vector3.new(.45,2,.35)*scale,Vector3.new(0,-.5,-.55)*scale,
   Color3.fromRGB(164,174,183),nil,Enum.Material.Metal)
 end
 if kind=='Boss' then
  addPart(rig,head,'Shattered crown',Vector3.new(2.6,.36,2.4)*scale,Vector3.new(0,1.33,0)*scale,
   Color3.fromRGB(236,178,62),nil,Enum.Material.Metal)
 end
 -- Minor facial light makes these NPCs readable under night lighting.
 for side=-1,1,2 do
  addPart(rig,head,'Glowing eye',Vector3.new(.28,.32,.16)*scale,Vector3.new(side*.35,.08,-.58)*scale,
   kind=='Boss' and Color3.fromRGB(255,79,94) or Color3.fromRGB(250,236,158),Enum.PartType.Ball,Enum.Material.Neon)
 end
 local hud=Instance.new('BillboardGui');hud.Name='EnemyHUD';hud.Adornee=head
 hud.Size=UDim2.fromOffset(kind=='Boss' and 270 or 158,45)
 hud.StudsOffset=Vector3.new(0,2.5*scale,0);hud.AlwaysOnTop=true;hud.MaxDistance=155;hud.Parent=rig
 local title=Instance.new('TextLabel');title.Size=UDim2.fromScale(1,.46)
 title.BackgroundTransparency=1;title.Font=Enum.Font.GothamBold;title.TextSize=12
 title.TextColor3=Color3.new(1,1,1);title.TextStrokeTransparency=.35;title.Text=conf.display;title.Parent=hud
 local holder=Instance.new('Frame');holder.Position=UDim2.fromScale(.07,.56)
 holder.Size=UDim2.fromScale(.86,.25);holder.BorderSizePixel=0
 holder.BackgroundColor3=Color3.fromRGB(24,25,31);holder.Parent=hud
 local bar=Instance.new('Frame');bar.Size=UDim2.fromScale(1,1);bar.BorderSizePixel=0
 bar.BackgroundColor3=kind=='Boss' and Color3.fromRGB(244,74,112) or Color3.fromRGB(115,237,141);bar.Parent=holder
 local animator=hum:FindFirstChildOfClass('Animator') or Instance.new('Animator',hum)
 local anim=Instance.new('Animation');anim.AnimationId='rbxassetid://507777826'
 local ok,track=pcall(function()return animator:LoadAnimation(anim)end)
 if ok and track then track.Looped=true;pcall(function()track:Play(.2,.65,1)end)end
 rig:PivotTo(CFrame.new(position+Vector3.new(0,2.6*scale,0)))
 return rig,scale,bar,2.6*scale
end
return Factory