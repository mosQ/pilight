GCC = $(CROSS_COMPILE)gcc
SYS := $(shell $(GCC) -dumpmachine)
USE_LIRC := `grep -c '^#define USE_LIRC' libs/settings.h`
ifneq (, $(findstring x86_64, $(SYS)))
	OSFLAGS = -Ofast -fPIC -march=native -mtune=native -mfpmath=sse -Wconversion -Wunreachable-code -Wstrict-prototypes 
endif
ifneq (, $(findstring arm, $(SYS)))
	ifneq (, $(findstring gnueabihf, $(SYS)))
		OSFLAGS = -Ofast -mfloat-abi=hard -mfpu=vfp -march=armv6 -Wconversion -Wunreachable-code -Wstrict-prototypes 
	endif
	ifneq (, $(findstring gnueabi, $(SYS)))
		OSFLAGS = -Ofast -mfloat-abi=hard -mfpu=vfp -march=armv6 -Wconversion -Wunreachable-code -Wstrict-prototypes 
	endif	
	ifneq (, $(findstring gnueabisf, $(SYS)))
		OSFLAGS = -Ofast -mfloat-abi=soft -mfpu=vfp -march=armv6 -Wconversion -Wunreachable-code -Wstrict-prototypes 
	endif
endif
ifneq (, $(findstring amd64, $(SYS)))
	OSFLAGS = -O3 -fPIC -march=native -mtune=native -mfpmath=sse -Wno-conversion
endif
CFLAGS = -ffast-math $(OSFLAGS) -Wfloat-equal -Wshadow -Wpointer-arith -Wcast-align -Wstrict-overflow=5 -Wwrite-strings -Waggregate-return -Wcast-qual -Wswitch-default -Wswitch-enum -Wformat=2 -g -Wall -I. -I.. -Ilibs/ -Iprotocols/ -Ilirc/ -I/usr/include/ -L/usr/lib/arm-linux-gnueabihf/ -pthread -lm

ifeq (, $(findstring 1, $(USE_LIRC)))
	SUBDIRS = libs protocols lirc
	SRC = $(wildcard *.c)
	INCLUDES = $(wildcard protocols/*.o) $(wildcard lirc/*.o) $(wildcard libs/*.h) $(wildcard libs/*.o)
	PROGAMS = $(patsubst %.c,pilight-%,$(SRC))
	LIBS = libs/libs.o protocols/protocols.o lirc/lirc.o
else
	SUBDIRS = libs protocols
	SRC = $(wildcard *.c)
	INCLUDES = $(wildcard protocols/*.o) $(wildcard libs/*.o)
	PROGAMS = $(patsubst %.c,pilight-%,$(SRC))
	LIBS = libs/libs.o protocols/protocols.o
endif

.PHONY: subdirs $(SUBDIRS)

subdirs: $(SUBDIRS) all

$(SUBDIRS):
	$(MAKE) -C $@

all: $(LIBS) libpilight.so.1 libpilight.a $(PROGAMS) 

libpilight.so.1:
	$(GCC) $(LIBS) -shared -o libpilight.so.1 -lpthread -lm
	
libpilight.a:
	$(CROSS_COMPILE)ar -rsc libpilight.a $(LIBS)

pilight-daemon: daemon.c $(INCLUDES) $(LIBS)
	$(GCC) $(CFLAGS) -o $@ $(patsubst pilight-%,%.c,$@) libpilight.so.1

pilight-send: send.c $(INCLUDES) $(LIBS)
	$(GCC) $(CFLAGS) -o $@ $(patsubst pilight-%,%.c,$@) libpilight.so.1

pilight-receive: receive.c $(INCLUDES) $(LIBS)
	$(GCC) $(CFLAGS) -o $@ $(patsubst pilight-%,%.c,$@) libpilight.so.1

pilight-debug: debug.c $(INCLUDES) $(LIBS)
	$(GCC) $(CFLAGS) -o $@ $(patsubst pilight-%,%.c,$@) libpilight.so.1

pilight-learn: learn.c $(INCLUDES) $(LIBS)
	$(GCC) $(CFLAGS) -o $@ $(patsubst pilight-%,%.c,$@) libpilight.so.1

pilight-control: control.c $(INCLUDES) $(LIBS)
	$(GCC) $(CFLAGS) -o $@ $(patsubst pilight-%,%.c,$@) libpilight.so.1

install:
	install -m 0755 -d /usr/local/lib
	install -m 0755 -d /usr/local/sbin
	install -m 0755 -d /etc/pilight
	install -m 0655 pilight-daemon /usr/local/sbin/
	install -m 0655 pilight-send /usr/local/sbin/
	install -m 0655 pilight-receive /usr/local/sbin/
	install -m 0655 pilight-control /usr/local/sbin/
	install -m 0655 pilight-debug /usr/local/sbin/
	install -m 0655 pilight-learn /usr/local/sbin/
	install -m 0655 libpilight.so.1 /usr/local/lib/
	install -m 0644 settings.json-default /etc/pilight/
	mv /etc/pilight/settings.json-default /etc/pilight/settings.json
	ln -sf /usr/local/lib/libpilight.so.1 /usr/local/lib/libpilight.so
	ldconfig
	
	
clean:
	rm pilight-* >/dev/null 2>&1 || true
	rm *.so* || true
	rm *.a* || true
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir $@; \
	done