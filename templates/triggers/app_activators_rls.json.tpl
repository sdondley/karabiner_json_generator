{
  "title": "[% title %] - Right-Left Shift Sequence Triggers",
  "rules": [
    [%- SET first = 1 -%]
    [%- IF modifiers.rl_shift.quick_press -%]
    [%- FOREACH app IN modifiers.rl_shift.quick_press -%]
    [%- IF !first %],[% END -%]
    [%- SET first = 0 -%]
    {
      "description": "Right-Left shift quick press + [% app.trigger_key %] to [% app.app_name %]",
      "manipulators": [{
        "type": "basic",
        "conditions": [{
          "type": "variable_if",
          "name": "rl_shift",
          "value": 1
        }],
        "from": {
          "key_code": "[% app.trigger_key %]"
        },
        "to": [{
          "shell_command": "[% shell_command %] '[% app.app_name %]'"
        }],
        "to_after_key_up": [{
          "set_variable": {
            "name": "rl_shift",
            "value": 0
          }
        }]
      }]
    }
    [%- END -%]
    [%- END -%]
    [%- IF modifiers.rl_shift.long_press -%]
    [%- FOREACH app IN modifiers.rl_shift.long_press -%]
    ,[%- # Comma needed since we have quick_press items above -%]
    {
      "description": "Right-Left shift long press + [% app.trigger_key %] to [% app.app_name %]",
      "manipulators": [{
        "type": "basic",
        "conditions": [{
          "type": "variable_if",
          "name": "rl_shift",
          "value": 2
        }],
        "from": {
          "key_code": "[% app.trigger_key %]"
        },
        "to": [
          {
            "set_notification_message": {
              "id": "org.pqrs.long_rl_shift",
              "text": ""
            }
          },
          {
            "shell_command": "[% shell_command %] '[% app.app_name %]'"
          }
        ],
        "to_after_key_up": [{
          "set_variable": {
            "name": "rl_shift",
            "value": 0
          }
        }]
      }]
    }
    [%- END -%]
    [%- END -%]
  ]
}