{"title":"[% title %]","rules":[
{
  "description":"Complex modifier: LR-shift hotkey",
  "manipulators":[{
    "type":"basic",
    "conditions":[{
      "type":"variable_if",
      "name":"lr_shift",
      "value":0
    }],
    "from":{
      "key_code":"right_shift",
      "modifiers":{"mandatory":["left_shift"]}
    },
    "parameters":{
      "basic.to_if_held_down_threshold_milliseconds":150
    },
    "to":[{
      "set_variable":{
        "name":"lr_shift",
        "value":1
      }
    }],
    "to_if_held_down":[{
      "set_variable":{
        "name":"lr_shift",
        "value":2
      }
    },{
      "set_notification_message":{
        "id":"org.pqrs.long_lr_shift",
        "text":"LR shift pressed"
      }
    }]
  },{
    "type":"basic",
    "conditions":[{
      "type":"variable_if",
      "name":"lr_shift",
      "value":1
    }],
    "from":{
      "key_code":"right_shift",
      "modifiers":{"mandatory":["left_shift"]}
    },
    "to":[{
      "set_variable":{
        "name":"lr_shift",
        "value":0
      }
    }]
  },{
    "type":"basic",
    "conditions":[{
      "type":"variable_if",
      "name":"lr_shift",
      "value":2
    }],
    "from":{
      "key_code":"right_shift",
      "modifiers":{"mandatory":["left_shift"]}
    },
    "to":[{
      "set_variable":{
        "name":"lr_shift",
        "value":0
      }
    }]
  }]
},{
  "description":"Complex modifier: RL-shift hotkey",
  "manipulators":[{
    "type":"basic",
    "conditions":[{
      "type":"variable_if",
      "name":"rl_shift",
      "value":0
    }],
    "from":{
      "key_code":"left_shift",
      "modifiers":{"mandatory":["right_shift"]}
    },
    "parameters":{
      "basic.to_if_held_down_threshold_milliseconds":150
    },
    "to":[{
      "set_variable":{
        "name":"rl_shift",
        "value":1
      }
    }],
    "to_if_held_down":[{
      "set_variable":{
        "name":"rl_shift",
        "value":2
      }
    },{
      "set_notification_message":{
        "id":"org.pqrs.long_rl_shift",
        "text":"RL shift pressed"
      }
    }]
  },{
    "type":"basic",
    "conditions":[{
      "type":"variable_if",
      "name":"rl_shift",
      "value":1
    }],
    "from":{
      "key_code":"left_shift",
      "modifiers":{"mandatory":["right_shift"]}
    },
    "to":[{
      "set_variable":{
        "name":"rl_shift",
        "value":0
      }
    }]
  },{
    "type":"basic",
    "conditions":[{
      "type":"variable_if",
      "name":"rl_shift",
      "value":2
    }],
    "from":{
      "key_code":"left_shift",
      "modifiers":{"mandatory":["right_shift"]}
    },
    "to":[{
      "set_variable":{
        "name":"rl_shift",
        "value":0
      }
    }]
  }]
},[%- SET outputted = [] -%]
[%- FOREACH modifier_name = modifiers.keys -%]
[%- SET modifier = modifiers.$modifier_name -%]
[%- IF modifier.apps -%]
[%- FOREACH app IN modifier.apps -%]
[%- IF outputted.size > 0 %],[% END -%]
[%- outputted.push(1) -%]
{
  "description":"[% IF modifier_name == 'double_tap_rshift' %]Double tap right shift[% ELSIF modifier_name == 'double_tap_lshift' %]Double tap left shift[% ELSIF modifier_name == 'lr_shift' %]Left then right shift[% ELSIF modifier_name == 'rl_shift' %]Right then left shift[% END %]-[% app.trigger_key %] to [% app.app_name %]",
  "manipulators":[{
    "type":"basic",
    "conditions":[{
      "type":"variable_if",
      "name":"[% modifier_name %]",
      "value":2
    }],
    "from":{
      "key_code":"[% app.trigger_key %]"
    },
    "to":[{
      "shell_command":"[% shell_command %] '[% app.app_name %]'"
    }],
    "to_after_key_up":[{
      "set_variable":{
        "name":"[% modifier_name %]",
        "value":0
      }
    }]
  }]
}[%- END -%]
[%- ELSE -%]
[%- FOREACH app IN modifier.quick_press -%]
[%- IF outputted.size > 0 %],[% END -%]
[%- outputted.push(1) -%]
{
  "description":"[% IF modifier_name == 'lr_shift' %]Left then right shift[% ELSE %]Right then left shift[% END %]-[% app.trigger_key %] to [% app.app_name %]",
  "manipulators":[{
    "type":"basic",
    "conditions":[{
      "type":"variable_if",
      "name":"[% modifier_name %]",
      "value":1
    }],
    "from":{
      "key_code":"[% app.trigger_key %]"
    },
    "to":[{
      "shell_command":"[% shell_command %] '[% app.app_name %]'"
    },{
      "set_variable":{
        "name":"[% modifier_name %]",
        "value":0
      }
    }]
  }]
}[%- END -%]
[%- FOREACH app IN modifier.long_press -%]
[%- IF outputted.size > 0 %],[% END -%]
[%- outputted.push(1) -%]
{
  "description":"[% IF modifier_name == 'lr_shift' %]Left then long right shift[% ELSE %]Right then long left shift[% END %]-[% app.trigger_key %] to [% app.app_name %]",
  "manipulators":[{
    "type":"basic",
    "conditions":[{
      "type":"variable_if",
      "name":"[% modifier_name %]",
      "value":2
    }],
    "from":{
      "key_code":"[% app.trigger_key %]"
    },
    "to":[{
      "shell_command":"[% shell_command %] '[% app.app_name %]'"
    },{
      "set_variable":{
        "name":"[% modifier_name %]",
        "value":0
      }
    }]
  }]
}[%- END -%]
[%- END -%]
[%- END -%]
]}