import bpy, math, random, sys
from mathutils import Vector, Euler
random.seed(5)
argv = sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
PCT = int(argv[0]) if argv else 25
SAMPLES = int(argv[1]) if len(argv) > 1 else 32
OUT = argv[2] if len(argv) > 2 else "/tmp/claude-0/-home-user-my-web-apps/8d80fa72-b2c8-5055-9f62-4b5965f27331/scratchpad/b3d/out.png"

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
R = math.radians

# ---------- 재질 ----------
def mat(name, color, rough=0.6, emit=None, strength=0.0, metal=0.0, sheen=0.0, alpha=1.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1)
        b.inputs["Emission Strength"].default_value = strength
    if sheen:
        try:
            b.inputs["Sheen Weight"].default_value = sheen
        except Exception:
            pass
    if alpha < 1:
        b.inputs["Alpha"].default_value = alpha
    return m
SKIN = mat("skin", (0.95, 0.70, 0.50), 0.5)
GI = mat("gi", (0.035, 0.035, 0.045), 0.75, sheen=0.4)
PANTS = mat("pants", (0.025, 0.025, 0.03), 0.8, sheen=0.4)
RED = mat("red", (0.55, 0.02, 0.03), 0.55, sheen=0.3)
GOLD = mat("gold", (1.0, 0.7, 0.25), 0.3, metal=1.0)
HAIR = mat("hair", (0.01, 0.01, 0.012), 0.45)
EYE = mat("eye", (0.01, 0.01, 0.015), 0.2)
WHITE = mat("white", (1, 1, 1), 0.3, emit=(1, 1, 1), strength=2.0)
ROCK = mat("rock", (0.06, 0.055, 0.06), 0.9)
CYAN = mat("cyan", (0.2, 0.7, 1.0), 0.3, emit=(0.35, 0.8, 1.0), strength=40)
CYAN2 = mat("cyan2", (0.2, 0.7, 1.0), 0.3, emit=(0.5, 0.9, 1.0), strength=12)
EMBER = mat("ember", (1, 0.5, 0.2), 0.3, emit=(1.0, 0.55, 0.2), strength=25)

def emis(name, color, strength):
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; nt.nodes.clear()
    o = nt.nodes.new("ShaderNodeOutputMaterial"); e = nt.nodes.new("ShaderNodeEmission")
    e.inputs[0].default_value = (*color, 1); e.inputs[1].default_value = strength
    nt.links.new(e.outputs[0], o.inputs[0]); return m

