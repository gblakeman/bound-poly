require './hash_poly'

describe HashPoly do
  before :each do
    @hp = HashPoly.new([160,90], 0.7, "rollit") 
  end

  it "should have everything it needs" do
    @hp.hash.should_not be_empty
    @hp.angles.should_not be_empty
    @hp.poly_points.should_not be_empty
  end
  
  it "should be filled with angles" do
    sum = @hp.angles.inject(0){|sum, item| sum += item}
    sum.should_not be 0
  end

  it "should normalize the angles between .035 and pi/2" do
    @hp.angles.each do |angle|
      angle.should be <= (Math::PI/2) and angle.should be >= 0.035
    end
  end

  describe "#poly_points" do
    it "should contain only points" do
      @hp.poly_points.each do |point|
        point.should be_is_a Point
      end
    end

    it "should have enough points" do
      @hp.poly_points.length.should be > 7
    end

    it "should return plain text points if asked" do
      @hp.poly_points(:coordinates).should be_is_a String
    end

    it "should make an svg polygon if asked" do
      @hp.poly_points(:svg).should be_is_a String
      @hp.poly_points(:svg).should =~ /svg/
    end
  end

  describe "#polygon" do
    it "should return plain text points if asked" do
      @hp.poly_points(:coordinates).should be_is_a String
    end

    it "should be an svg shape" do
    end
  end

  describe "#make_closed_polygon" do
    it "should remove escess trailing points so that the polygon can close" do
      @hp.poly_points.length.should equal 16
      @hp.polygon(:points).length.should equal 10
    end
    it "should be contain only points by default" do
      @hp.polygon(:points).each { |point| point.should be_is_a Point }
    end
    it "should make an svg polygon if asked" do
      @hp.polygon(:svg).should be_is_a String
      @hp.poly_points(:svg).should =~ /svg/
    end
  end

  describe "#make_angle_safe" do
    it "should make sure a line doesn't go to where it shouldn't" do
      nb = NestedBoxes.new(Box.new(Point.new(0,0), Point.new(100, 100)), 0.5)
      point = Point.new(1, 0, nb)

      @hp.make_angle_safe(1.2217, point, nb).should == (Math::atan(nb.y_diff.to_f / ((nb.inner.x_offset - point.x).to_f)) - 0.1)
      @hp.make_angle_safe(0.5, point, nb).should == 0.5
    end
  end

end

