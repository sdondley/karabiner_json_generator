{
  "title": "Caps lock to escape",
  "rules": [
{
"description": "Change left control to <esc> if pressed alone",
"manipulators": [
    {
	"from": {
	    "key_code": "caps_lock"
	},
	"to": [
	    {
		"key_code": "left_control"
	    }
	],
	"to_if_alone": [
	    {
		"key_code": "escape"
	    }
	],
	"type": "basic"
    }
]
}
]
}