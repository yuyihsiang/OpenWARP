% 
% --> function [Mass,Inertia,KH,XB,YB,ZB]=GDFMesh(fname,tX,CG,nfobj)
%
% Purpose : Convert a WAMIT .gdf mesh file to Nemoh. Symmetry about xOz is
%           expected.
%
% Inputs : description of body surface in large panels
%   - fname             : filename of the GDF file in the format 'file.GDF'
%   - tX(1)             : translations
%   - CG(1,3)           : position of gravity centre
%   - nfobj(1)           : target number of panels for Aquaplus mesh
%
% Outputs : hydrostatics
%   - Mass(1)               : masses of bodies
%   - Inertia(1,6,6)        : inertia matrices (estimated assuming mass is distributed on
%   wetted surface)
%   - KH(1,6,6)             : hydrostatic stiffness matrices
%   - XB,YB,ZB              : coordinaates of buoyancy centers
%
% Copyright Ecole Centrale de Nantes 2014
% Licensed under the Apache License, Version 2.0
% Written by L. Banos, Univ of Gran Canarias and A. Babarit, LHEEA Lab 
%
function [Mass,Inertia,KH,XB,YB,ZB]=GDFMesh(fname,tX,CG,nfobj)
nBodies=1;
status=close('all');
%nomrep=input('\n - Directory name for storage of results : ');
nomrep='GDFMesh'
system(['mkdir ',nomrep]);
system(['mkdir ',nomrep,filesep,'mesh']);
system(['mkdir ',nomrep,filesep,'results']);
fid=fopen('ID.dat','w');
fprintf(fid,['% g \n',nomrep,' \n'],length(nomrep));
status=fclose(fid);
clear KH Mass Inertia XB YB ZB nx nf
Mass=zeros(nBodies,1);
KH=zeros(nBodies,6,6);
Inertia=zeros(nBodies,6,6);
XB=zeros(nBodies,1);
YB=zeros(nBodies,1);
ZB=zeros(nBodies,1);
WPA=zeros(nBodies,1);
nx=zeros(nBodies,1);
nf=zeros(nBodies,1);
%Number of panels
NPAN=zeros(nBodies,1);

%% Reading and Grouping of node coordinates in .GDF file
fid = fopen(fname,'r');
% Program info
header_a = fgetl(fid);
% binit92- 
disp('binit92')
%disp(header_a)

% Dimensional length ULEN and gravity constant GRAV
header_a2 = textscan(fid,'%f %f %s %s\n');

ULEN = header_a2{1,1};
GRAV = header_a2{1,2};

% Symmetry info ISX ISY
header_a3 = textscan(fid,'%f %f %s %s\n');

ISX = header_a3{1,1};
ISY = header_a3{1,2};
%binit92
disp(ISX)
disp(ISY)

%Number of panels NPAN
header_a4 = cell2mat(textscan(fid,'%f\n'));

dbstop if error
NPAN(1,1) = header_a4(2,1);
%NPAN = header_a4(2,1);

%Read Point coordinates X,Y and Z
data = fscanf(fid,'%f %f %f \n');


ds = 3;% number of coordinates


ll = 0;
% group coords by nodes
for ii = 1:1:length(data)/ds
    ll = ll+1;
    xn(ll,1) = data(ii+2*(ii-1),1);
    yn(ll,1) = data(ii+1+2*(ii-1),1);
    zn(ll,1) = data(ii+2+2*(ii-1),1);
end
dq = 4;% quadrangular panels
for jj = 1:1:NPAN
    X(1,jj,:,:) = [xn(1+dq*(jj-1),1) yn(1+dq*(jj-1),1) zn(1+dq*(jj-1),1);xn(...
     2+dq*(jj-1),1) yn(2+dq*(jj-1),1) zn(2+dq*(jj-1),1);xn(3+dq*(jj-1),1) ...
     yn(3+dq*(jj-1),1) zn(3+dq*(jj-1),1);xn(4+dq*(jj-1),1) yn(4+dq*(jj-1),1)...
     zn(4+dq*(jj-1),1)];
end


%% Symmetry check
sgn=X(1,1,1,2);
for c=1:nBodies
    for d=1:NPAN(c)
        for i=1:4
            if (sgn*X(c,d,i,2) < 0)
                input('\n Be careful: it is assumed that a symmetry about the (xOz) plane is used. \n Only one half of the mesh must be descrided. \n The mesh will not be generated. \n');
                return;
            end;
        end;
    end;
