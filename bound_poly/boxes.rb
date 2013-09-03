require './bound_poly/point'

class Box

  attr_accessor :width, :height, :x_offset, :y_offset

  def initialize(start_point, end_point)
    @width = end_point.x - start_point.x
    @height = end_point.y - start_point.y
    @x_offset = start_point.x
    @y_offset = start_point.y
  end

  def to_side(side)
    if side == :right
      @width + @x_offset
    elsif side == :bottom
      @height + @y_offset
    end
  end
end

class NestedBoxes

  attr_accessor :outer, :inner, :x_diff, :y_diff

  def initialize(outer_box, inner_percent)
    @outer = outer_box
    # we need both even, or both odd. even is good.
    @outer.width = make_even(@outer.width)
    @outer.height = make_even(@outer.height)
    @inner = make_inside_box(outer_box, inner_percent)
    @x_diff = @inner.x_offset - outer.x_offset
    @y_diff = @inner.y_offset - outer.y_offset
  end

  def make_inside_box(outer_box, percentage)
    width = make_even((outer_box.width * percentage).to_i)
    height = make_even((outer_box.height * percentage).to_i)
    x_offset = ((outer_box.width - width) / 2) + outer_box.x_offset
    y_offset = ((outer_box.height - height) / 2) + outer_box.y_offset
    Box.new(Point.new(x_offset, y_offset), Point.new(x_offset + width, y_offset + height))
  end

  def make_even(number)
    return (number + 1) if (number % 2) != 0
    number
  end
end
