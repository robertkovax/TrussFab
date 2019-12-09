require 'csv'
require 'src/spring_animation.rb'
require 'src/system_simulation/modellica_export.rb'

class SpringAnimationTool < Tool
  HTML_FILE = '../ui/spring-interact/index.html'.freeze

  def initialize(ui)
    super(ui)


    @data = nil

    @mouse_input = MouseInput.new(snap_to_edges: true, snap_to_nodes: true)
    @edge = nil
    @spring = nil
    @initial_edge_length = nil
    @initial_edge_position = nil
    @animation = nil
    @dialog = nil
  end

  def onLButtonDown(_flags, x, y, view)
    if @animation
      @animation.halt
    end
    @mouse_input.update_positions(view, x, y)
    obj = @mouse_input.snapped_object
    if !obj.nil? && obj.is_a?(Edge) && obj.link_type == 'spring'
      # TODO adjust paths
      @data = ModellicaExport.import_csv("src/system_simulation/test.csv")
      @edge = obj

      @initial_edge_length = @edge.length
      @initial_edge_position = @edge.mid_point
      @first_vector = @initial_edge_position.vector_to(@edge.first_node.position)
      @second_vector = @initial_edge_position.vector_to(@edge.second_node.position)

      @animation = SpringAnimation.new(@data, @first_vector, @second_vector, @initial_edge_position, @edge)
      Sketchup.active_model.active_view.animation = @animation
      open_dialog(x,y)
    end


  end

  def open_dialog(x,y)
    return if @dialog
    props = {
      # resizable: false,
      preferences_key: 'com.trussfab.spring_interaction',
      width: 200,
      height: 250,
      left: 5,
      top: 5,
      min_width: 200,
      min_height: 150,
      max_width: 100,
      # max_height: @height
      :style => UI::HtmlDialog::STYLE_UTILITY
    }

    @dialog = UI::HtmlDialog.new(props)
    file = File.join(File.dirname(__FILE__), HTML_FILE)
    @dialog.set_file(file)
    puts("" + x.to_s + " " + y.to_s)
    @dialog.set_position(x / 2 - 150,y / 2 + 100)
    @dialog.show
    register_callbacks
  end

  def register_callbacks
    @dialog.add_action_callback('spring_interaction_plus') do |_|
      puts("plus")
      @animation.factor = @animation.factor + 2
    end

    @dialog.add_action_callback('spring_interaction_minus') do |_|
      puts("minus")
      @animation.factor = @animation.factor - 2
    end
  end

  def onMouseMove(_flags, x, y, view)
    @mouse_input.update_positions(view, x, y)
  end




end
