#Makefile based system to interrogate Github and turn it into a stream of
#code postings

CURL=curl --silent
JSON=json
GITHUB_ROOT=http://$(GITHUB)
CLONE_ROOT=git://$(GITHUB)

.PHONY: repositories/orgs/.all

all: repositories


# Cloning from Github #

#starter target, this make sure we have every repository for 
#every org, mirrored to local disk so we can work on it with git commands
repositories: repositories/orgs/.all
	#marker file updated every time we update repositories from github
	touch repositories/.update
	cat $< \
	| $(JSON) render templates/slice_orgs.mustache \
	| xargs -I _ $(MAKE) repositories/orgs/_/.all

#Every org listed to a file
repositories/orgs/.all: 
	if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi
	$(CURL) --user '$(USERNAME):$(PASSWORD)' $(GITHUB_ROOT)/api/v3/user/orgs \
	> $@

#Every repository in the org
repositories/orgs/%/.all: repositories/.update
	if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi
	$(CURL) --user '$(USERNAME):$(PASSWORD)' $(GITHUB_ROOT)/api/v3/orgs/$*/repos \
	> $@
	#updated versionsions of every repository
	cat $@ \
	| $(JSON) render templates/slice_repos.mustache \
	| xargs -I _ $(MAKE) repositories/_.git.update

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


