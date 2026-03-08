.PHONY: build test release install format check clean spec

build:
	crystal build src/easy_subtitle.cr -o bin/easy-subtitle

release:
	crystal build src/easy_subtitle.cr -o bin/easy-subtitle --release --no-debug

test: spec

spec:
	crystal spec

format:
	crystal tool format

check:
	crystal tool format --check

install: release
	install -m 755 bin/easy-subtitle /usr/local/bin/easy-subtitle

clean:
	rm -rf bin/ lib/ .shards/
