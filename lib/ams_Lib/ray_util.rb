# Ray utility adds more options to the +Sketchup.active_model.raytest+ function.
# @since 2.0.0
module AMS::RayUtil
  class << self

    # Get an array of points intersecting the ray.
    # _T1_ : type 1 checks all model entities.
    # @param [Geom::Point3d, Array] point Ray position.
    # @param [Geom::Vector3d, Array] vector Ray direction.
    # @param [Boolean] chg Whether to consider hidden geometry.
    # @return [Array<Geom::Point3d>] An array of points intersecting the ray.
    def deepray_t1(point, vector, chg = false)
      chg = chg ? true : false
      pts = []
      hit = nil
      while true
        hit = Sketchup.active_model.raytest(point, vector, !chg)
        break unless hit
        x = hit[0]
        pts.push x
        point = x
      end
      pts
    end

    # Get an array of points intersecting the ray.
    # _T2_ : type 2 checks all the given entities.
    # @param [Array<entity>] ents An array of entities to include.
    # @param [Geom::Point3d, Array] point Ray position.
    # @param [Geom::Vector3d, Array] vector Ray direction.
    # @param [Boolean] chg Whether to consider hidden geometry.
    # @return [Array<Geom::Point3d>] An array of points intersecting the ray.
    def deepray_t2(ents, point, vector, chg = false)
      chg = chg ? true : false
      unless ents.is_a?(Array)
        ents = ents.respond_to?(:to_a) ? ents.to_a : [ents]
      end
      entIDs = Hash[ents.map {|e| [e.entityID, 1]}]
      pts = []
      hit = nil
      while true
        hit = Sketchup.active_model.raytest(point, vector, !chg)
        break unless hit
        x = hit[0]
        pts.push x if entIDs[hit[1][0].entityID]
        point = x
      end
      pts
    end

    # Get an array of points intersecting the ray.
    # _T3_ : type 3 checks all, but the given entities.
    # @param [Array<entity>] ents An array of entities to ignore.
    # @param [Geom::Point3d, Array] point Ray position.
    # @param [Geom::Vector3d, Array] vector Ray direction.
    # @param [Boolean] chg Whether to consider hidden geometry.
    # @return [Array<Geom::Point3d>] An array of points intersecting the ray.
    def deepray_t3(ents, point, vector, chg = false)
      chg = chg ? true : false
      unless ents.is_a?(Array)
        ents = ents.respond_to?(:to_a) ? ents.to_a : [ents]
      end
      entIDs = Hash[ents.map {|e| [e.entityID, 1]}]
      pts = []
      hit = nil
      while true
        hit = Sketchup.active_model.raytest(point, vector, !chg)
        break unless hit
        x = hit[0]
        pts.push x unless entIDs[hit[1][0].entityID]
        point = x
      end
      pts
    end

    # Cast a ray through the model and get the first thing that the ray hits.
    # _T1_ : type 1 checks all the given entities.
    # @param [Array<entity>] ents An array of entities to include.
    # @param [Geom::Point3d, Array] point Ray position.
    # @param [Geom::Vector3d, Array] vector Ray direction.
    # @param [Boolean] chg Whether to consider hidden geometry.
    # @return [Array, nil] A ray result:
    #   http://www.sketchup.com/intl/en/developer/docs/ourdoc/model.php#raytest
    def raytest_t1(ents, point, vector, chg = false)
      chg = chg ? true : false
      unless ents.is_a?(Array)
        ents = ents.respond_to?(:to_a) ? ents.to_a : [ents]
      end
      entIDs = Hash[ents.map {|e| [e.entityID, 1]}]
      hit = nil
      while true
        hit = Sketchup.active_model.raytest(point, vector, !chg)
        break unless hit
        return hit if entIDs[hit[1][0].entityID]
        point = hit[0]
      end
      nil
    end

    # Cast a ray through the model and get the first thing that the ray hits.
    # _T2_ : type 2 checks all, but the given entities.
    # @param [Array<entity>] ents An array of entities to ignore.
    # @param [Geom::Point3d, Array] point Ray position.
    # @param [Geom::Vector3d, Array] vector Ray direction.
    # @param [Boolean] chg Whether to consider hidden geometry.
    # @return [Array, nil] A ray result:
    #   http://www.sketchup.com/intl/en/developer/docs/ourdoc/model.php#raytest
    def raytest_t2(ents, point, vector, chg = false)
      chg = chg ? true : false
      unless ents.is_a?(Array)
        ents = ents.respond_to?(:to_a) ? ents.to_a : [ents]
      end
      entIDs = Hash[ents.map {|e| [e.entityID, 1]}]
      hit = nil
      while true
        hit = Sketchup.active_model.raytest(point, vector, !chg)
        break unless hit
        return hit unless entIDs[hit[1][0].entityID]
        point = hit[0]
      end
      nil
    end

    # Cast a ray through the model and get the first thing that the ray hits.
    # _T3_ : type 3 passes through transparent faces and stops until it hits a
    # solid face.
    # @param [Geom::Point3d, Array] point Ray position.
    # @param [Geom::Vector3d, Array] vector Ray direction.
    # @param [Boolean] chg Whether to consider hidden geometry.
    # @return [Array, nil] A ray result:
    #   http://www.sketchup.com/intl/en/developer/docs/ourdoc/model.php#raytest
    def raytest_t3(point, vector, chg = false)
      chg = chg ? true : false
      hit = nil
      model = Sketchup.active_model
      cam = model.active_view.camera
      while true
        hit = model.raytest(point, vector, !chg)
        break unless hit
        ent = hit[1].last
        return hit unless ent.is_a?(Sketchup::Face)
        angle = ent.normal.angle_between(cam.direction)
        mat = nil
        normal = ent.normal
        for i in 0...(hit[1].size-1)
          e = hit[1][i]
          normal.transform!(e.transformation)
          mat = e.material if e.material != nil
        end
        fmat = angle < 90.degrees ? ent.back_material : ent.material
        mat = fmat if fmat != nil
        return hit if mat.nil? or mat.alpha == 1.0
        point = hit[0]
      end
      nil
    end

  end # class << self
end # module AMS::RayUtil
