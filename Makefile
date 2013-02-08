#Makefile based system to interrogate Github and turn it into a stream of
#code postings

CURL=curl --silent
JSON=json

.PHONY: repositories/orgs/.all

all: repositories

repositories: repositories/orgs/.all
	touch repositories/.update
	cat $< \
	| $(JSON) render templates/slice_orgs.mustache \
	| xargs -I _ $(MAKE) repositories/orgs/_/.all

#Every org listed to a file
repositories/orgs/.all: 
	if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi
	$(CURL) --user $(USERNAME):$(PASSWORD) http://$(GITHUB)/api/v3/user/orgs \
	> $@

#Every repository in the org
repositories/orgs/%/.all: repositories/.update
	if [ ! -d $(dir $@) ]; then mkdir -p $(dir $@); fi
	$(CURL) --user $(USERNAME):$(PASSWORD) http://$(GITHUB)/api/v3/orgs/$*/repos \
	> $@

