# Spirix.rb - Version 1.5 - (C) 2010-2017 by Aqualung - Permission granted to freely use this
# code as long as this line and the preceding line are included in any derivative work(s) JRH
#
#  8/23/13 version 0.91 - added SpirixParameters dictionary to store input parameters so they
#                         are re-displayed the next time.
#  8/31/13 version 0.92 - added group transform logic to the functions that use groups so that
#                         they now may be moved and re-oriented at will and used from their new
#                         location.
#  8/31/13 version 0.93 - added code to auto-delete entities used to create surfaces or groups.
# 12/11/13 version 0.94 - added new module for patterns - uses named group for input and provides
#                         revolution, rotation, scaling, z-transform, and radial delta for one
#                         or more copies.
# 12/12/13 version 1.0  - Modified pattern input to accept more intuitive values - Added auto-
#                         naming for copies when a name is supplied - Added "X Centroid Offset"
#                         and "Y/Z Centroid Offset" to give a little more flexibility to those
#                         operations involving rotations - Mostly ready for Prime Time (hence the
#                         1.0 version number).
# 09/18/14 version 1.1  - Added interpolation to the rotation parameter (Linear, Sine, Arc1)
#                         Refined polygon creation - eliminated points being added to the mesh
# 11/07/14 version 1.2  - Added offset surface options -> Offset = 0 then normal surface creation
#                         Added offset side skirts (Side 1, Side 2, End 1, and End 2)
# 11/12/14 version 1.2a - Replaced "i.typename == 'Edge'" with "i.is_a? Sketchup::Edge" where
#                         appropriate
# 11/15/14 version 1.3  - Added rotation in the plane of the geometry (includes projected offsets)
#                         Replaced "if"s with ternary operators for unambiguous definitions
#                         Replaced "if(x_flag)"s with "if(x_flag == 1)"s, etc.
# 11/18/14 version 1.4  - Added support for SPIRIX_AXES
# 12/26/15 version 2.0  - Converted to Spirix module - modified to work with different units
# 12/27/15 version 2.1  - Added ability to retain edges as sub-named groups
# 12/16/16 version 2.2  - Added Create from Face function
# 04/01/17 version 2.3  - Fixed Bug in Face Function
#-----------------------------------------------------------------------
require 'sketchup.rb'
#-----------------------------------------------------------------------
module Spirix
  module SpirixPolygonMesh
