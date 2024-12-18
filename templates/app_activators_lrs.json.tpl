{
  "title": "[% title %] - Left-Right Shift Sequence Triggers",
  "rules": [
    [%- SET first = 1 -%]
    [%- IF modifiers.lr_shift.quick_press -%]
    [%- FOREACH app IN modifiers.lr_shift.quick_press -%]
    [%- IF !first %],[% END -%]
    [%- SET first = 0 -%]
    {
      "description": "Left-Right shift quick press + [% app.trigger_key %] to [% app.app_name %]",
      "manipulators": [{
        "type": "basic",
        "conditions": [{
          "type": "variable_if",
          "name": "lr_shift",
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
            "name": "lr_shift",
            "value": 0
          }
        }]
      }]
    }
    [%- END -%]
    [%- END -%]
    [%- IF modifiers.lr_shift.long_press -%]
    [%- FOREACH app IN modifiers.lr_shift.long_press -%]
    ,[%- # Comma needed since we have quick_press items above -%]
    {
      "description": "Left-Right shift long press + [% app.trigger_key %] to [% app.app_name %]",
      "manipulators": [{
        "type": "basic",
        "conditions": [{
          "type": "variable_if",
          "name": "lr_shift",
          "value": 2
        }],
        "from": {
          "key_code": "[% app.trigger_key %]"
        },
        "to": [
          {
            "set_notification_message": {
              "id": "org.pqrs.long_lr_shift",
              "text": ""
            }
          },
          {
            "shell_command": "[% shell_command %] '[% app.app_name %]'"
          }
        ],
        "to_after_key_up": [{
          "set_variable": {
            "name": "lr_shift",
            "value": 0
          }
        }]
      }]
    }
    [%- END -%]
    [%- END -%]
  ]
}