NAME=`jq -r '.name' package.json`
VERSION=`jq -r '.version' package.json`

build: clean
	mkdir -p build
	cp package.json build/
	coffee -o build/lib -c lib
	coffee -o build -c index.coffee
	cd build && npm install
	./node_modules/pkg/lib-es5/bin.js --options max-old-space-size=2048 -t node6-linux -d ./build/index.js -o ./bin/${NAME}-${VERSION}-linux

clean:
	rm -rf build
	rm -rf ./bin/${NAME}-${VERSION}-linux

test: build
	${SETENV} ./bin/${NAME}-${VERSION}-linux < ./test/test.list