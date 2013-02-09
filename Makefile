#Makefile based system to interrogate Github and turn it into a stream of
#code postings

CURL=curl --silent
JSON=json
GITHUB_ROOT=http://$(GITHUB)
CLONE_ROOT=git://$(GITHUB)
BARE_USERNAME=$(shell python -c "import os; print os.environ['USERNAME'].split('@')[0]")
.SECONDARY:
.PHONY: clean always

organization-name=$(shell python -c "print '$1'.strip().split('/')[0]")

all: repositories/.all
	cat $< \
	| xargs -I % $(MAKE) codestreams/%/hipchat_postings

# Cloning from Github #

#starter target, this make sure we have every repository for 
#every org, mirrored to local disk so we can work on it with git commands
	
repositories/.all: always
	if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi
	$(CURL) --user "$(BARE_USERNAME):$(PASSWORD)" $(GITHUB_ROOT)/api/v3/user/orgs \
	| $(JSON) render templates/slice_orgs.mustache \
	| xargs -I % sh -c '$(CURL) --user "$(BARE_USERNAME):$(PASSWORD)" $(GITHUB_ROOT)/api/v3/orgs/%/repos | $(JSON) render templates/slice_repos.mustache' \
	| tee $@


#Actual repositories, these have no dependencies, just a tmp swap in case
#of network interruption. This uses git mirroring, no working directory, we'll
#never actually use these to commit.
repositories/%.git:
	-rm -rf $@.tmp
	git clone --mirror $(CLONE_ROOT)/$*.git $@.tmp
	mv $@.tmp $@

#Update a repository, this doesn't actually generate a file
repositories/%.git.update: repositories/%.git
	cd $(basename $@); git remote update

# Latest code changes #
codestreams/owner_user_id:
	if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi
	$(CURL) "https://api.hipchat.com/v1/users/show?user_id=$(USERNAME)&auth_token=$(HIPCHAT_API_KEY)" \
	| json pluck '.user.user_id' \
	> $@

codestreams/%/latest_changes: repositories/%.git.update
	if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi
	git --git-dir=$(basename $<) rev-list --remotes --all \
	| memories new $(dir $@)checkpointdb \
	| xargs -I _ ./commit_info.sh "$(basename $<)" _
	#and now remember that we have everything
	git --git-dir=$(basename $<) rev-list --remotes --all \
	| memories new $(dir $@)checkpointdb \
	| memories remember $(dir $@)checkpointdb 

codestreams/%/hipchat_room_id: codestreams/owner_user_id
	if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi
	$(CURL) --data "name=Codestream/$*&owner_user_id=$(shell cat codestreams/owner_user_id)" "https://api.hipchat.com/v1/rooms/create?auth_token=$(HIPCHAT_API_KEY)" \
	| json pluck '.room.room_id' \
	| tee $@.tmp
	mv $@.tmp $@

codestreams/%/hipchat_postings: codestreams/%/latest_changes 
	$(MAKE) codestreams/$(call organization-name, $*)/hipchat_room_id
	if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi


clean:
	find codestreams | grep hipchat_room_id$$ \
	| xargs cat \
