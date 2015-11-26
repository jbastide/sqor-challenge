require 'byebug' # Debugging gem.
require 'axlsx'  # Excel output gem.

#
# Get data from multiple sources. MySQL (user profiles), Facebook's API 
# (Likes and comments), and MongoDB (questions, user answers, question sets,
# file uploads.) Use an Excel report generation tool to output basic user
# information and calculated stats about a users performance 
# (ie, number correct out of total.)
#

#
# My assumption: Assume a single MongoDB instance per competition. 
# We could consolidate competitions into a single large DB, 
# but for the purposes of this exercise, a single instance per 
# competition it makes the data easier to debug and deal with data. 
#
# In production, it this architecture would add operations overhead 
# (another DB instance to deploy and monitor). However, this would
# be mitigated if infrastructure is managed as code (ie, Puppet, Ansible.)
# On the codingside, it would simplify data structures (less nesting),
# possibly improve query performance (fewer total records to sort),
# and limit the size of your fault domain (easier to debug).
#

####
#
# Script parameter section
#
####

#
# MySQL DB connection params. We'll make authentication info secret
# for production runs. We should also prompt the user to get the 
# parameters. This is all assuming we're talking straight to the DB
# and not 
# 

sql_params = { 
  :user => 'foo', 
  :password => 'never in source', 
  :connection_info => 'DB identifier for connection'}
  
#
# Same for MongoDB
#

mongo_params = {
  :user => 'foo',
  :password => 'not on your life',
  :connection_info => 'This is where the DB lives'
}

current_competition = nil # Holds a competition entity.
competition_id = nil
sql_instance = nil 
mongo_instance = nil
facebook_instance = nil
user_id_list = nil # Helper list for the facebook API queries.
highest_possible_score = 0 # This gets set later.
facebook_api_key = 'some value'

####
# End script parameters.
####

####
#
# Sample data section.
#
####

#
# These would be user input, for creating question sets. But for the purposes 
# of this script, assume that's already been done. Keep this tool focused on
# generating the report.
#

tags = ["rocket science","chem_experiments"] 

#
# Sample cloud files
#
cloud_files = {
  :user_id_1 => [
    {
    :filename => "War-and-Peace.pdf",
    :uploaded_at => "some-time"
    },
    {:filename => "Martha-Stewart-Kitchen.pdf",
     :uploaded_at => "some-other-time"}
  ],
  :user_id_2 => [
    {
      :filename => "A-Tale-of-Two-Cities.pdf",
      :uploaded_at => "some-time"
    },
    {:filename => "How-to-win-friends-and-influence-people.pdf",
     :uploaded_at => "some-other-time"}
  ]
}

#
# Sample question data, representing two different question tags. 
# In real-life, we'd get this from MongoDB and allow the user
# to specify tags.
#

questions = { :question_id_1 => {
                :question => "This is the first question.",
                :answer => "a",
                :type => "multi",
                :points => 1,
                :tag => "chem_experiments",
                :reviewed => nil },# Only questions of type 'text' need review.
              :question_id_2 => {
                :question => "This is the second question.",
                :answer => "b",
                :type => "multi",
                :points => 2,
                :tag => "chem_experiments",
                :reviewed => nil },
              :question_id_3 => {
                :question => "This is the third question.",
                :answer => "c",
                :type => "multi",
                :points => 3,
                :tag => "rocket_science",
                :reviewed => nil }, 
              :question_id_4 => {
                :question => "This is the fourth question.",
                :answer => nil,
                :type => "text",
                :points => 10,
                :tag => "rocket_science",
                :reviewed => nil }            
            }          
         
#
# How our question_sets data might look in the DB. Sample data here.
#

question_sets = { :qset_id_1 => [ :question_id_1, :question_id_2 ],
                  :qset_id_2 => [ :question_id_3, :question_id_4 ] }
#
# A challenge is defined by its question sets. Let's make a sample one now.
# This data structure would exist in Mongo.
#
                        
competitions = [{  :competition_id => 'competition_id_1',
                   :competition_name => "awesome challenge",
                   :question_sets => [:qset_id_1,:qset_id_2] }
               ]

               