end
%% Sauvegarde de la description du maillage
for c=1:nBodies
    fprintf('\n -> Meshing body number %g \n',c);
    clear x y z tri;
    fid=fopen([,nomrep,filesep,'mesh',filesep,'mesh',int2str(c)],'w');
    fprintf(fid,'%g \n',4*NPAN(c));
    fprintf(fid,'%g \n',NPAN(c));
    nx(c)=0;
    for i=1:NPAN(c)
        for j=1:4
            nx(c)=nx(c)+1;
            x(nx(c))=X(c,i,j,1);
            y(nx(c))=X(c,i,j,2);
            z(nx(c))=X(c,i,j,3);
            fprintf(fid,'%E %E %E \n',[X(c,i,j,1) X(c,i,j,2) X(c,i,j,3)]);
        end;
    end;
    for i=1:NPAN(c)
        fprintf(fid,'%g %g %g %g \n',[4*(i-1)+1 4*(i-1)+2 4*(i-1)+3 4*(i-1)+4]');
    end;
    status=fclose(fid);
    % Affichage de la description du maillage
    nftri=0;
    for i=1:NPAN(c)
        nftri=nftri+1;
        tri(nftri,:)=[4*(i-1)+1 4*(i-1)+2 4*(i-1)+3];
        nftri=nftri+1;
        tri(nftri,:)=[4*(i-1)+1 4*(i-1)+3 4*(i-1)+4];
    end;
%    figure;
%    trimesh(tri,x,y,z,[zeros(nx(c),1)]);
%    title('Characteristics of the discretisation');
    fprintf('\n --> Number of nodes             : %g',nx(c));
    fprintf('\n --> Number of panels (max 2000) : %g \n',NPAN(c));
%   Creation des fichiers de calcul du maillage
    fid=fopen('Mesh.cal','w');
    fprintf(fid,['mesh',int2str(c),'\n'],1);
    fprintf(fid,'1 \n %f 0. \n ',tX(c));
    fprintf(fid,'%f %f %f \n',CG(c,:));
    fprintf(fid,'%g \n 2 \n 0. \n 1.\n',nfobj(c));
    status=fclose(fid);
%%   Raffinement automatique du maillage et calculs hydrostatiques
    l = ispc;
    if l == 1
        system('mesh >Mesh.log');
    else
        system('.\Mesh\Mesh.exe >Mesh\Mesh.log');
    end
%%   Visualisation du maillage
    clear x y z NN nftri tri u v w xu yv zw;
    fid=fopen([nomrep,filesep,'mesh',filesep,'mesh',int2str(c),'.tec'],'r');
    ligne=fscanf(fid,'%s',2);
    nx(c)=fscanf(fid,'%g',1);
    ligne=fscanf(fid,'%s',2);
    nf(c)=fscanf(fid,'%g',1);
    ligne=fgetl(fid);
    fprintf('\n Characteristics of the mesh for Nemoh \n');
    fprintf('\n --> Number of nodes : %g',nx(c));
    fprintf('\n --> Number of panels : %g\n \n',nf(c));
    for i=1:nx(c)
        ligne=fscanf(fid,'%f',6);
        x(i)=ligne(1);
        y(i)=ligne(2);
        z(i)=ligne(3);
    end;
    for i=1:nf(c)
        ligne=fscanf(fid,'%g',4);
        NN(1,i)=ligne(1);
        NN(2,i)=ligne(2);
        NN(3,i)=ligne(3);
        NN(4,i)=ligne(4);
    end;
    nftri=0;
    for i=1:nf(c)
        nftri=nftri+1;
        tri(nftri,:)=[NN(1,i) NN(2,i) NN(3,i)];
        nftri=nftri+1;
        tri(nftri,:)=[NN(1,i) NN(3,i) NN(4,i)];
    end;
    ligne=fgetl(fid);
    ligne=fgetl(fid);
    for i=1:nf(c)    
        ligne=fscanf(fid,'%g %g',6);
        xu(i)=ligne(1);
        yv(i)=ligne(2);
        zw(i)=ligne(3);
        u(i)=ligne(4);
        v(i)=ligne(5);
        w(i)=ligne(6);
    end;
    status=fclose(fid);
    figure;
    trimesh(tri,x,y,z);
    hold on;
    quiver3(xu,yv,zw,u,v,w);
    title('Mesh for Nemoh');
    fid=fopen([nomrep,filesep,'mesh',filesep,'KH.dat'],'r');
    for i=1:6   
        ligne=fscanf(fid,'%g %g',6);
        KH(c,i,:)=ligne;
    end;
    status=fclose(fid);
    fid=fopen([nomrep,filesep,'mesh',filesep,'Hydrostatics.dat'],'r');
    ligne=fscanf(fid,'%s',2);
    XB(c)=fscanf(fid,'%f',1);
    ligne=fgetl(fid);
    ligne=fscanf(fid,'%s',2);
    YB(c)=fscanf(fid,'%f',1);
    ligne=fgetl(fid);
    ligne=fscanf(fid,'%s',2);
    ZB(c)=fscanf(fid,'%f',1);
    ligne=fgetl(fid);
    ligne=fscanf(fid,'%s',2);
    Mass(c)=fscanf(fid,'%f',1)*1025.;
    ligne=fgetl(fid);
    ligne=fscanf(fid,'%s',3);
    WPA(c)=fscanf(fid,'%f',1);
    status=fclose(fid);
    clear ligne
    fid=fopen([nomrep,filesep,'mesh',filesep,'Inertia_hull.dat'],'r');
    for i=1:3
        ligne=fscanf(fid,'%g %g',3);
        Inertia(c,i+3,4:6)=ligne;
    end;
    Inertia(c,1,1)=Mass(c);
    Inertia(c,2,2)=Mass(c);
    Inertia(c,3,3)=Mass(c);
    if (~(c == nBodies))
        next=input('Press enter to proceed with next body ');
    end
end;
%% Write Nemoh input file
fid=fopen([nomrep,filesep,'Nemoh.cal'],'w');
fprintf(fid,'--- Environment ------------------------------------------------------------------------------------------------------------------ \n');
fprintf(fid,'1000.0				! RHO 			! KG/M**3 	! Fluid specific volume \n');
fprintf(fid,'9.81				! G			! M/S**2	! Gravity \n');
fprintf(fid,'0.                 ! DEPTH			! M		! Water depth\n');
fprintf(fid,'0.	0.              ! XEFF YEFF		! M		! Wave measurement point\n');
fprintf(fid,'--- Description of floating bodies -----------------------------------------------------------------------------------------------\n',c);
fprintf(fid,'%g				! Number of bodies\n',nBodies);
for c=1:nBodies
    fprintf(fid,'--- Body %g -----------------------------------------------------------------------------------------------------------------------\n',c);
    if isunix 
        fprintf(fid,['''',nomrep,filesep,'mesh',filesep,'mesh',int2str(c),'.dat''		! Name of mesh file\n']);
    else
        fprintf(fid,[nomrep,'\\mesh\\mesh',int2str(c),'.dat      ! Name of mesh file\n']);
    end;
    fprintf(fid,'%g %g			! Number of points and number of panels 	\n',nx(c),nf(c));
    fprintf(fid,'6				! Number of degrees of freedom\n');
    fprintf(fid,'1 1. 0.	0. 0. 0. 0.		! Surge\n');
    fprintf(fid,'1 0. 1.	0. 0. 0. 0.		! Sway\n');
    fprintf(fid,'1 0. 0. 1. 0. 0. 0.		! Heave\n');
    fprintf(fid,'2 1. 0. 0. %f %f %f		! Roll about a point\n',CG(c,:));
    fprintf(fid,'2 0. 1. 0. %f %f %f		! Pitch about a point\n',CG(c,:));
    fprintf(fid,'2 0. 0. 1. %f %f %f		! Yaw about a point\n',CG(c,:));
    fprintf(fid,'6				! Number of resulting generalised forces\n');
    fprintf(fid,'1 1. 0.	0. 0. 0. 0.		! Force in x direction\n');
    fprintf(fid,'1 0. 1.	0. 0. 0. 0.		! Force in y direction\n');
    fprintf(fid,'1 0. 0. 1. 0. 0. 0.		! Force in z direction\n');
    fprintf(fid,'2 1. 0. 0. %f %f %f		! Moment force in x direction about a point\n',CG(c,:));
    fprintf(fid,'2 0. 1. 0. %f %f %f		! Moment force in y direction about a point\n',CG(c,:));
    fprintf(fid,'2 0. 0. 1. %f %f %f		! Moment force in z direction about a point\n',CG(c,:));
    fprintf(fid,'0				! Number of lines of additional information \n');
end
fprintf(fid,'--- Load cases to be solved -------------------------------------------------------------------------------------------------------\n');
fprintf(fid,'1	0.8	0.8		! Number of wave frequencies, Min, and Max (rad/s)\n');
fprintf(fid,'1	0.	0.		! Number of wave directions, Min and Max (degrees)\n');
fprintf(fid,'--- Post processing ---------------------------------------------------------------------------------------------------------------\n');
fprintf(fid,'1	0.1	10.		! IRF 				! IRF calculation (0 for no calculation), time step and duration\n');
fprintf(fid,'0				! Show pressure\n');
fprintf(fid,'0	0.	180.		! Kochin function 		! Number of directions of calculation (0 for no calculations), Min and Max (degrees)\n');
fprintf(fid,'0	50	400.	400.	! Free surface elevation 	! Number of points in x direction (0 for no calcutions) and y direction and dimensions of domain in x and y direction\n');	
fprintf(fid,'---')
status=fclose(fid);
fclose('all');
end
