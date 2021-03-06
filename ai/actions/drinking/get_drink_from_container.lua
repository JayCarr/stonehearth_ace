local Entity = _radiant.om.Entity
local GetDrinkFromContainer = class()

GetDrinkFromContainer.name = 'get drink from container'
GetDrinkFromContainer.does = 'stonehearth_ace:get_drink'
GetDrinkFromContainer.args = {
   drink_filter_fn = 'function',
   drink_rating_fn = 'function',
}
GetDrinkFromContainer.think_output = {
   drink_container_filter_fn = 'function',
   max_distance = 'number'
}
GetDrinkFromContainer.priority = {0, 1}

local log = radiant.log.create_logger('get_drink_from_container')

local function _should_reserve(drink_container)
   local container_data = radiant.entities.get_entity_data(drink_container, 'stonehearth_ace:drink_container')
   if container_data then
      return (container_data.stacks_per_serving or 1) > 0
   end
end

local function make_drink_container_filter(owner_id, drink_filter_fn)
   return function(item)
         if not radiant.entities.get_entity_data(item, 'stonehearth_ace:drink_container') then
            return false
         end
         if owner_id ~= '' then
            local player_id = radiant.entities.get_player_id(item)
            if player_id ~= '' and player_id ~= owner_id then
               return false
            end
         end
         return drink_filter_fn(item)
      end
end

function GetDrinkFromContainer:start_thinking(ai, entity, args)
   self._ready = false
   self._max_distance = nil
   self._ai = ai
   self._entity = entity
   local owner_id = radiant.entities.get_player_id(entity)
   local key = tostring(args.drink_filter_fn) .. ':' .. owner_id
   self._drink_container_filter_fn = stonehearth.ai:filter_from_key('drink_container_filter', key, make_drink_container_filter(owner_id, args.drink_filter_fn))

   self._delay_start_timer = radiant.on_game_loop_once('GetDrinkFromContainer start_thinking', function()
         -- listen for drink satiety level changes
         self._drink_satiety_listener = radiant.events.listen(self._entity, 'stonehearth:expendable_resource_changed:drink_satiety', self, self._reconsider)
         self:_reconsider()
      end)
end

function GetDrinkFromContainer:_reconsider()
   local max_distance
   local consumption = self._entity:get_component('stonehearth:consumption')
   local state = consumption and consumption:get_drink_satiety_state()
   if state == stonehearth.constants.drink_satiety_levels.VERY_THIRSTY then
      max_distance = stonehearth.constants.drink_max_distance.VERY_THIRSTY
   elseif state == stonehearth.constants.drink_satiety_levels.THIRSTY then
      max_distance = stonehearth.constants.drink_max_distance.THIRSTY
   else
      max_distance = stonehearth.constants.drink_max_distance.DEFAULT
   end

   --log:debug('%s reconsidering state %s (%s -> %s)', self._entity, tostring(state), tostring(self._max_distance), max_distance)
   if max_distance ~= self._max_distance then
      local set_think_output = function()
         self:_destroy_reconsidering_listener()
         self._max_distance = max_distance
         --log:debug('%s set_think_output', self._entity)
         self._ai:set_think_output({
            drink_container_filter_fn = self._drink_container_filter_fn,
            max_distance = max_distance
         })
      end

      if self._ready then
         self:_destroy_reconsidering_listener()
         self._ai:clear_think_output()
         self._reconsidering_listener = radiant.on_game_loop_once('setting think output', function()
            set_think_output()
         end)
      else
         self._ready = true
         set_think_output()
      end
   end
end

function GetDrinkFromContainer:stop_thinking(ai, entity, args)
   self:_destroy_listener()
end

function GetDrinkFromContainer:_destroy_listener()
   if self._delay_start_timer then
      self._delay_start_timer:destroy()
      self._delay_start_timer = nil
   end
   if self._drink_satiety_listener then
      self._drink_satiety_listener:destroy()
      self._drink_satiety_listener = nil
   end
   self:_destroy_reconsidering_listener()
end

function GetDrinkFromContainer:_destroy_reconsidering_listener()
   if self._reconsidering_listener then
      self._reconsidering_listener:destroy()
      self._reconsidering_listener = nil
   end
end

function GetDrinkFromContainer:compose_utility(entity, self_utility, child_utilities, current_activity)
   return child_utilities:get('stonehearth_ace:find_best_close_reachable_entity_by_type')
end

local ai = stonehearth.ai
return ai:create_compound_action(GetDrinkFromContainer)
         :execute('stonehearth:drop_carrying_now', {})
         :execute('stonehearth_ace:find_best_close_reachable_entity_by_type', {
            filter_fn = ai.BACK(2).drink_container_filter_fn,
            rating_fn = ai.ARGS.drink_rating_fn,
            description = 'drink container filter',
            max_distance = ai.BACK(2).max_distance
         })
         :execute('stonehearth:find_path_to_reachable_entity', {
            destination = ai.PREV.item
         })
         :execute('stonehearth:follow_path', { path = ai.PREV.path })
         :execute('stonehearth:reserve_entity', { entity = ai.BACK(3).item })
         :execute('stonehearth_ace:get_drink_from_container_adjacent', { container = ai.BACK(4).item })