-- Blossom UI Library public entry point.
-- Install `build/Blossom.rbxmx` into ReplicatedStorage as Blossom, then require this
-- ModuleScript from a LocalScript. This file intentionally contains no game logic.
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local implementation = ReplicatedStorage:WaitForChild('Blossom')
assert(implementation:IsA('ModuleScript'), 'ReplicatedStorage.Blossom must be the built Blossom library model')
return require(implementation)
