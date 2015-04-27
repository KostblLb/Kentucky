#manual Conversation file translator for Kentucky Route Zero game
#todo: убрать пустые полоски, сделать копипасту и пометки о том, что фрагмент не совпадает с оригиналом или переведён только что
$:.unshift File.dirname($0)
require 'gtk2'
load 'kxml.rb'

kdoc, ktree, ktree_t, $treepath = nil

mainWindow = Gtk::Window.new("Kentucky: A manual Conversation file translator")
mainWindow.set_default_size(500, 400)
mainWindow.signal_connect("delete_event") do
	Gtk::main_quit
end

mainBox = Gtk::VBox.new # menu, tree/textboxes, state string
vBox = Gtk::VBox.new # textbox, textbox
panBox = Gtk::HPaned.new # tree | textboxes
panBox.set_size_request(300,-1)
label = Gtk::Label.new("filename here")
label.justify = Gtk::JUSTIFY_LEFT

mainWindow.add(mainBox)

treeStore = Gtk::TreeStore.new(String)
list = Gtk::TreeView.new(treeStore)
renderer = Gtk::CellRendererText.new
renderer.background = 'green'
renderer.background_set=false
col = Gtk::TreeViewColumn.new("Сцены", renderer, :text => 0)
list.append_column(col)
def open_doc(filename, ts)
	$treepath = nil
	kdoc = Kxml.new filename
	ktree = kdoc.make_tree(true) #true for original
	ktree_t = kdoc.make_tree(false)
	ts.clear
	ktree.each do |scene|
		parent = ts.append(nil)
		parent.set_value(0,scene[0])
		scene[1].each do |line|
			child = ts.append(parent)
			if /\n/.match(line[0])
				next
			end
			child.set_value(0,line[0])
			if line[1].match(/w+/)
				grandchild = ts.append(child)
				grandchild.set_value(0, line[1])
			end
		end
	end
	#fill array with .conversation files
	$dir_entries = []
	$dir_entries_i = 0
	$dir = File.dirname(filename)
	name = filename.dump
	@dir,name = *File.split(filename)
	i=0
	Dir.foreach($dir) do |entry|
		if name.match entry
			puts "OK"
			$dir_entries_i = i
		end
		if /.conversation/.match File.extname(entry) 
			# or /.xml/.match File.extname(entry)
			$dir_entries<<entry
			i+=1
		end
	end
	puts name
	puts $dir
	puts $dir_entries.to_s
	puts $dir_entries_i
	puts i
	return *[kdoc, ktree, ktree_t]
end

textBufferOriginal = Gtk::TextBuffer.new
textBufferOriginal.text="Оригинал"
textBufferTranslation = Gtk::TextBuffer.new
textBufferTranslation.text = "Перевод"

textFieldOriginal = Gtk::TextView.new
textFieldOriginal.wrap_mode = Gtk::TextTag::WRAP_WORD
textFieldOriginal.buffer=textBufferOriginal
textFieldTranslation = Gtk::TextView.new
textFieldTranslation.wrap_mode = Gtk::TextTag::WRAP_WORD
textFieldTranslation.buffer = textBufferTranslation

list.signal_connect("row-activated") do |view, path, column|
	$treepath = path.indices
	scene=path.indices[0]
	line=path.indices[1]
	inserted=path.indices[2]
	if inserted
		textBufferOriginal.text = ktree[scene][1][line][1] #line==[content, insertedText]
		textBufferTranslation.text = ktree_t[scene][1][line][1]
	elsif line
		textBufferOriginal.text = ktree[scene][1][line][0]
		textBufferTranslation.text = ktree_t[scene][1][line][0]
	end
end

scrolled_win = Gtk::ScrolledWindow.new
scrolled_win.add(list)
scrolled_win.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
scrolled_win.set_size_request(100,-1)

