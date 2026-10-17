-- OUTLAW VALLEY: SCRIPT-FREE CURATED CREATOR STORE IMPORTER
-- Tested statically only. Roblox network/asset permissions must be tested in Studio.
-- Automatically tries to install when the game server launches.
-- To bake the models permanently, call:
--   require(game.ServerScriptService.OutlawAssetInstaller).Install(true)
-- from Roblox Studio's Command Bar, then save the place.
local AssetService=game:GetService('AssetService')
local RunService=game:GetService('RunService')
local Catalog=require(game:GetService('ReplicatedStorage'):WaitForChild('OutlawAssetCatalog'))
local Installer={}
local BUSY=false
local FOLDER_NAME='OutlawCuratedCreatorStoreArt'
local function sanitize(source,maxParts)
 local count=0
 for _,child in ipairs(source:GetDescendants()) do
  if child:IsA('LuaSourceContainer') or child:IsA('Tool') or child:IsA('RemoteEvent') or
     child:IsA('RemoteFunction') or child:IsA('BindableFunction') or child:IsA('BindableEvent') then
   child:Destroy()
  elseif child:IsA('BasePart') then
   count=count+1
   if count>maxParts then return false,'asset has more parts than expected' end
   child.Anchored=true
   child.CanCollide=false
   child.CanTouch=false
   child.CanQuery=false
   child.CastShadow=true
   child.AssemblyLinearVelocity=Vector3.zero
   child.AssemblyAngularVelocity=Vector3.zero
  elseif child:IsA('Humanoid') or child:IsA('AnimationController') then
   child:Destroy()
  elseif child:IsA('Sound') then
   child:Destroy() -- no unverified third-party audio permissions
  end
 end
 if count==0 then return false,'asset has no visible BaseParts' end
 return true,count
end
local function loadAsset(id)
 local ok,result=pcall(function()return AssetService:LoadAssetAsync(id)end)
 if ok and result and result:IsA('Model') then return result end
 local explanation=tostring(result)
 -- GetObjects may be available in Roblox Studio's Command Bar/security context;
 -- never assume it works in published game servers.
 if RunService:IsStudio() then
  local other,objects=pcall(function()return game:GetObjects('rbxassetid://'..tostring(id))end)
  if other and type(objects)=='table' and #objects>0 then
   local wrapper=Instance.new('Model');wrapper.Name='StoreAsset_'..tostring(id)
   for _,object in ipairs(objects) do object.Parent=wrapper end
   return wrapper
  end
 end
 return nil,explanation
end
local function scaleAndPlace(template,entry,position,index,parent)
 local model=template:Clone()
 model.Name=entry.key..'_'..index
 model.Parent=parent
 local okay,why=pcall(function()
  local cf,sz=model:GetBoundingBox()
  if sz.X<.05 or sz.Y<.05 or sz.Z<.05 then error('empty size')end
  if sz.Magnitude>50000 then error('outlier bounds')end
  local horizontal=math.max(sz.X,sz.Z)
  local scale=math.clamp(entry.targetWidth/horizontal,.12,9)
  model:ScaleTo(scale)
  local _,afterSize=model:GetBoundingBox()
  local afterCFrame=model:GetBoundingBox()
  local delta=Vector3.new(position.X-afterCFrame.Position.X,
        position.Y+afterSize.Y*.5-afterCFrame.Position.Y,
        position.Z-afterCFrame.Position.Z)
  model:PivotTo(model:GetPivot()+delta)
  local angles=entry.angles
  if angles and angles[index] then
   local pivot=model:GetPivot()
   model:PivotTo(CFrame.new(pivot.Position)*CFrame.Angles(0,angles[index],0)*pivot.Rotation)
  end
  model:SetAttribute('CreatorStoreAssetId',entry.assetId)
  model:SetAttribute('CreatorStoreOriginalName',entry.title)
  model:SetAttribute('OriginalCreator',entry.creator)
  model:SetAttribute('AssetVerifiedInStudio',false) -- actual look is not previewed yet
 end)
 if not okay then model:Destroy();return false,tostring(why)end
 return true,model
end
local function fadeOriginalHouse(x,z)
 local town=workspace:FindFirstChild('CROOKED CREEK  |  SETTLEMENT')
 if not town then return end
 local hidden=0
 for _,part in ipairs(town:GetChildren()) do
  if part:IsA('BasePart') and (Vector2.new(part.Position.X-x,part.Position.Z-z)).Magnitude<16 then
   local nm=part.Name
   if nm:find('wall') or nm:find('roof') or nm:find('eaves') or
      nm:find('ridge') or nm:find('beam') or nm:find('window') or nm:find('lintel') or
      nm:find('Door frame') then
    if not part:GetAttribute('OV_OldOpacity') then part:SetAttribute('OV_OldOpacity',part.Transparency)end
    part.Transparency=.97
    hidden=hidden+1
   end
  end
 end
 return hidden
end
local function log(entry,status,details)
 if status=='OK' then
  print('[Outlaw Art] Loaded '..entry.key..': '..details)
 else
  warn('[Outlaw Art] '..entry.key..' unavailable: '..tostring(details))
 end
end
function Installer.Install(bake)
 if BUSY then return false,'asset importer already running' end
 local existing=workspace:FindFirstChild(FOLDER_NAME)
 if existing and existing:GetAttribute('ImportComplete') then
  return true,'already imported' -- does not duplicate artwork on every server startup
 end
 if existing then existing:ClearAllChildren() end -- prevents duplicate models after a partial retry
 BUSY=true
 local folder=existing or Instance.new('Folder')
 folder.Name=FOLDER_NAME;folder.Parent=workspace
 local okCount=0;local failures={}
 for _,entry in ipairs(Catalog.Entries) do
  local template,errorText=loadAsset(entry.assetId)
  if template then
   local safe,partCount=sanitize(template,entry.maxParts)
   if safe then
    local succeeded=0
    for i,position in ipairs(entry.positions) do
     local ok,model=scaleAndPlace(template,entry,position,i,folder)
     if ok then
      if entry.key=='WizardTower' then
       for _,p in ipairs(model:GetDescendants()) do
        if p:IsA('BasePart') then p.CanCollide=true;p.CanQuery=true end
       end
      end
      succeeded=succeeded+1
      if entry.hideShell then fadeOriginalHouse(position.X,position.Z)end
     else table.insert(failures,entry.key..': '..tostring(model))end
    end
    okCount=okCount+succeeded
    log(entry,'OK',tostring(succeeded)..' placements, '..tostring(partCount)..' source parts')
   else
    table.insert(failures,entry.key..': '..tostring(partCount))
    log(entry,'FAILED',partCount)
   end
   template:Destroy()
  else
   table.insert(failures,entry.key..': '..tostring(errorText))
   log(entry,'FAILED',errorText)
  end
  task.wait(.08)
 end
 folder:SetAttribute('CreatorStorePlacementsLoaded',okCount)
 folder:SetAttribute('CreatorStoreAssetCandidates',#Catalog.Entries)
 folder:SetAttribute('ImportComplete',okCount>0) -- freezes partial successes; no duplicate imports
 folder:SetAttribute('ImportedAsEditTimeAssets',bake==true)
 folder:SetAttribute('ImportErrors',table.concat(failures,' | '):sub(1,3000))
 BUSY=false
 print('[Outlaw Art] Imported '..tostring(okCount)..' artwork placements. '..tostring(#failures)..' catalogs had issues.')
 return okCount>0,{placements=okCount,failures=failures}
end
return Installer