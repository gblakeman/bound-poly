require 'bound_poly/boxes'

class Point
  attr_accessor :x, :y, :location
  def initialize(x, y, nested_boxes = nil)
    @x = x
    @y = y
    @location = Hash.new

    if nested_boxes.is_a? NestedBoxes
      ghost_point = Point.new(@x, @y)
      if on_box?(ghost_point, nested_boxes.outer)
        @location[:box] = :outer
        @location[:side] = on_box?(ghost_point, nested_boxes.outer)
      elsif on_box?(ghost_point, nested_boxes.inner)
        @location[:box] = :inner
        @location[:side] = on_box?(ghost_point, nested_boxes.inner)
      else
        @location = false
      end
    end
  end

  def on_box?(point, box)
    return false unless point.is_a? Point

    within_x = (box.x_offset..(box.to_side(:right))).include? point.x
    within_y = (box.y_offset..(box.to_side(:bottom))).include? point.y
    on_left = (point.x == box.x_offset)
    on_right = (point.x == box.to_side(:right))
    on_top = (point.y == box.y_offset)
    on_bottom = (point.y == box.to_side(:bottom))

    if on_top && within_x
      :top
    elsif on_right && within_y
      :right
    elsif on_bottom && within_x
      :bottom
    elsif on_left && within_y
      :left
    else
      false
    end
  end
end
