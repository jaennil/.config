import catppuccin

config.load_autoconfig(False)

catppuccin.setup(c, 'mocha')

c.editor.command = ['alacritty', '-e', 'nvim', '{file}']

config.bind('<Alt++>', 'tab-focus 1')
config.bind('<Alt+[>', 'tab-focus 2')
config.bind('<Alt+{>', 'tab-focus 3')
config.bind('<Alt+(>', 'tab-focus 4')
config.bind('<Alt+&>', 'tab-focus 5')
config.bind('<Alt+=>', 'tab-focus 6')
config.bind('<Alt+)>', 'tab-focus 7')
config.bind('<Alt+}>', 'tab-focus 8')
config.bind('<Alt+]>', 'tab-focus -1')