#
# Let's say that, for a given challenge, a user won't participate more than once.
# Let's also work under the assumption that DB calls are expensive, so the fewer
# of them we can make, the better. We'll chunk the user_answer information. 
#

#
# Only run this call once when making the report. This would retrieve all
# user_answers for the competition
#

# user_answers = get_all_answers(competition_id)

#
# Here's our placeholder data for users and their associated answers.
# This would come from Mongo. We're keeping the :reviewed metadata
# across results, for symmetry. There is some duplication of data 
# between this data structure and the questions data structure.
#
# Assume that user data is manually reviewed through a separate service.
# We're only going to calculate score entries when all entries of 
# type "multi" are submitted and entries of type "text" are marked as 
# :reviewed = true
#

users_answers = { :user_id_1 => 
                 { :qset_id_1 => 
                   { :question_id_1 => { 
                       :answer => "a", 
                       :points => 1,
                       :type => "multi",
                       :reviewed => false },
                     :question_id_2 => {
                       :answer => "b", 
                       :points => 2,
                       :type => "multi",
                       :reviewed => false }
                   },
                   :qset_id_2 =>
                   { :question_id_3 => { 
                       :answer => "c", 
                       :points => 3,
                       :type => "multi",
                       :reviewed => false },
                     :question_id_4 => {
                       :answer => "My wonderful answer", 
                       :points => 10, 
                       :type => "text",
                       :reviewed => true }
                   }
                 },
                 :user_id_2 =>
                 { :qset_id_1 => 
                   { :question_id_1 => { 
                       :answer => "c", 
                       :points => 0,
                       :type => "multi", 
                       :reviewed => false },
                     :question_id_2 => {
                       :answer => "b", 
                       :points => 2,
                       :type => "multi", 
                       :reviewed => false }
                   },
                   :qset_id_2 =>
                   { :question_id_3 => { 
                       :answer => "b", 
                       :points => 0,
                       :type => "multi", 
                       :reviewed => false },
                     :question_id_4 => {
                       :answer => "My thoughtful answer", 
                       :points => 10, 
                       :type => "text",
                       :reviewed => true }
                   }
                 }
               }  

#
# Sample user profile hash. Simplified to only contain name, 
# although the real listings will have other attributes like full name, 
# e-mail, and other tasty nuggets of profile info.
#
# We'll be getting this info from MySQL.
# Thought: The entire user list might be huge. It probably makes more
# sense to retrieve the users_answers data from Mongo first, pull user_ids, then 
# query MySQL using only those user_ids to get profile data.
#
# Since user_ids will be primary keys in MySQL, the search is implicitly 
# indexed and should be fast.
#

users = { :user_id_1 => {:name => "Suzie", 
                         :competitions => [:competition_id_1]}, 
          :user_id_2 => {:name => "Roy",
                         :competitions => [:competition_id_1]}
        }
        
####
#
# End sample data section.
#
####

####
# Function section
####

##
#
# Stub: Connect to MySQL. Don't do this more than once per report
# run. We don't want 15,000 MySQL connections (one per user.)
#
##

def mysql_connect(sql_params)
  
  #
  # Initiate a connection to the DB.
  #
  
  connection = 'a_db_connection'
  
  #
  # Some connection string here.
  #
  
  return db_instance
end

##
#
# Stub: Helper to run a query against the MySQL DB.
# 
# If we use ActiveRecord for this, a lot of the underlying DB
# mechanics become easier to manage. 
#
##

def query_db(query,db_instance)
  result = 'The result of our query'
end

##
#
# Stub: Opens a connection to the mongoDB instance for the competition.
# Returns a mongo connection instance.
#
##

def mongo_connect(params)
  return mongo_instance
end

##
# 
# Stub: Transform user profiles. As input, take the data from 
# a query against MySQL, and turn it into a hash of the general form:
# :user_id_1 => {:name => "Suzie", 
#                :competitions => [:competition_id_1]},
# 
##

def transform_user_profiles(user_profiles)
  
  # returns a nicer form of the data.
  
end

##
#
# Stub: Get all the user profile records from MySQL.
#
##

