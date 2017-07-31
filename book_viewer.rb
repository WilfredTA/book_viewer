require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "yaml"


# What does search template need access to?
	# A chapter name and number: the name to display, the number to provide a link
	# It also needs access to the query: If the query does not exist, only show
	# search bar; if the query exists but is empty, show no results

# Passed to query should be a variable containing the chapter name and number for each chapter
# that has matched the search

# Method in app should therefore return an ivar that contains name and number of chapter
	# Method requires access to query - passed in as an argument
	# If query is nil, then we must return an empty array, otherwise we will be trying to call
	# a method on nil. We must also return empty array is query is empty (i.e. the user just hit search)


# Gets the data for each chapter (name number and chapter contents) and passes that data to a block, executes
# and returns the value of each_with_index
def get_each_chapter(&block)
	
	@toc.each_with_index do |ch_name, index|
		ch_number = index + 1
		contents = File.read("data/chp#{ch_number}.txt")
			yield ch_name, ch_number, contents
	end
end

# gets the data from each chapter with get_each_chapter and
# upon iterating over each chapter, checks if chapter includes query
# if it does include query, finds paragraph that contains query
# and id of that paragraph and places all data into a hash, placing 
# hash in an ivar array that can be passed to the search template
# below method uses a custom  method get_each_chapter, which ultimately
# returns the return value of Array#each_with_index.

# get_each_chapter gives us name, number, and contents of chapter
# check if chapter includes query
# if it does, split chapter into paragraphs and iterate over paragraphs
# if paragraph includes query, get paragraph and its id and place
# name, number, paragraph, and id into a hash
# push hash into @results
def find_each_chapter(query)
	@result = []
	return @result if !query || query.empty?

	get_each_chapter do |ch_name, ch_number, contents|
		if contents.include?(query)
				contents.split("\n\n").each_with_index do |paragraph, idx|
					if paragraph.include?(query)
						@result << {:name => ch_name, 
									:number => ch_number, 
									:paragraph => paragraph, 
									:id => idx} 
					end
				end
			end
	end
	@result

end


helpers do
	def in_paragraphs(chapter)
		chapter.split("\n\n").map do |paragraph|
			"<p id=#{chapter.split("\n\n").index(paragraph)}> #{paragraph} </p>"
		end.join
	end

  def highlight(text, term)
    text.gsub(term, %(<strong>#{term}</strong>))
  end

  def count_interests
  	total_interests = 0
		@users.each do |user, info|
			total_interests += info[:interests].count
		end
 		total_interests
  end
end

before do
	@toc = File.readlines("data/toc.txt")
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  @users = YAML.load_file("users.yaml")
  erb :users
end

get "/users/:user" do
	@user = params[:user]
	@users = YAML.load_file("users.yaml")

	erb :users
end

get "/chapters/:number" do
	@title = "Chapter #{params[:number]}"
	@chapter = File.read("data/chp#{params[:number]}.txt")

	erb :chapter
end

not_found do
	redirect "/"
end

get "/search" do
	find_each_chapter(params[:query])
	erb :search
end