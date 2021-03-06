exclude = .git .gitignore *~ *.dump Mnesia* src rel notes.org README.md
deps = erlsha2 common
erl_lib = $(ERL_PROJECTS)

### Erlang shortcuts
ERL = erl -pa ebin -pa priv -pa deps/*/ebin -pa deps/*/priv

erl_start = -eval 'lists:map(fun (App) -> application:load(App), application:start(App) end, [sasl, common, mnesia, auth]).'

erl_stop = -s init stop

define mnesia_create
	$(ERL) -name $(1) -eval 'mnesia:create_schema([node()]).' $(erl_start) -eval 'users:create(), groups:create(), rsa_auth:create().' $(erl_stop)
endef

### Rules
all: 
	$(foreach var, $(deps), mkdir deps/$(var); cp -r $(erl_lib)$(var)/ebin deps/$(var); cp -r $(erl_lib)$(var)/priv deps/$(var);)
	erlc -Wf -o ebin/ src/*erl
	cp src/*app ebin/
	cp src/server_auth.key priv/
	cp src/server_auth.pub priv/
	pycompile src/*py; mv src/*pyc priv/

install:
	apt-get install screen erlang python-setuptools
	easy_install erlport

gen-key:
	python gen_key

mnesia-create:
	$(call mnesia_create, auth@127.0.1.1)

mnesia-delete:
	rm -r Mnesia*

mnesia-recreate: mnesia-delete mnesia-create

test: 
	$(call mnesia_create, test@127.0.0.1 )
	$(ERL) -name test@127.0.0.1 $(erl_start) -eval 'test:run(["Inaimathi", "Test Co."])' $(erl_stop)
	rm -r Mnesia.test@127.0.0.1

start: 
	screen -S auth $(ERL) -name auth@127.0.1.1 $(erl_start)

attach:
	screen -r auth

clean:
	rm -r ebin/* deps/* priv/* 