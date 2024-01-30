import px_engine_pxd


type
  Transform* = object
    qrotation*: Quat
    rotation*:  Vec3
    position*:  Vec3
    scale*:     Vec3 = vec(1,1,1)

pxd.ecs.genComponent(Transform)


using
  self: ptr Transform | var Transform


proc getPositionMatrix*(self;): Matrix =
  result = matrixIdentity(); result.setPosition(self.position)


proc getRotationMatrix*(self;): Matrix =
  result = self.qrotation.mat4x4


proc position*(self: EntityObj): var Vec3 = self.transform.position
proc `position=`*(self: EntityObj, arg: Vec3) = self.transform.position = arg


proc rotation*(self: EntityObj): var Vec3 = self.transform.rotation
proc `rotation=`*(self: EntityObj, arg: Vec3) = self.transform.rotation = arg
