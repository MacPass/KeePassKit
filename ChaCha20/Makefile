ifndef TARGET
  ifdef WINDIR
    TARGET=win
  else
    TARGET=unix
  endif
endif

CC=gcc
CFLAGS=-W -Wall -O3 -I.
OE=.o
OUTE=
LFLAGS=-s

ifeq ($(TARGET), win)
  ifndef WINDIR
    CC=i686-w64-mingw32-gcc
  endif
  OE=.obj
  OUTE=.exe
endif

ifeq ($(TARGET), ppc)
  CC=powerpc-linux-gnu-gcc
  OE=.po
  OUTE=.ppc
  LFLAGS=-static -s
endif

OBJECTS=chacha20_simple$(OE) test$(OE)

.SUFFIXES: .c

%$(OE): %.c
	$(CC) $(CFLAGS) -o $@ -c $<

ALL: test$(OUTE)

test$(OUTE): $(OBJECTS)
	$(CC) -o $@ $(OBJECTS) $(LFLAGS)

clean:
	rm -f test$(OUTE) $(OBJECTS)
