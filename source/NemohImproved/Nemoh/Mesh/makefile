# makefile written by Christophe Peyrard from EDF R&D

#COMPILATEUR
gtest=$(shell which gfortran 2> /dev/null | grep -o gfortran)
itest=$(shell which ifort 2> /dev/null | grep -o ifort)

outputdir=../Mesh

ifeq ($(gtest), gfortran)
	FC=gfortran
	FFLAGS=-cpp -DGNUFORT -O2 -ffree-line-length-none -c
endif

ifeq ($(itest), ifort)
	FC=ifort
	FFLAGS=-c -cpp
endif

#SOURCES FORTRAN Mesh(modules de maillage)
SRCM=../commonFiles/Identification.f90\
hydre.f90\
Netting.f90\
mesh.f90\

# LISTE DES .o preProc
#TRANSFORME f90 en o  
OBJM=$(SRCM:.f90=.o)

#Liste pour transformer ./*/*.o en .o dans le OBJP (cf Yoann pour automatisation)  
OBJM2=Identification.o\
hydre.o\
Netting.o\
mesh.o\


build: mesh clean

#
#Rules to Build MAIN EXECUTABLE  (dependances et regle d'execution)
mesh:	$(OBJM) 
		$(FC) -o meshEXE $(OBJM2)

# Rules for .f comiplation
.f.o:
	$(FC) $(FFLAGS) $<
%.o:	%.f90
	$(FC) $(FFLAGS) $<

# Remove *.o and main executable
clean:
	rm *.o *.mod