# ---------- 블록 ----------
def box(name, size, loc, material, parent=None, bevel=0.12, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object; o.name = name
    o.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0:
        m = o.modifiers.new("bev", "BEVEL"); m.width = bevel; m.segments = 4; m.limit_method = "NONE"
    o.data.materials.append(material)
    for p in o.data.polygons:
        p.use_smooth = True
    if parent:
        bpy.context.view_layer.update()
        o.parent = parent
        o.matrix_parent_inverse = parent.matrix_world.inverted()
    return o
def pivot(name, loc, parent=None):
    e = bpy.data.objects.new(name, None); sc.collection.objects.link(e)
    e.location = loc
    if parent:
        bpy.context.view_layer.update()
        e.parent = parent
        e.matrix_parent_inverse = parent.matrix_world.inverted()
    return e

# ---------- 캐릭터 (R15 비율, 바라보는 쪽 -Y) ----------
root = pivot("root", (0, 0, 3.2))
low = box("LowerTorso", (2, 1, 0.5), (0, 0, 3.2), PANTS, root)
sash = box("Sash", (2.1, 1.1, 0.42), (0, 0, 3.35), RED, root, bevel=0.08)
knot = box("Knot", (0.45, 0.25, 0.4), (0.55, -0.6, 3.35), RED, root, bevel=0.08)
waist = pivot("waist", (0, 0, 3.45), root)
up = box("UpperTorso", (2, 1, 1.7), (0, 0, 4.3), GI, waist)
# 옷깃 (V자 붉은 테)
for sx in (-1, 1):
    box("Lapel", (0.16, 0.08, 1.3), (sx * 0.28, -0.52, 4.45), RED, waist, bevel=0.03, rot=(0, R(sx * 22), 0))
box("Chest", (0.55, 0.06, 0.5), (0, -0.52, 4.85), SKIN, waist, bevel=0.03)
neck = pivot("neck", (0, 0, 5.15), waist)
head = box("Head", (1.25, 1.2, 1.2), (0, 0, 5.75), SKIN, neck, bevel=0.32)
# 얼굴: 눈 (흰자 + 눈동자), 찡그린 눈썹, 입
for sx in (-1, 1):
    box("EyeW", (0.26, 0.04, 0.16), (sx * 0.26, -0.61, 5.82), mat("eyew", (0.95, 0.95, 0.95), 0.3), neck, bevel=0.03)
    box("Pupil", (0.12, 0.05, 0.14), (sx * 0.22, -0.63, 5.81), EYE, neck, bevel=0.02)
    box("Brow", (0.34, 0.06, 0.08), (sx * 0.27, -0.62, 6.0), HAIR, neck, bevel=0.02, rot=(0, R(-sx * 18), 0))
box("Mouth", (0.3, 0.04, 0.05), (0, -0.61, 5.48), EYE, neck, bevel=0.015)
# 머리: 검은 머리 덩어리 + 상투
box("Hair", (1.32, 1.25, 0.42), (0, 0.05, 6.22), HAIR, neck, bevel=0.15)
box("HairBack", (1.32, 0.4, 0.9), (0, 0.48, 5.9), HAIR, neck, bevel=0.15)
box("Bun", (0.5, 0.5, 0.42), (0, 0.15, 6.55), HAIR, neck, bevel=0.18)
# 머리띠와 휘날리는 꼬리 (조각을 이어서)
box("Band", (1.34, 1.28, 0.16), (0, 0, 6.08), RED, neck, bevel=0.05)
def tail(start, n, step, droop, sway, width, parent, phase):
    # 매끈하게 휘는 띠: 곡선에 납작한 두께를 주고, 끝으로 갈수록 가늘게
    cu = bpy.data.curves.new("tailc", "CURVE"); cu.dimensions = "3D"
    sp = cu.splines.new("NURBS"); sp.points.add(n - 1)
    x, y, z = start
    for i in range(n):
        t = i / (n - 1)
        px = x + sway * math.sin(t * 5 + phase) * t
        py = y + step * n * t
        pz = z - droop * step * n * t * t + 0.25 * math.sin(t * 6 + phase) * t
        sp.points[i].co = (px, py, pz, 1)
        sp.points[i].radius = max(0.15, 1 - t * 0.85)
        sp.points[i].tilt = math.sin(t * 4 + phase) * 0.8
    sp.order_u = 4; sp.use_endpoint_u = True
    cu.extrude = width / 2
    cu.bevel_depth = 0.02
    cu.resolution_u = 24
    o = bpy.data.objects.new("Tail", cu); sc.collection.objects.link(o)
    o.data.materials.append(RED)
    bpy.context.view_layer.update()
    o.parent = parent
    o.matrix_parent_inverse = parent.matrix_world.inverted()
    return o
tail((0.2, 0.6, 6.08), 8, 0.36, 0.2, 0.35, 0.22, neck, 0.0)
tail((-0.15, 0.6, 6.02), 8, 0.32, 0.4, 0.3, 0.18, neck, 1.7)
# 허리띠 꼬리 (뒤로 날린다)
tail((0.6, 0.55, 3.3), 8, 0.4, 0.22, 0.45, 0.3, root, 0.7)
tail((0.35, 0.55, 3.22), 8, 0.36, 0.42, 0.4, 0.24, root, 2.3)

def arm(side):
    sx = 1 if side == "R" else -1
    sh = pivot("sh" + side, (sx * 1.5, 0, 4.85), waist)
    box("UpperArm" + side, (1, 1, 1.25), (sx * 1.5, 0, 4.4), GI, sh, bevel=0.14)
    box("Cuff" + side, (1.06, 1.06, 0.22), (sx * 1.5, 0, 3.86), RED, sh, bevel=0.06)
    el = pivot("el" + side, (sx * 1.5, 0, 3.75), sh)
    box("LowerArm" + side, (0.9, 0.9, 1.1), (sx * 1.5, 0, 3.25), SKIN, el, bevel=0.14)
    box("Wrap" + side, (0.94, 0.94, 0.2), (sx * 1.5, 0, 2.85), mat("wrap", (0.85, 0.82, 0.75), 0.8), el, bevel=0.05)
    wr = pivot("wr" + side, (sx * 1.5, 0, 2.72), el)
    box("Fist" + side, (0.98, 0.95, 0.8), (sx * 1.5, 0, 2.38), SKIN, wr, bevel=0.2)
    return sh, el, wr
def leg(side):
    sx = 1 if side == "R" else -1
    hp = pivot("hip" + side, (sx * 0.5, 0, 2.95), root)
    box("UpperLeg" + side, (1, 1.05, 1.35), (sx * 0.5, 0, 2.3), PANTS, hp, bevel=0.14)
    kn = pivot("kn" + side, (sx * 0.5, 0, 1.62), hp)
    box("LowerLeg" + side, (0.95, 1, 1.25), (sx * 0.5, 0, 1.0), PANTS, kn, bevel=0.14)
    box("Wrap" + side, (1.0, 1.04, 0.28), (sx * 0.5, 0, 0.5), mat("wrapL", (0.85, 0.82, 0.75), 0.8), kn, bevel=0.06)
    an = pivot("an" + side, (sx * 0.5, 0, 0.38), kn)
    box("Foot" + side, (0.95, 1.4, 0.36), (sx * 0.5, -0.2, 0.18), mat("shoe", (0.02, 0.02, 0.02), 0.5), an, bevel=0.12)
    return hp, kn, an
shR, elR, wrR = arm("R")
shL, elL, wrL = arm("L")
hpR, knR, anR = leg("R")
hpL, knL, anL = leg("L")

# ---------- 자세: 오른 주먹을 앞 (-Y)으로 내지른다, 왼 주먹은 허리, 왼발 앞 활 자세 ----------
root.rotation_euler = Euler((0, 0, R(-62)))
waist.rotation_euler = Euler((R(-10), 0, R(-22)))
neck.rotation_euler = Euler((R(4), 0, R(26)))
shL.rotation_euler = Euler((R(-86), R(4), R(-6)))
elL.rotation_euler = Euler((R(-3), 0, 0))
shR.rotation_euler = Euler((R(36), 0, R(14)))
elR.rotation_euler = Euler((R(-108), 0, 0))
wrR.rotation_euler = Euler((R(-10), 0, 0))
hpL.rotation_euler = Euler((R(-58), 0, R(-8)))
knL.rotation_euler = Euler((R(70), 0, 0))
anL.rotation_euler = Euler((R(-10), 0, 0))
hpR.rotation_euler = Euler((R(34), 0, R(10)))
knR.rotation_euler = Euler((R(10), 0, 0))
anR.rotation_euler = Euler((R(-40), 0, 0))
bpy.context.view_layer.update()
# 발을 땅 (z=0)에 맞춘다
minz = min((o.matrix_world @ Vector(c)).z for o in bpy.data.objects if o.type == "MESH" and o.name.startswith("Foot") for c in o.bound_box)
root.location.z -= minz
bpy.context.view_layer.update()

# ---------- 주먹 끝의 기운 ----------
fist = bpy.data.objects["FistL"]
fp = fist.matrix_world.translation.copy()
d = (fist.matrix_world.to_quaternion() @ Vector((0, 0, -1))).normalized()   # 팔 방향 (주먹이 향하는 쪽)
core_loc = fp + d * 0.7
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.42, location=core_loc)
c = bpy.context.active_object; c.data.materials.append(emis("core", (0.75, 0.95, 1.0), 60))
# 충격파 고리 (팔 방향에 수직)
rot_q = Vector((0, 0, 1)).rotation_difference(d)
for i, (dist, rad, th, st) in enumerate([(1.0, 0.75, 0.045, 30), (1.9, 1.15, 0.035, 18), (3.0, 1.6, 0.028, 10), (4.3, 2.1, 0.022, 6)]):
    bpy.ops.mesh.primitive_torus_add(major_radius=rad, minor_radius=th, location=fp + d * dist)
    t = bpy.context.active_object
    t.rotation_mode = "QUATERNION"; t.rotation_quaternion = rot_q
    t.data.materials.append(emis("ring%d" % i, (0.4, 0.85, 1.0), st))
