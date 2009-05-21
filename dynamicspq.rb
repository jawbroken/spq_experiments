require 'thread'
require 'circle_aabb'

Quadtree = Struct.new(:value, :topleft, :topright, :bottomleft, :bottomright)

$quadtree = Quadtree.new(1, nil, nil, nil, nil)
$qmutex = Mutex.new

$cursor_centre = [256, 256]
$cursor_radius = 16

def in_circle(x, y, centre, radius)
  (x-centre[0])**2 + (y-centre[1])**2 <= radius**2
end

def leaf_node(qt)
  !qt.value.nil?
end

def destroy_quadtree(qt, centre, radius)
  def destroy_quadtree_r(qt, x, y, w, centre, radius)
    # Cases: Not overlapping - do nothing
    #        Fully overlapping - delete all subtrees, replace with leaf
    #        Partial overlap - subdivide and recur
    #        Can replace full and partial overlap cases by merging if all
    #        children are leaves. Inefficient though as it subdivides to 
    #        1 pixel. Don't do this in a real implementation.
    if w == 1
      if in_circle(x, y, centre, radius)
        Quadtree.new(0, nil, nil, nil, nil)
      else
        Quadtree.new(1, nil, nil, nil, nil)
      end
    end
    if in_circle(x, y, centre, radius) and in_circle(x, y+w, centre, radius) and in_circle(x+w, y, centre, radius) and in_circle(x+w, y+w, centre, radius)
      #full overlap
      return Quadtree.new(0, nil, nil, nil, nil)
    elsif circle_aabb_overlap?(Circle.new(Point.new(centre[0], centre[1]), radius),
      AABB.new(Point.new(x, y), w))
      #partial overlap
      #subdivide leaf nodes and recur
      if leaf_node(qt)
        oldval = qt.value
        qt = Quadtree.new(nil, Quadtree.new(oldval,nil,nil,nil,nil),
          Quadtree.new(oldval,nil,nil,nil,nil), Quadtree.new(oldval,nil,nil,nil,nil),
          Quadtree.new(oldval,nil,nil,nil,nil))
      end
      tlchild = destroy_quadtree_r(qt.topleft,x,y,w/2,centre,radius)
      trchild = destroy_quadtree_r(qt.topright,x+w/2,y,w/2,centre,radius)
      blchild = destroy_quadtree_r(qt.bottomleft,x,y+w/2,w/2,centre,radius)
      brchild = destroy_quadtree_r(qt.bottomright,x+w/2,y+w/2,w/2,centre,radius)
      if leaf_node(tlchild) and leaf_node(trchild) and leaf_node(blchild) and leaf_node(brchild)
        sum = tlchild.value+trchild.value+blchild.value+brchild.value
        if sum == 0 #all black
          return Quadtree.new(0, nil, nil, nil, nil)
        elsif sum == 4 # all white
          return Quadtree.new(1, nil, nil, nil, nil)
        end
      end
      return Quadtree.new(nil, tlchild, trchild, blchild, brchild)
    else
      #no overlap
      return qt
    end
  end
  destroy_quadtree_r(qt, 0, 0, 512, centre, radius)
end

# terrible code duplication :(
# but it is a hacky prototype so whatever
def construct_quadtree(qt, centre, radius)
  def construct_quadtree_r(qt, x, y, w, centre, radius)
    # Cases: Not overlapping - do nothing
    #        Fully overlapping - delete all subtrees, replace with leaf
    #        Partial overlap - subdivide and recur
    #        Can replace full and partial overlap cases by merging if all
    #        children are leaves. Inefficient though as it subdivides to 
    #        1 pixel. Don't do this in a real implementation.
    if w == 1
      if in_circle(x, y, centre, radius)
        Quadtree.new(1, nil, nil, nil, nil)
      else
        Quadtree.new(0, nil, nil, nil, nil)
      end
    end
    if in_circle(x, y, centre, radius) and in_circle(x, y+w, centre, radius) and in_circle(x+w, y, centre, radius) and in_circle(x+w, y+w, centre, radius)
      #full overlap
      return Quadtree.new(1, nil, nil, nil, nil)
    elsif circle_aabb_overlap?(Circle.new(Point.new(centre[0], centre[1]), radius),
      AABB.new(Point.new(x, y), w))
      #partial overlap
      #subdivide leaf nodes and recur
      if leaf_node(qt)
        oldval = qt.value
        qt = Quadtree.new(nil, Quadtree.new(oldval,nil,nil,nil,nil),
          Quadtree.new(oldval,nil,nil,nil,nil), Quadtree.new(oldval,nil,nil,nil,nil),
          Quadtree.new(oldval,nil,nil,nil,nil))
      end
      tlchild = construct_quadtree_r(qt.topleft,x,y,w/2,centre,radius)
      trchild = construct_quadtree_r(qt.topright,x+w/2,y,w/2,centre,radius)
      blchild = construct_quadtree_r(qt.bottomleft,x,y+w/2,w/2,centre,radius)
      brchild = construct_quadtree_r(qt.bottomright,x+w/2,y+w/2,w/2,centre,radius)
      if leaf_node(tlchild) and leaf_node(trchild) and leaf_node(blchild) and leaf_node(brchild)
        sum = tlchild.value+trchild.value+blchild.value+brchild.value
        if sum == 0 #all black
          return Quadtree.new(0, nil, nil, nil, nil)
        elsif sum == 4 # all white
          return Quadtree.new(1, nil, nil, nil, nil)
        end
      end
      return Quadtree.new(nil, tlchild, trchild, blchild, brchild)
    else
      #no overlap
      return qt
    end
  end
  construct_quadtree_r(qt, 0, 0, 512, centre, radius)
