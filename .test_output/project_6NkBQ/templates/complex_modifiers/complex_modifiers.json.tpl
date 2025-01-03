{
  "title": "Complex Modifiers",
  "rules": [
                    {
                        "description": "Complex modifier: Double tap right shift",
                        "manipulators": [
                            {
                                "conditions": [
                                    {
                                        "name": "double_tap_rshift",
                                        "type": "variable_if",
                                        "value": 1
                                    }
                                ],
                                "from": { "key_code": "right_shift" },
                                "to": [ { "key_code": "right_shift" }                                ],
                                "to_delayed_action": {
                                    "to_if_canceled": [
                                        {
                                            "set_variable": {
                                                "name": "double_tap_rshift",
                                                "value": 0
                                            }
                                        },
                                        { "key_code": "right_shift" } ,     

                                        {
                                            "set_notification_message": {
                                                "id": "org.pqrs.double_tap_shift",
                                                "text": ""
                                            }
                                        }




                                    ],
                                    "to_if_invoked": [
                                        {
                                            "set_variable": {
                                                "name": "double_tap_rshift",
                                                "value": 0
                                            }
                                        },
                                        { "key_code": "right_shift" },     

                                        {
                                            "set_notification_message": {
                                                "id": "org.pqrs.double_tap_shift",
                                                "text": ""
                                            }
                                        }
                                    ]
                                },
                                "to_if_alone": [
                                    {
                                        "set_variable": {
                                            "name": "double_tap_rshift",
                                            "value": 2
                                        }
                                    },

                                        {
                                            "set_notification_message": {
                                                "id": "org.pqrs.double_tap_shift",
                                                "text": "2x Right Shift"
                                            }
                                        }

                                ],
                                "type": "basic"
                            },
                            {
                                "from": { "key_code": "right_shift" },
                                "to": { "key_code": "right_shift" },
                                "to_delayed_action": {
                                    "to_if_canceled": [
                                        {
                                            "set_variable": {
                                                "name": "double_tap_rshift",
                                                "value": 0
                                            }
                                        },
                                        { "key_code": "right_shift" }
                                    ],
                                    "to_if_invoked": [
                                        {
                                            "set_variable": {
                                                "name": "double_tap_rshift",
                                                "value": 0
                                            }
                                        }
                                    ]
                                },
                                "to_if_alone": [
                                    {
                                        "set_variable": {
                                            "name": "double_tap_rshift",
                                            "value": 1
                                        }
                                    }
                                ],
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "Complex modifier: Double tap left shift",
                        "manipulators": [
                            {
                                "conditions": [
                                    {
                                        "name": "double_tap_lshift",
                                        "type": "variable_if",
                                        "value": 1
                                    }
                                ],
                                "from": { "key_code": "left_shift" },
                                "to": [ { "key_code": "left_shift" } ],
                                "to_delayed_action": {
                                    "to_if_canceled": [
                                        {
                                            "set_variable": {
                                                "name": "double_tap_lshift",
                                                "value": 0
                                            }
                                        },
                                        { "key_code": "left_shift" },

                                        {
                                            "set_notification_message": {
                                                "id": "org.pqrs.double_tap_shift",
                                                "text": ""
                                            }
                                        }
                                    ],
                                    "to_if_invoked": [
                                        {
                                            "set_variable": {
                                                "name": "double_tap_lshift",
                                                "value": 0
                                            }
                                        },
                                        { "key_code": "left_shift" },

                                        {
                                            "set_notification_message": {
                                                "id": "org.pqrs.double_tap_shift",
                                                "text": ""
                                            }
                                        }
                                    ]
                                },
                                "to_if_alone": [
                                    {
                                        "set_variable": {
                                            "name": "double_tap_lshift",
                                            "value": 2
                                        }
                                    },

                                    {
                                        "set_notification_message": {
                                            "id": "org.pqrs.double_tap_shift",
                                            "text": "2x Left Shift"
                                        }
                                    }
                                ],
                                "type": "basic"
                            },
                            {
                                "from": { "key_code": "left_shift" },
                                "to": { "key_code": "left_shift" },
                                "to_delayed_action": {
                                    "to_if_canceled": [
                                        {
                                            "set_variable": {
                                                "name": "double_tap_lshift",
                                                "value": 0
                                            }
                                        },
                                        { "key_code": "left_shift" }
                                    ],
                                    "to_if_invoked": [
                                        {
                                            "set_variable": {
                                                "name": "double_tap_lshift",
                                                "value": 0
                                            }
                                        }
                                    ]
                                },
                                "to_if_alone": [
                                    {
                                        "set_variable": {
                                            "name": "double_tap_lshift",
                                            "value": 1
                                        }
                                    }
                                ],
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "Complex modifier: LR-shift & L-long-R-shift",
                        "manipulators": [
                            {
                                "conditions": [
                                    {
                                        "name": "lr_shift",
                                        "type": "variable_if",
                                        "value": 0
                                    }
                                ],
                                "from": {
                                    "key_code": "right_shift",
                                    "modifiers": { "mandatory": ["left_shift"] }
                                },
                                "parameters": { "basic.to_if_held_down_threshold_milliseconds": 150 },
                                "to": [
                                    {
                                        "set_variable": {
                                            "name": "lr_shift",
                                            "value": 1
                                        }
                                    },
                                    {
                                        "set_notification_message": {
                                            "id": "org.pqrs.long_lr_shift",
                                            "text": "LR shift"
                                        }
                                    }
                                ],
                                "to_if_held_down": [
                                    {
                                        "set_variable": {
                                            "name": "lr_shift",
                                            "value": 2
                                        }
                                    },
                                    {
                                        "set_notification_message": {
                                            "id": "org.pqrs.long_lr_shift",
                                            "text": "LR long shift pressed"
                                        }
                                    }
                                ],
                                "type": "basic"
                            },
                            {
                                "conditions": [
                                    {
                                        "name": "lr_shift",
                                        "type": "variable_if",
                                        "value": 1
                                    }
                                ],
                                "from": {
                                    "key_code": "right_shift",
                                    "modifiers": { "mandatory": ["left_shift"] }
                                },
                                "to": [
                                    {
                                        "set_variable": {
                                            "name": "lr_shift",
                                            "value": 0
                                        }
                                    },
                                    {
                                        "set_notification_message": {
                                            "id": "org.pqrs.long_lr_shift",
                                            "text": ""
                                        }
                                    }
                                ],
                                "type": "basic"
                            },
                            {
                                "conditions": [
                                    {
                                        "name": "lr_shift",
                                        "type": "variable_if",
                                        "value": 2
                                    }
                                ],
                                "from": {
                                    "key_code": "right_shift",
                                    "modifiers": { "mandatory": ["left_shift"] }
                                },
                                "to": [
                                    {
                                        "set_variable": {
                                            "name": "lr_shift",
                                            "value": 0
                                        }
                                    },
                                    {
                                        "set_notification_message": {
                                            "id": "org.pqrs.long_lr_shift",
                                            "text": ""
                                        }
                                    }
                                ],
                                "type": "basic"
                            }
                        ]
                    },
                    {
                        "description": "Complex modifier: RL-shift & R-long-L-shift",
                        "manipulators": [
                            {
                                "conditions": [
                                    {
                                        "name": "rl_shift",
                                        "type": "variable_if",
                                        "value": 0
                                    }
                                ],
                                "from": {
                                    "key_code": "left_shift",
                                    "modifiers": { "mandatory": ["right_shift"] }
                                },
                                "parameters": { "basic.to_if_held_down_threshold_milliseconds": 150 },
                                "to": [
                                    {
                                        "set_variable": {
                                            "name": "rl_shift",
                                            "value": 1
                                        }
                                    },
                                    {
                                        "set_notification_message": {
                                            "id": "org.pqrs.long_rl_shift",
                                            "text": "RL shift"
                                        }
                                    }
                                ],
                                "to_if_held_down": [
                                    {
                                        "set_variable": {
                                            "name": "rl_shift",
                                            "value": 2
                                        }
                                    },
                                    {
                                        "set_notification_message": {
                                            "id": "org.pqrs.long_rl_shift",
                                            "text": "RL long shift pressed"
                                        }
                                    }
                                ],
                                "type": "basic"
                            },
                            {
                                "conditions": [
                                    {
                                        "name": "rl_shift",
                                        "type": "variable_if",
                                        "value": 1
                                    }
                                ],
                                "from": {
                                    "key_code": "left_shift",
                                    "modifiers": { "mandatory": ["right_shift"] }
                                },
                                "to": [
                                    {
                                        "set_variable": {
                                            "name": "rl_shift",
                                            "value": 0
                                        }
                                    },
                                    {
                                        "set_notification_message": {
                                            "id": "org.pqrs.long_rl_shift",
                                            "text": ""
                                        }
                                    }
                                ],
                                "type": "basic"
                            },
                            {
                                "conditions": [
                                    {
                                        "name": "rl_shift",
                                        "type": "variable_if",
                                        "value": 2
                                    }
                                ],
                                "from": {
                                    "key_code": "left_shift",
                                    "modifiers": { "mandatory": ["right_shift"] }
                                },
                                "to": [
                                    {
                                        "set_variable": {
                                            "name": "rl_shift",
                                            "value": 0
                                        }
                                    },
                                    {
                                        "set_notification_message": {
                                            "id": "org.pqrs.long_rl_shift",
                                            "text": ""
                                        }
                                    }
                                ],
                                "type": "basic"
                            }
                        ]
                    }
  ]
}