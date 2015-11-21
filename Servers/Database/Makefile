files := init.sql tables/u*.sql tables/[!u]*.sql functions/*.sql

.PHONY : reset

reset :
	cat $(files) | psql postgres -f -
