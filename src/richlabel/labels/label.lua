
---
--- 文件名规则：label_[标签名]
---

--
-- 示例
-- 说明：此函数由RichLabel调用, 请不要改变标签文件的位置，此文件仅用于说明，无实际意义
-- 作用：解析标签
-- 参数：self - RichLabel对象本身，可以调用对象的方法或者使用对象的属性
--		params - 其中包含了标签对应的内容及属性
--		default - 默认的属性包含了，fontName, fontColor, fontSize
-- 返回值：返回值是一个table；其中应该保存着根据传入的属性和内容创建的一些可显示的精灵(区分顺序)
--
return function (self, params, default)
	return {} -- 必须返回表，表中包含要显示的精灵
end