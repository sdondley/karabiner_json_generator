{
  "title": "[% title %] - Double Tap Right Shift Triggers",
  "rules": [
    [%- SET first = 1 -%]
    [%- IF modifiers.double_tap_rshift.apps -%]
    [%- FOREACH app IN modifiers.double_tap_rshift.apps -%]
    [%- IF !first %],[% END -%]
    [%- SET first = 0 -%]
    {
      "description": "Double tap right shift-[% app.trigger_key %] to [% app.app_name %]",
      "manipulators": [{
        "type": "basic",
        "conditions": [{
          "type": "variable_if",
          "name": "double_tap_rshift",
          "value": 2
        }],
        "from": {
          "key_code": "[% app.trigger_key %]"
        },
        "to": [{
          "shell_command": "[% shell_command %] '[% app.app_name %]'"
        }
        ],
        "to_after_key_up": [{
          "set_variable": {
            "name": "double_tap_rshift",
            "value": 0
          }
        }]
      }]
    }
    [%- END -%]
    [%- END -%]
  ]
}