#Makefile based system to interrogate Github and turn it into a stream of
#code postings

CURL=curl --silent
JSON=json

.PHONY: repositories/groups

all: repositories/groups

repositories:
	if [ ! -d $@ ]; then mkdir -p $@; fi

repositories/groups: repositories
	$(CURL) --user $(USERNAME):$(PASSWORD) http://$(GITHUB)/api/v3/user/orgs \
	| $(JSON) render templates/slice_orgs.mustache \
	> $@
	#curl -i --user $(USERNAME):$(PASSWORD) http://$(GITHUB)/api/v3/orgs/Deploy/repos
	#curl -i --user $(USERNAME):$(PASSWORD) http://$(GITHUB)/api/v3/repositories


