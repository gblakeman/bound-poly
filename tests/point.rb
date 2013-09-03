require './point'
require './boxes'

describe "Point" do
  before :each do
    @point = Point.new(3, 8)
  end

  it "should have and x and a y coordinate" do
    @point.x.should_not be_nil
    @point.y.should_not be_nil
  end

  it "should have correct location when initialized with a box_set" do
    nested_boxes = NestedBoxes.new(Box.new(Point.new(5, 9), Point.new(204, 400)), 0.6)
    
    # inner right?
    inner_right_point = Point.new(nested_boxes.inner.to_side(:right), 300, nested_boxes)
    inner_right_point.location[:box].should equal :inner
    inner_right_point.location[:side].should equal :right

    # inner bottom?
    inner_bottom_point = Point.new(70, nested_boxes.inner.to_side(:bottom), nested_boxes)
    inner_bottom_point.location[:box].should equal :inner
    inner_bottom_point.location[:side].should equal :bottom

    #outer left?
    outer_left_point = Point.new(nested_boxes.outer.x_offset, 200, nested_boxes)
    outer_left_point.location[:box].should equal :outer
    outer_left_point.location[:side].should equal :left

    #outer top?
    outer_top_point = Point.new(40, nested_boxes.outer.y_offset, nested_boxes)
    outer_top_point.location[:box].should equal :outer
    outer_top_point.location[:side].should equal :top
  end

  describe "#on_box?" do
    it "should let you know where a point falls on a box" do
      box = Box.new(Point.new(3, 9), Point.new(203, 509))
      @point.on_box?(Point.new(150, 9), box).should equal :top
      @point.on_box?(Point.new(203, 400), box).should equal :right
      #@point.on_box?(Point.new(203, 509), box).should equal :bottom and :right?
      @point.on_box?(Point.new(10, 509), box).should equal :bottom
      @point.on_box?(Point.new(3, 300), box).should equal :left
      
      @point.on_box?(Point.new(0, 0), box).should be_false
      @point.on_box?(Point.new(50, 50), box).should be_false
      @point.on_box?(Point.new(150, 10), box).should be_false
    end
  end
end