tb = Gtk::Toolbar.new
tb.toolbar_style = Gtk::Toolbar::Style::ICONS
tbOpen = Gtk::ToolButton.new(Gtk::Stock::OPEN)
tbSave = Gtk::ToolButton.new(Gtk::Stock::SAVE)
tbRW = Gtk::ToolButton.new(Gtk::Stock::MEDIA_REWIND)
tbFF = Gtk::ToolButton.new(Gtk::Stock::MEDIA_FORWARD)
tbPrev = Gtk::ToolButton.new(Gtk::Stock::MEDIA_PREVIOUS)
tbNext = Gtk::ToolButton.new(Gtk::Stock::MEDIA_NEXT)
tbTr = Gtk::ToolButton.new(Gtk::Stock::APPLY)
tbOpen.tooltip_text = "Открыть.."
tbSave.tooltip_text = "Сохранить"
tbRW.tooltip_text = "Похоже, эта кнопка не работает"
tbFF.tooltip_text = "...и эта тоже"
tbPrev.tooltip_text = "Предыдущий файл в папке"
tbNext.tooltip_text = "Следующий файл в папке"
tbTr.tooltip_text = "Отметить как переведённое"
tb.insert(0,tbOpen)
tb.insert(1,tbSave)
tb.insert(2,tbRW)
tb.insert(3,tbFF)
tb.insert(4,tbPrev)
tb.insert(5,tbNext)
tb.insert(6,tbTr)
tbOpen.signal_connect('clicked') do
	dialog = Gtk::FileChooserDialog.new("Открыть файл", 
		mainWindow, 
		Gtk::FileChooser::ACTION_OPEN,
		nil,
		[Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
		[Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
	filter = Gtk::FileFilter.new
	filter.add_pattern("*.conversation")
	#filter.add_pattern("*.xml")
	dialog.add_filter(filter)
	if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
		kdoc, ktree, ktree_t = open_doc(dialog.filename, treeStore)
		label.text = dialog.filename
	end
	dialog.destroy
end
tbSave.signal_connect('clicked') do 
	kdoc.save_copy
end
tbTr.signal_connect('clicked') do
	if $dir
	if $treepath
		kdoc.replace_copy($treepath,textBufferTranslation.text)
	end
	scene=$treepath[0]
	line=$treepath[1]
	inserted=$treepath[2]
	if inserted #line==[content, insertedText]
		ktree_t[scene][1][line][1] = textBufferTranslation.text
	elsif line
		ktree_t[scene][1][line][0] = textBufferTranslation.text 
	end
	end
end
tbNext.signal_connect('clicked') do 
	if $dir
	if $dir_entries[$dir_entries_i+1]
		filename = $dir + '\\' + $dir_entries[$dir_entries_i+1]
		kdoc,ktree,ktree_t = open_doc(filename, treeStore)
		label.text = filename
	end
	end
end
tbPrev.signal_connect('clicked') do 
	if $dir
	if $dir_entries_i>0 and $dir_entries[$dir_entries_i-1]
		filename = $dir + '\\' + $dir_entries[$dir_entries_i-1]
		kdoc,ktree,ktree_t = open_doc(filename, treeStore)
		label.text = filename
	end
	end
end
=begin
tbFF.signal_connect('clicked') do 
	scene, line, inserted = *$treepath
	if scene
	if inserted
		if ktree[scene][1][line+1][0]
			line+=1
		elsif ktree[scene+1][1][1][0]
			scene+=1
			line = 1
		end
		path = scene.to_s+':'+line.to_s
	elsif line
		if ktree[scene][1][line][1]
			inserted = 0
			path = scene.to_s+':'+line.to_s+':'+inserted.to_s
		elsif ktree[scene][1][line+1][0]
			line+=1
			path = scene.to_s+':'+line.to_s
		elsif ktree[scene+1][1][1][0]
			scene+=1
			line = 1
			path = scene.to_s+':'+line.to_s
		end
	elsif scene
		if ktree[scene][1][1][0]
			line=1
			path = scene.to_s+':'+line.to_s
		end
	end
	path = Gtk::TreePath.new(path)
	puts path.to_s
	list.row_activated(path, 0)
end
end
=end
panBox.pack1(scrolled_win,true,false)
vBox.pack_start(textFieldOriginal, true, true, 2)
vBox.pack_start(textFieldTranslation, true, true, 2)
panBox.pack2(vBox, true, false)
mainBox.pack_start(tb,false,false)
mainBox.pack_start(panBox, true, true)
mainBox.pack_start(label,false,false)

#kdoc,ktree,ktree_t = open_doc('test', treeStore)
mainWindow.show_all
Gtk.main