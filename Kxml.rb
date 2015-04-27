require 'nokogiri'

class Kxml
	
	def initialize(path)
	#открываем файл
		@path = path
		@filename=path.rpartition('\\')
		f = File.open(path)
		@doc = Nokogiri::XML(f,nil,'UTF-8')
		if not File.exist?("t_"+@path)
			f.seek(0, IO::SEEK_SET)
			@doc_copy = Nokogiri::XML(f,nil,'UTF-8')
			f.close
		else
			f.close
			File.open("t_"+@path) {|f| @doc_copy = Nokogiri::XML(f,nil,'UTF-8')}
		end
		#создаём глобальный массив узлов-сцен
		@scenes = @doc.search 'scene'
		@scenes_t = @doc_copy.search 'scene'
	end
	
	#функция для вывода списка сцен
	def list_scenes
		arr = @scenes.map do |scene|
			scene['name']
		end
		arr
	end
	
	def make_tree(opt)
		if opt 
			scenes = @scenes
		else 
			scenes = @scenes_t end
		
		tree = scenes.map do |scene|
			name = scene['name']
			lines = scene.children.map do |child|
				[child.content, child.attributes['insertedText'].to_s]
			end
			[name,lines] #=tree
		end
		tree
	end
	
	#выбор активной сцены по имени из списка, active.class == element
	def chose_scene(name)
		@content = nil
		@active = (@scenes.search "scene[@name=#{name}]")[0]
	end
	
	#вывод списка диалогов в сцене
	def list_active 
		if not @content
			@content = []
			i = 0
			children = @active.children  #children.class == text or node
			children.each do |child|
				if /\n/.match(child.content)
					@content[i]=nil
				else
					@content[i] = child.content
				end	
				i+=1
			end
			puts '\n'
		end
		@content.each do |entry|
			puts entry
		end
	end
	
	def replace_copy(path, text)
		scene = path[0]
		line =path[1]
		inserted = path[2]
		target = @scenes_t[scene].children[line]
		if inserted
			target.set_attribute('insertedText', text)
		else
			target.content=text
		end
	end
	
	def save_copy
		File.open(@filename[0]+@filename[1]+"t_"+@filename[2],"w") do |f|
			f.write(@doc_copy.to_xml)
		end
		
	end
end #Kxml end