end

#############################
# bunch of hacky GL code here
require 'rubygems'
require 'gl'
require 'glu'
require 'glut'

include Gl
include Glu
include Glut

glutInit
glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA)
glutInitWindowSize(512, 512)
glutCreateWindow("Sparse Pixel Quadtree")
# nice mid blue, make sure everything is being rendered
glClearColor(0.5, 0.5, 1.0, 1.0)
glPointSize(1.0)
glLineWidth(0.5)
glEnable(GL_LINE_SMOOTH)
glEnable(GL_POINT_SMOOTH)
glEnable(GL_BLEND)
glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
glHint(GL_LINE_SMOOTH_HINT, GL_DONT_CARE)
glHint(GL_POINT_SMOOTH_HINT, GL_DONT_CARE)
glMatrixMode(GL_PROJECTION)
glLoadIdentity()
glOrtho(0, 512, 512, 0, -1.0, 1.0)

SLEEP_TICKS = 10
def timercall(value)
  glutTimerFunc(SLEEP_TICKS, method(:timercall).to_proc, 0)
  glutPostRedisplay
end

keyboard = lambda do |key, x, y|
  if key == ?\e || key == ?q
    exit(0)
  # elsif key == ?w
  #   $cursor_centre[1] -= 1 if $cursor_centre[1] > 0
  # elsif key == ?s
  #   $cursor_centre[1] += 1 if $cursor_centre[1] < 511
  # elsif key == ?a
  #   $cursor_centre[0] -= 1 if $cursor_centre[0] > 0
  # elsif key == ?d
  #   $cursor_centre[0] += 1 if $cursor_centre[0] < 511
  elsif key == ?-
    $cursor_radius -= 1 if $cursor_radius > 1
  elsif key == ?=
    $cursor_radius += 1 if $cursor_radius < 128
  elsif key == " "[0]
    $qmutex.synchronize do
      $quadtree = destroy_quadtree($quadtree, $cursor_centre, $cursor_radius)
    end
  end
end

def draw_quadtree(qt, x, y, w, h)
  return if qt.nil?
  if !qt.value.nil?
    if qt.value == 1
      glColor3f(1.0,1.0,1.0)
    else
      glColor3f(0.0, 0.0, 0.0)
    end
    glBegin(GL_QUADS)
      glVertex2f(x,y)
      glVertex2f(x+w,y)
      glVertex2f(x+w,y+h)
      glVertex2f(x, y+h)
    glEnd()
    glColor3f(1.0, 0.0, 0.0)
    glBegin(GL_LINE_STRIP)
      glVertex2f(x,y)
      glVertex2f(x+w,y)
      glVertex2f(x+w,y+h)
      glVertex2f(x, y+h)
      glVertex2f(x, y)
    glEnd()
  else
    draw_quadtree(qt.topleft,     x,     y,     w/2, h/2)
    draw_quadtree(qt.topright,    x+w/2, y,     w/2, h/2)
    draw_quadtree(qt.bottomleft,  x,     y+h/2, w/2, h/2)
    draw_quadtree(qt.bottomright, x+w/2, y+h/2, w/2, h/2)
  end
end

def display
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    $qmutex.synchronize do
      draw_quadtree($quadtree, 0, 0, 512, 512)
    end
    # show cursor
    glColor4f(0.0, 1.0, 0.0, 0.5)
    glBegin(GL_TRIANGLE_FAN)
      glVertex2f($cursor_centre[0], $cursor_centre[1])
      (0..360).step(5) do |theta|
        glVertex2f($cursor_centre[0]+Math::sin(theta*Math::PI/180)*$cursor_radius,
                   $cursor_centre[1]+Math::cos(theta*Math::PI/180)*$cursor_radius)
      end
    glEnd()
    glutSwapBuffers
end

passive_mouse = lambda do |x, y|
  $cursor_centre = [x,y]
end

mouse = lambda do |button, state, x, y|
  if state == GLUT_UP and button == GLUT_LEFT_BUTTON
    $qmutex.synchronize do
      $quadtree = destroy_quadtree($quadtree, [x,y], $cursor_radius)
    end
  end
  if state == GLUT_UP and button == GLUT_RIGHT_BUTTON
    $qmutex.synchronize do
      $quadtree = construct_quadtree($quadtree, [x,y], $cursor_radius)
    end
  end
end

glutDisplayFunc(method(:display).to_proc)
glutTimerFunc(SLEEP_TICKS, method(:timercall).to_proc, 0)
glutKeyboardFunc(keyboard)
glutPassiveMotionFunc(passive_mouse)
glutMotionFunc(passive_mouse)
glutMouseFunc(mouse)
glutMainLoop()