# MAIN BODY -----------------------------------------------------------------------------
    class << self
      @@model = Sketchup.active_model
      @@name = ''
      @@create_edges = 'No'
      def create_spirix_surface(mesh,pts,pte,org,x_axis,y_axis,z_axis,revs,rots,r_pln,r_func,x_ctr,yz_ctr,segments,height,h_func,delta,d_func,m_func,scale,s_func,offset,surface)
        pts != pte ? m_flag = 1 : m_flag = 0
        revs != 0.0 ? c_flag = 1 : c_flag = 0
        rots != 0.0 ? r_flag = 1 : r_flag = 0
        scale != 1.0 ? s_flag = 1 : s_flag = 0
        height != 0.0 ? h_flag = 1 : h_flag = 0
        delta != 0.0 ? d_flag = 1 : d_flag = 0
        pi = Math::PI
        numpts = pts.length
        da = pi * 2 * revs / segments
        dr = pi * 2 * rots
        ds = 1.0 / segments
      #------- centroid plus offset
        if(r_flag == 1 || s_flag == 1)
          ptc = get_spirix_centroid(pts)
          vx = Geom::Vector3d.new(x_axis)
          vx.length = x_ctr
          pto = ptc.transform(vx)
          if(c_flag == 0)
            vy = Geom::Vector3d.new(y_axis)
            vy.length = yz_ctr
            pto.transform!(vy)
            r_vec = Geom::Vector3d.new(z_axis)
          else
            vz = Geom::Vector3d.new(z_axis)
            vz.length = yz_ctr
            pto.transform!(vz)
            r_vec = Geom::Vector3d.new(y_axis).reverse
          end
          if(r_pln == 1)
            line = [pto,r_vec]
            v1 = Geom::Vector3d.new(pts[0].x - ptc.x,pts[0].y - ptc.y,pts[0].z - ptc.z)
            v2 = Geom::Vector3d.new(pts[1].x - ptc.x,pts[1].y - ptc.y,pts[1].z - ptc.z)
            r_vec = (v1 * v2).normalize
            pto = Geom.intersect_line_plane(line,[ptc,r_vec])
          end
        end
      #------- add the points to the mesh
        node = []
        for j in 0..segments do
          pt = []
      #------- revolution movement
          if(c_flag == 1)
            r = Geom::Transformation.rotation(org,z_axis,da * j)
          end
      #------- rotational movement
          if(r_flag == 1)
            if(r_func == 0)
              rr = Geom::Transformation.rotation(pto,r_vec,dr * j / segments)
            elsif(r_func == 1)
              rr = Geom::Transformation.rotation(pto,r_vec,((1.0 - Math.cos(pi * j / segments)) / 2.0) * dr)
            elsif(r_func == 2)
              rr = Geom::Transformation.rotation(pto,r_vec,(1.0 - Math.cos((pi * j) / (2.0 * segments))) * dr)
            end
          end
      #------- axial movement
          if(h_flag == 1)
            v = Geom::Vector3d.new(z_axis)
            if(h_func == 0)
              v.length = ds * j * height
              ht = Geom::Transformation.translation(v)
            elsif(h_func == 1)
              v.length = (((Math.sin(pi * ds * j - pi / 2)) + 1) / 2) * height
              ht = Geom::Transformation.translation(v)
            elsif(h_func == 2)
              v.length = (1.0 - Math.sqrt(1.0 - (ds * j)**2)) * height
              ht = Geom::Transformation.translation(v)
            elsif(h_func == 3)
              v.length = (Math.sqrt(2.0 * ds * j - (ds * j)**2)) * height
              ht = Geom::Transformation.translation(v)
            elsif(h_func == 4)
              v.length = (Math.sqrt(1.0 - (2.0 * ds * j - 1.0)**2)) * height
              ht = Geom::Transformation.translation(v)
            elsif(h_func == 5)
              v.length = (1.0 - Math.sqrt(1.0 - (2.0 * ds * j - 1.0)**2)) * height
              ht = Geom::Transformation.translation(v)
            elsif(h_func == 6)
              v.length = Math.log10(ds * j * 9 + 1) * height
              ht = Geom::Transformation.translation(v)
            elsif(h_func == 7)
              v.length = (ds * j)**2 * height
              ht = Geom::Transformation.translation(v)
            elsif(h_func == 8)
              v.length = (ds * j)**3 * height
              ht = Geom::Transformation.translation(v)
            end
          end
      #------- radial movement
          if(d_flag == 1)
            v = Geom::Vector3d.new(x_axis)
            if(d_func == 0)
              v.length = ds * delta * j
              dt = Geom::Transformation.translation(v)
            elsif(d_func == 1)
              v.length = (((Math.sin(pi * ds * j - pi / 2)) + 1) / 2) * delta
              dt = Geom::Transformation.translation(v)
            elsif(d_func == 2)
              v.length = (1.0 - Math.sqrt(1.0 - (ds * j)**2)) * delta
              dt = Geom::Transformation.translation(v)
            elsif(d_func == 3)
              v.length = (Math.sqrt(2.0 * ds * j - (ds * j)**2)) * delta
              dt = Geom::Transformation.translation(v)
            elsif(d_func == 4)
              v.length = (Math.sqrt(1.0 - (2.0 * ds * j - 1.0)**2)) * delta
              dt = Geom::Transformation.translation(v)
            elsif(d_func == 5)
              v.length = (1.0 - Math.sqrt(1.0 - (2.0 * ds * j - 1.0)**2)) * delta
              dt = Geom::Transformation.translation(v)
            elsif(d_func == 6)
              v.length = Math.log10(ds * j * 9 + 1) * delta
              dt = Geom::Transformation.translation(v)
            elsif(d_func == 7)
              v.length = (ds * j)**2 * delta
              dt = Geom::Transformation.translation(v)
            elsif(d_func == 8)
              v.length = (ds * j)**3 * delta
              dt = Geom::Transformation.translation(v)
            end
          end
      #------- morphing movement
          if(m_flag == 1)
            if(m_func == 0)
              s = ds * j
            elsif(m_func == 1)
              s = (((Math.sin(pi * ds * j - pi / 2)) + 1) / 2)
            elsif(m_func == 2)
              s = 1.0 - Math.sqrt(1.0 - (ds * j)**2)
            elsif(m_func == 3)
              s = Math.sqrt(2.0 * ds * j - (ds * j)**2)
            elsif(m_func == 4)
              s = Math.sqrt(1.0 - (2.0 * ds * j - 1.0)**2)
            elsif(m_func == 5)
              s = 1.0 - Math.sqrt(1.0 - (2.0 * ds * j - 1.0)**2)
            elsif(m_func == 6)
              s = Math.log10(ds * j * 9 + 1)
            elsif(m_func == 7)
              s = (ds * j)**2
            elsif(m_func == 8)
              s = (ds * j)**3
            end
          end
      #------- scaling movement
          if(s_flag == 1)
            if(s_func == 0)
              sf = ds * j
            elsif(s_func == 1)
              sf = (((Math.sin(pi * ds * j - pi / 2)) + 1) / 2)
            elsif(s_func == 2)
              sf = 1.0 - Math.sqrt(1.0 - (ds * j)**2)
            elsif(s_func == 3)
              sf = Math.sqrt(2.0 * ds * j - (ds * j)**2)
            elsif(s_func == 4)
              sf = Math.sqrt(1.0 - (2.0 * ds * j - 1.0)**2)
            elsif(s_func == 5)
              sf = 1.0 - Math.sqrt(1.0 - (2.0 * ds * j - 1.0)**2)
            elsif(s_func == 6)
              sf = Math.log10(ds * j * 9 + 1)
            elsif(s_func == 7)
              sf = (ds * j)**2
            elsif(s_func == 8)
              sf = (ds * j)**3
            end
            dsf = sf * (scale - 1.0) + 1.0
          end
      #-------
          for i in 0...numpts do
            ptmp = pts[i]
            if(m_flag == 1)
              m = Geom::Transformation.translation([(pte[i].x-pts[i].x)*s,(pte[i].y-pts[i].y)*s,(pte[i].z-pts[i].z)*s])
              ptmp = ptmp.transform(m)
            end
            if(s_flag == 1)
              st = Geom::Transformation.translation([(ptmp.x-ptc.x)*(dsf-1.0),(ptmp.y-ptc.y)*(dsf-1.0),(ptmp.z-ptc.z)*(dsf-1.0)])
              ptmp = ptmp.transform(st)
            end
            if(r_flag == 1)
              ptmp = ptmp.transform(rr)
            end
            if(d_flag == 1)
              ptmp = ptmp.transform(dt)
            end
            if(h_flag == 1)
              ptmp = ptmp.transform(ht)
            end
            if(c_flag == 1)
              ptmp = ptmp.transform(r)
            end
            pt.push ptmp
          end
          node.push pt
        end
        if(offset == 0.0)
          # Create the polygons using original points
          for j in 0...segments do
            for i in 0...numpts-1 do
              mesh.add_polygon(node[j][i],node[j+1][i],node[j][i+1])
              mesh.add_polygon(node[j][i+1],node[j+1][i],node[j+1][i+1])
            end
          end
          if(@@create_edges == 'Yes')
            edges1 = @@model.active_entities.add_group
            edges1.name = @@name + 'E1'
            edges2 = @@model.active_entities.add_group
            edges2.name = @@name + 'E2'
            for j in 0...segments do
              edges1.entities.add_line(node[j][0],node[j+1][0])
              edges2.entities.add_line(node[j][numpts-1],node[j+1][numpts-1])
            end
            edges3 = @@model.active_entities.add_group
            edges3.name = @@name + 'S'
            edges4 = @@model.active_entities.add_group
            edges4.name = @@name + 'E'
            for i in 0...numpts-1 do
              edges3.entities.add_line(node[0][i],node[0][i+1])
              edges4.entities.add_line(node[segments][i],node[segments][i+1])
            end
          end
        else
          # Create the offset points instead
          node2 = []
          np = numpts-1
          sg = segments
          for j in 0..sg do
            pt2 = []
            for i in 0..np do
              if(i != 0 && j != 0 && i != np && j != sg)
                # in the middle
                v1 = Geom::Vector3d.new(node[j+1][i].x - node[j][i].x, node[j+1][i].y - node[j][i].y, node[j+1][i].z - node[j][i].z)
                v2 = Geom::Vector3d.new(node[j][i+1].x - node[j][i].x, node[j][i+1].y - node[j][i].y, node[j][i+1].z - node[j][i].z)
                v3 = Geom::Vector3d.new(node[j-1][i+1].x - node[j][i].x, node[j-1][i+1].y - node[j][i].y, node[j-1][i+1].z - node[j][i].z)
                v4 = Geom::Vector3d.new(node[j-1][i].x - node[j][i].x, node[j-1][i].y - node[j][i].y, node[j-1][i].z - node[j][i].z)
                v5 = Geom::Vector3d.new(node[j][i-1].x - node[j][i].x, node[j][i-1].y - node[j][i].y, node[j][i-1].z - node[j][i].z)
                v6 = Geom::Vector3d.new(node[j+1][i-1].x - node[j][i].x, node[j+1][i-1].y - node[j][i].y, node[j+1][i-1].z - node[j][i].z)
                v = (v1 * v2).normalize + (v2 * v3).normalize + (v3 * v4).normalize + (v4 * v5).normalize + (v5 * v6).normalize + (v6 * v1).normalize
              elsif(i == 0 && j == 0)
                # lower left corner
                v1 = Geom::Vector3d.new(node[j+1][i].x - node[j][i].x, node[j+1][i].y - node[j][i].y, node[j+1][i].z - node[j][i].z)
                v2 = Geom::Vector3d.new(node[j][i+1].x - node[j][i].x, node[j][i+1].y - node[j][i].y, node[j][i+1].z - node[j][i].z)
                v = v1 * v2
              elsif(i == 0 && j == sg)
                # lower right corner
                v1 = Geom::Vector3d.new(node[j][i+1].x - node[j][i].x, node[j][i+1].y - node[j][i].y, node[j][i+1].z - node[j][i].z)
                v2 = Geom::Vector3d.new(node[j-1][i+1].x - node[j][i].x, node[j-1][i+1].y - node[j][i].y, node[j-1][i+1].z - node[j][i].z)
                v3 = Geom::Vector3d.new(node[j-1][i].x - node[j][i].x, node[j-1][i].y - node[j][i].y, node[j-1][i].z - node[j][i].z)
                v = (v1 * v2).normalize + (v2 * v3).normalize
              elsif(i == np && j == 0)
                # upper left corner
                v1 = Geom::Vector3d.new(node[j][i-1].x - node[j][i].x, node[j][i-1].y - node[j][i].y, node[j][i-1].z - node[j][i].z)
                v2 = Geom::Vector3d.new(node[j+1][i-1].x - node[j][i].x, node[j+1][i-1].y - node[j][i].y, node[j+1][i-1].z - node[j][i].z)
                v3 = Geom::Vector3d.new(node[j+1][i].x - node[j][i].x, node[j+1][i].y - node[j][i].y, node[j+1][i].z - node[j][i].z)
                v = (v1 * v2).normalize + (v2 * v3).normalize
              elsif(i == np && j == sg)
                # upper right corner
                v1 = Geom::Vector3d.new(node[j-1][i].x - node[j][i].x, node[j-1][i].y - node[j][i].y, node[j-1][i].z - node[j][i].z)
                v2 = Geom::Vector3d.new(node[j][i-1].x - node[j][i].x, node[j][i-1].y - node[j][i].y, node[j][i-1].z - node[j][i].z)
                v = v1 * v2
              elsif(i == 0)
                # lower edge
                v1 = Geom::Vector3d.new(node[j+1][i].x - node[j][i].x, node[j+1][i].y - node[j][i].y, node[j+1][i].z - node[j][i].z)
                v2 = Geom::Vector3d.new(node[j][i+1].x - node[j][i].x, node[j][i+1].y - node[j][i].y, node[j][i+1].z - node[j][i].z)
                v3 = Geom::Vector3d.new(node[j-1][i+1].x - node[j][i].x, node[j-1][i+1].y - node[j][i].y, node[j-1][i+1].z - node[j][i].z)
                v4 = Geom::Vector3d.new(node[j-1][i].x - node[j][i].x, node[j-1][i].y - node[j][i].y, node[j-1][i].z - node[j][i].z)
                v = (v1 * v2).normalize + (v2 * v3).normalize + (v3 * v4).normalize
              elsif(i == np)
                # upper edge
                v1 = Geom::Vector3d.new(node[j-1][i].x - node[j][i].x, node[j-1][i].y - node[j][i].y, node[j-1][i].z - node[j][i].z)
                v2 = Geom::Vector3d.new(node[j][i-1].x - node[j][i].x, node[j][i-1].y - node[j][i].y, node[j][i-1].z - node[j][i].z)
                v3 = Geom::Vector3d.new(node[j+1][i-1].x - node[j][i].x, node[j+1][i-1].y - node[j][i].y, node[j+1][i-1].z - node[j][i].z)
                v4 = Geom::Vector3d.new(node[j+1][i].x - node[j][i].x, node[j+1][i].y - node[j][i].y, node[j+1][i].z - node[j][i].z)
                v = (v1 * v2).normalize + (v2 * v3).normalize + (v3 * v4).normalize
              elsif(j == 0)
                # left edge
                v1 = Geom::Vector3d.new(node[j][i-1].x - node[j][i].x, node[j][i-1].y - node[j][i].y, node[j][i-1].z - node[j][i].z)
                v2 = Geom::Vector3d.new(node[j+1][i-1].x - node[j][i].x, node[j+1][i-1].y - node[j][i].y, node[j+1][i-1].z - node[j][i].z)
                v3 = Geom::Vector3d.new(node[j+1][i].x - node[j][i].x, node[j+1][i].y - node[j][i].y, node[j+1][i].z - node[j][i].z)
                v4 = Geom::Vector3d.new(node[j][i+1].x - node[j][i].x, node[j][i+1].y - node[j][i].y, node[j][i+1].z - node[j][i].z)
                v = (v1 * v2).normalize + (v2 * v3).normalize + (v3 * v4).normalize
              else
                # right edge
                v1 = Geom::Vector3d.new(node[j][i+1].x - node[j][i].x, node[j][i+1].y - node[j][i].y, node[j][i+1].z - node[j][i].z)
                v2 = Geom::Vector3d.new(node[j-1][i+1].x - node[j][i].x, node[j-1][i+1].y - node[j][i].y, node[j-1][i+1].z - node[j][i].z)
                v3 = Geom::Vector3d.new(node[j-1][i].x - node[j][i].x, node[j-1][i].y - node[j][i].y, node[j-1][i].z - node[j][i].z)
                v4 = Geom::Vector3d.new(node[j][i-1].x - node[j][i].x, node[j][i-1].y - node[j][i].y, node[j][i-1].z - node[j][i].z)
                v = (v1 * v2).normalize + (v2 * v3).normalize + (v3 * v4).normalize
              end
              v.length = offset
              ptmp = node[j][i].offset v
              pt2.push ptmp
            end
            node2.push pt2
          end
          if(@@create_edges == 'Yes')
            edges1 = @@model.active_entities.add_group
            edges1.name = @@name + 'E1'
            edges2 = @@model.active_entities.add_group
            edges2.name = @@name + 'E2'
            for j in 0...segments do
              edges1.entities.add_line(node2[j][0],node2[j+1][0])
              edges2.entities.add_line(node2[j][numpts-1],node2[j+1][numpts-1])
            end
            edges3 = @@model.active_entities.add_group
            edges3.name = @@name + 'S'
            edges4 = @@model.active_entities.add_group
            edges4.name = @@name + 'E'
            for i in 0...numpts-1 do
              edges3.entities.add_line(node2[0][i],node2[0][i+1])
              edges4.entities.add_line(node2[segments][i],node2[segments][i+1])
            end
          end
          if(surface == 0)
            # Offset Surface
            for j in 0...segments do
              for i in 0...numpts-1 do
                mesh.add_polygon(node2[j][i],node2[j+1][i],node2[j][i+1])
                mesh.add_polygon(node2[j][i+1],node2[j+1][i],node2[j+1][i+1])
              end
            end
          end
          if(surface == 1)
            # Side 1
            for j in 0...segments do
                mesh.add_polygon(node2[j][0],node[j][0],node[j+1][0])
                mesh.add_polygon(node[j+1][0],node2[j+1][0],node2[j][0])
            end
          end
          if(surface == 2)
            # Side 2
            for j in 0...segments do
                mesh.add_polygon(node2[j][np],node2[j+1][np],node[j][np])
                mesh.add_polygon(node2[j+1][np],node[j+1][np],node[j][np])
            end
          end
          if(surface == 3)
            # End 1
            for i in 0...numpts-1 do
              mesh.add_polygon(node[0][i],node2[0][i],node[0][i+1])
              mesh.add_polygon(node2[0][i],node2[0][i+1],node[0][i+1])
            end
          end
          if(surface == 4)
            # End 2
            for i in 0...numpts-1 do
              mesh.add_polygon(node2[sg][i],node[sg][i],node2[sg][i+1])
              mesh.add_polygon(node[sg][i],node[sg][i+1],node2[sg][i+1])
            end
          end
        end
      end
