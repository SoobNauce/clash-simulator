ORCHID_SKILLS = {
  na: ["Normal Attack: Poke", 9, 1, 2],# 10
  s1: ["Skill 1: Initiate", 8, 2, 3],# 11
  s2: ["Skill 2: Unload", 4, 2, 8]# 12
}.freeze
ORCHID_WEIGHTS = {
  na: 3,
  s1: 2,
  s2: 1
}.freeze
MIKO_SKILLS = {
  na: ["Normal Attack: Gambler's Cut", 6, 1, 8],# 10
  s1: ["Skill 1: Roll the Dice", 6, 1, 10],# 11
  s2: ["Skill 2: The House Always Wins", 7, 5, 2]# 12
}.freeze
BLADEDANCER_SKILLS = {
  na: ["Normal Attack: Totter", 1,1,18],# 10
  s1: ["Skill 1: Overwhelm", 16, 4,-4],# ??
  s2: ["Skill 2: Shaky Hands", 20, 1, -20]
}.freeze
MIKO_WEIGHTS = ORCHID_WEIGHTS.dup
BLADEDANCER_WEIGHTS = ORCHID_WEIGHTS.dup