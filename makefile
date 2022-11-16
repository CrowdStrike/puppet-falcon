## run pdk build --force

build:
	pdk build --force

install: build
	puppet module install pkg/*.tar.gz

facts:
	puppet facts falcon