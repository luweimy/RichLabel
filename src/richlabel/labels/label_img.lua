
--
-- <img/> 标签解析
--

return function (self, params, default)
	if not params.src then return 
	end
	-- 创建精灵，自动在帧缓存中查找，屏蔽了图集中加载和直接加载的区别
	local sprite = self:getSprite(params.src)
	if not sprite then
		self:printf("<img> - create sprite failde")
		return
	end
	if params.scale then
		sprite:setScale(params.scale)
	end
	if params.rotate then
		sprite:setRotation(params.rotate)
	end
	if params.visible ~= nil then
		sprite:setVisible(params.visible)
	end
	return {sprite}
end
