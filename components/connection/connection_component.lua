--[[
connection json structure:
connector regions are typically a 2-voxel region, including one voxel inside the entity and another outside it
"stonehearth_ace:connection": {
   "type1": {
      "connectors": {
         "connector1": {
            "region": {
               "min": { "x": -1, "y": 0, "z": 0 },
               "max": { "x": 1, "y": 1, "z": 1 }
            },
            "max_connections": 1,
            "region_intersection_threshold": 1,
            "info": {}
         },
         "connector2": {
            "region": {
               "min": { "x": 0, "y": 0, "z": 0 },
               "max": { "x": 2, "y": 1, "z": 1 }
            },
            "max_connections": 1,
            "info": {}
         }
      },
      "max_connections": 1
   }
}
]]

local ConnectionComponent = class()

function ConnectionComponent:initialize()
   local json = radiant.entities.get_json(self)
   self._connections = json or {}
end

-- this is performed in activate rather than post_activate so that all specific connection services can use it in post_activate
function ConnectionComponent:activate()
   stonehearth_ace.connection:register_entity(self._entity, self._connections)
end

function ConnectionComponent:destroy()
   stonehearth_ace.connection:unregister_entity(self._entity)
end

return ConnectionComponent