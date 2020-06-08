# TODO: move this file to the right place in the project structure.

class SpringConstantObserver < Sketchup::EntityObserver
  def initialize(id)
    @spring_id = id
  end

  def onChangeEntity(text)
    unless text.is_a? Sketchup::Text
      puts "WARNING: SpringConstantObserver attached to a entity which is not a text. This is not intended to work."
    end
    puts "constant changed: #{text.text}"
    TrussFab.get_spring_pane.update_constant_for_spring(@spring_id, text.text.to_i)

  end
end

