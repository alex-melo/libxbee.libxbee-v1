#-- set this to the man directory you would like to use
MANPATH:=/usr/share/man

#-- uncomment this to enable debugging
#DEBUG:=-g -DDEBUG


###### YOU SHOULD NOT CHANGE BELOW THIS LINE ######


SRCS:=api.c
MANS:=man3/libxbee.3 \
      man3/xbee_setup.3 \
      man3/xbee_setuplog.3 \
      man3/xbee_newcon.3 \
      man3/xbee_flushcon.3 \
      man3/xbee_endcon.3 \
      man3/xbee_getpacket.3 \
      man3/xbee_senddata.3 \
      man3/xbee_nsenddata.3 \
      man3/xbee_vsenddata.3 \
      man3/xbee_getdigital.3 \
      man3/xbee_hasdigital.3 \
      man3/xbee_getanalog.3 \
      man3/xbee_hasanalog.3 \
      man3/xbee_pkt.3
MANPATHS:=$(foreach dir,$(shell ls man -ln | grep ^d | tr -s ' ' | cut -d ' ' -f 9),${MANPATH}/$(dir))

PDFS:=${SRCS} ${SRCS:.c=.h} makefile main.c xbee.h globals.h

CC:=gcc
CFLAGS:=-Wall -Wstrict-prototypes -pedantic -c -fPIC ${DEBUG}
CLINKS:=-lm ./lib/libxbee.so.1.0.1 -lpthread ${DEBUG}
DEFINES:=

ifeq ($(strip $(wildcard ${MANPATH}/man3/libxbee.3.bz2)),)
FIRSTTIME:=TRUE
else
FIRSTTIME:=FALSE
endif

ENSCRIPT:=-MA4 --color -f Courier8 -C --margins=15:15:0:20
ifneq ($(strip $(wildcard /usr/share/enscript/mine-web.hdr)),)
  ENSCRIPT+= --fancy-header=mine-web
else
  ENSCRIPT+= --fancy-header=a2ps
endif

SRCS:=${sort ${SRCS}}
PDFS:=${sort ${PDFS}}

.PHONY: FORCE
.PHONY: all run new clean cleanpdfs main pdfs
.PHONY: install install_su install_man
.PHONY: uninstall uninstall_su uninstall_man/


# all - do everything (default) #
all: main
	@echo "*** Done! ***"


# run - remake main and then run #
run: main
	LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH ./bin/main


# new - clean and do everything again #
new: clean all


