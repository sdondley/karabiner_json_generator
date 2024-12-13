# Karabiner JSON Rule Generator with Complex Modifiers™️

## About
This repo is primarily designed to showcase the Complex Modifiers™️ Ruleset which
provides a set of easy-to-install modifiers for your K-E configuration. So have
a look at the **complex_modifiers.json** file first. If you like what you see,
download it and install the Complex Modifiers™️ json file into your K-E
configuration, activate the Complex Modifiers™️  you wish to use and be on your
way.

If you're feeling a little lost or are curious about what the JSON generator script
might do for you, read on.

### What's Inside This Repo
* A (mostly) hand-crafted **complex_modifiers.json** config containing the "Complex
  Modifiers"™️. This is what you came here for. This script is ready for you to 
  install directly into your K-E configuration.
* A (mostly AI-generated) Perl script, **bin/json_generator.pl**, with modular
  components in the `lib/` directory for converting your YAML configurations and
  JSON templates into K-E JSON files.
* A global configuration YAML file for setting up paths and global options
* A sample config YAML file with app-specific configurations. If you want to use
  it, you'll probably want to change it first.
* An app_activators.json sample file in the generated json directory, generated
  by the json_generator.pl script. Notes that if you install it, it will not
  work on your machine.
* The template file for the app_activators.json.tpl file in the `templates`
  directory. You'll definitely need to change this before generating new JSON
  files with it.
* Test files in the `t/` directory ensuring code reliability
* This README file

## Big Picture Overview

### Complex Modifiers™️ Ruleset: What is it?
Not to be confused with complex *modifications*, the Complex Modifier™️ Ruleset
is just a set of key combination definitions designed to make it a no-brainer
for you to add modifiers to your existing K-E configuration. 

The current ruleset version consists of six complex modifiers:

- **Double Tap Right Shift**: This complex modifier gets activated when the
  right shift key is double-tapped. You then have to press a trigger key before
  the timeout setting to trigger an action.
- **Double Tap Left Shift**: Same as double tapping right shift key
- **LR-Shift**: This involves holding down the left shift and then pressing the
  right shift key. K-E then wait indefinitely for you to hit a trigger key. If
  you change your mind and you don't want to trigger anything, you can clear the
  state by doing left-right shift again. 
- **RL-Shift**: Same as LR-Shift but with the right shift key held down and the
  left shift key pressed.
- **LR-Shift Long Press**: Like LR-Shift but with a long press on the right
  shift key. A notification will pop up to let you know that the long press has
  registered.
- **RL-Shift Long Press**: Same as LR-Shift but with the right shift key held
  down and the left shift key long pressed.

If you just want the Complex Modifiers™️, you can skip everything below. Simply
copy over the commplex_modifications.json file into your K-E
`complex_modifications` directory. By default, this is found at:
`~/.config/karabiner/assets/complex_modifications`.

Then enable the desired complex modifiers in the K-E Complex Modifications tab.

Note that the LR-Shift and RL-Shift modifiers include the long press
modifiers by default.

### Trigger Keys Ruleset
By themselves, the complex modifiers don't do anything. You also need to add
trigger keys to your K-E configuration. The `app_activators.json` file is a
sample file that contains definitions for triggers keys that use the Complex
Modifiers™️. 

You have two options: write your own trigger keys from scratch or use the
script provided in this repository below to generate them.

If you want to roll your own, it's probably easiest to install the app_activators.json file
into K-E and then change it as needed in K-E using its crude editor.

If you want to try the Perl script file to generate the triggers, read on.

## Getting It Working

The steps below assume you know a little bit about adding rulesets to K-E, so it
doesn't go into great detail on where to click. If you are unclear, consult the
K-E documentation at:
https://karabiner-elements.pqrs.org/docs/getting-started/configuration/.

### Configuration
1. (Optional) Configure the global_config.yaml file if you need to override
   default paths:
   - Karabiner CLI path (defaults to `/Library/Application
     Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli`)
   - Config directory (defaults to `~/.config/karabiner`)
   - Complex modifications directory (defaults to
     `~/.config/karabiner/assets/complex_modifications`)

2. Configure your app-specific settings in config.yaml. Use the supplied example
   file as reference.

### Generating and Installing JSON Files
The script now supports automatic validation and installation of your generated configurations:

1. To generate JSON files with validation:
   ```bash
   perl json_generator.pl
   ```
   This will:
   - Generate the JSON files
   - Validate them using the Karabiner CLI
   - Ask if you want to install them to your complex modifications directory
   Note: There's a good chance you will be missing some required Perl modules
   that the script needs to work. Follow the helpful instructions after the
   error message for getting them installed. 

2. For automatic installation of the generated json file into K-E after validation:
   ```bash
   perl bin/json_generator.pl -i
   ```

3. For debugging output:
   ```bash
   perl bin/json_generator.pl -d
   ```

4. For quiet mode with minimal output:
   ```bash
   perl bin/json_generator.pl -q
   ```

5. You can combine flags:
   ```bash
   perl bin/json_generator.pl -d -i   # Debug mode with auto-install
   perl bin/json_generator.pl -q -i   # Quiet mode with auto-install
   ```

The script will:
- Generate JSON files from your templates and configurations
- Validate the generated files using Karabiner's built-in validator
- Optionally install the files to your complex modifications directory
- Provide clear feedback about the process with emoji-formatted status messages

### Activation of Complex Modifiers™️ Rulesets
To use these rulesets:
1. If you haven't used the automatic installation option, manually copy the complex_modifiers.json file into the Karabiner-Elements configuration directory
2. Go to the 'Complex Modifications' tab in Karabiner-Elements
3. Add in the complex modifiers you wish to use with your triggers

## Bugs, Suggestions, Questions?
Drop a message in the issue queue. I'll do my best to address your input.

Once this is refined and tested more, I'll drop the Complex Modifiers™️ into the public K-E JSON repo.