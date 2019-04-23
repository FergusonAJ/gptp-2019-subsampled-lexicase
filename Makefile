EMP_DIR := ../../tools/Empirical/source

CXX := g++-8 

CFLAGS := -Wall -Wno-unused-function -iquote $(EMP_DIR)/ -std=c++17

OFLAGS_optim := -O3 -DNDEBUG
OFLAGS_debug := -O3 -g -pedantic -DEMP_TRACK_MEM  -Wnon-virtual-dtor -Wcast-align -Woverloaded-virtual

all: ./src/main.cc
	$(CXX) ./src/main.cc $(CFLAGS) $(OFLAGS_optim) -o gptp2019

debug: ./src/main.cc
	$(CXX) ./src/main.cc $(CFLAGS) $(OFLAGS_debug) -o gptp2019

clean:
	rm ./gptp2019
