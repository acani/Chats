files := init.sql tables/u*.sql tables/[!u]*.sql functions/*.sql

.PHONY : all development test

all : development test

development :
	cat $(files) | psql postgres -v env=development -f -

test :
	cat $(files) | psql postgres -v env=test -f -
