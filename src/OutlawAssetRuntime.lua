-- Automatically import curated free Creator Store scenery when Roblox permits it.
-- This Script never substitutes assets during combat; game remains playable if import fails.
-- An offline .rbxlx cannot embed third-party source model bytes without Studio access.
local installer=require(game:GetService('ServerScriptService'):WaitForChild('OutlawAssetInstaller'))
task.delay(4,function()
 local ok,result=pcall(installer.Install,false)
 if not ok then
  warn('[Outlaw Art] Loading failed. Enable Game Settings > Security > Allow Loading Third Party Assets: ',result)
 elseif result==false then
  warn('[Outlaw Art] Studio import requires asset permissions. See OutlawAssetCatalog.')
 end
end)