# 빛줄기 (팔 방향으로 부채꼴)
for i in range(46):
    ang = random.uniform(0, math.tau); spread = random.uniform(0.05, 0.6)
    perp = d.orthogonal().normalized()
    perp.rotate(Euler((0, 0, 0)))
    from mathutils import Quaternion
    q = Quaternion(d, ang)
    side = q @ perp
    dir2 = (d + side * spread).normalized()
    L = random.uniform(1.2, 4.5)
    start = core_loc + dir2 * random.uniform(0.3, 1.2)
    bpy.ops.mesh.primitive_cylinder_add(radius=random.uniform(0.008, 0.022), depth=L, location=start + dir2 * L / 2)
    s = bpy.context.active_object
    s.rotation_mode = "QUATERNION"; s.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(dir2)
    s.data.materials.append(emis("streak%d" % i, (0.6, 0.9, 1.0), random.uniform(4, 10)))
# 불티
for i in range(160):
    p = core_loc + Vector((random.gauss(0, 1.4), random.gauss(0, 1.4), random.gauss(0, 1.1))) + d * random.uniform(0, 3.5)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=random.uniform(0.02, 0.07), location=p)
    e = bpy.context.active_object
    e.data.materials.append(emis("emb%d" % i, (0.45, 0.85, 1.0) if random.random() < 0.6 else (1.0, 0.6, 0.25), random.uniform(15, 40)))
