require 'byebug' # Debugging gem

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

#
# MySQL DB creds. We'll make these secret for production runs. 
# We should also prompt the user to get the parameters.
# 

creds = {user: 'foo', password: 'never-in-source'}

#
# Stub: Connect to MySQL. Don't do this more than once per report
# run. We don't want 15,000 MySQL connections (one per user.)
#

def connect_to_mysql(creds)
  
  #
  # Initiate a connection to the DB.
  #
  
  connection = 'a_db_connection'
  
  return db_connection
end

#
# Stub: Helper to run a query against the MySQL DB.
# 
# If we use ActiveRecord for this, a lot of the underlying DB
# mechanics become easier to manage. 
#

def query_db(query,db_connection)
  result = 'The result of our query'
end

#
# Stub: Get all the user profile records from MySQL.
#

def get_all_users(db_connection)
  placeholder_query = 'Get all the user records.'
  
  users = query_db(placeholder_query,db_connection) 
  
  #
  # Last value in a function is the return value. 
  #
  
end

#
# Stub: Retrieve all the user_answers from MongoDB.
# Returns all user_answer entities for the given challenge.
#

def get_all_user_answers(competition_id)
  
end

#
# Stub: A function to create a question set based on a tag.
# Returns a TODO: hash?/list? of question elements. Each question element
# is an anonymous hash. This 
#

def create_question_set(tag)
  
  question_set = nil
  
  #
  # Iterate through all the questions in the DB
  # If question[:tag] == tag, then add that question
  # entity to question_set
  #
  
  return questionSet
end

#
# Stub: Get the user answer data.
#

def get_user_answer_data(user_id,users_answers)
  #answers = user_answers[user_id]  
end

#
# Stub: Get files in Mongo storage that have file[:user_id] == user_id.
# 

def get_cloud_storage_data(user_id)
  #files = retrieveCloudFilesFromMongo(user_id)
  files = [{:filename => "war-and-peace.pdf"}] # placeholder data. Everyone uploaded
                                               # Tolstoy.
end 
  
#
# Gets Facebook data for a single user ID
#

def get_facebook_data(user_id)
  facebookData = {}
  #facebookData[:comments] = retrieveComments(user_id)
  #facebookData[:likes] = retrieveLikes(user_id)
  
  #
  # Some placeholder data.
  #
  
  facebook_data = {:likes => 999, :comments => ['love it!', 'way cool!']} 
end

#
# Do this only once and then pass the result to functions as necessary.
#

#
# TODO (maybe): Write a function that fills in points earned for questions of
# type :multi in the users_answers table. 
# This could happen in a separate script, or we could do it here.
#
# My preference: We could have the points earned on "multi" questions get added 
# to the DB at the time the user_answers submission is created. 
# That's actually my preference at the moment, unless there's a good 
# reason not to.
#

#
# Calculate total points earned. We'll use the points in user_answers.
# Each answer looks like the following in this example:
# question_set_id => {question_id => {:answer => "", 
#                                     :points => 2,
#                                     :type => "multi"
#                                     :reviewed => false}
#
# TODO: If there is a text field that is not :reviewed == true, return nil.
# Otherwise, calculate a total score.
#                    

def calculate_points_earned(user_answers)
  points = 0
  user_answers.each do |question_set, answers|
    answers.each do |question,params|
      puts "DEBUG: question ID: #{question}"
      puts "DEBUG: params: #{params}"
      if params[:text] == true and params[:reviewed] == false
        return nil
      else
        points += question[:points]
        puts "DEBUG: Current points earned: #{points}"
      end
    end
  end
  puts "DEBUG: Total points earned: #{points}"
  return points
end

###
#
# Sample data section.
#
###

#
# Sample question data. In real-life, we'd get this from 
# MongoDB.
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

        
###
#
# End sample data section.
#
###

#
# Retrieve the current competition based on its name.
# This report will run per-competition.
#

competition_name = "awesome challenge" # This will be user input
puts "INFO: Retrieving competition: #{competition_name}"

current_competition = nil # Holds a competition entity.

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

exit            
# current_competition = competitions[:competition_id_1]


#
# Our app now should have the information it needs.
#


#
# Notice we don't do this per-user. That is very much intentional.
# Otherwise, ouch!
#

dbConnection = connect_to_my_sql(creds)

#
# Simple program flow.
#


users.each do |user_id,params|
  profile = params

  #
  # For the facebook data, we could do this asynchronously or at
  # least in another background job. 
  #

  facebookInfo = get_facebook_data(user_id)
  
  cloudFiles = get_cloud_storage_data(user_id)

  #
  # Since we have placeholder data for all user answers, let's use that now.
  #
  
  #answers = getAnswerData(id)
  user_answers = get_answers[user_id]
  puts "UserID:#{user_id}::Name:#{params[:name]}::Answers: #{user_answers}"
 
  #
  # We can calculate total points earned, for example.
  #
  
  totalPoints = calculate_points_earned(user_answers)
  
  #
  # We can also build the data structure that we'll use to output a single
  # row per user in Excel.
  #
  
  #userId, name, competition, facebookInfo, cloudFiles, totalPoints
  
end


