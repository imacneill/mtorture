# Request latest gcc!
# . /opt/rh/devtoolset-2/enable

VR       := 1
VECHOST  := -mavx -vec-report=${VR}
VECMIC   := -mmic -vec-report=${VR}

### To disable vectorization set USER_CXXFLAGS := -no-simd -no-vec
# Setting only one of the above has little effect.
# Note, this also screws-up prefetching so it's a lousy deal.

# -opt-prefetch-distance=64,8
OPT      := -O3

CPPFLAGS := -I. ${USER_CPPFLAGS} ${DEFS}
CXXFLAGS := ${OPT} -openmp -std=gnu++0x ${USER_CXXFLAGS}

LDFLAGS  := ${USER_LDFLAGS}

TGTS     := t1 t2 t3 t4 mkFit/mkFit

EXES     := ${TGTS} $(addsuffix -mic, ${TGTS})

all: ${EXES}

matriplex-auto:
	${MAKE} -C Matriplex auto && touch $@

auto: matriplex-auto
.PHONY: auto

%.o: %.cxx *.h matriplex-auto
	icc ${CPPFLAGS} ${CXXFLAGS} ${VECHOST} -c -o $@ $<

%.om: %.cxx *.h matriplex-auto
	icc ${CPPFLAGS} ${CXXFLAGS} ${VECMIC} -c -o $@ $<


clean:
	rm -f ${EXES} *.o *.om mkFit/mkFit mkFit/mkFit-mic mkFit/*.o mkFit/*.om

distclean: clean
	${MAKE} -C Matriplex clean
	rm -f matriplex-auto

echo:
	@echo CPPFLAGS = ${CPPFLAGS}
	@echo CXXFLAGS = ${CXXFLAGS}
	@echo LDFLAGS  = ${LDFLAGS}

################################################################

### mkFit test

MKFSRCS := $(wildcard mkFit/*.cc)
MKFHDRS := $(wildcard mkFit/*.h)

MKFOBJS     := $(MKFSRCS:.cc=.o)
MKFOBJS_MIC := $(MKFSRCS:.cc=.om)

MKEXES  := mkFit/mkFit mkFit/mkFit-mic

.PHONY: mkFit
mkFit: ${MKEXES}

mkFit/mkFit: auto ${MKFOBJS}
	icc ${CXXFLAGS} ${VECHOST} ${LDFLAGS} -o $@ ${MKFOBJS}

mkFit/mkFit-mic: auto ${MKFOBJS_MIC}
	icc ${CXXFLAGS} ${VECMIC}  ${LDFLAGS} -o $@ ${MKFOBJS_MIC}
	scp $@ mic0:

mkFit/%.o: mkFit/%.cc mkFit/*.h Matriplex/*
	icc ${CPPFLAGS} ${CXXFLAGS} ${VECHOST} -DNO_ROOT -IMatriplex -c -o $@ $<

mkFit/%.om: mkFit/%.cc mkFit/*.h Matriplex/*
	icc ${CPPFLAGS} ${CXXFLAGS} ${VECMIC} -DNO_ROOT -IMatriplex -c -o $@ $<

### t1

T1_DEPS := t1 ArrayTest Timing

t1: $(addsuffix .o, ${T1_DEPS})
	icc ${CXXFLAGS} ${VECHOST} ${LDFLAGS} -o $@ $^

t1-mic:  $(addsuffix .om, ${T1_DEPS})
	icc ${CXXFLAGS} ${VECMIC} ${LDFLAGS} -o $@ $^
	scp $@ mic0:

run-t1:	t1 t1-mic
	./t1
	ssh mic0 ./t1-mic

### t2

T2_DEPS := t2 ArrayTest Timing

t2: $(addsuffix .o, ${T2_DEPS})
	icc ${CXXFLAGS} ${VECHOST} ${LDFLAGS} -o $@ $^

t2-mic:  $(addsuffix .om, ${T2_DEPS})
	icc ${CXXFLAGS} ${VECMIC} ${LDFLAGS} -o $@ $^
	scp $@ mic0:

run-t2:	t2 t2-mic
	./t2
	ssh mic0 ./t2-mic

### t3

T3_DEPS := t3 MPlexTest Timing

MPlexTest.o MPlexTest.om: Matriplex/Matriplex.h Matriplex/MatriplexSym.h Matriplex/MatriplexVector.h

t3: $(addsuffix .o, ${T3_DEPS})
	icc ${CXXFLAGS} ${VECHOST} ${LDFLAGS} -o $@ $^

t3-mic: $(addsuffix .om, ${T3_DEPS})
	icc ${CXXFLAGS} ${VECMIC} ${LDFLAGS} -o $@ $^
	scp $@ mic0:

run-t3:	t3 t3-mic
	./t3
	ssh mic0 ./t3-mic

### t4

T4_DEPS := t4 MPlexTest

MPlexTest.o MPlexTest.om: Matriplex/Matriplex.h Matriplex/MatriplexSym.h Matriplex/MatriplexVector.h

t4: $(addsuffix .o, ${T4_DEPS})
	icc ${CXXFLAGS} ${VECHOST} ${LDFLAGS} -o $@ $^

t4-mic: $(addsuffix .om, ${T4_DEPS})
	icc ${CXXFLAGS} ${VECMIC} ${LDFLAGS} -o $@ $^
	scp $@ mic0:

run-t4:	t4 t4-mic
	./t4
	ssh mic0 ./t4-mic