#-----------------------------------------------------------------------
      def get_spirix_group_centroid()
        total_area = 0
        total_centroids = Geom::Vector3d.new(0,0,0)
        third = Geom::Transformation.scaling(1.0 / 3.0)
        npts = pts.length
        puts npts
        vec1 = Geom::Vector3d.new(pts[1].x - pts[0].x, pts[1].y - pts[0].y, pts[1].z - pts[0].z)
        vec2 = Geom::Vector3d.new(pts[2].x - pts[0].x, pts[2].y - pts[0].y, pts[2].z - pts[0].z)
        ref_sense = vec1.cross vec2
        for i in 0...(npts-2)
          vec1 = Geom::Vector3d.new(pts[i+1].x - pts[0].x, pts[i+1].y - pts[0].y, pts[i+1].z - pts[0].z)
          vec2 = Geom::Vector3d.new(pts[i+2].x - pts[0].x, pts[i+2].y - pts[0].y, pts[i+2].z - pts[0].z)
          vec = vec1.cross vec2
          area = vec.length / 2.0
          if(ref_sense.dot(vec) < 0)
             area *= -1.0
          end
          total_area += area
          centroid = (vec1 + vec2).transform(third)
          t = Geom::Transformation.scaling(area)
          total_centroids += centroid.transform(t)
        end
        c = Geom::Transformation.scaling(1.0 / total_area)
        total_centroids.transform!(c) + Geom::Vector3d.new(pts[0].x,pts[0].y,pts[0].z)
      end
