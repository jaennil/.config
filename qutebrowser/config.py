config.load_autoconfig(False)

c.editor.command = ['alacritty', '-e', 'nvim', '{file}']

config.bind('<Alt++>', 'tab-focus 1')
config.bind('<Alt+[>', 'tab-focus 2')
config.bind('<Alt+{>', 'tab-focus 3')
config.bind('<Alt+(>', 'tab-focus 4')
config.bind('<Alt+&>', 'tab-focus 5')
config.bind('<Alt+=>', 'tab-focus 6')
config.bind('<Alt+)>', 'tab-focus 7')
config.bind('<Alt+}>', 'tab-focus 8')
config.bind('<Alt+]>', 'tab-focus 9')
config.bind('<Alt+*>', 'tab-focus -1')

c.content.proxy = "http://127.0.0.1:8888"
c.auto_save.session = True
