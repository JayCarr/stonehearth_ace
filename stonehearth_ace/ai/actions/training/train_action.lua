local Train = class()

Train.name = 'train'
Train.status_text_key = 'stonehearth_ace:ai.actions.status_text.train'
Train.does = 'stonehearth_ace:train'
Train.args = {}
Train.priority = 1

local log = radiant.log.create_logger('training_action')
local combat = stonehearth.combat

-- the entity first checks to see if they're below level 6 and have training enabled
-- then they seek out a training dummy and acquire a lease on it
-- then they run to a position where they're in range of attacking it
-- then they play their attack animation to "damage" the dummy and gain experience and release their lease
-- this is the end of the action; they may then decide to do it again and might choose a slightly different position

function Train:start_thinking(ai, entity, args)
	-- check if we're eligible (below level 6, training enabled)
	local job_component = entity:get_component('stonehearth:job')
	if job_component:is_max_level() then
		ai:reject('entity is max level, cannot train')
		return
	end
	if radiant.entities.get_attribute(entity, 'stonehearth_ace:training_enabled', 'true') ~= 'true' then
		ai:reject('training is disabled for this entity')
		return
	end
	ai:set_think_output()
end

function find_training_dummy(entity)
	stonehearth.ai:filter_from_key('stonehearth_ace:training_dummy', entity:get_player_id(),
		function(target)
			if stonehearth.player:are_entities_friendly(entity, target) then
				log:error('checking for training_dummy component')
				return target:get_component('stonehearth_ace:training_dummy') ~= nil
			end
			return false
		end)
end

function find_training_location(entity, target)
	local weapon = combat:get_main_weapon(entity)
	local weapon_data = combat:get_main_weapon(entity)
	local min_range, max_range
	if weapon_data.range then
		-- it's a ranged combat class so get the range including any bonus range
		min_range = 1
		max_range = combat:get_weapon_range(entity, weapon)
	else
		-- otherwise it's melee so get the reach
		min_range, max_range = get_melee_range(entity, weapon_data, self._entity)
	end

	-- determine the direction the target is facing
	-- get a location at max_range in front of the target
	-- test and go closer until it's a valid location (i.e., it has line of sight; don't worry about reachability for now)

	local location

	return location
end

local ai = stonehearth.ai
return ai:create_compound_action(Train)
         :execute('stonehearth:abort_on_event_triggered', {
            source = ai.ENTITY,
            event_name = 'stonehearth:work_order:job:work_player_id_changed',
         })
         :execute('stonehearth:drop_backpack_contents_on_ground', {})
		 :execute('stonehearth:set_posture', { posture = 'stonehearth:combat' })
         :execute('stonehearth:find_best_reachable_entity_by_type', 
					{ filter_fn = ai.CALL(find_training_dummy, ai.ENTITY), target = ai.ENTITY})
         :execute('stonehearth:reserve_entity', { entity = ai.PREV.item })
         :execute('stonehearth:find_path_to_location', { location = ai.CALL(find_training_location, ai.ENTITY, ai.BACK(2).item) })
		 :execute('stonehearth:follow_path', { path = ai.PREV.path })
	-- now can we just tell our entity to attack the target, even though it's not an enemy?