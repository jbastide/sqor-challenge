require 'byebug' # Debugging gem

#
# Get data from multiple sources. MySQL (user profiles), Facebook's API 
# (Likes and comments), and MongoDB (questions, user answers, question sets,
# file uploads.) Use an Excel report generation tool to output basic user
# information and calculated stats about a users performance 
# (ie, number correct out of total.)
#

#
# MySQL DB creds. We'll make these secret for production runs. 
# We should also prompt the user to get the parameters.
#

creds = {user: 'foo', password: 'never in source'}

#
# Stub: Connect to MySQL. Don't do this more than once per report
# run. We don't want 15,000 MySQL connections (one per user.)
#

def connectToMySql(creds)
  
  #
  # Initiate a connection to the DB.
  #
  
  connection = 'A_db_connection'
  
  return db_connection
end

#
# Stub: Helper to run a query against the DB.
# 
# If we use ActiveRecord for this, a lot of the underlying DB
# mechanics become easier to manage. 
#

def queryDB(query,db_connection)
  result = 'The result of our query'
end

#
# Stub: Get all the user profile records from MySQL.
#

def getAllUsers(dbConnection)
  query = 'Get all the user records.'
  users = queryDB(query,dbConnection) # Last value in a function is 
                                      # the return value. 
end

#
# Stub: Retrieve all the user_answers from MongoDB.
# Returns all user_answer entities.
#

def getAllUserAnswers()
  
end

#
# Stub: A function to create a question set based on a tag.
# Returns a TODO: hash?/list? of question elements. Each question element
# is an anonymous hash. This 
#

def createQuestionSet(tag)
  
  questionSet = nil
  
  #
  # Iterate through all the questions in the DB
  # If question[:tag] == tag, then add that question
  # entity to questionSet
  #
  
  return questionSet
end

#
# Stub: Get the user answer data.
#

def getUserAnswerData(id)
  #answers = userAnswers[id]  
end

#
# Stub: Get files in Mongo storage that have file[:user_id] == user_id.
# 

def getCloudStorageData(user_id)
  #files = retrieveCloudFilesFromMongo(user_id)
  files = [{:filename => "war-and-peace.pdf"}] # placeholder data. Everyone uploaded
                                               # Tolstoy.
end 
  
#
# Gets Facebook data for a single user ID
#

def getFacebookData(user_id)
  facebookData = {}
  #facebookData[:comments] = retrieveComments(user_id)
  #facebookData[:likes] = retrieveLikes(user_id)
  
  #
  # Some placeholder data.
  #
  
  facebookData = {:likes => 999, :comments => ['love it!', 'way cool!']} 
end

#
# Do this only once and then pass the result to functions as necessary.
#

=begin
def getExpectedAnswersPoints(allQuestionSets)
  
  #
  # Want this: { :qsetID1 => [["a",2],["b",2]}
  # We have the answer value in position 0, and the point value
  # in position 1.
  #
  # We should break this out and do it once in its own
  # method rather than repeating the calculation.
  #
  
  expectedAnswers = {}
  allQuestionSets.each do |id,params|
    results = []
    params.each do |entity|
      results << {:answer => entity[:answer], :points => entity[:points], 
                  :type => entity[:type]}
    end
    expectedAnswers[id] = results
  end
  
  return expectedAnswers
end

=end

#
# Calculate total points earned. For now, we'll use the points in userAnswers.
# Each answer looks like the following (for now.)
# question_set_id => {question_id => {:answer => "", :points => 2}
#                     


def calculatePointsEarned(userAnswers)
  points = 0
  userAnswers.each do |question_set, answers|
    answers.each do |question,params|
      puts "DEBUG: question ID: #{question}"
      puts "DEBUG: params: #{params}"
      points += question[:points]
      puts "DEBUG: Current points earned: #{points}"
  end
  puts "DEBUG: Total points earned: #{points}"
  return points
end

#
# Define a single question. Its data might look like this.
#
=begin
question1 = {question: "This is a sample question.",
            answer: "A",
            type: "multi",
            points: 1,
            tag: "chemistry_experiments"}     

#
# Create some more sample data.
#

question2 = {question: "This is another question.",
             answer: "B",
             type: "multi",
             points: 2,
             tag: "rocket_science"}
             