def get_all_users(db_instance,competition_id)
  
  #
  # In the SQL DB, index competition_id!
  #
  
  placeholder_query = 'Get all the user records for users\
who are members of this competition.' # Includes competition_id

  user_profiles = query_db(placeholder_query,db_instance) 
  
  #
  # Structure this information to make it more easily accessible.
  # Example:
  # :user_id_1 => {:name => "Suzie", 
  #                       :competitions => [:competition_id_1]}
  #
  
  users = transform_user_profiles(user_profiles)
  
  #
  # Last value in a function is the return value. 
  #
  
end

##
#
# Stub: A function to create a question set based on a tag associated with 
# an individual question.
# Returns a structure like this:
# { :qset_id_1 => [ :question_id_1, :question_id_2 ],
#   :qset_id_2 => [ :question_id_3, :question_id_4 ] }
#
##

def create_question_set(tag)
  
  question_set = nil
  
  #
  # Iterate through all the questions in the DB
  # If question[:tag] == tag, then add that question
  # entity to question_set
  #
  
  search_questions_based_on_tag(tag)
  
  return questionSet
end

##
# 
#Stub: Get all the users_answers entries from Mongo.
# Assuming we only get users_answers data for this challenge
# (unique Mongo instance per challenge)
# Returns a structure of the form:
# users_answers = { :user_id_1 => 
#                   { :qset_id_1 => 
#                     { :question_id_1 => { 
#                         :answer => "a", 
#                         :points => 1,
#                         :type => "multi",
#                         :reviewed => false },
#                       :question_id_2 => {
#                         :answer => "b", 
#                         :points => 2,
#                         :type => "multi",
#                         :reviewed => false }
#                    },
#
##

def get_users_answers(mongo_instance)
  # Example: mongo_instance[:users_answers]
end

##
#
# Stub: Get all cloud file metadata.
# We're only working with the mongo instance bound to 
# this competition. 
# 
# If we weren't, we'd have an additional layer of nesting to 
# traverse.
#
##

def get_all_cloud_files(mongo_instance)
  # all_cloud_files = mongo_instance[:cloud_files]
end

##
#
# Stub: Make a connection to Facebook's API. Return a connection instance.
#
##

def facebook_connect(facebook_api_key)
  #return facebook_instance
end

##
# 
# Stub: Helper method so that we can retrieve all the Facebook likes
# and comments for user_ids attached to this competition.
# Removes the requirement to make multiple calls.
# 
##

def get_all_facebook_data(facebook_instance, user_id_list, competition_id)
  
  facebook_data = {}
  user_id_list.each do |user_id|
    
    #
    # Example Facebook API calls.
    # Good chance we'd have to filter based on competition_id here on our side.
    # In pretend-land here, I can pass it as a search parameter ;)
    #
    
    # comments = facebook_connection_instance.retrieve_facebook_comments(user_id,competition_id)
    # likes = facebook_connection_instance.retrieve_facebook_likes(user_id,competition_id)
  
    # facebook_data[:user_id] = {:comments => comments, :likes => likes}
    
    #
    # Placeholder info for Facebook data. Same for all users for now.
    #
    
    facebook_data[user_id] = {:likes => 999, :comments => ['love it!', 'way cool!']} 
  end

  return facebook_data
end

##
# For a question set, retrieve all the associated questions from the DB.
# Return a smaller list of questions used only in this competition.
##

def get_challenge_questions(question_set, mongo_instance)
  
  # Select all questions from the mongo instance 
  competition_questions = {}
  
  #
  # If we need another db connection to a different DB, we might have to pass that in
  # or do it outside the function. Probably better to keep them separate.
  #
  
  question_set.each do |question_set_id, questions|
    questions.each do |question_id|
      
      #
      # Run a Mongo query where we ask something like this:
      # Does mongo_instance[:questions][:question_id] exist?
      # If so, retrieve that record and add it to our hash.
      
      matching_question = mongo_instance[:questions][:question_id]
      if matching_question
        competition_questions[:question_id] = matching_question
      else 
        puts "WARN: Question not found. ID: #{question_id}"
      end
    end
  end
  
  return competition_questions

end

#
# TODO (maybe): Write a function that fills in points earned for questions of
# type "multi" in the users_answers table. 
# This could happen in a separate script, or we could do it here.
#
# My preference: We could have the points earned on "multi" questions 
# get added to the DB at the time the user_answers submission is created 
# inside users_answers. 
# That's actually my preference at the moment, unless there's a good 
# reason not to.
#

