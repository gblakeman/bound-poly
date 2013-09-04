require 'digest/md5'
require 'bound_poly/boxes'
require 'bound_poly/point'

class BoundPoly
  attr_accessor :hash, :angles, :poly_points, :nested_boxes, :polygon, :min_angle, :max_angle

  def initialize(outer_box_dimentions, inner_box_percentage, some_text)
    @min_angle = 0.035 # in radians
    @max_angle = Math::PI/4
    @nested_boxes = NestedBoxes.new(
      Box.new(Point.new(0,0),
              Point.new(outer_box_dimentions[0], outer_box_dimentions[1])),
      inner_box_percentage)
    @hash = Digest::MD5.hexdigest(some_text)
    @angles = make_angles(@hash)
    @poly_points = make_poly_points(@angles, @nested_boxes)
    @polygon = make_closed_polygon(@poly_points, @nested_boxes)
  end

  def poly_points(method = :points)
    if method == :points
      @poly_points
    elsif method == :coordinates
      coords = ""
      @poly_points.each do |point|
        coords = coords + "#{point.x},#{point.y}\n"
      end
      coords
    end
  end

  def polygon(method = :points)
    if method == :points
      @polygon
    elsif method == :svg
      svg_string = <<SVG
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="#{@nested_boxes.outer.width}px" height="#{@nested_boxes.outer.height}" viewBox="0 0 #{@nested_boxes.outer.width} #{@nested_boxes.outer.height}" enable-background="new 0 0 #{@nested_boxes.outer.width} #{@nested_boxes.outer.height}" xml:space="preserve">
<polygon fill="none" stroke="lime" stroke-width="4" 
points="#{polygon(:coordinates)}"></polygon>
</svg>
SVG
    elsif method == :coordinates
      coords = ""
      @polygon.each do |point|
        coords = coords + "#{point.x},#{point.y}\n"
      end
      coords
    end
  end

  def make_closed_polygon(points, nested_boxes)
    # take off any points after we've wrapped around one and a half times
    five_quarters = points.inject([]) do |sides_hit, point|
      if sides_hit.include?(:stop)
        true
      elsif sides_hit.include?(:top) &&
        sides_hit.include?(:right) &&
        sides_hit.include?(:bottom) &&
        sides_hit.include?(:left)
        if point.location[:side] == :right
          sides_hit.push(:stop) 
        else
          sides_hit.push(point.location[:side])
        end
      elsif
        sides_hit.push(point.location[:side])
      end
      sides_hit
    end
    five_quarters = points.take(five_quarters.length)
    # take off points until we can close the polygon!
    closest_to_start = [1000, 10000]
    five_quarters.inject(0) do |n, point|
      if point.location[:box] == :outer &&
        point.location[:side] == :top &&
        n > 5

        distance_to_start = distance_between_points(five_quarters[0], point)
        closest_to_start = [n, distance_to_start] if distance_to_start < closest_to_start[1]
      end
      n + 1
    end
    points = points.take(closest_to_start[0])
    # well, we might need to scooch the last point a bit so
    # we don't collide with the inside box
    if points.last.location[:side] == :left
      if points.last.location[:box] == :inner
        # logic to try and scoot, or delete
      elsif points.last.location[:box] == :outer
        # logic to try and scoot
      end
    elsif points.last.location[:side] == :top
      if points.last.location[:box] == :inner
        # if the angle between this and last is in bounds
        angle = distance_between_points
      elsif points.last.location[:box] == :outer
        raise "Agh! The world has ended."
      end
    end
    points
  end

  def distance_between_points(point1, point2)
    result = Math::hypot(point2.x - point1.x, point2.y - point1.y)
    return result if result > 0
    return result * -1
  end
  
  def angle_between_points(point1, point2)
    result = Math::hypot(point2.x - point1.x, point2.y - point1.y)
    return result if result > 0
    return result * -1
  end

  def make_angles(hash)
    hash_ary = hash.dup.split("")
    angles = Array.new
    until hash_ary.empty?
      hex_num = hash_ary.shift(2).join
      decimal_num = hex_num.to_i(16).to_s(10).to_i
      angle = ((decimal_num/255.0) * (max_angle - min_angle)) + min_angle
      angles.push(angle)
    end
    angles
  end

  def make_poly_points(angles, nested_boxes, coords = Array.new)
    angles.empty? ? (return coords) : angle = angles[0] 
    if coords.empty?
      #generate a spot along the top of the box to start from and angle
      angle_percent = angle / (Math::PI/2)
      first_x_coordinate =
        (nested_boxes.outer.width * angle_percent) +
        nested_boxes.outer.x_offset
      initial_point = Point.new(first_x_coordinate, 0, nested_boxes)
      coords.push(initial_point)
    else
      next_point = get_next_point(coords.last, angle, nested_boxes)
      unless next_point.nil?
        coords.push(next_point)
      else
        raise "Couldn't find the point after (#{coords.last.x},#{coords.last.y}). Got through #{coords.length} coordinates first." # not cool
      end
    end
    make_poly_points(angles.drop(1), nested_boxes, coords)
  end

  def get_next_point(point, angle, nested_boxes)
    angle = make_angle_safe(angle, point, nested_boxes)
    if point.location[:box] == :outer

      if point.location[:side] == :top
        if ((nested_boxes.inner.to_side(:right) - point.x) > 0)
          o = nested_boxes.y_diff
          a = (o.to_f / Math::tan(angle))
          try = Point.new(point.x + a, point.y + o, nested_boxes)
          return try unless try.location == false
        end
        a = nested_boxes.outer.to_side(:right) - point.x
        o = (a * Math::tan(angle))
        try = Point.new(point.x + a, point.y + o, nested_boxes)
        return try unless try.location == false
        
      elsif point.location[:side] == :right
        if ((nested_boxes.inner.to_side(:bottom) - point.y) > 0)
          o = nested_boxes.x_diff
          a = (o.to_f / Math::tan(angle))
          try = Point.new(point.x - o, point.y + a, nested_boxes)
          return try unless try.location == false
        end
        a = nested_boxes.outer.to_side(:bottom) - point.y
        o = (a * Math::tan(angle))
        try = Point.new(point.x - o, point.y + a, nested_boxes)
        return try unless try.location == false

      elsif point.location[:side] == :bottom
        if ((point.x - nested_boxes.inner.x_offset) > 0)
          o = nested_boxes.y_diff
          a = (o.to_f / Math::tan(angle))
          try = Point.new(point.x - a, point.y - o, nested_boxes)
          return try unless try.location == false
        end
        a = point.x - nested_boxes.outer.x_offset
        o = (a * Math::tan(angle))
        try = Point.new(point.x - a, point.y - o, nested_boxes)
        return try unless try.location == false
        
      elsif point.location[:side] == :left
        if point.y > nested_boxes.inner.y_offset
          o = nested_boxes.x_diff
          a = (o.to_f / Math::tan(angle))
          try = Point.new(point.x + o, point.y - a, nested_boxes)
          return try unless try.location == false
        end
        a = point.y - nested_boxes.outer.y_offset
        o = (a * Math::tan(angle))
        try = Point.new(point.x + o, point.y - a, nested_boxes)
        return try unless try.location == false

      end # close box sides

    elsif point.location[:box] == :inner

      if point.location[:side] == :top
        o = nested_boxes.y_diff
        a = (o.to_f / Math::tan(angle))
        try = Point.new(point.x + a, point.y - o, nested_boxes)
        return try unless try.location == false

        a = nested_boxes.outer.to_side(:right) - point.x
        o = (a * Math::tan(angle))
        try = Point.new(point.x + a, point.y - o, nested_boxes)
        return try unless try.location == false

      elsif point.location[:side] == :right
        o = nested_boxes.x_diff
        a = (o.to_f / Math::tan(angle))
        try = Point.new(point.x + o, point.y + a, nested_boxes)
        return try unless try.location == false

        a = nested_boxes.outer.to_side(:bottom) - point.y
        o = (a * Math::tan(angle))
        try = Point.new(point.x + o, point.y + a, nested_boxes)
        return try unless try.location == false

      elsif point.location[:side] == :bottom
        o = nested_boxes.y_diff
        a = (o.to_f / Math::tan(angle))
        try = Point.new(point.x - a, point.y + o, nested_boxes)
        return try unless try.location == false

        a = point.x - nested_boxes.outer.x_offset
        o = (a * Math::tan(angle))
        try = Point.new(point.x - a, point.y + o, nested_boxes)
        return try unless try.location == false

      elsif point.location[:side] == :left
        o = nested_boxes.x_diff
        a = (o.to_f / Math::tan(angle))
        try = Point.new(point.x - o, point.y - a, nested_boxes)
        return try unless try.location == false

        a = point.y - nested_boxes.outer.y_offset
        o = (a * Math::tan(angle))
        try = Point.new(point.x - o, point.y - a, nested_boxes)
        return try unless try.location == false

      end # close box sides

    end # close inner/outer logic

    nil
  end

  def make_angle_safe(angle, point, nested_boxes)
    if point.location[:box] == :outer

      if point.location[:side] == :top
        if point.x < nested_boxes.inner.x_offset
          break_angle = Math::atan(nested_boxes.y_diff.to_f / ((nested_boxes.inner.x_offset - point.x).to_f))
          return break_angle - 0.1 if angle > break_angle
        elsif point.x > nested_boxes.inner.to_side(:right)
          break_angle = Math::atan(nested_boxes.outer.height.to_f / (nested_boxes.outer.width - point.x).to_f)
          return break_angle - 0.1 if angle > break_angle
        end

      elsif point.location[:side] == :right
        if point.y < nested_boxes.inner.y_offset
          break_angle = Math::atan(nested_boxes.x_diff.to_f / (nested_boxes.y_diff - point.y).to_f)
          return break_angle - 0.1 if angle > break_angle
        elsif point.y > nested_boxes.inner.to_side(:bottom)
          break_angle = Math::atan(nested_boxes.outer.width.to_f / (nested_boxes.outer.height - point.y).to_f)
          return break_angle - 0.1 if angle > break_angle
        end

      elsif point.location[:side] == :bottom
        if point.x > nested_boxes.inner.to_side(:right)
          break_angle = Math::atan(nested_boxes.y_diff.to_f / (point.x - nested_boxes.inner.to_side(:right)).to_f)
          return break_angle - 0.1 if angle > break_angle
        elsif point.x < nested_boxes.inner.x_offset
          break_angle = Math::atan(nested_boxes.outer.height.to_f / point.x.to_f)
          return break_angle - 0.1 if angle > break_angle
        end

      elsif point.location[:side] == :left
        if point.y > nested_boxes.inner.to_side(:bottom)
          break_angle = Math::atan((point.y - nested_boxes.inner.to_side(:bottom)).to_f / nested_boxes.x_diff.to_f)
          return break_angle - 0.1 if angle > break_angle
        elsif point.y < nested_boxes.y_diff
          break_angle = Math::atan(nested_boxes.outer.width.to_f / point.y.to_f)
          return break_angle - 0.1 if angle > break_angle
        end

      end

    end
    angle
  end
end