# 기운 빛
bpy.ops.object.light_add(type="POINT", location=core_loc)
L = bpy.context.active_object; L.data.energy = 7000; L.data.color = (0.45, 0.85, 1.0); L.data.shadow_soft_size = 0.8

# ---------- 땅: 바위 단 ----------
for i in range(9):
    sx, sy = random.uniform(2.5, 5.5), random.uniform(2.5, 5)
    box("Rock", (sx, sy, random.uniform(1.0, 2.2)), (random.uniform(-4, 5), random.uniform(-2, 5), -random.uniform(0.5, 0.95)), ROCK, None, bevel=0.35, rot=(R(random.uniform(-6, 6)), R(random.uniform(-6, 6)), R(random.uniform(0, 90))))
# 흩어진 작은 돌
for i in range(25):
    s = random.uniform(0.15, 0.5)
    box("Pebble", (s, s, s * 0.7), (random.uniform(-5, 6), random.uniform(-4, 4), random.uniform(0.05, 0.6) if random.random() < 0.3 else 0.05), ROCK, None, bevel=0.05, rot=(R(random.uniform(0, 90)), R(random.uniform(0, 90)), R(random.uniform(0, 90))))

# ---------- 배경: 하늘 · 달 · 산 ----------
sky = bpy.data.materials.new("sky"); sky.use_nodes = True
nt = sky.node_tree; nt.nodes.clear()
o = nt.nodes.new("ShaderNodeOutputMaterial"); em = nt.nodes.new("ShaderNodeEmission")
tc = nt.nodes.new("ShaderNodeTexCoord"); sep = nt.nodes.new("ShaderNodeSeparateXYZ"); ramp = nt.nodes.new("ShaderNodeValToRGB")
nt.links.new(tc.outputs["Generated"], sep.inputs[0]); nt.links.new(sep.outputs["Z"], ramp.inputs[0])
ramp.color_ramp.elements[0].position = 0.0; ramp.color_ramp.elements[0].color = (0.55, 0.16, 0.08, 1)
ramp.color_ramp.elements[1].position = 1.0; ramp.color_ramp.elements[1].color = (0.004, 0.006, 0.02, 1)
mid = ramp.color_ramp.elements.new(0.35); mid.color = (0.09, 0.03, 0.08, 1)
mid2 = ramp.color_ramp.elements.new(0.6); mid2.color = (0.012, 0.016, 0.05, 1)
nt.links.new(ramp.outputs[0], em.inputs[0]); em.inputs[1].default_value = 1.0
nt.links.new(em.outputs[0], o.inputs[0])
bpy.ops.mesh.primitive_plane_add(size=1, location=(10, 70, 20), rotation=(R(90), 0, R(-28)))
p = bpy.context.active_object; p.scale = (260, 120, 1); p.data.materials.append(sky)
# 달
bpy.ops.mesh.primitive_circle_add(vertices=96, radius=9, fill_type="NGON", location=(14, 60, 22), rotation=(R(90), 0, R(-28)))
m = bpy.context.active_object; m.data.materials.append(emis("moon", (1.0, 0.84, 0.62), 2.2))
# 별
for i in range(260):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=random.uniform(0.05, 0.16), location=(random.uniform(-90, 110), 66, random.uniform(14, 70)))
    st = bpy.context.active_object; st.data.materials.append(emis("star", (0.85, 0.9, 1.0), random.uniform(2, 8)))
# 산 (멀수록 옅은 안개 빛)
def mountain(x, y, h, r, col):
    bpy.ops.mesh.primitive_cone_add(vertices=7, radius1=r, depth=h, location=(x, y, h / 2 - 2), rotation=(0, 0, R(random.uniform(0, 60))))
    mo = bpy.context.active_object; mo.data.materials.append(emis("mt", col, 1.0))
for i in range(14):
    mountain(random.uniform(-70, 80), random.uniform(48, 56), random.uniform(16, 30), random.uniform(10, 18), (0.12, 0.05, 0.1))
