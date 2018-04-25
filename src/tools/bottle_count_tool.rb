require 'src/tools/tool'
require 'src/utility/bottle_counter'

# Checks how many bottles and hubs there are in the scene.
class BottleCountTool < Tool
  def activate
    counts = BottleCounter.bottle_counts
    bottle_count_strings = counts.map { |name, count| "#{name}: #{count}" }
    msg = "Hubs: #{BottleCounter.number_nodes}\n\n" +
          bottle_count_strings.join("\n")
    UI.messagebox(msg)
  end
end
