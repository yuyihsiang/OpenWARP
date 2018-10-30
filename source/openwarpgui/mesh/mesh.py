# Copyright 2014 the National Renewable Energy Laboratory
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""
This module serves provides utilities to work with the following mesh types:
    * WAMTI
    * Nemoh
    * VTK Polydata (*.vtp)
    * STL files

The functionality provided includes:
    * Ability to read mesh the mesh formats listed above
    * Ability to convert between mesh formats listed above
    * Utilities to calculate volume, surface area, linear sprint stiffness, and
    other related mesh parameters.

.. Note::
"""
import numpy as np

import imp

import os

from sys import platform as _platform

from copy import copy

from platform import system as _system

# try:

#     import vtk
#     from vtk.util.numpy_support import vtk_to_numpy


# except:

#     print 'The VTK Python module is required for a significant amnount of functionality in this module. Many functions will not be available for use.'



# class VTK_Exception(Exception):
#     pass

class PanelMesh(object):
    ''' Class to store mesh data. All mesh data is currently read and stored
    as quad elements. Tri elements are supported, but are stored as quad
    elements with a repeated point.

    Parameters:
        file_name : str
            Name of mesh file to read. Currently WAMIT (.gdf), Stereolithography
            (.stl), VTK PolyDATA (.vtp), and NEMOH (.dat) mesh formats are
            supported

    Attribuites:
        files : dictionary
            Dictionary containg input and output file names
        orig_type : str
            Mesh type of input file
        points : list
            List of points that define the mesh. `points[n] = [x coord, y coord, z coord]`.
        faces : list
            List of points that define connectivity for each face. `face[n] = [point 1 index
            , point 2 index, point 3 index, point 4 index]`, where 'point 1-4'
            are integres that correspond to the point index in the `points`
            attribuite.
        center_of_gravity : np.array
            Center of gravity of floating body
        center_of_buoyancy : np.array
            Center of buoyancy
        volume_vtk : np.array
            Mesh volume determined using VTK
        volume_x, y, and z : np.array
            Mesh volume determined using internal bemio calculations
        surface_area_vtk : float
            Surface area determined using VTK
        surface_area : float
            Surface area determined using internal bemio calculations
        normals : np.array
            Cell normals. This arrays is size `[faces.shape[0], 3]`.
            `normals[n] = [x, y, z]` is a vector that defines the normal vector
            for face `n`
        cell_surface_area : np.array
            Cell survace area. This array is size `[faces.shape[0], 3]`.
            `cell_surface_area[n]` is the surface aras of face[n].
        centroid : np.array
            Cell centroid. This array is size `[faces.shape[0], 3]`.
            `cell_surface_area[n]` is centroid of face[n].
        hydrostatic_stiffness : np.array
            The linear hydrostatic stiffness matrix of the mesh assuming the
            water surface is at z=0
        bounds : dictionary
            The bounds of the mesh. `bounds['min']` and `bounds['max']` are the
            minimum and maximum mesh dimensions, respectively
    '''
    def __init__(self,file_name):

        self.files = {}
        self.files['input_file'] = file_name

        self.orig_type = None
        self.points = []
        self.points_mod = []
        self.faces = []
        self.faces_mod = []
        self.center_of_gravity = np.array([0., 0., 0.])
        self._center_of_buoyancy = None
        self._volume_vtk = None
        self._volume_x = None
        self._volume_y = None
        self._volume_z = None
        self._surface_area = None
        self._surface_area_vtk = None
        self._normals = None
        self._cell_surface_area = None
        self._centroid = None
        self._hydrostatic_stiffness = None
        self._bounds = None

        self.zero_tol = -1.e-3

        try:

            imp.find_module('vtk')
            self.VTK_installed = True

        except :

            self.VTK_installed = False

        if os.path.isfile(file_name) is False:

            raise Exception('The file ' + file_name + ' does not exist')

    def __repr__(self):
        out_string = 'Object type: bemio.mesh_utilities.mesh.PanelMesh' + \
        '\nFile name: ' + str(self.files['input_file']) + \
        '\nNumber of points: ' + str(self.points.shape[0]) + \
        '\nNumber of faces: ' + str(self.faces.shape[0]) + \
        '\nOriginal mesh type: ' + str(self.orig_type) + \
        '\nMesh bounds:' + \
        '\n\tMax: ' + str(self.bounds['max']) + \
        '\n\tMin: ' + str(self.bounds['min']) + \
        '\nCenter of mass: ' + str(self.center_of_gravity) + \
        '\nCenter of buoyancy: ' + str(self.center_of_buoyancy) + \
        '\nMesh volume [volume_x, volume_y, volume_z]: [' + str(self.volume_x) + ', ' + str(self.volume_y) + ', ' + str(self.volume_z) + ']' + \
        '\nMesh surface area: ' + str(self.surface_area) + \
        '\nHydrostatic stiffness: ' + \
        '\n\tC[3,3], C[3,4], C[3,5]: '  +  str(self.hydrostatic_stiffness[2,2]) + ', ' + str(self.hydrostatic_stiffness[2,3]) + ', ' + str(self.hydrostatic_stiffness[2,4]) + \
        '\n\tC[4,4], C[4,5], C[4,6]: '  +  str(self.hydrostatic_stiffness[3,3]) + ', ' + str(self.hydrostatic_stiffness[3,4]) + ', ' + str(self.hydrostatic_stiffness[3,5]) + \
        '\n\tC[5,5], C[5,6]:         '  +  str(self.hydrostatic_stiffness[4,4]) + ', ' + str(self.hydrostatic_stiffness[4,5])

        return out_string

    @ property
    def bounds(self, ):
        if self._bounds is None:
            self._bounds = {}
            self._bounds['max'] = self.points.max(axis=0)
            self._bounds['min'] = self.points.min(axis=0)

        return self._bounds

    @property
    def hydrostatic_stiffness(self, ):
        '''Getter for the `hydrostatic_stiffness` variable.

        Calculated as defined in Section 3.1 of the WAMIT v7.0 users manual.
        '''
        if self._hydrostatic_stiffness is None:

            self._hydrostatic_stiffness = np.zeros([6,6])
            for face_n,face in enumerate(self.faces):

                if self.points[face[0]][2] <= self.zero_tol or \
                self.points[face[1]][2] <= self.zero_tol or \
                self.points[face[2]][2] <= self.zero_tol or \
                self.points[face[3]][2] <= self.zero_tol:
                    self._hydrostatic_stiffness[2,2] += -self.normals[face_n][2] * self.cell_surface_area[face_n]
                    self._hydrostatic_stiffness[2,3] += -self.centroid[face_n][1] * self.normals[face_n][2] * self.cell_surface_area[face_n]
                    self._hydrostatic_stiffness[2,4] += self.centroid[face_n][0] * self.normals[face_n][2] * self.cell_surface_area[face_n]
                    self._hydrostatic_stiffness[3,3] += -self.centroid[face_n][1]**2 * self.normals[face_n][2] * self.cell_surface_area[face_n]
                    self._hydrostatic_stiffness[3,4] += self.centroid[face_n][0] * self.centroid[face_n][1] * self.normals[face_n][2] * self.cell_surface_area[face_n]
                    self._hydrostatic_stiffness[4,4] += -self.centroid[face_n][0]**2 * self.normals[face_n][2] * self.cell_surface_area[face_n]

            self._hydrostatic_stiffness[3,3] += self.volume_x * self.center_of_buoyancy[2] - self.volume_x * self.center_of_gravity[2]
            self._hydrostatic_stiffness[3,5] += -self.volume_x * self.center_of_buoyancy[0] + self.volume_x * self.center_of_gravity[0]
            self._hydrostatic_stiffness[4,4] += self.volume_x * self.center_of_buoyancy[2] - self.volume_x * self.center_of_gravity[2]
            self._hydrostatic_stiffness[4,5] += -self.volume_x * self.center_of_buoyancy[1] + self.volume_x * self.center_of_gravity[1]

            print 'Calculated hydorstatic stiffness'

        return self._hydrostatic_stiffness

    @property
    def center_of_buoyancy(self, ):
        '''Getter for the `center_of_buoyancy` variable.

        Calculated as defined in Section 3.1 of the WAMIT v7.0 users manual.
        '''
        if self._center_of_buoyancy is None:
            x_b = 0.
            y_b = 0.
            z_b = 0.
            self._center_of_buoyancy = 0.

            for face_n,face in enumerate(self.faces):
                if self.points[face[0]][2] <= self.zero_tol or \
                self.points[face[1]][2] <= self.zero_tol or \
                self.points[face[2]][2] <= self.zero_tol or \
                self.points[face[3]][2] <= self.zero_tol:
                    x_b += self.normals[face_n][0]*self.centroid[face_n][0]**2*self.cell_surface_area[face_n]
                    y_b += self.normals[face_n][1]*self.centroid[face_n][1]**2*self.cell_surface_area[face_n]
                    z_b += self.normals[face_n][2]*self.centroid[face_n][2]**2*self.cell_surface_area[face_n]
            self._center_of_buoyancy = 1./(2.*self.volume_x )*np.array([x_b, y_b, z_b])

            print 'Calculated the center of buoyancy'

        return self._center_of_buoyancy


    @property
    def normals(self, ):
        if self._normals is None:
            self._normals = {}
            for face_n in xrange(self.faces.shape[0]):
                a = self.points[self.faces[face_n][1]] - self.points[self.faces[face_n][0]]
                b = self.points[self.faces[face_n][2]] - self.points[self.faces[face_n][1]]
                self._normals[face_n] = np.cross(a,b)

                if self._normals[face_n][0] == 0. and  self._normals[face_n][1] == 0. and self._normals[face_n][2] == 0.:
                    a = self.points[self.faces[face_n][2]] - self.points[self.faces[face_n][1]]
                    b = self.points[self.faces[face_n][3]] - self.points[self.faces[face_n][2]]
                    self._normals[face_n] = np.cross(a,b)

                if self._normals[face_n][0] == 0. and  self._normals[face_n][1] == 0. and self._normals[face_n][2] == 0.:
                    a = self.points[self.faces[face_n][2]] - self.points[self.faces[face_n][0]]
                    b = self.points[self.faces[face_n][3]] - self.points[self.faces[face_n][2]]
                    self._normals[face_n] = np.cross(a,b)

                self._normals[face_n] /= np.linalg.norm(self._normals[face_n])

            print 'Calculated mesh cell normals'

        return self._normals


    @property
    def cell_surface_area(self):
        '''Getter for `cell_surface_area`

        Calculated
        '''
        if self._cell_surface_area is None:
            self._cell_surface_area = {}
            for face_n in xrange(self.faces.shape[0]):
                a = self.points[self.faces[face_n][1]] - self.points[self.faces[face_n][0]]
                b = self.points[self.faces[face_n][2]] - self.points[self.faces[face_n][1]]
                c = self.points[self.faces[face_n][3]] - self.points[self.faces[face_n][2]]
                d = self.points[self.faces[face_n][0]] - self.points[self.faces[face_n][3]]
                self._cell_surface_area[face_n] = 1./2. * ( np.linalg.norm(np.cross(a,b)) + np.linalg.norm(np.cross(c,d)) )

            print 'Calculated surface cell area'

        return self._cell_surface_area

    @property
    def surface_area(self):
        if self._surface_area is None:

            self._surface_area = sum(self.cell_surface_area.values())

            print 'Calculated surface area'

        return self._surface_area

    @property
    def volume_vtk(self):
        if self.VTK_installed is False:
            raise VTK_Exception('VTK must be installed to access the volume_vtk property')

        if self._volume_vtk is None:
            tri_converter = vtk.vtkTriangleFilter()
            tri_converter.SetInputDataObject(self.vtp_mesh)
            tri_converter.Update()
            tri_mesh = tri_converter.GetOutput()
            mass_props = vtk.vtkMassProperties()
            mass_props.SetInputDataObject(tri_mesh)
            self._volume_vtk = mass_props.GetVolume()

            print 'Calculated mesh volume using VTK library'

        return self._volume_vtk

    @property
    def centroid(self):

        if self._centroid is None:
            self._centroid = {}

            for face_n,face in enumerate(self.faces):
                points = [self.points[face[0]],
                          self.points[face[1]],
                          self.points[face[2]],
                          self.points[face[3]]]

                points = map(np.asarray, set(map(tuple, points))) # This removes duplicate points... somehow
                self._centroid[face_n] = np.mean(points,axis=0)

        return self._centroid


    @property
    def volume_x(self):
        if self._volume_x is None:
            self._calc_component_vol()
        return self._volume_x


    @property
    def volume_y(self):
        if self._volume_y is None:
            self._calc_component_vol()
        return self._volume_y


    @property
    def volume_z(self):
        if self._volume_z is None:
            self._calc_component_vol()
        return self._volume_z


    @property
    def surface_area_vtk(self):
        if self.VTK_installed is False:
            raise VTK_Exception('VTK must be installed to access the surface_area_vtk property')
        if self._surface_area_vtk is None:
            tri_converter = vtk.vtkTriangleFilter()
            tri_converter.SetInputDataObject(self.vtp_mesh)
            tri_converter.Update()
            tri_mesh = tri_converter.GetOutput()
            mass_props = vtk.vtkMassProperties()
            mass_props.SetInputDataObject(tri_mesh)
            self._surface_area_vtk = mass_props.GetSurfaceArea()

            print 'Calculated mesh surface area using VTK Python bindings'

        return self._surface_area_vtk


    def write(self,mesh_format='VTP',refShift=[0,0,0]):
        '''Function to write NEMOH, WAMIT, or VTK PolyData formats.

        Parameters:
            mesh_format : string {'VTP', 'WAMIT', 'NEMOH'}
                Variable that specifies the mesh format to write.

        Examples:
            This example assumes that a mesh has been read by bemio and mesh
            data is contained in a `PanelMesh` object called `mesh`

            Here is how a WAMIT mesh would be written
            >>> mesh.write(mesh_format='WAMTI')
        '''
        if mesh_format == 'VTK' or mesh_format == 'VTP':
            self._write_vtp()

        if mesh_format == 'WAMIT' or mesh_format == 'GDF':
            self._write_gdf()

        if mesh_format == 'NEMOH':
            self._write_nemoh(refShift)


    def calculate_center_of_gravity_vtk(self, ):
        '''Function to calculate the center of gravity

        .. Note::
            The VTK Pytnon bindings must be installed to use this function

        Examples:
            This example assumes that a mesh has been read by bemio and mesh
            data is contained in a `PanelMesh` object called `mesh`

            >>> mesh.calculate_center_of_gravity_vtk()
        '''
        if self.VTK_installed is False:
            raise VTK_Exception('VTK must be installed to access the calculate_center_of_gravity_vtk function')

        com = vtk.vtkCenterOfMass()
        if vtk.VTK_MAJOR_VERSION >= 6:
            com.SetInputData(self.vtp_mesh)
        else:
            com.SetInput(self.vtp_mesh)
        com.Update()
        self.center_of_gravity = com.GetCenter()

        print 'Calculated center of gravity assuming uniform material density'

    # def cut(self,plane=2,value=0.0,direction=1):
    '''This function is not currently working 100%
    '''
    #     self.collapse(plane,value,direction)
    #
    #     tempFaces = []
    #     count = 0
    #
    #     for i in xrange(self.faces.shape[0]):
    #
    #        delete_face = 0
    #
    #        for j in xrange(4):
    #
    #            p = self.faces[i][j]
    #            z = float(self.cords[int(p)][2])
    #
    #            if z == 0.:
    #                delete_face += 1
    #
    #        if delete_face != 4:
    #            tempFaces.append(self.faces[i])
    #            count  += 1
    #
    #     print 'removed ' + str(count) + ' surface faces'
    #     self.faces = tempFaces
    #     self.faces.shape[0] = self.faces.shape[0]

    def view(self, color=[0.5,1,0.5], opacity=1.0, save_png=False, camera_pos=[50,50,50], interact=True):
        '''Function to view the mesh using the VTK library

        Parameters:
            color : list, optional
                VTK color specification for the mesh
            opackty : float, optional
                VTK opacity for the mesh. Must be between 0. and 1.
            save_png : bool
                Boolean operater that determines if a .png image of the mesh is
                saved.
            interact : bool, optional
                Boolean operater that determines if the user can interact with
                the geometry (e.g. zoom and rotate) after it is displayed
            camera_pos : list, optional

        Examples:
            This example assumes that a mesh has been read by bemio and mesh
            data is contained in a `PanelMesh` object called `mesh`

            >>> mesh.view()

            The mesh view window must be closed in order to return command to
            the Python shell
        '''
        if self.VTK_installed is False:
            raise VTK_Exception('VTK must be installed to use the view function')

        # Create a mapper and load VTP data into the mapper
        mapper=vtk.vtkPolyDataMapper()
        if vtk.VTK_MAJOR_VERSION >= 6:
            mapper.SetInputData(self.vtp_mesh)
        else:
            mapper.SetInput(self.vtp_mesh)

        # Create an actor that contains the data in the mapper
        actor=vtk.vtkActor()
        actor.GetProperty().SetColor(color)
        actor.GetProperty().SetOpacity(opacity)
        actor.SetMapper(mapper)
        actor.GetProperty().EdgeVisibilityOn()

        # Camera
        camera = vtk.vtkCamera();
        camera.SetPosition(camera_pos)
        camera.SetFocalPoint(0, 0, 0)

        # Add axes
        axes = vtk.vtkAxesActor()

        # Render the data
        ren = vtk.vtkRenderer()
        ren.AddActor(actor)
        ren.AddActor(axes)
        ren.SetActiveCamera(camera)

        # Create a render window
        renWin = vtk.vtkRenderWindow()
        renWin.AddRenderer(ren)
        renWin.SetSize(800, 800)

        # Start the visiuilization
        iren = vtk.vtkRenderWindowInteractor()
        iren.SetRenderWindow(renWin)
        ren.SetBackground(0,0,0)
        renWin.Render()


        vtk.vtkPolyDataMapper().SetResolveCoincidentTopologyToPolygonOffset()

        if save_png is True:
            w2if = vtk.vtkWindowToImageFilter()
            w2if.SetInput(renWin)
            w2if.Update()

            writer = vtk.vtkPNGWriter()
            writer.SetFileName(self.files['png_image'])
            writer.SetInputDataObject(w2if.GetOutput())
            writer.Write()

            print 'Wrote mesh image to: ' + self.files['png_image']

        if interact is True:
            iren.Start()

    def scale(self, scale_vect):
        '''Function used to scale mesh objects in the x, y, and z directions.

        Parameters:
            scale_vect : list
                A list that contains the x, y, and z scale factors for the mesh

        Examples:
            This example assumes that a mesh has been read by bemio and mesh
            data is contained in a `PanelMesh` object called `mesh`

            Here is how to scale a mesh by a factor of 2 in the x direction and
            .5 in the y direction:

            >>> mesh.scale(scale_vect=[2, 0.5, 1])
        '''
        scale_vect = np.array(scale_vect)
        if scale_vect.size != 3:
            raise Exception('The scale_vect input must be a length 3 vector')
        self.points = self.points*scale_vect
        self.scale_vect = scale_vect
        self._create_vtp_mesh()
        print 'Scaled mesh by: ' + str(scale_vect)

    def translate(self,translation_vect,translate_cog=True):
        '''Function used to translate mesh obvjects in the x, y, and z directions.

        Parameters:
            translation_vect : list
                A list that contains the desired x, y, and z translation for the
                mesh

        Examples:
            This example assumes that a mesh has been read by bemio and mesh
            data is contained in a `PanelMesh` object called `mesh`

            Here is how to translate a mesh by 2 in the x direction and
            .5 in the y direction:

            >>> mesh.translate(scale_vect=[2, 0.5, 0])
        '''
        translation_vect = np.array(translation_vect)
        if translation_vect.size != 3:
            raise Exception('The translation_vect input must be a length 3 vector')
        self.points += translation_vect
        self.translation_vect = translation_vect

        if translate_cog is True:
            self.center_of_gravity += translation_vect

        print 'Translated mesh by: ' + str(translation_vect) + '\nCenter of gravity is: ' + str(self.center_of_gravity)

    def open(self):
        '''Function to open a VTK PolyData object in the default viewer of your
        operating system.

        .. Note::
            This function is only available for OSX and Linux systems and
            and requires you have a program installed that has the ability to
            open VTK PolyData (.vtp) files.

        Example:
            This example assumes that a mesh has been read by bemio and mesh
            data is contained in a `PanelMesh` object called `mesh`

            >>> mesh.open()
        '''
        self.write(mesh_format='VTP')
        if _system() == 'Darwin':
            os.system('open ' + self.files['vtp'])

        elif _system() == 'Linux':
            os.system('xdg ' + self.files['vtp'])

        else:
            raise Exception('The open function is only supported for OSX')



    def _write_nemoh(self,refShift):
        '''Internal function to write NEMOH mesh files
        '''
        self.points_modT = np.zeros([len(self.points),3])
        self.points_mod  = np.zeros([len(self.points),3])
        self.faces_mod   = np.zeros([len(self.faces),4])

        with open(self.files['nemoh'],'w') as fid:
            fid.write('2 0') # This should not be hard coded
            fid.write('\n')
            for i in xrange(self.points.shape[0]):
                a=eval(self.points[i,0])+refShift[0]
                b=eval(self.points[i,1])+refShift[1]
                c=eval(self.points[i,2])+refShift[2]
                self.points_modT[i]=[a,b,c]

            k = 0
            j = 0
            for i in xrange(self.faces.shape[0]):
                if all(self.points_modT[i*4:i*4+4,2] == 0):
                   j = j+1
                else:
                   k = k+1
                   self.points_mod[(k-1)*4:(k-1)*4+4] = self.points_modT[i*4:i*4+4]
                   self.faces_mod[k-1] = self.faces[i]

            for i in xrange(4*k):
                fid.write(str(i+1) + ' ' +str(self.points_mod[i]).replace('[','').replace(']',''))
                fid.write('\n')
            fid.write('0 0 0 0')
            fid.write('\n')
            for i in xrange(k):
                fid.write(str(self.faces[i]+1).replace('[','').replace(']','').replace('.',''))
                fid.write('\n')
            fid.write('0 0 0 0')

        print ' '
        print 'Wrote NEMOH mesh to: ' + str(self.files['nemoh'])
        print 'Final numebr of meshes: ' + str(k)
        print ' '


    def _write_gdf(self):
        '''Internal function to write WAMIT mesh files
        '''
        with open(self.files['wamit'],'w') as fid:
            fid.write('Mesh file written by meshio.py')
            fid.write('\n')
            fid.write('1 9.80665       ULEN GRAV')
            fid.write('\n')
            fid.write('0  0    ISX  ISY')
            fid.write('\n')
            fid.write(str(self.faces.shape[0]))
            fid.write('\n')
            for i,face in enumerate(self.faces):
                if np.size(face) is 4: # if the mesh element is a quad
                    for j,pointKey in enumerate(face):
                        fid.write(str(self.points[pointKey]).replace(',','').replace('[','').replace(']','') + '\n')
                if np.size(face) is 3: # if the mesh element is a tri
                    faceMod = np.append(face,face[-1])
                    for j,pointKey in enumerate(faceMod):
                        fid.write(str(self.points[pointKey]).replace(',','').replace('[','').replace(']','') + '\n')

        print 'Wrote WAMIT mesh to: ' + str(self.files['wamit'])

    def _calc_component_vol(self, ):
        '''Internal function to calculate mesh volume using the methods
        described in Section 3.1 the WAMIT v7.0 users manual.
        '''
        self._volume_x = 0.
        self._volume_y = 0.
        self._volume_z = 0.
        volume = 0.

        for face_n in xrange(self.faces.shape[0]):
            volume += self.normals[face_n]*self.centroid[face_n]*self.cell_surface_area[face_n]

        self._volume_x = volume[0]
        self._volume_y = volume[1]
        self._volume_z = volume[2]

        print 'Calculated x y and z mesh volumes'

def _read_gdf(file_name):
    '''Internal function to read gdf wamit meshes
    '''

    with open(file_name,'r') as fid:

        lines = fid.readlines()

    mesh_data = PanelMesh(file_name)
    mesh_data.orig_type = 'WAMIT (.gdf)'

    mesh_data.gdfLines = lines
    mesh_data.uLen = float(lines[1].split()[0])
    mesh_data.gravity = float(lines[1].split()[1])
    mesh_data.isx = float(lines[2].split()[0])
    mesh_data.isy = float(lines[2].split()[1])
    mesh_data.num_faces = int(lines[3].split()[0])
    mesh_data.num_points = mesh_data.num_faces * 4
    mesh_data.points = np.array([temp.split() for temp in lines[4:]])

    mesh_data.pointsString = [str(temp).replace(","      ,'').replace('\r','') for temp in lines[4:]] # Output string for Nemoh mesh fil

    for panelNum,i in enumerate(np.arange(4,4+mesh_data.num_points,4)):

        mesh_data.faces.append(np.array([i-4,i-3,i-2,i-1]))

    mesh_data.faces = np.array(mesh_data.faces)

    return mesh_data

def _read_stl(file_name):
    '''Internal function to read stl mesh files
    '''

    reader = vtk.vtkSTLReader()
    reader.SetFileName(file_name)
    reader.Update()

    mesh_data = PanelMesh(file_name)
    mesh_data.orig_type = 'Stereolithography (.stl)'
    mesh_data.num_faces = int(reader.GetOutput().GetNumberOfCells())
    mesh_data.num_points = mesh_data.num_faces * 3
    for i in range(mesh_data.num_faces):
        n = i*3
        mesh_data.faces.append(np.array([n,n+1,n+2,n+2]))
        mesh_data.points.append(np.array(vtk_to_numpy(reader.GetOutput().GetCell(i).GetPoints().GetData())))
    mesh_data.points = np.array(mesh_data.points).reshape([mesh_data.num_faces*3,3])

    return mesh_data

def _read_vtp(file_name):
    '''Internal function to read vtp mesh files
    '''

    reader = vtk.vtkXMLPolyDataReader()
    reader.SetFileName(file_name)
    reader.Update()

    mesh_data = PanelMesh(file_name)
    mesh_data.orig_type = 'VTK Polydata (.vtp)'
    readerOut = reader.GetOutput()
    mesh_data.num_faces =    int(readerOut.GetNumberOfCells())
    mesh_data.num_points =   int(readerOut.GetNumberOfPoints())

    for i in xrange(mesh_data.num_points):
        mesh_data.points.append(readerOut.GetPoint(i))
    mesh_data.points = np.array(mesh_data.points)

    for i in xrange(mesh_data.num_faces):
        c = readerOut.GetCell(i)
        numCellPoints = int(c.GetNumberOfPoints())
        idsTemp = []
        for i in xrange(numCellPoints):
            idsTemp.append(int(c.GetPointId(i)))
        mesh_data.faces.append(np.array(idsTemp))
    mesh_data.faces = np.array(mesh_data.faces)


    return mesh_data

def _read_nemoh(file_name):
    '''Internal function to read nemoh mesh
    '''

    with open(file_name,'r') as fid:

        lines = fid.readlines()
    temp = np.array([np.array(str(lines[i]).split()).astype(float) for i in range(1,np.size(lines))])
    count = 0

    mesh_data = PanelMesh(file_name)
    mesh_data.orig_type = 'NEMOH (.dat)'

    while temp[count,0] != 0.:

        mesh_data.points.append(temp[count,1:])
        count += 1
    count += 1
    while sum(temp[count,:]) != 0.:

        mesh_data.faces.append(temp[count,:])
        count += 1
    mesh_data.points = np.array(mesh_data.points)
    mesh_data.faces = np.array(mesh_data.faces)-1
    mesh_data.num_points = np.shape(mesh_data.points)[0]
    mesh_data.num_faces = np.shape(mesh_data.faces)[0]

    return mesh_data


def read(file_name):
    '''Function to read surface mesh files. Currently VTK PolyData (.vtk),
    WAMIT (.gdf), NEMOH (.dat), and Stereolithography (.stl) mesh formats are
    supported

    Parameters:
        file_name : str
            Name of the mesh file

    Returns:
        mesh_data : PanelMesh
            A PanelMesh object that contains the mesh data

    Exmaples:
        This example assumes that a VTK PlolyData mesh named mesh.vtp exists
        in the current working directory

        >>> mesh = read('mesh.vtp')

        The mesh can then be converted to another format using the `write`
        function. In this case a wamit mesh is created.

        >>> mesh.write(mesh_format='WAMIT')

        If the VTK python bindings are installed the mesh can be viewed using
        the following command:

        >>> mesh.view()

        If you would are using OSX or Linux and have Paraview installed you can
        view the file using the follwing command:

        >>> mesh.open()
    '''
    print 'Reading mesh file: ' + str(file_name)

    file_name = os.path.abspath(file_name)
    (f_name,f_ext) = os.path.splitext(file_name)

    if f_ext == '.GDF' or f_ext == '.gdf':
        mesh_data = _read_gdf(file_name)

    elif f_ext == '.stl':
        mesh_data = _read_stl(file_name)

    elif f_ext == '.vtp':
        mesh_data = _read_vtp(file_name)

    elif f_ext == '.dat':
        mesh_data = _read_nemoh(file_name)

    else:
        raise Exception(f_ext + ' is an unsupported file mesh file type')


    mesh_data.files_base = os.path.splitext(file_name)[0] 
    head, tail = os.path.split(mesh_data.files_base)
    
    mesh_data.files['vtp'] = mesh_data.files_base + '.vtp'
    mesh_data.files['wamit'] = mesh_data.files_base + '.gdf'
    mesh_data.files['nemoh'] = mesh_data.files_base + '.dat'
    #mesh_data.files['nemoh'] = os.path.dirname(file_name)+ tail + '.dat'
    mesh_data.files['png'] = os.path.splitext(file_name)[0] + '.png'

    if mesh_data.VTK_installed is True:

        mesh_data._create_vtp_mesh()

    print 'Successfully read mesh file: ' + str(file_name)

    return mesh_data

def _mk_vtk_id_list(it):
    '''
    Internal function to make vtk id list object

    Parameters:
        it : list
            List of nodes that define a face
    Returns:
        vil: vtkIdList
            A vtkIdList object
    '''
    vil = vtk.vtkIdList()
    for i in it:
        vil.InsertNextId(int(i))

    return vil

def collapse_to_plane(mesh_obj, plane_ind=2, plane_loc=-1e-5, cut_dir=1.):
    '''Function to collapse points to a given plane

    .. Note::
        This function is not yet implemented
    '''
    pass


def cut_mesh(mesh_obj, plane_ind=2, plane_loc=-1e-5, cut_dir=1.):
    '''Function to remove cells on one side of plane

    .. Note::
        This function is still early in the stages of development and needs
        to be improved and made more robust.

    Parameters:
        mesh_obj : PanelMesh
            Mesh object to cut
        plane_ind : int, optional
            Index of plane along which to cut the mesh, 0 == x, 1 == y, 2 == z
        plane_loc : float
            Location of the mesh cut
        cut_dir : int, {1, -1}
            Direction for the mesh cut

    Returns:
        cut_mesh : PanelMesh
            Panel mesh object that has been cut as specified

    Examples:
        None avaiable to data
    '''
    cut_mesh = copy(mesh_obj)
    tempFaces = []
    cut_mesh.removed_faces = []
    cut_mesh.removed_points = []

    for face_n,face in enumerate(cut_mesh.faces):
        if cut_mesh.points[face[0]][plane_ind] <= plane_loc*cut_dir or \
        cut_mesh.points[face[1]][plane_ind] <= plane_loc*cut_dir or \
        cut_mesh.points[face[2]][plane_ind] <= plane_loc*cut_dir or \
        cut_mesh.points[face[3]][plane_ind] <= plane_loc*cut_dir:

            tempFaces.append(face)

        else:
            cut_mesh.removed_faces.append(face)
            cut_mesh.removed_points.append(cut_mesh.points[face[0]])
            cut_mesh.removed_points.append(cut_mesh.points[face[1]])
            cut_mesh.removed_points.append(cut_mesh.points[face[2]])
            cut_mesh.removed_points.append(cut_mesh.points[face[3]])

    cut_mesh.faces = np.array(tempFaces)
    cut_mesh.removed_faces = np.array(cut_mesh.removed_faces)
    cut_mesh.removed_points = np.array(cut_mesh.removed_points)
    cut_mesh._create_vtp_mesh()

    cut_mesh.files_base = os.path.splitext(cut_mesh.file_name)[0] + '_cut_mesh_bemio_output'

    print 'Cut mesh in direction [' + str(plane_ind) + '] in direction [' + str(cut_dir) + '] at the location [' + str(plane_loc) + ']'

    return cut_mesh