for i in range(12):
    mountain(random.uniform(-60, 70), random.uniform(32, 40), random.uniform(10, 20), random.uniform(7, 12), (0.05, 0.02, 0.05))
for i in range(10):
    mountain(random.uniform(-45, 55), random.uniform(18, 24), random.uniform(6, 12), random.uniform(5, 9), (0.015, 0.01, 0.02))

# 안개 띠 (아래는 짙고 위로 옅어진다)
def mist(y, z, height, color, strength, alpha):
    m = bpy.data.materials.new("mist"); m.use_nodes = True
    nt = m.node_tree; nt.nodes.clear()
    o = nt.nodes.new("ShaderNodeOutputMaterial"); mix = nt.nodes.new("ShaderNodeMixShader")
    tr = nt.nodes.new("ShaderNodeBsdfTransparent"); em = nt.nodes.new("ShaderNodeEmission")
    em.inputs[0].default_value = (*color, 1); em.inputs[1].default_value = strength
    tc = nt.nodes.new("ShaderNodeTexCoord"); sep = nt.nodes.new("ShaderNodeSeparateXYZ"); ramp = nt.nodes.new("ShaderNodeValToRGB")
    nt.links.new(tc.outputs["Generated"], sep.inputs[0]); nt.links.new(sep.outputs["Y"], ramp.inputs[0])
    ramp.color_ramp.elements[0].color = (alpha, alpha, alpha, 1); ramp.color_ramp.elements[1].color = (0, 0, 0, 1)
    nt.links.new(ramp.outputs[0], mix.inputs[0]); nt.links.new(tr.outputs[0], mix.inputs[1]); nt.links.new(em.outputs[0], mix.inputs[2])
    nt.links.new(mix.outputs[0], o.inputs[0])
    bpy.ops.mesh.primitive_plane_add(size=1, location=(0, y, z + height / 2), rotation=(R(90), 0, R(-10)))
    p = bpy.context.active_object; p.scale = (220, height, 1); p.data.materials.append(m)
mist(44, -2, 14, (0.5, 0.22, 0.28), 0.8, 0.75)
mist(28, -2, 10, (0.35, 0.14, 0.22), 0.6, 0.7)
mist(14, -2, 6, (0.18, 0.07, 0.14), 0.5, 0.6)

# ---------- 조명 ----------
def area(loc, rot, energy, color, size):
    bpy.ops.object.light_add(type="AREA", location=loc, rotation=rot)
    l = bpy.context.active_object; l.data.energy = energy; l.data.color = color; l.data.size = size; return l
key = area((5, -8, 9), (R(50), 0, R(35)), 700, (1.0, 0.8, 0.62), 5)          # 앞 왼쪽 위 따뜻한 빛
rim1 = area((7, 6, 7), (R(-60), 0, R(130)), 9000, (1.0, 0.5, 0.22), 3)          # 뒤 오른쪽 주황 테두리
rim2 = area((-6, 7, 8), (R(-55), 0, R(-140)), 5000, (0.35, 0.65, 1.0), 3)         # 뒤 왼쪽 푸른 테두리
fill = area((3, -10, 2), (R(80), 0, R(15)), 120, (0.5, 0.55, 1.0), 8)
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.01, 0.012, 0.03, 1)
w.node_tree.nodes["Background"].inputs[1].default_value = 1.0

# ---------- 카메라 ----------
cam_data = bpy.data.cameras.new("cam"); cam = bpy.data.objects.new("cam", cam_data); sc.collection.objects.link(cam); sc.camera = cam
cam.location = (-1.6, -12.8, 1.3)
target = Vector((-2.3, 0, 3.6))
cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
cam_data.lens = 30
cam_data.dof.use_dof = True
cam_data.dof.focus_distance = (Vector((0, 0, 5.5)) - cam.location).length
cam_data.dof.aperture_fstop = 5.6

# ---------- 렌더 ----------
sc.render.engine = "CYCLES"
sc.cycles.device = "CPU"
sc.cycles.samples = SAMPLES
sc.cycles.use_adaptive_sampling = True
sc.cycles.use_denoising = True
sc.render.resolution_x = 1920; sc.render.resolution_y = 1080; sc.render.resolution_percentage = PCT
sc.render.image_settings.file_format = "PNG"
sc.render.filepath = OUT
try:
    sc.view_settings.view_transform = "AgX"
    sc.view_settings.look = "AgX - Punchy"
except Exception:
    sc.view_settings.view_transform = "Filmic"
sc.render.threads_mode = "AUTO"
bpy.ops.render.render(write_still=True)
print("RENDERED", OUT)