##
#
# Calculate total points earned for a given user. We'll use the
# points already defined in user_answers.
#
# Each answer looks like the following in this example:
# question_set_id => {question_id => {:answer => "", 
#                                     :points => 2,
#                                     :type => "multi"
#                                     :reviewed => false}
#
# Also: If there is a text field that is not :reviewed == true, return nil.
# Otherwise, calculate a total score. If not reviewed, the true final
# score is still unknown.
#
##                    

def calculate_points_earned(user_answers)
  points = 0
  user_answers.each do |question_set, answers|
    answers.each do |question_id,params|
      #puts "DEBUG: question ID: #{question_id}"
      #puts "DEBUG: params: #{params}"
      if params[:text] == true and params[:reviewed] == false
        return nil
      else
        points += params[:points]
        #puts "DEBUG: Current points earned: #{points}"
      end
    end
  end
  #puts "DEBUG: Total points earned: #{points}"
  return points
end

##
#
#
#
##

def get_highest_possible_score(questions)
  count = 0

  questions.each do |question_id, params|
    count += params[:points]
  end

  highest_possible_score = count
end

##
#
# Stub: Gets question sets that match the current competition_id.
# There's a good chance we'd be connecting to another Mongo instance here.
# Returns the question sets in the form:
#  { :qset_id_1 => [ :question_id_1, :question_id_2 ] }
#
##

def get_question_sets(competition_id,mongo_instance)
end


##
#
# Export Excel.
# Remember:
# report_data_structure[user_id] = {
#    :username => params[:name],
#    :total_points_earned => total_points,
#    :total_points_possible => highest_possible_score,
#    :total_facebook_likes => total_facebook_likes,
#    :total_facebook_comments => total_facebook_comments,
#    :cloud_file_list => user_cloud_file_names  
#  }
#
# Found helpful report generation info here:
# https://pramodbshinde.wordpress.com/2013/12/29/design-spreadsheets-using-axlsx-in-rails/
#
# And here: 
# http://www.rubydoc.info/github/randym/axlsx/Axlsx/Package#serialize-instance_method
#
##

def generate_excel(report_data_structure, competition_name)
  package = Axlsx::Package.new
  workbook = package.workbook
  workbook.add_worksheet(name: competition_name) do |sheet|
    sheet.add_row ["User ID", "Username", "Points Earned", 
      "Points Possible", "Facebook Likes", "Comments", "Cloud File Names"]
    report_data_structure.each do |user_id, params|
      sheet.add_row [
        user_id, 
        params[:username], 
        params[:total_points_earned], 
        params[:total_points_possible], 
        params[:total_facebook_likes], 
        params[:total_facebook_comments], 
        params[:cloud_file_list], 
      ]
    end
  end
  package.serialize("#{competition_name}.xlsx")
end

####
# Execution
####

#
# Retrieve the current competition based on its name.
# This report will run per-competition. 
#

competition_name = "awesome challenge" # TODO: This will be user input
puts "INFO: Retrieving competition: #{competition_name}"

competitions.each do |competition| 
  if competition[:competition_name] == competition_name
    current_competition = competition
  else
    puts "ERROR: Could not find #{competition_name}!"
    exit
  end
end

puts "INFO: The current competition is \
#{current_competition[:competition_id]}::#{current_competition[:competition_name]}"

competition_id = current_competition[:competition_id]

#
# Our script should now should have the information it needs.
# Information to connect to the databases and populate data structures
# is commented out, since we've already populated sample data for 
# the script to use.
#

#
# Get all the user profile data from MySQL. We're filtering on 
# users who are members of this competition.
#
# Notice we don't do this per-user. That is very much intentional.
# Otherwise, ouch on the connection front!
#

# sql_instance = mysql_connect(sql_params)

# users = get_all_users(sql_instance,competition_id)

#
# This is a quick helper for later, when we're getting data from
# facebook. Enabled for demonstration purposes.
#

user_id_list = users.keys()

#
# Connect to MongoDB to retrieve other records.
#

# mongo_instance = mongo_connect(mongo_params)

#
# Populate the users_answers data structure from MongoDB
#

# users_answers = get_users_answers(mongo_instance)

