Codestream connects to one or more Git repositories, turning your commit
history into an online chat stream. Code review without yet another web
app to use.

# Bits #
All the things that need ot be built to get this going.
  * Github connector, lists out all the repositories
  * Git cloner, clone a bunch of repositories if they don't exist
  * Git fetcher, fetch a bunch of repostories
  * Renderer, turn JSON into another string, like a shell script
  * json slicer, pick apart REST results
  * remember, an eash way to keek track of tokens (git shas) already
seen
  * hitchat command line tools
    * open source is all API library, tools are not quite there
    * make a chat room
    * make a message
  * command line markdown render
  * command line code pretty print that works in hipchat
  * cron job to keep things up to date


# Things to Read #
http://help.hipchat.com/knowledgebase/articles/64359-running-a-hipchat-bot
http  ://github.com/kennethreitz/clint
docopt
bonsai
# Command Line Design #
codestream github hipchat [verb]
reads api tokens from environment variables
## Verbs ##
clone
: creates a local clone of github

catchup
: fetches the world

changes
: spits out a stream of commits since the last checkpoint

checkpoint
: remembers a set of commits so we don't mess with them any mmore 
