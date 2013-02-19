#Makefile based system to interrogate Github and turn it into a stream of
#code postings

CURL=curl --silent
JSON=json
GITHUB_ROOT=http://$(GITHUB)
CLONE_ROOT=git://$(GITHUB)
BARE_USERNAME=$(shell python -c "import os; print os.environ['USERNAME'].split('@')[0]")
.SECONDARY:
.PHONY: clean always repositories catchup repositories/.all
export GITHUB_ROOT

organization-name=$(shell python -c "print '$1'.strip().split('/')[0]")

#Dummy target, makes 'make' by itself do nothing
all:
	@echo

install:
	pip install --requirement=pipfile
	$(MAKE) repositories checkpoint

# Cloning from Github #

#get all the repositories for all orgs, clone them, and make sure they are
#fully up to date
repositories: repositories/.all

#starter target, this make sure we have every repository for 
#every org, mirrored to local disk so we can work on it with git commands
repositories/.all:
	if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi
	$(CURL) --output - --user "$(BARE_USERNAME):$(PASSWORD)" $(GITHUB_ROOT)/api/v3/user/orgs \
	> $@.raw
	cat $@.raw \
	| $(JSON) render templates/slice_orgs.mustache \
	| xargs -I % $(MAKE) repositories/%.repositories
	ls repositories/*.repositories \
	| xargs cat \
	| sort \
	| uniq \
	> $@
	cat $@ \
	| xargs -I % $(MAKE) repositories/%.git.update

repositories/%.repositories: always
	$(CURL) --output - --user "$(BARE_USERNAME):$(PASSWORD)" $(GITHUB_ROOT)/api/v3/orgs/$*/repos \
	> $@.raw
	cat $@.raw \
	| $(JSON) render templates/slice_repos.mustache \
	> $@

#Actual repositories, these have no dependencies, just a tmp swap in case
#of network interruption. This uses git mirroring, no working directory, we'll
#never actually use these to commit.
repositories/%.git:
	-rm -rf $@.tmp
	git clone --mirror $(CLONE_ROOT)/$*.git $@.tmp
	mv $@.tmp $@

#Update a repository, this doesn't actually generate a file
repositories/%.git.update: repositories/%.git
	git --git-dir=repositories/$*.git remote update

# Latest code changes #

#Catch up the latest without making any postings, this is useful the very first
#time to avoid a huge firehose
checkpoint: repositories/.all
	cat $< \
	| xargs -I % $(MAKE) codestreams/%/checkpointdb

#Make codestreams postings through to hipchat
hipchat_postings: repositories/.all
	-rm codestreams/chatroom
	cat $< \
	| xargs -I % $(MAKE) codestreams/%/hipchat_postings

codestreams/chatroom:
	hipchat rooms list "Codestreams" > $@
	if [[ ! -s $@ ]]; then hipchat rooms create $(USERNAME) "Codestreams"; fi;
	hipchat rooms list "Codestreams" > $@

codestreams/chatrooms: repositories/.all
	if [ ! -d $@ ]; then mkdir -p $@; fi
	cat $< \
  | python bin/slashsplit.py \
	| uniq \
	| xargs -I _ $(MAKE) codestreams/chatrooms/_

codestreams/chatrooms/%:
	hipchat rooms list "$*" > $@
	if [[ ! -s $@ ]]; then hipchat rooms create $(USERNAME) "$*"; fi;
	hipchat rooms list "$*" > $@

#Create the checkpointdb, recording all ids of all commits
codestreams/%/checkpointdb: always
	if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi
	git --git-dir=repositories/$*.git rev-list --remotes --all \
	| memories remember $@

#using the checkpoint database, figure all commits that are new
#then pipe them along for posting to hipchat
#and remember that you sent them, so we don't double post
codestreams/%/hipchat_postings: repositories/%.git.update codestreams/chatroom
	if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi
	git --git-dir=$(basename $<) rev-list --remotes --all --date-order --reverse --no-merges \
	| tail \
	| memories new codestreams/$*/checkpointdb \
	> $@.new
	cat $@.new \
	| xargs -I _ ./bin/post_commit_info.sh "$(basename $<)" $* _ \
	> $@.posted
	cat $@.posted \
	| memories remember codestreams/$*/checkpointdb

clean:
	rm -rf codestreams
