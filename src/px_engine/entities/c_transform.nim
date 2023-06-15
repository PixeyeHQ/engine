import px_engine/pxd/api
import px_engine/pxd/m_ecs
import px_engine/pxd/m_math
import px_engine/pxd/data/m_obj_context
import components_d


pxd.ecs.genComponent(CTransform)


using
  self: ptr CTransform | var CTransform


proc getPositionMatrix*(self;): Matrix =
  result = matrixIdentity(); result.setPosition(self.position)


proc getRotationMatrix*(self;): Matrix =
  result = self.rotation.mat4x4