#-----------------------------------------------------------------------
      def get_spirix_centroid(pti)
        pt1 = pti[0]
        xt = pt1.x
        yt = pt1.y
        zt = pt1.z
        closed = 0
        len = pti.length
        for i in 1...len
          if(pt1 != pti[i])
            xt += pti[i].x
            yt += pti[i].y
            zt += pti[i].z
          else
            closed = 1
          end
        end
        len -= closed
        xt /= len
        yt /= len
        zt /= len
        Geom::Point3d.new(xt,yt,zt)
      end
      #-----------------------------------------------------------------------
      def init_dictionary(dict)
        dict['name'] = ''
        dict['revs'] = '1.0'
        dict['rots'] = '0.0'
        dict['plane'] = 'Axes'
        dict['r_func'] = 'Linear'
        dict['x_ctr'] = '0"'
        dict['yz_ctr'] = '0"'
        dict['segments'] = '24'
        dict['scale'] = '1.0'
        dict['s_func'] = 'Linear'
        dict['height'] = '0"'
        dict['h_func'] = 'Linear'
        dict['delta'] = '0"'
        dict['d_func'] = 'Linear'
        dict['m_func'] = 'Linear'
        dict['group1'] = ''
        dict['group2'] = ''
        dict['smoothing'] = 'None'
        dict['offset'] = '0"'
        dict['choice'] = 'Surface'
        dict['edges'] = 'No'
      end
      #-----------------------------------------------------------------------
      def get_spirix_surface()