question3 = {question: "How much wood could a woodchuck...",
            answer: "C",
            type: "multi",
            points: 3,
            tag: "chemistry_experiments"}
            
question4 = {question: "Tell me the meaning of life.",
            answer: nil,
            type: "text",
            points: 10,
            tag: "rocket science"}
=end

#
# Sample question data. In real-life, we'd get this from 
# MongoDB.
#

questions = { question_id_1 => {
                :question => "This is the first question.",
                :answer => "a",
                :type => "multi",
                :points => 1,
                :tag => "chem_experiments",
                :reviewed => nil },# Only questions of type 'text' need review.
              question_id_2 => {
                :question => "This is the second question.",
                :answer => "b",
                :type => "multi",
                :points => 2,
                :tag => "chem_experiments",
                :reviewed => nil },
              question_id_3 => {
                :question => "This is the third question.",
                :answer => "c",
                :type => "multi",
                :points => 3,
                :tag => "rocket_science",
                :reviewed => nil }, 
              question_id_4 => {
                :question => "This is the fourth question.",
                :answer => nil,
                :type => "text",
                :points => 10,
                :tag => "rocket_science",
                :reviewed => nil }            
            }          
         
#
# How are question_sets data might look in the DB. Sample data here.
#

question_sets = { :qset_id_1 => [ question_id1, question_id2 ],
                  :qset_id_2 => [ question_id3, question_id4 ] }
#
# A challenge is defined by its question sets. Let's make a sample one now.
# This data structure would exist in Mongo.
#
                        
competitions = { :competition_id_1 => { 
                   :competition_name => "awesome challenge",
                   :question_sets => [:qset_id_1,:qset_id_2] }
               }

#
# TODO: Move this to where it belongs. Group calls. 
#
               
current_competition = competitions[:competition_id_1]

#
# On the Mongo side, we'll store information about questions, question sets, 
# the challenge itself, and user answers.
#

#
# Let's say that, for a given challenge, a user won't participate more than once.
# Let's also work under the assumption that DB calls are expensive, so the fewer
# of them we can make, the better. We'll chunk the user answer information. 
# For storing user answer data to questions, 
# we can try something like what's below.
#

#
# Only run this call once when making the report. This would retrieve all
# user_answers for the competition
#

# user_answers = getAllAnswers(competition_id)

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

user_answers = { :user_id_1 => 
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
                       :type => "text"
                       :reviewed => true }
                   }
                 }
               }  
#
# Entering a new user answer entry would look like this:
# userAnswers[userID] = {:qsetID1 = ["A", "C"],
#                        :qsetID2 = ["C", "Drawing blanks."]}
#

#
# Sample user list. We'll be getting this info from MySQL.
#

users = { :user1 => {:name => "Suzie"}, :user2 => {:name => "Roy"} }

#
# If we were actually connecting to a DB, we could populate our list
# this way. Having access to 'users' now is helpful, so let's keep it
# around. Let's also say that user accounts are tagged with the challenges
# they've done, so we can filter based on that attribute; this is a good
# place for a DB index.
#

# challengeTag = 'sample_challenge'
# users = getAllUserIdsFromMySql(challengeTag)

#
# Break this out once instead of doing the operation per user.
#

expectedAnswers = getExpectedAnswersPoints(allQuestionSets)
 
#
# Our app now should have the information it needs.
#


dbConnection = connectToMySql(creds)

users.each do |id,params|
  profile = params

  #
  # For the facebook data, we could do this asynchronously or at
  # least in another background job. 
  #

  facebookInfo = getFacebookData(id)
  
  cloudFiles = getCloudStorageData(id)

  #
  # Since we have placeholder data for all user answers, let's use that now.
  #
  
  #answers = getAnswerData(id)
  userAnswers = getAnswers[id]
  puts "UserID:#{id}::Name:#{params[:name]}::Answers: #{userAnswers}"
 
  #
  # We can calculate total points earned, for example.
  #
  
  totalPoints = calculatePointsEarned(userAnswers)
  
  #
  # We can also build the data structure that we'll use to output a single
  # row per user in Excel.
  #
  
  #userId, name, competition, facebookInfo, cloudFiles, totalPoints
  
end