#
# Get the question_sets associated with this competition.
# They could be in this db, or live in another one. That is TBD.
# If they live per competition, you might end up duplicating 
# info across DBs, making updates a pain.
# Might make sense to put question sets and questions
# in their own dedicated Mongo instance to centralize updates.
# 

# question_sets = get_question_sets(competition_id,mongo_instance)

#
# Get the questions associated with the competition.
#

# questions = get_challenge_questions(question_sets, mongo_instance)

#
# Get all the cloud file metadata in one query instead of multiple.
#

# all_cloud_files = get_all_cloud_files(mongo_instance)

#
# Use our test data instead, since the function above is just a stub.
#

all_cloud_files = cloud_files

#
# Pull the facebook data all at once rather than doing api calls per user.
# Prevents a lot of additional connection overhead. And maybe we pay
# by API call?
#

# facebook_connection_instance = facebook_connect(facebook_api_key)

all_facebook_data = get_all_facebook_data(
  facebook_instance, 
  user_id_list, 
  competition_id)

#
# TODO: The question now is, what's the memory footprint of this script after it 
# pulls all those records from the DBs ahead of time and makes its ginormous 
# facebook API request?
#

highest_possible_score = get_highest_possible_score(questions)

#
# The report data structure will look like the following.
# user_id => {
#   :username => , # Just params[:name] for this example
#   :total_points_earned => ,
#   :total_points_possible => ,
#   :total_facebook_likes => ,
#   :total_facebook_comments => , 
#   :cloud_file_list ,
# }
#

report_data_structure = {}

#
# Simple program flow.
#

users.each do |user_id,params|
  
  profile = params

  #
  # For the facebook data, we could do this asynchronously or at
  # least in another background job. 
  #

  facebook_info = all_facebook_data[user_id]
  
  #
  # We're passing in the existing mongo instance so it's okay.
  # We'll receive a list of the form 
  # files[user_id] = [{
  #   :filename => "war-and-peace.pdf", 
  #   :uploaded_at: "some-time"},]
  #
  
  user_cloud_files = all_cloud_files[user_id]

  #
  # We won't report ALL the cloud file metadata. So let's just grab the 
  # filenames for now.
  #
  
  user_cloud_file_names = []
  
  user_cloud_files.each do |file|
    user_cloud_file_names << file[:filename]
  end
    
  #
  # Since we have placeholder data for all user answers, let's use that now.
  #
  
  # answers = getAnswerData(id)
  user_answers = users_answers[user_id]
  #puts "INFO: UserID:#{user_id}::Name:#{params[:name]}::\
#Answers: #{user_answers}"
 
  #
  # We can calculate total points earned, for example.
  #
  
  total_points = calculate_points_earned(user_answers)
  
  #puts "INFO: #{user_id}:#{params[:name]}:#{total_points}:\
#{facebook_info[:comments]}:#{facebook_info[:likes]}:#{cloud_files}"
  
  total_facebook_likes = facebook_info[:likes]
  total_facebook_comments = facebook_info[:comments].length
  
  #
  # Generate the report data structure that we'll feed to our 
  # excel-generating gem.
  #
  
  report_data_structure[user_id] = {
    :username => params[:name],
    :total_points_earned => total_points,
    :total_points_possible => highest_possible_score,
    :total_facebook_likes => total_facebook_likes,
    :total_facebook_comments => total_facebook_comments,
    :cloud_file_list => user_cloud_file_names  
  }
     
  #
  # We can also build the data structure that we'll use to output a single
  # row per user in Excel.
  #
  # Should contain: user_id, name, competition, number of facebook likes, number of facebook comments, 
  # cloud_file names, total_points earned, total points possible.
  #
  
end

puts "INFO: This is a datastructure we could feed into an excel generating tool."
report_data_structure.each do |user_id,params|
  puts "#{user_id}: #{params}"
  puts "###"
end

#
# Right now we're just overwriting the current report. When this goes live, we should prompt
# so data doesn't get lost. We may want to allow the user to choose their own report name, as well.
# Alternatively,generate a report name using a unique, pseudo-random number based on the 
# current system time.
#

puts "INFO: Generating Excel report of results. Check the current directory from where you\
 ran this report."
generate_excel(report_data_structure, competition_name)