#        model = Sketchup.active_model
        dict = @@model.attribute_dictionaries['SpirixParameters']
        if !dict
          dict = @@model.attribute_dictionary("SpirixParameters",true)
          init_dictionary(dict)
        end
        prompts = ["Name ","Revolutions ","Rotations ","Plane ","Interpolation ","X Centroid Offset ","Y/Z Centroid Offset ","Segments ","Scale ","Interpolation ","Height ","Interpolation ","Delta Radius ","Interpolation ","Morphing ","Start Group ","End Group ","Smoothing ","Offset ","Surface ","Edges "]
        defaults = [dict['name'],dict['revs'],dict['rots'],dict['plane'],dict['r_func'],dict['x_ctr'].to_l,dict['yz_ctr'].to_l,dict['segments'],dict['scale'],dict['s_func'],dict['height'].to_l,dict['h_func'],dict['delta'].to_l,dict['d_func'],dict['m_func'],dict['group1'],dict['group2'],dict['smoothing'],dict['offset'].to_l,dict['choice'],dict['edges']]
        list = ["","","","Axes|Face","Linear|Sine|Arc1","","","","","Linear|Sine|Arc1|Arc2|Arc3|Arc4|Log10|Parabolic|Cubic","","Linear|Sine|Arc1|Arc2|Arc3|Arc4|Log10|Parabolic|Cubic","","Linear|Sine|Arc1|Arc2|Arc3|Arc4|Log10|Parabolic|Cubic","Linear|Sine|Arc1|Arc2|Arc3|Arc4|Log10|Parabolic|Cubic","","","None|Edge|Face|Both","","Surface|Side 1|Side 2|End 1|End 2","No|Yes"]
        input = UI.inputbox prompts, defaults, list, "Enter Surface Parameters:"
        func = {'Linear'=>0,'Sine'=>1,'Arc1'=>2,'Arc2'=>3,'Arc3'=>4,'Arc4'=>5,'Log10'=>6,'Parabolic'=>7,'Cubic'=>8}
        smooth = {'None'=>0, 'Edge'=>4, 'Face'=>8, 'Both'=>12}
        choice = {'Surface'=>0,'Side 1'=>1,'Side 2'=>2,'End 1'=>3,'End 2'=>4}
        pln = {'Axes'=>0,'Face'=>1}
        if(input)
          @@name = input[0]
          revs = input[1].to_f
          rots = input[2].to_f
          r_pln = pln[input[3]]
          r_func = func[input[4]]
          x_ctr = input[5].to_l.to_f
          yz_ctr = input[6].to_l.to_f
          segments = input[7].to_i
          scale = input[8].to_f
          s_func = func[input[9]]
          height = input[10].to_l.to_f
          h_func = func[input[11]]
          delta = input[12].to_l.to_f
          d_func = func[input[13]]
          m_func = func[input[14]]
          group1 = input[15]
          group2 = input[16]
          smoothing = smooth[input[17]]
          offset = input[18].to_l.to_f
          surface = choice[input[19]]
          @@create_edges = input[20]
      
          dict['name'] = input[0]
          dict['revs'] = input[1]
          dict['rots'] = input[2]
          dict['plane'] = input[3]
          dict['r_func'] = input[4]
          dict['x_ctr'] = input[5].to_l
          dict['yz_ctr'] = input[6].to_l
          dict['segments'] = input[7]
          dict['scale'] = input[8]
          dict['s_func'] = input[9]
          dict['height'] = input[10].to_l
          dict['h_func'] = input[11]
          dict['delta'] = input[12].to_l
          dict['d_func'] = input[13]
          dict['m_func'] = input[14]
          dict['group1'] = input[15]
          dict['group2'] = input[16]
          dict['smoothing'] = input[17]
          dict['offset'] = input[18].to_l
          dict['choice'] = input[19]
          dict['edges'] = input[20]
      
          curpts = 0
          pts = []
          last_i = 0
          entities = @@model.active_entities
          @@model.start_operation "Spirix Surface"
          group = entities.add_group
          if(group1 != "" && group2 == "")
            entities.each do |i|
              if(i.typename == "Group" && i.name == group1)
                gtx = i.transformation
                start = i.entities
                for j in 0...start.count
                  if(start[j].is_a? Sketchup::Edge)
                    pts.push(start[j].start.position.transform(gtx))
                    curpts += 1
                    last_i = j
                  end
                end
                pts.push(start[last_i].end.position.transform(gtx))
                curpts += 1
              end
            end
            pte = pts
          elsif(group1 != "" && group2 != "")
            entities.each do |i|
              if(i.typename == "Group" && i.name == group1)
                gtx = i.transformation
                start = i.entities
                for j in 0...start.count
                  if(start[j].is_a? Sketchup::Edge)
                    pts.push(start[j].start.position.transform(gtx))
                    curpts += 1
                    last_i = j
                  end
                end
                pts.push(start[last_i].end.position.transform(gtx))
                curpts += 1
              end
            end
            pte = []
            curpts = 0
            last_i = 0
            entities.each do |i|
              if(i.typename == "Group" && i.name == group2)
                gtx = i.transformation
                start = i.entities
                for j in 0...start.count
                  if(start[j].is_a? Sketchup::Edge)
                    pte.push(start[j].start.position.transform(gtx))
                    curpts += 1
                    last_i = j
                  end
                end
                pte.push(start[last_i].end.position.transform(gtx))
                curpts += 1
              end
            end
          else
            etbd = []
            etbdi = 0
            for i in 0...entities.count
              if(entities[i].is_a? Sketchup::Edge)
                pts.push(entities[i].start.position)
                etbd[etbdi] = entities[i]
                etbdi += 1
                curpts += 1
                last_i = i
              end
            end
            pts.push(entities[last_i].end.position)
            curpts += 1
            pte = pts
            entities.erase_entities(etbd)
          end
          org = [0,0,0]
          x_axis = [1,0,0]
          y_axis = [0,1,0]
          z_axis = [0,0,1]
          entities.each do |i|
            if(i.typename == "Group" && i.name == "SPIRIX_AXES")
              gtx = i.transformation
              axes = i.entities
              org = axes[0].start.position.transform(gtx)
              px = axes[0].end.position.transform(gtx)
              py = axes[1].end.position.transform(gtx)
              pz = axes[2].end.position.transform(gtx)
              x_axis = [px.x - org.x,px.y - org.y,px.z - org.z]
              y_axis = [py.x - org.x,py.y - org.y,py.z - org.z]
              z_axis = [pz.x - org.x,pz.y - org.y,pz.z - org.z]
            end
          end
          numpoly = segments * curpts * 2
          numpts = segments * curpts + curpts
          mesh = Geom::PolygonMesh.new(numpts, numpoly)
          create_spirix_surface(mesh,pts,pte,org,x_axis,y_axis,z_axis,revs,rots,r_pln,r_func,x_ctr,yz_ctr,segments,height,h_func,delta,d_func,m_func,scale,s_func,offset,surface)
          group.entities.fill_from_mesh(mesh,1,smoothing)
          if(@@name != "")
            group.name = @@name
          end
          @@model.commit_operation
        end
      end
      #-----------------------------------------------------------------------
      def create_spirix_group()
        prompts = ["Name "] 
        defaults = [""] 
        input = UI.inputbox prompts, defaults, "Group Entities:"
        if(input)
