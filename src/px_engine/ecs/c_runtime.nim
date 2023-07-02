import px_engine/m_pxd
import definition/types


pxd.ecs.genComponent(ComponentObject)
pxd.ecs.genComponent(ComponentCamera)
pxd.ecs.genComponent(ComponentInteraction)
pxd.ecs.genComponent(ComponentTransform)


using
  self: ptr CTransform | var CTransform


proc getPositionMatrix*(self;): Matrix =
  result = matrixIdentity(); result.setPosition(self.position)


proc getRotationMatrix*(self;): Matrix =
  result = self.qrotation.mat4x4