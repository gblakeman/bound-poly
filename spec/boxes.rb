require './lib/bound_poly/boxes'

describe "Box" do
  before :each do
    @box = Box.new(Point.new(2, 3), Point.new(300, 400))
  end

  it "should have dimentions and offset and to edges" do
    @box.width.should equal 298
    @box.height.should equal 397
    @box.x_offset.should equal 2
    @box.y_offset.should equal 3
    @box.to_side(:right).should equal 300
    @box.to_side(:bottom).should equal 400
  end
end

describe "NestedBoxes" do
  before :each do
    @nb = NestedBoxes.new(Box.new(Point.new(0,0), Point.new(160,90)), 0.5)
  end
  it "should have two boxes" do
    @nb.outer.should be_is_a Box
    @nb.inner.should be_is_a Box
  end
  it "should tell you the differences" do
    @nb.x_diff.should equal 40
    @nb.y_diff.should equal 22
  end
  it "should scale the inside box appropriately" do
    @nb.inner.x_offset.should equal 40
    @nb.inner.y_offset.should equal 22
    @nb.inner.width.should equal 80
    @nb.inner.height.should equal 46
  end
  it "should tell you how long to the edge of the inside box" do
    @nb.inner.to_side(:right).should equal 120
    @nb.inner.to_side(:bottom).should equal 68
  end
end