#          model = Sketchup.active_model
          entities = @@model.active_entities
          @@model.start_operation "Spirix Grouping"
          group = entities.add_group
          group.name = input[0]
          etbd = []
          etbdi = 0
          entities.each do |i|
            if(i.is_a? Sketchup::Edge)
              group.entities.add_line(i.start.position,i.end.position)
              etbd[etbdi] = i
              etbdi += 1
            end
          end
          entities.erase_entities(etbd)
          @@model.commit_operation
        end
      end
      #-----------------------------------------------------------------------
      def create_spirix_group_face()
        prompts = ["Name "] 
        defaults = [""] 
        input = UI.inputbox prompts, defaults, "Group Entities:"
        if(input)
          entities = @@model.active_entities
          @@model.start_operation "Spirix Grouping"
          group = entities.add_group
          group.name = input[0]
          verts = []
          entities.each do |i|
            if(i.is_a? Sketchup::Face)
              verts = (i.outer_loop).vertices
            end
          end
          for i in 0...verts.length-1
            group.entities.add_line(verts[i].position,verts[i+1].position)
          end
          group.entities.add_line(verts[i+1].position,verts[0].position)
          @@model.commit_operation
        end
      end
      #-----------------------------------------------------------------------
      def init_dictionary2(dict)
        dict['name'] = ""
        dict['revs'] = "30.0"
        dict['rots'] = "0.0"
        dict['x_ctr'] = "0.0"
        dict['yz_ctr'] = "0.0"
        dict['plane'] = "XZ Plane"
        dict['copies'] = "1"
        dict['scale'] = "1.0"
        dict['s_func'] = "Linear"
        dict['height'] = "0.0"
        dict['h_func'] = "Linear"
        dict['delta'] = "0.0"
        dict['d_func'] = "Linear"
        dict['group'] = ""
      end
      #-----------------------------------------------------------------------
      def create_spirix_pattern(name,group,org,axis,revs,rots,x_ctr,yz_ctr,plane,copies,hdelta,h_func,ddelta,d_func,scale,s_func)
        height = (hdelta * copies).to_f
        delta = (ddelta * copies).to_f
        ptctr = Geom::Point3d.new((group.bounds.min.x+group.bounds.max.x)/2.0,(group.bounds.min.y+group.bounds.max.y)/2.0,(group.bounds.min.z+group.bounds.max.z)/2.0)
        revs != 0.0 ? c_flag = 1 : c_flag = 0
        rots != 0.0 ? r_flag = 1 : r_flag = 0
        scale != 1.0 ? s_flag = 1 : s_flag = 0
        height != 0.0 ? h_flag = 1 : h_flag = 0
        delta != 0.0 ? d_flag = 1 : d_flag = 0
      #------- rotation center (calculate regardless if needed)
        if(plane == 1)
          ptc = Geom::Point3d.new(ptctr.x+x_ctr,ptctr.y+yz_ctr,0)
        else
          ptc = Geom::Point3d.new(ptctr.x+x_ctr,0,ptctr.z+yz_ctr)
        end
      #------- Basic initialization parameters
        pi = Math::PI
        da = pi * revs / 180.0
        dr = pi * rots / 180.0
        ds = 1.0 / copies
      #------- create the groups
        for j in 1..copies do
      #------- revolution movement
          if(c_flag == 1)
            r = Geom::Transformation.rotation(org, axis, da * j)
          end
      #------- rotational movement (calculate regardless if needed)
          if(plane == 1)
            rr = Geom::Transformation.rotation(ptc, [0,0,1], dr * j)
          else
            rr = Geom::Transformation.rotation(ptc, [0,-1,0], dr * j)
          end
      #------- axial movement
          if(h_flag == 1)
            if(h_func == 0)
              ht = Geom::Transformation.translation([0,0,ds * j * height])
            elsif(h_func == 1)
              ht = Geom::Transformation.translation([0,0,(((Math.sin(pi * ds * j - pi / 2)) + 1) / 2) * height])
            elsif(h_func == 2)
              ht = Geom::Transformation.translation([0,0,(1.0 - Math.sqrt(1.0 - (ds * j)**2)) * height])
            elsif(h_func == 3)
              ht = Geom::Transformation.translation([0,0,(Math.sqrt(2.0 * ds * j - (ds * j)**2)) * height])
            elsif(h_func == 4)
              ht = Geom::Transformation.translation([0,0,(Math.sqrt(1.0 - (2.0 * ds * j - 1.0)**2)) * height])
            elsif(h_func == 5)
              ht = Geom::Transformation.translation([0,0,(1.0 - Math.sqrt(1.0 - (2.0 * ds * j - 1.0)**2)) * height])
            elsif(h_func == 6)
              ht = Geom::Transformation.translation([0,0,Math.log10(ds * j * 9 + 1) * height])
            elsif(h_func == 7)
              ht = Geom::Transformation.translation([0,0,(ds * j)**2 * height])
            elsif(h_func == 8)
              ht = Geom::Transformation.translation([0,0,(ds * j)**3 * height])
            end
          end
      #------- radial movement
          if(d_flag == 1)
            if(d_func == 0)
              dt = Geom::Transformation.translation([ds * delta * j,0,0])
            elsif(d_func == 1)
              dt = Geom::Transformation.translation([(((Math.sin(pi * ds * j - pi / 2)) + 1) / 2) * delta,0,0])
            elsif(d_func == 2)
              dt = Geom::Transformation.translation([(1.0 - Math.sqrt(1.0 - (ds * j)**2)) * delta,0,0])
            elsif(d_func == 3)
              dt = Geom::Transformation.translation([(Math.sqrt(2.0 * ds * j - (ds * j)**2)) * delta,0,0])
            elsif(d_func == 4)
              dt = Geom::Transformation.translation([(Math.sqrt(1.0 - (2.0 * ds * j - 1.0)**2)) * delta,0,0])
            elsif(d_func == 5)
              dt = Geom::Transformation.translation([(1.0 - Math.sqrt(1.0 - (2.0 * ds * j - 1.0)**2)) * delta,0,0])
            elsif(d_func == 6)
              dt = Geom::Transformation.translation([Math.log10(ds * j * 9 + 1) * delta,0,0])
            elsif(d_func == 7)
              dt = Geom::Transformation.translation([(ds * j)**2 * delta,0,0])
            elsif(d_func == 8)
              dt = Geom::Transformation.translation([(ds * j)**3 * delta,0,0])
            end
          end
      #------- scaling movement
          if(s_flag == 1)
            if(s_func == 0)
              sf = ds * j
            elsif(s_func == 1)
              sf = (((Math.sin(pi * ds * j - pi / 2)) + 1) / 2)
            elsif(s_func == 2)
              sf = 1.0 - Math.sqrt(1.0 - (ds * j)**2)
            elsif(s_func == 3)
              sf = Math.sqrt(2.0 * ds * j - (ds * j)**2)
            elsif(s_func == 4)
              sf = Math.sqrt(1.0 - (2.0 * ds * j - 1.0)**2)
            elsif(s_func == 5)
              sf = 1.0 - Math.sqrt(1.0 - (2.0 * ds * j - 1.0)**2)
            elsif(s_func == 6)
              sf = Math.log10(ds * j * 9 + 1)
            elsif(s_func == 7)
              sf = (ds * j)**2
            elsif(s_func == 8)
              sf = (ds * j)**3
            end
            st = Geom::Transformation.scaling ptctr,(sf * (scale - 1.0) + 1.0)
          end
      #-------
          group_t = Sketchup.active_model.active_entities.add_group
          group_t = group.copy
          if(name != "")
            group_t.name = name + "(" + j.to_s + ")"
          end
          if(s_flag == 1)
            group_t.transform! st
          end
          if(r_flag == 1)
            group_t.transform! rr
          end
          if(d_flag == 1)
            group_t.transform! dt
          end
          if(h_flag == 1)
            group_t.transform! ht
          end
          if(c_flag == 1)
            group_t.transform! r
          end
      #-------
        end
      end
      #-----------------------------------------------------------------------
      def get_spirix_pattern()
