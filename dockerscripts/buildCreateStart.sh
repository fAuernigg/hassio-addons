cd $(dirname $0)
./build.sh $@ && ./createContainer.sh $@ && ./start.sh $@
