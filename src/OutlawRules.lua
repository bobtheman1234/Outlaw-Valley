-- Pure Lua gameplay rules; also executed by offline regression tests.
local Rules={}
function Rules.purchase(id,gold,owned,weapons)
 local weapon=weapons[id]
 if not weapon or weapon.price<0 then return false,'ITEM NOT FOR SALE',0 end
 if owned[id] then return false,'ALREADY OWNED',weapon.price end
 if gold<weapon.price then return false,'NEED '..tostring(weapon.price-gold)..' MORE GOLD',weapon.price end
 return true,'PURCHASED',weapon.price
end
function Rules.stolenGold(gold,fraction)
 return math.floor(math.max(0,gold)*math.max(0,math.min(1,fraction)))
end
function Rules.readyEgg(eggs,now)
 if #eggs==0 then return nil,0 end
 local minimum=math.huge
 for i,readyAt in ipairs(eggs) do
  if readyAt<=now then return i,0 end
  minimum=math.min(minimum,readyAt-now)
 end
 return nil,math.ceil(minimum)
end
function Rules.refillCost(owned,weapons,ammo)
 local missing=0
 for id,valid in pairs(owned) do
  local w=weapons[id]
  if valid and w and w.price>=0 and w.mag>0 then
   if (ammo[id] or 0)<w.reserve then missing=missing+1 end
  end
 end
 return missing
end
return Rules
