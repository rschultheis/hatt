flat_scoped_state = 1

def get_current_state
  flat_scoped_state
end

def increment_state
  flat_scoped_state += 1
end

def get_instance_var
  @instance_var ||= 100
end

def increment_instance_var
  @instance_var += 100
end

SOME_HASH_STATE = {}

def get_hash_state_value
  SOME_HASH_STATE[:value] ||= 1000
end

def increment_hash_state_value
  SOME_HASH_STATE[:value] += 1000
end