#        model = Sketchup.active_model
        dict2 = @@model.attribute_dictionaries['SpirixParameters2']
        if(!dict2)
          dict2 = @@model.attribute_dictionary("SpirixParameters2",true)
          init_dictionary2(dict2)
        end
        prompts = ["Name ","Delta Revolution Angle ","Delta Rotation Angle ","X Offset ","Y/Z Offset ","Rotation Plane ","Copies ","Scale ","Interpolation ","Delta Height ","Interpolation ","Delta Radius ","Interpolation ","Group "]
        defaults = [dict2['name'],dict2['revs'],dict2['rots'],dict2['x_ctr'],dict2['yz_ctr'],dict2['plane'],dict2['copies'],dict2['scale'],dict2['s_func'],dict2['height'],dict2['h_func'],dict2['delta'],dict2['d_func'],dict2['group']]
        list = ["","","","","","XZ Plane|XY Plane","","","Linear|Sine|Arc1|Arc2|Arc3|Arc4|Log10|Parabolic|Cubic","","Linear|Sine|Arc1|Arc2|Arc3|Arc4|Log10|Parabolic|Cubic","","Linear|Sine|Arc1|Arc2|Arc3|Arc4|Log10|Parabolic|Cubic",""]
        input = UI.inputbox prompts, defaults, list, "Enter Pattern Parameters:"
        func = {'Linear'=>0,'Sine'=>1,'Arc1'=>2,'Arc2'=>3,'Arc3'=>4,'Arc4'=>5,'Log10'=>6,'Parabolic'=>7,'Cubic'=>8}
        func2 = {'XZ Plane'=>0,'XY Plane'=>1}
        smooth = {'None'=>0, 'Edge'=>4, 'Face'=>8, 'Both'=>12}
        if(input)
          name = input[0]
          revs = input[1].to_f
          rots = input[2].to_f
          x_ctr = input[3].to_f
          yz_ctr = input[4].to_f
          plane = func2[input[5]]
          copies = input[6].to_i
          scale = input[7].to_f
          s_func = func[input[8]]
          height = input[9].to_f
          h_func = func[input[10]]
          delta = input[11].to_f
          d_func = func[input[12]]
          group1 = input[13]
          
          dict2['name'] = input[0]
          dict2['revs'] = input[1]
          dict2['rots'] = input[2]
          dict2['x_ctr'] = input[3]
          dict2['yz_ctr'] = input[4]
          dict2['plane'] = input[5]
          dict2['copies'] = input[6]
          dict2['scale'] = input[7]
          dict2['s_func'] = input[8]
          dict2['height'] = input[9]
          dict2['h_func'] = input[10]
          dict2['delta'] = input[11]
          dict2['d_func'] = input[12]
          dict2['group'] = input[13]
          
          entities = @@model.active_entities
          @@model.start_operation "Spirix Pattern"
          if(group1 != "")
            entities.each do |i|
              if(i.typename == "Group" && i.name == group1)
                create_spirix_pattern(name,i,[0,0,0],[0,0,1],revs,rots,x_ctr,yz_ctr,plane,copies,height,h_func,delta,d_func,scale,s_func)
                @@model.commit_operation
              end
            end
          else
            UI.messagebox "You must provide a Group name!"
          end
        end
      end
#-----------------------------------------------------------------------
    end
    menu = UI.menu("PlugIns").add_submenu("Spirix")
    menu.add_item("Create Surface") { get_spirix_surface() }
    menu.add_item("Create Group") { create_spirix_group() }
    menu.add_item("Create From Face") { create_spirix_group_face() }
    menu.add_item("Create Pattern") { get_spirix_pattern() }
    menu.add_item("Get Group Centroid") { get_spirix_group_centroid() }
  end
end
#-----------------------------------------------------------------------
