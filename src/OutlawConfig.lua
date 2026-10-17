-- OUTLAW VALLEY: THE HOLLOW CROWN
-- Shared, data-driven balancing. Every value here is editable.
local C = {}
C.Version = '0.3.0-grenade-relic-defense'
C.PassId = 0 -- The creator must insert their Game Pass ID after publishing.
C.UseRiggedEnemies = true -- Try Roblox's animated R15 rigs; use static stylized fallback when unavailable.
C.OwnerUserIds = {} -- Optional explicit owner IDs for group-owned experiences.
C.StartCoins = 125
C.StartWeapon = 'Rustfang'
C.PlayerMaxHealth = 125
C.PvPLootDropFraction = 0.25
C.EggSeconds = 600
C.DayCycleSeconds = 900
C.RaidInterval = 240
C.MapBounds = 530
C.TownCenter = Vector3.new(-160,4,-145)
C.SafeRadius = 100
C.RaidLocation = Vector3.new(-72,4,-90)
C.EnemyLeash = 175
C.Weapons = {
 Rustfang={label='RUSTFANG',category='melee',damage=30,range=11,cooldown=.52,mag=0,reserve=0,reload=0,price=0,color=Color3.fromRGB(191,205,217),blast=0},
 Crossbow={label='IRONBARK REPEATER',category='projectile',damage=40,range=280,cooldown=.78,mag=6,reserve=48,reload=1.95,price=180,color=Color3.fromRGB(235,193,109),blast=0},
 Blunderbuss={label='THUNDERMOUTH',category='shotgun',damage=16,pellets=8,spread=.11,range=115,cooldown=1.12,mag=2,reserve=36,reload=2.4,price=290,color=Color3.fromRGB(255,167,74),blast=0},
 Witchfire={label='WITCHFIRE STAFF',category='projectile',damage=62,range=240,cooldown=.83,mag=8,reserve=56,reload=2.8,price=420,color=Color3.fromRGB(173,91,255),blast=8},
 Rattler={label='SCRAP RATTLER',category='projectile',damage=13,range=240,cooldown=.095,mag=40,reserve=240,reload=2.4,price=520,color=Color3.fromRGB(87,240,160),blast=0},
 Boomstick={label='BOOMSTICK',category='projectile',damage=100,range=260,cooldown=1.3,mag=5,reserve=40,reload=2.7,price=690,color=Color3.fromRGB(255,132,50),blast=19},
 Soulrender={label='SOULRENDER',category='melee',damage=125,range=12,cooldown=.82,mag=0,reserve=0,reload=0,price=-2,color=Color3.fromRGB(204,115,255),blast=0},
 Godslayer={label='GODSLAYER',category='projectile',damage=100000,range=700,cooldown=1.8,mag=999,reserve=999,reload=.1,price=-1,color=Color3.fromRGB(92,255,120),blast=25},
}
C.Enemies = {
 Goblin={display='GOBLIN CUTTHROAT',health=145,damage=13,speed=12,range=5,windup=.5,cooldown=1.6,coins=18,attack='slash',color=Color3.fromRGB(113,178,78),zone='woods',level=1},
 Archer={display='BRAMBLE ARCHER',health=125,damage=13,speed=10,range=90,windup=.7,cooldown=2.8,coins=25,attack='arrow',color=Color3.fromRGB(126,182,86),zone='woods',level=2},
 Bandit={display='HIGHWAY BANDIT',health=175,damage=20,speed=15,range=5,windup=.46,cooldown=1.5,coins=33,attack='lunge',color=Color3.fromRGB(183,116,85),zone='woods',level=3},
 Wisp={display='ROT WISP',health=95,damage=17,speed=17,range=68,windup=.6,cooldown=2.3,coins=29,attack='orb',color=Color3.fromRGB(93,230,183),zone='marsh',level=3},
 Wizard={display='BOGGED WIZARD',health=235,damage=24,speed=10,range=100,windup=1.05,cooldown=3.0,coins=53,attack='meteor',color=Color3.fromRGB(156,113,225),zone='marsh',level=5},
 Knight={display='HOLLOW KNIGHT',health=380,damage=29,speed=10,range=7,windup=.85,cooldown=2.4,coins=82,attack='slam',color=Color3.fromRGB(121,145,157),zone='fort',level=6},
 Brute={display='CHAINBREAKER',health=550,damage=36,speed=10,range=11,windup=1.5,cooldown=3.1,coins=105,attack='slam',color=Color3.fromRGB(171,123,89),zone='fort',level=7},
 Boss={display='THE CROWNLESS WARDEN',health=3200,damage=42,speed=12,range=95,windup=1.2,cooldown=3.3,coins=1000,attack='boss',color=Color3.fromRGB(94,77,139),zone='fort',level=10},
}
C.Spawns = {
 {type='Goblin',pos=Vector3.new(-55,2.75,78)}, {type='Goblin',pos=Vector3.new(-10,2.75,125)}, {type='Goblin',pos=Vector3.new(55,2.75,94)},
 {type='Archer',pos=Vector3.new(20,2.75,156)}, {type='Archer',pos=Vector3.new(90,2.75,140)},
 {type='Bandit',pos=Vector3.new(105,2.75,41)}, {type='Bandit',pos=Vector3.new(160,2.75,96)},
 {type='Goblin',pos=Vector3.new(145,2.75,190)}, {type='Archer',pos=Vector3.new(-85,2.75,153)},
 {type='Wisp',pos=Vector3.new(-200,2.75,185)}, {type='Wisp',pos=Vector3.new(-265,2.75,220)},
 {type='Wizard',pos=Vector3.new(-175,2.75,263)}, {type='Wizard',pos=Vector3.new(-278,2.75,285)},
 {type='Knight',pos=Vector3.new(255,7.65,-50)}, {type='Knight',pos=Vector3.new(335,7.65,-15)},
 {type='Brute',pos=Vector3.new(285,7.65,-127)}, {type='Knight',pos=Vector3.new(360,7.65,-145)},
}
C.WorldEvents = {'BANDIT RAID','FALLING STAR','CURSED FOG','LOST CARAVAN'}
return C