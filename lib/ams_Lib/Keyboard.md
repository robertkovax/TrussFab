## Utilizing Keyboard
The sample code below demonstrates a way to retrieve key up/down state.

    # The vk can be any of the keys bellow.
    # The vk is not case sensitive.
    vk = "space"
    AMS::Keyboard.key(vk) # => 1 (if down) or 0 (if up)

See {AMS::Keyboard} for all keyboard functions.


## Virtual Key Names
The following virtual key names are available both on Windows and Mac OS X.
Information within the comments, separated by spaces, provides aliases for a
virtual key.


### Numbers
    '0'                 # ) closeparenthese rightparenthese
    '1'                 # ! exclamation exclamationmark
    '2'                 # @ at atsign
    '3'                 # # number numbersign hash
    '4'                 # $ dollar dollarsign
    '5'                 # % percent
    '6'                 # ^ caret
    '7'                 # & ampersand
    '8'                 # * asterick
    '9'                 # ( openparenthese leftparenthese

### Letters
    'a'
    'b'
    'c'
    'd'
    'e'
    'f'
    'g'
    'h'
    'i'
    'j'
    'k'
    'l'
    'm'
    'n'
    'o'
    'p'
    'q'
    'r'
    's'
    't'
    'u'
    'v'
    'w'
    'x'
    'y'
    'z'

### Pad
    'numpad0'           # keypad0
    'numpad1'           # keypad1
    'numpad2'           # keypad2
    'numpad3'           # keypad3
    'numpad4'           # keypad4
    'numpad5'           # keypad5
    'numpad6'           # keypad6
    'numpad7'           # keypad7
    'numpad8'           # keypad8
    'numpad9'           # keypad9

    'numpadmultiply'    # keypadmultiply    keypad*     numpad*
    'numpaddivide'      # keypaddivide      keypad/     numpad/
    'numpadplus'        # keypadplus        keypad+     numpad+
    'numpadminus'       # keypadminus       keypad-     numpad-
    'numpaddecimal'     # keypaddecimal     keypad.     numpad.

### Syntax
    'backslash'         # verticalbar | "\\"
    'comma'             # , <
    'equals'            # plus + =
    'grave'             # tilde ~ `
    'leftbracket'       # openbracket openbrace leftbrace { [
    'minus'             # dash underscore _ -
    'period'            # . >
    'quote'             # quotation quotationmark apostrophe ' "\""
    'rightbracket'      # closebracket closebrace rightbrace } ]
    'semicolon'         # colon : ;
    'slash'             # question questionmark ? /

### F keys
    'f1'
    'f2'
    'f3'
    'f4'
    'f5'
    'f6'
    'f7'
    'f8'
    'f9'
    'f10'
    'f11'
    'f12'
    'f13'
    'f14'
    'f15'
    'f16'
    'f17'
    'f18'
    'f19'
    'f20'

### Arrows
    'up'                # uparrow ↑
    'down'              # downarrow ↓
    'left'              # leftarrow ←
    'right'             # rightarrow →

### Volume
    'mute'
    'volumedown'
    'volumeup'

### Other
    'lcontrol'          # lctrl
    'rcontrol'          # rctrl
    'lmenu'             # lalt loption
    'rmenu'             # ralt roption
    'lshift'
    'rshift'

    'capslock'          # capital
    'backspace'         # back
    'delete'
    'end'
    'escape'            # esc
    'help'
    'home'
    'pageup'            # prior
    'pagedown'          # next
    'return'            # enter
    'space'             # spacebar " "
    'tab'


## Virtual Key Names for Windows
Additional virtual key names reserved for Windows.
Information within the comments provides aliases for a virtual key.
See also [Virtual-Key Codes](http://msdn.microsoft.com/en-us/library/windows/desktop/dd375731(v=vs.85).aspx)

    'lbutton'
    'rbutton'
    'cancel'
    'mbutton'
    'xbutton1'
    'xbutton2'
    'clear'
    'return'
    'shift'
    'control'           # ctrl
    'menu'              # alt option
    'pause'             # break
    'kana'
    'handuel'
    'hangul'
    'junja'
    'final'
    'hanja'
    'hanji'
    'convert'
    'nonconvert'
    'accept'
    'modechange'
    'select'
    'print'
    'execute'
    'snapshot'          # printscreen prtscn sysrq
    'insert'
    'lwin'
    'rwin'
    'apps'
    'sleep'
    'separator'
    'f21'
    'f22'
    'f23'
    'f24'
    'numlock'
    'scroll'            # scrolllock scrlk
    'browserback'
    'browserforward'
    'browserrefresh'
    'browserstop'
    'browsersearch'
    'browserfavorites'
    'browserhome'
    'medianexttrack'        # medianext
    'mediaprevtrack'        # mediaprev
    'mediastop'
    'mediaplaypause'        # mediatoggleplay
    'launchmail'            # mail
    'launchmediaselect'     # mediaselect
    'launchapp1'            # app1
    'launchapp2'            # app2
    'oem8'
    'attn'
    'crsel'
    'exsel'
    'ereof'
    'play'
    'zoom'
    'pa1'
    'oemclear'


## Virtual Key Names for Mac OS X
Additional virtual key names reserved for Mac OS X.

    'numpadclear'
    'numpadenter'
    'numpadequals'

    'command'
    'function'

    # Key names for ISO keyboards only
    'section'

    # Key names for JIS keyboards only
    'yen'
    'underscore'
    'keypadcomma'
    'eisu'
    'kana'
