# @since 3.3.0
module AMS::Group
  class << self

    # Get group/component instance definition.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] object A group or a
    #   component instance.
    # @return [Sketchup::ComponentDefinition]
    def get_definition(object)
    end

    # Get group/component instance entities.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] object A group or a
    #   component instance.
    # @return [Sketchup::Entities]
    def get_entities(object)
    end

    # Get group/component instance bounding box from edges.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] object A group or a
    #   component instance.
    # @param [Boolean] recursive Whether to include sub-groups and sub-component
    #   instances. All points of a sub-element are transformed to +object+'s
    #   transformation and then applied a desired transformation.
    # @param [Geom::Transformation, nil] transformation A coordinate system to
    #   transform all the points to before computing. Usually this parameter is
    #   the coordinate system +object+ is associated to. Pass +nil+ to
    #   compute in +object+'s local coordinates.
    # @yield A procedure to determine whether a particular edge, sub-group, or a
    #   sub-component instance, should be considered a part of the operation.
    # @yieldparam [Sketchup::Drawingelement] entity
    # @yieldreturn [Boolean] Pass +true+ to consider an entity a part of the
    #   operation; pass +false+ to ignore the entity.
    # @return [Geom::BoundingBox]
    # @since 3.5.0
    def get_bounding_box_from_edges(object, recursive = true, transformation = nil, &entity_validation)
    end

    # Get group/component instance bounding box from faces.
    # @note This function was revised in version 3.5.0.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] object A group or a
    #   component instance.
    # @param [Boolean] recursive Whether to include sub-groups and sub-component
    #   instances. All points of a sub-element are transformed to +object+'s
    #   transformation and then applied a desired transformation.
    # @param [Geom::Transformation, nil] transformation A coordinate system to
    #   transform all the points to before computing. Usually this parameter is
    #   the coordinate system +object+ is associated to. Pass +nil+ to
    #   compute in +object+'s local coordinates.
    # @yield A procedure to determine whether a particular face, sub-group, or a
    #   sub-component instance, should be considered a part of the operation.
    # @yieldparam [Sketchup::Drawingelement] entity
    # @yieldreturn [Boolean] Pass +true+ to consider an entity a part of the
    #   operation; pass +false+ to ignore the entity.
    # @return [Geom::BoundingBox]
    def get_bounding_box_from_faces(object, recursive = true, transformation = nil, &entity_validation)
    end

    # Get group/component instance edges.
    # @note This function was revised in version 3.5.0.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] object A group or a
    #   component instance.
    # @param [Boolean] recursive Whether to include sub-groups and sub-component
    #   instances. All points of a sub-element are transformed to +object+'s
    #   transformation and then applied a desired transformation.
    # @param [Geom::Transformation, nil] transformation A coordinate system to
    #   transform all the points to before computing. Usually this parameter is
    #   the coordinate system +object+ is associated to. Pass +nil+ to
    #   compute in +object+'s local coordinates.
    # @yield A procedure to determine whether a particular edge, sub-group, or a
    #   sub-component instance, should be considered a part of the operation.
    # @yieldparam [Sketchup::Drawingelement] entity
    # @yieldreturn [Boolean] Pass +true+ to consider an entity a part of the
    #   operation; pass +false+ to ignore the entity.
    # @return [Array<Array<Geom::Point3d>>] An array of edges. Each edge
    #   represents an array of two points.
    def get_edges(object, recursive = true, transformation = nil, &entity_validation)
    end

    # Get group/component instance edge vertices.
    # @note This function was revised in version 3.5.0.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] object A group or a
    #   component instance.
    # @param [Boolean] recursive Whether to include sub-groups and sub-component
    #   instances. All points of a sub-element are transformed to +object+'s
    #   transformation and then applied a desired transformation.
    # @param [Geom::Transformation, nil] transformation A coordinate system to
    #   transform all the points to before computing. Usually this parameter is
    #   the coordinate system +object+ is associated to. Pass +nil+ to
    #   compute in +object+'s local coordinates.
    # @yield A procedure to determine whether a particular edge, sub-group, or a
    #   sub-component instance, should be considered a part of the operation.
    # @yieldparam [Sketchup::Drawingelement] entity
    # @yieldreturn [Boolean] Pass +true+ to consider an entity a part of the
    #   operation; pass +false+ to ignore the entity.
    # @return [Array<Geom::Point3d>] An array of points.
    def get_vertices_from_edges(object, recursive = true, transformation = nil, &entity_validation)
    end

    # Get group/component instance faces.
    # @note This function was revised in version 3.5.0.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] object A group or a
    #   component instance.
    # @param [Boolean] recursive Whether to include sub-groups and sub-component
    #   instances. All points of a sub-element are transformed to +object+'s
    #   transformation and then applied a desired transformation.
    # @param [Geom::Transformation, nil] transformation A coordinate system to
    #   transform all the points to before computing. Usually this parameter is
    #   the coordinate system +object+ is associated to. Pass +nil+ to
    #   compute in +object+'s local coordinates.
    # @yield A procedure to determine whether a particular face, sub-group, or a
    #   sub-component instance, should be considered a part of the operation.
    # @yieldparam [Sketchup::Drawingelement] entity
    # @yieldreturn [Boolean] Pass +true+ to consider an entity a part of the
    #   operation; pass +false+ to ignore the entity.
    # @return [Array<Array<Geom::Point3d>>] An array of faces. Each face
    #   represents an array of points.
    def get_faces(object, recursive = true, transformation = nil, &entity_validation)
    end

    # Get group/component instance face vertices.
    # @note This function was revised in version 3.5.0.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] object A group or a
    #   component instance.
    # @param [Boolean] recursive Whether to include sub-groups and sub-component
    #   instances. All points of a sub-element are transformed to +object+'s
    #   transformation and then applied a desired transformation.
    # @param [Geom::Transformation, nil] transformation A coordinate system to
    #   transform all the points to before computing. Usually this parameter is
    #   the coordinate system +object+ is associated to. Pass +nil+ to
    #   compute in +object+'s local coordinates.
    # @yield A procedure to determine whether a particular face, sub-group, or a
    #   sub-component instance, should be considered a part of the operation.
    # @yieldparam [Sketchup::Drawingelement] entity
    # @yieldreturn [Boolean] Pass +true+ to consider an entity a part of the
    #   operation; pass +false+ to ignore the entity.
    # @return [Array<Geom::Point3d>] An array of points.
    def get_vertices_from_faces(object, recursive = true, transformation = nil, &entity_validation)
    end

    # Get group/component instance face vertices collections.
    # @note This function was revised in version 3.5.0.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] object A group or a
    #   component instance.
    # @param [Boolean] recursive Whether to include sub-groups and sub-component
    #   instances. All points of a sub-element are transformed to +object+'s
    #   transformation and then applied a desired transformation.
    # @param [Geom::Transformation, nil] transformation A coordinate system to
    #   transform all the points to before computing. Usually this parameter is
    #   the coordinate system +object+ is associated to. Pass +nil+ to
    #   compute in +object+'s local coordinates.
    # @yield A procedure to determine whether a particular face, sub-group, or a
    #   sub-component instance, should be considered a part of the operation.
    # @yieldparam [Sketchup::Drawingelement] entity
    # @yieldreturn [Boolean] Pass +true+ to consider an entity a part of the
    #   operation; pass +false+ to ignore the entity.
    # @return [Array<Array<Geom::Point3d>>] An array of point collections
    #   from every included sub-group/sub-component instance. Each point
    #   collection represents an array of points.
    def get_vertices_from_faces2(object, recursive = true, transformation = nil, &entity_validation)
    end

    # Get group/component instance construction point and line positions.
    # @note This function was revised in version 3.5.0.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] object A group or a
    #   component instance.
    # @param [Boolean] recursive Whether to include sub-groups and sub-component
    #   instances. All points of a sub-element are transformed to +object+'s
    #   transformation and then applied a desired transformation.
    # @param [Geom::Transformation, nil] transformation A coordinate system to
    #   transform all the points to before computing. Usually this parameter is
    #   the coordinate system +object+ is associated to. Pass +nil+ to
    #   compute in +object+'s local coordinates.
    # @yield A procedure to determine whether a particular construction point,
    #   construction line, sub-group, or a sub-component instance, should be
    #   considered a part of the operation.
    # @yieldparam [Sketchup::Drawingelement] entity
    # @yieldreturn [Boolean] Pass +true+ to consider an entity a part of the
    #   operation; pass +false+ to ignore the entity.
    # @return [Array<Geom::Point3d>] An array of points.
    def get_construction(object, recursive = true, transformation = nil, &entity_validation)
    end

    # Get group/component instance face triplets.
    # @note This function was revised in version 3.5.0.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] object A group or a
    #   component instance.
    # @param [Boolean] recursive Whether to include sub-groups and sub-component
    #   instances. All points of a sub-element are transformed to +object+'s
    #   transformation and then applied a desired transformation.
    # @param [Geom::Transformation, nil] transformation A coordinate system to
    #   transform all the points to before computing. Usually this parameter is
    #   the coordinate system +object+ is associated to. Pass +nil+ to
    #   compute in +object+'s local coordinates.
    # @yield A procedure to determine whether a particular face, sub-group, or a
    #   sub-component instance, should be considered a part of the operation.
    # @yieldparam [Sketchup::Drawingelement] entity
    # @yieldreturn [Boolean] Pass +true+ to consider an entity a part of the
    #   operation; pass +false+ to ignore the entity.
    # @return [Array<Array<Geom::Point3d>>] An array of polygons. Each polygon
    #   represents an array of three points - a triplet.
    def get_polygons_from_faces(object, recursive = true, transformation = nil, &entity_validation)
    end

    # Get group/component instance triangular mesh.
    # @note This function was revised in version 3.5.0.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] object A group or a
    #   component instance.
    # @param [Boolean] recursive Whether to include sub-groups and sub-component
    #   instances. All points of a sub-element are transformed to +object+'s
    #   transformation and then applied a desired transformation.
    # @param [Geom::Transformation, nil] transformation A coordinate system to
    #   transform all the points to before computing. Usually this parameter is
    #   the coordinate system +object+ is associated to. Pass +nil+ to
    #   compute in +object+'s local coordinates.
    # @yield A procedure to determine whether a particular face, sub-group, or a
    #   sub-component instance, should be considered a part of the operation.
    # @yieldparam [Sketchup::Drawingelement] entity
    # @yieldreturn [Boolean] Pass +true+ to consider an entity a part of the
    #   operation; pass +false+ to ignore the entity.
    # @return [Geom::PolygonMesh] Everything merged into one mesh.
    def get_triangular_mesh(object, recursive = true, transformation = nil, &entity_validation)
    end

    # Get group/component instance triangular mesh collections. Each sub-group,
    # sub-component, a collection of connected faces is reserved its own mesh.
    # @note This function was revised in version 3.5.0.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] object A group or a
    #   component instance.
    # @param [Boolean] recursive Whether to include sub-groups and sub-component
    #   instances. All points of a sub-element are transformed to +object+'s
    #   transformation and then applied a desired transformation.
    # @param [Geom::Transformation, nil] transformation A coordinate system to
    #   transform all the points to before computing. Usually this parameter is
    #   the coordinate system +object+ is associated to. Pass +nil+ to
    #   compute in +object+'s local coordinates.
    # @yield A procedure to determine whether a particular face, sub-group, or a
    #   sub-component instance, should be considered a part of the operation.
    # @yieldparam [Sketchup::Drawingelement] entity
    # @yieldreturn [Boolean] Pass +true+ to consider an entity a part of the
    #   operation; pass +false+ to ignore the entity.
    # @return [Array<Geom::PolygonMesh>] An array of meshes.
    def get_triangular_meshes(object, recursive = true, transformation = nil, &entity_validation)
    end

    # Calculate group/component instance centre of mass from faces.
    # @note This method returns an improper centre of mass in some cases.
    # @note This function was revised in version 3.5.0.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] object A group or a
    #   component instance.
    # @param [Boolean] recursive Whether to include sub-groups and sub-component
    #   instances. All points of a sub-element are transformed to +object+'s
    #   transformation and then applied a desired transformation.
    # @param [Geom::Transformation, nil] transformation A coordinate system to
    #   transform all the points to before computing. Usually this parameter is
    #   the coordinate system +object+ is associated to. Pass +nil+ to
    #   compute in +object+'s local coordinates.
    # @yield A procedure to determine whether a particular face, sub-group, or a
    #   sub-component instance, should be considered a part of the operation.
    # @yieldparam [Sketchup::Drawingelement] entity
    # @yieldreturn [Boolean] Pass +true+ to consider an entity a part of the
    #   operation; pass +false+ to ignore the entity.
    # @return [Geom::Point3d]
    def calc_centre_of_mass(object, recursive = true, transformation = nil, &entity_validation)
    end

    # Copy group/component instance without including the undesired entities.
    # @note Make sure to wrap this function with a start/commit operation to
    #   avoid polluting the undo stack.
    # @note The original group is not modified in any way.
    # @note Regardless of whether +object+ is a group or a component instance,
    #   the resulting entity will always be a group. Same applies to sub-groups
    #   and sub-component instances.
    # @note For copied faces:
    #   - Each is assigned its original front/back material.
    #   - Each is assigned to Layer0.
    #   - Attributes are not copied.
    #   - Casts/receives shadows and visibility state are not retained; they
    #     will depend on the parent group/component properties.
    # @note For copied edges:
    #   - Each is assigned its original soft/smooth options.
    #   - Each is assigned to Layer0.
    #   - Attributes are not copied.
    #   - Casts/receives shadows and visibility state are not retained; they
    #     will depend on the parent group/component properties.
    # @note For copied construction points and lines:
    #   - Each is assigned its original layer.
    #   - Attributes are not copied.
    # @note For copied group and sub-groups:
    #   - Each is assigned its original name, layer, material, visibility state,
    #     casts/receives shadows state, and transformation.
    #   - Attributes are not copied.
    # @note This function was revised in version 3.5.0.
    # @note Tiny faces with loops don't always replicate properly.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] object A group or a
    #   component instance.
    # @param [Sketchup::Entities, nil] context The entities context to paste to.
    #   Pass +nil+ to paste to the context +object+ is associated to.
    # @param [Boolean] recursive Whether to include sub-groups and sub-component
    #   instances.
    # @param [Geom::Transformation, nil] transformation A transformation matrix,
    #   relative to +context+, to apply to the resulting group. Pass +nil+
    #   to have the resulting group be applied the matrix of +object+.
    # @yield A procedure to determine whether a particular edge, face,
    #   construction point, construction line, sub-group, or a sub-component
    #   instance, should be considered a part of the operation.
    # @yieldparam [Sketchup::Drawingelement] entity
    # @yieldreturn [Boolean] Pass +true+ to consider an entity a part of the
    #   operation; pass +false+ to ignore the entity.
    # @return [Sketchup::Group, nil] A copied group or +nil+ if nothing copied.
    def copy(object, context = nil, recursive = true, transformation = nil, &entity_validation)
    end

    # Split group/component instance at plane.
    # @todo WIP
    # @note Make sure to wrap this function with a start/commit operation to
    #   avoid polluting the undo stack.
    # @note The original group is not modified in any way.
    # @note Regardless of whether +object+ is a group or a component instance,
    #   the resulting entity/entities will always be a group. Same applies to
    #   sub-groups and sub-component instances.
    # @note For copied/split faces:
    #   - Each is assigned its original front/back material.
    #   - Each is assigned to Layer0.
    #   - Attributes are not copied.
    #   - Casts/receives shadows and visibility state are not retained; they
    #     will depend on the parent group/component properties.
    # @note For copied/split edges:
    #   - Each is assigned its original soft/smooth options.
    #   - Each is assigned to Layer0.
    #   - Attributes are not copied.
    #   - Casts/receives shadows and visibility state are not retained; they
    #     will depend on the parent group/component properties.
    # @note For copied/split construction points and lines:
    #   - Each is assigned its original layer.
    #   - Attributes are not copied.
    # @note For copied/split group and sub-groups:
    #   - Each is assigned its original name, layer, material, visibility state,
    #     casts/receives shadows state, and transformation.
    #   - Attributes are not copied.
    # @note When a split occurs:
    #   - Faces/edges intersecting the plane are split into two faces/edges.
    #   - If a construction point/line being split is positioned on the plane,
    #     it's is copied to both sides of the destination groups.
    #   - If an edge/face being split is entirely on the plane, it is copied to
    #     both of the destination groups.
    #   - If a construction line being split is intersecting the plane, it is
    #     not split into two. Instead, its original placement is the used as an
    #     indicator of its side.
    # @note This function was revised in version 3.5.0.
    # @param [Sketchup::Group, Sketchup::ComponentInstance] object A group or a
    #   component instance.
    # @param [Geom::Point3d] plane_origin Origin of the splitting plane relative
    #   to the coordinate system +object+ is associated to.
    # @param [Geom::Point3d] plane_normal Normal of the splitting plane relative
    #   to the coordinate system +object+ is associated to.
    # @param [Boolean] close_sections Whether to close split sections with
    #   faces.
    # @param [Sketchup::Entities, nil] context The entities context to paste to.
    #   Pass +nil+ to paste to the context +object+ is associated to.
    # @param [Boolean] recursive Whether to include sub-groups and sub-component
    #   instances.
    # @param [Geom::Transformation, nil] transformation A transformation matrix,
    #   relative to +context+, to apply to the resulting group. Pass +nil+
    #   to have the resulting group be applied the matrix of +object+.
    # @yield A procedure to determine whether a particular edge, face,
    #   construction point, construction line, sub-group, or a sub-component
    #   instance, should be considered a part of the operation.
    # @yieldparam [Sketchup::Drawingelement] entity
    # @yieldreturn [Boolean] Pass +true+ to consider an entity a part of the
    #   operation; pass +false+ to ignore the entity.
    # @return [Array<Sketchup::Group>] An array of groups split at plane.
    #   At the maximum, two groups are returned if there are entities on both
    #   sides of the plane. One group is returned if entities are on one side of
    #   the plane. An empty array is returned if nothing copied.
    #def split(object, plane_origin, plane_normal, close_sections, context = nil, recursive = true, transformation = nil, &entity_validation)
    #end

  end # class << self
end # module AMS::Group
