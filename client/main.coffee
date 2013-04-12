class RenderContext
  constructor : (@rt,@fov=75) ->
    @aspectRatio = @rt.width() / @rt.height()

  init : ->
    @scene = new THREE.Scene()
    @camera = new THREE.PerspectiveCamera(@fov,@aspectRatio,0.1,1000)
    @renderer = new THREE.WebGLRenderer()
#    @renderer.setClearColor(0x000000)
    @renderer.setSize(@rt.width(),@rt.height())
    @rt.append(@renderer.domElement)

  render : ->
    requestAnimationFrame =>
      @render()

    @renderer.render(@scene,@camera)

  demo : ->
    @camera.position.z = 5
    @camera.position.y = 1
    @camera.rotation.x = -0.1

class BoxContext extends RenderContext
  constructor: (args...) ->
    super args...

    @boxes = {}
    @tweens = []

  moveTo : (thing,x) ->
    @tweens.push(thing) unless thing in @tweens
    thing.target = x

  updateTween : (thing) ->
    diff = thing.target - thing.position.x
    if -0.1 < diff < 0.1
      thing.position.x = thing.target
      false
    else
      thing.position.x += diff * 0.1
      true


  render : ->
    for t in @tweens
      do (t) =>
        @updateTween t

    super

  addBackground : ->
    geom = new THREE.PlaneGeometry(300,300)
    material = new THREE.MeshPhongMaterial( color : 0x007f00 )
    plane = new THREE.Mesh( geom, material )
    plane.rotation.x = -Math.PI / 2
    plane.position.y = -1
    plane.castShadow = true
    plane.receiveShadow = true
    @scene.add plane

  init : ->
    super()

    @renderer.shadowMapEnabled = true
    @renderer.shadowMapSoft = true

    light = new THREE.DirectionalLight(0xffffff,1.5)
    light.position.set(0,10,10)
    light.castShadow = true
    light.shadowCameraRight = 5
    light.shadowCameraLeft = -5
    light.shadowCameraTop = 5
    light.shadowCameraBottom = -5
    light.shadowDarkness = 0.5
    light.shadowCameraNear = 0.01
    @scene.add light

    @addBackground()

    Boxes.find().observeChanges
      added:(id,box) =>
        geometry = new THREE.CubeGeometry(1,1,1)
        material = new THREE.MeshPhongMaterial( color : box.color ? 0x00ff00, ambient : 0xffffff, specular : 0xffffff, shininess : 30.0 )
        cube = new THREE.Mesh( geometry, material )
        cube.castShadow = true
        @boxes[id] = cube
        cube.position.x = box.x ? 0

        @scene.add(cube)

      changed:(id,box) =>
        cube = @boxes[id]
        return unless cube
        console.log cube

        @moveTo(cube,box.x ? 0)

      removed:(id) =>
        cube = @boxes[id]
        @scene.remove(cube) if cube


Template.three.rendered = ->
  renderTarget = $(@find('.renderTarget'))
  context = new BoxContext(renderTarget)
  context.init()
  context.demo()
  context.render()
  renderTarget.data('context',context)

Template.console.helpers
  boxes : ->
    Boxes.find()

Template.console.events
  'click .create' : ->
    Boxes.insert
      color:Math.floor(Math.random() * 0xffffff)
      x:Math.floor(Math.random() * 5) - 2
  'click .inc' : ->
    Meteor.call 'update', @_id, {$inc:{x:0.5}}
  'click .dec' : ->
    Meteor.call 'update', @_id,{$inc:{x:-0.5}}
  'click .delete' : ->
    Boxes.remove @_id