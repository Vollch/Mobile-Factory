if global.allowMigration == false then return end
-- Reset MF to all Internal Quatron Cube --
for k, MF in pairs(global.MFTable) do
    MF.internalQuatronObj.MF = MF
end