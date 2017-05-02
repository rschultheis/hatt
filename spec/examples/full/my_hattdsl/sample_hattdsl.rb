def a_hatt_method(_arg1)
  'return value'
end

def show_the_state_var
  @some_state_var ||= 0
  @some_state_var
end

def increment_the_state_var
  show_the_state_var
  @some_state_var += 1
  show_the_state_var
end