# clean - remove any compiled files and PDFs #
clean:
	rm -f ./*~
	rm -f ./svn_version.c
	rm -f ./sample/*~
	rm -f ./obj/*.o
	rm -f ./lib/libxbee.so*
	rm -f ./bin/main

cleanpdfs:
	rm -f ./pdf/*.pdf


# install - installs library #
install: ./lib/libxbee.so.1.0.1
	@echo
	@echo
ifneq ($(shell echo $$USER),root)
	@echo "#######################################################################################"
	@echo "### To Install this library I need the root password please!"
	@echo "#######################################################################################"
endif
	su -c "make install_su --no-print-directory"
	@echo
ifeq (${FIRSTTIME},TRUE)
	@echo "#######################################################################################"
	@echo
	@pr -h "" -o 3 -w 86 -tT ./README
	@echo
	@echo "#######################################################################################"
endif

install_su: /usr/lib/libxbee.so.1.0.1 /usr/include/xbee.h install_man

/usr/lib/libxbee.so.1.0.1: ./lib/libxbee.so.1.0.1
	cp ./lib/libxbee.so.1.0.1 /usr/lib/libxbee.so.1.0.1 -f
	@chmod 755 /usr/lib/libxbee.so.1.0.1
	@chown root:root /usr/lib/libxbee.so.1.0.1
	cp /usr/lib/libxbee.so.1.0.1 /usr/lib/libxbee.so.1 -sf
	@chown root:root /usr/lib/libxbee.so.1
	cp /usr/lib/libxbee.so.1.0.1 /usr/lib/libxbee.so -sf
	@chown root:root /usr/lib/libxbee.so

/usr/include/xbee.h: ./xbee.h
	cp ./xbee.h /usr/include/xbee.h -f
	@chmod 644 /usr/include/xbee.h
	@chown root:root /usr/include/xbee.h

install_man: ${MANPATH} ${MANPATHS} ${addsuffix .bz2,${addprefix ${MANPATH}/,${MANS}}}

${MANPATH} ${MANPATHS}:
	@echo "#######################################################################################"
	@echo "### $@ does not exist... cannot install man files here!"
	@echo "### Please check the directory and the MANPATH variable in the makefile"
	@echo "#######################################################################################"
	@false

${MANPATH}/%.bz2: ./man/%
	@echo "cat $< | bzip2 -z > $@"
	@cat $< | bzip2 -z > $@ || ( \
	  echo "#######################################################################################"; \
	  echo "### Installing man page '$*' to '$@' failed..."; \
	  echo "#######################################################################################"; )
	@chmod 644 $@
	@chown root:root $@

uninstall:
	@echo
	@echo
ifneq ($(shell echo $$USER),root)
	@echo "#######################################################################################"
	@echo "### To Uninstall this library I need the root password please!"
	@echo "#######################################################################################"
endif
	su -c "make uninstall_su --no-print-directory"
	@echo
	@echo

uninstall_su: ${addprefix uninstall_man/,${MANS}}
	rm /usr/lib/libxbee.so.1.0.1 -f
	rm /usr/lib/libxbee.so.1 -f
	rm /usr/lib/libxbee.so -f	
	rm /usr/include/xbee.h -f

uninstall_man/%:
	rm ${MANPATH}/$*.bz2 -f

# main - compile & link objects #
main: ./bin/main

./bin/main: ./lib/libxbee.so.1.0.1 ./bin/ ./main.c
	${CC} ${CLINKS} ./main.c -o ./bin/main ${DEBUG}

./bin/:
	mkdir ./bin/

./lib/libxbee.so.1.0.1: ./lib/ ./obj/ ${addprefix ./obj/,${SRCS:.c=.o}}  ./svn_version.c ./xbee.h
	gcc -shared -Wl,-soname,libxbee.so.1 -o ./lib/libxbee.so.1.0.1 ./obj/*.o -lrt
ifeq ($(strip $(wildcard ./lib/libxbee.so.1)),)
	ln ./libxbee.so.1.0.1 ./lib/libxbee.so.1 -sf
endif
ifeq ($(strip $(wildcard ./lib/libxbee.so)),)
	ln ./libxbee.so.1.0.1 ./lib/libxbee.so -sf
endif

./lib/:
	mkdir ./lib/

./obj/:
	mkdir ./obj/

./svn_version.c: api.c api.h globals.h xbee.h
	echo -n 'const char *xbee_svn_version(void) { return "' > ./svn_version.c
ifneq ($(strip $(wildcard /usr/bin/svnversion)),)
	svnversion -n . >> svn_version.c
else
	echo 'Unknown' >> svn_version.c
endif
	echo -n '";}' >> svn_version.c
	${CC} ${CFLAGS} ${DEFINES} ${DEBUG} svn_version.c -o ./obj/svn_version.o

./obj/%.o: %.c %.h xbee.h globals.h
	${CC} ${CFLAGS} ${DEFINES} ${DEBUG} $*.c -o $@

./obj/%.o: %.c xbee.h globals.h
	${CC} ${CFLAGS} ${DEFINES} ${DEBUG} $*.c -o $@


# pdfs - generate PDFs for each source file #
ifneq ($(strip $(wildcard /usr/bin/ps2pdf)),)
ifneq ($(strip $(wildcard /usr/bin/enscript)),)
pdfs: ./pdf/ ${addprefix ./pdf/,${addsuffix .pdf,${PDFS}}}

./pdf/:
	mkdir ./pdf/

./pdf/makefile.pdf: ./makefile
	enscript ${ENSCRIPT} -Emakefile $< -p - | ps2pdf - $@

./pdf/%.pdf: %
	enscript ${ENSCRIPT} -Ec $< -p - | ps2pdf - $@

./pdf/%.pdf:
	@echo "*** Cannot make $@ - '$*' does not exist ***"
else
pdfs:
	@echo "WARNING: enscript is not installed - cannot generate PDF files"
endif
else
pdfs:
	@echo "WARNING: ps2pdf is not installed - cannot generate PDF files"
endif
