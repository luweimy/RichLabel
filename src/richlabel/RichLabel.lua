
--[[

	富文本标签
	---
	RichLabel基于Cocos2dx+Lua v3.x  
	扩展标签极其简单，只需添加一个遵守规则的标签插件即可，无需改动已存在代码！！！  

	**特性：**
	    
	*   支持标签定义富文本展示格式
	*   支持图片(缩放，旋转，是否可见)
	*   支持文本属性(字体，大小，颜色，阴影，描边，发光)
	*   支持标签嵌套修饰文本，但是内部标签不会继承嵌套标签的属性
	*   支持标签扩展(labels文件夹中可添加标签支持)
	*   支持渐入动画，动画逐字回调
	*   支持设置最大宽度，自动换行布局
	*   支持手动换行，使用'\n'换行
	*   支持设置行间距，字符间距
	*   支持添加debug绘制文字范围和锚点
	*   支持获得文字的精灵节点
	*   支持设置标签锚点，透明度，颜色...
	*   支持遍历字符，行等
	*   支持获得任意行的行高
	        
	**标签支持：**  

	`<div>` - 文本标签，用于修饰文件，非自闭和标签，必须配对出现    
	属性： fontname, fontsize, fontcolor, outline, glow, shadow   
	注意：

	* *outline, glow 不能同时生效*
	* *使用glow会自动修改ttfConfig.distanceFieldEnabled=true，否则没有效果*
	* *使用描边效果后，ttfConfig.distanceFieldEnabled=false，否则没有效果*

	格式：

	+ fontname='pathto/msyh.ttf'
	+ fontsize=30
	+ fontcolor=#ff0099
	+ shadow=10,10,10,#ff0099 - (offset_x, offset_y, blur_radius, shadow_color)
	+ outline=1,#ff0099       - (outline_size, outline_color)
	+ glow=#ff0099            - (glow_color) 
	    
	`<img />` - 图像标签，用于添加图片，自闭合标签，必须自闭合<img />  
	属性：src, scale, rotate, visible  
	注意：*图片会首先在帧缓存中加载，否则直接在磁盘上加载*  
	格式：  
	+ src="pathto/avator.png"
	+ scale=0.5
	+ rotate=90
	+ visible=false

	**注意：**  

	+ 内部使用Cocos2dx的TTF标签限制，要设置默认的正确的字体，否则无法显示  
	+ 如果要设置中文，必须使用含有中文字体的TTF

	**示例：**
	```
	------------------------------------------------------
	------------  TEST RICH-LABEL
	------------------------------------------------------ 

	local test_text = {
	    "<div fontcolor=#ff0000>hello</div><div fontcolor=#00ff00>hello</div><div fontsize=12>你</div><div fontSize=26 fontcolor=#ff00bb>好</div>ok",
	    "<div outline=1,#ff0000 >hello</div>",
	    "<div glow=#ff0000 >hello</div>",
	    "<div shadow=2,-2,0.5,#ff0000 >hello</div>",
	    "hello<img src='res/test.png' scale=0.5 rotate=90 visible=true />world",
	}
	for i=1, #test_text do
	    local RichLabel = require("richlabel.RichLabel")
	    local label = RichLabel.new {
	        fontName = "res/msyh.ttf",
	        fontSize = 20,
	        fontColor = cc.c3b(255, 255, 255),
	        maxWidth=200,
	        lineSpace=0,
	        charSpace=0,
	    }
	    label:setString(test_text[i])
	    label:setPosition(cc.p(380,500-i*30))
	    label:playAnimation()
	    sceneGame:addChild(label)

	    label:debugDraw()
	end 
	
	```

	**基本接口：**

	* setString - 设置要显示的富文本   
	* getSize - 获得Label的大小  

	*当前版本：v1.0.1*  
	v1.0.0 - 支持`<div>`标签，仅支持基本属性(fontname, fontsize, fontcolor)  
	v1.0.1 - 增加`<div>`标签属性(shadow, outline, glow)的支持，增加`<img>`标签的支持(labelparser增加解析自闭和标签支持) 

]]--

local CURRENT_MODULE = ...
local dotindex = string.find(CURRENT_MODULE, "%.%w+$")
local currentpath = string.sub(CURRENT_MODULE, 1, dotindex-1)
local parserpath = string.format("%s.labelparser", currentpath, label)
local labelparser = require(parserpath)

local RichLabel = class("RichLabel", function()
    return cc.Node:create()
end)	

-- 文本的默认属性
RichLabel._default = nil

-- 属性
RichLabel._maxWidth = nil
RichLabel._currentWidth = nil
RichLabel._currentHeight = nil

-- 容器
RichLabel._containerNode = nil
RichLabel._allnodelist = nil
RichLabel._currentText = nil
RichLabel._parsedtable = nil
RichLabel._alllines = nil

RichLabel._animationCounter = nil

-- 共享解析器列表
local shared_parserlist = {}

-- 播放动画默认速度
local ANIM_WORD_PER_SEC = 15
local DEBUG_MARK = "richlabel.debug.drawnodes"

--[[--
-   ctor: 构造函数
	@param: 
		params - 可选参数列表
		params.fontName - 默认的字体名称
		params.fontSize - 默认字体大小
		params.fontColor - 默认字体颜色
		params.maxWidth - Label最大宽度
		params.lineSpace - 行间距
		params.charSpace - 字符间距
]]
function RichLabel:ctor(params)
	params = params or {}
	local fontName 	= params.fontName or "Arial"
	local fontSize 	= params.fontSize or 30
	local fontColor = params.fontColor or cc.c3b(255, 255, 255)
	local maxWidth 	= params.maxWidth or 0
	local linespace = params.lineSpace or 0 -- 行间距
	local charspace = params.charSpace or 0 -- 字符距

	-- 精灵容器
	local containerNode = cc.Node:create()
	self:addChild(containerNode)

	self._maxWidth = maxWidth
	self._containerNode = containerNode
	self._animationCounter = 0

	self._default = {}
	self._default.fontName = fontName
	self._default.fontSize = fontSize
	self._default.fontColor = fontColor
	self._default.lineSpace = linespace
	self._default.charSpace = charspace

	-- 标签内容向右向下增长
	self:setAnchorPoint(cc.p(0, 1))
	-- 允许setColor和setOpacity生效
    self:setCascadeOpacityEnabled(true)
    self:setCascadeColorEnabled(true)
    containerNode:setCascadeOpacityEnabled(true)
    containerNode:setCascadeColorEnabled(true)
end

--[[--
-   setString: 设置富文本字符串
	@param: text - 必须遵守规范的字符串才能正确解析	
			<div fontcolor=#ffccbb>hello</div>
]]
function RichLabel:setString(text)
	text = text or ""
	-- 字符串相同的直接返回
	if self._currentText == text then return
	end

	-- 若之前存在字符串，要先清空
	if self._currentText then
		self._allnodelist = nil
		self._parsedtable = nil
		self._alllines = nil
		self._containerNode:removeAllChildren()
	end
	self._currentText = text

	-- 解析字符串，解析成为一种内定格式(表结构)，便于创建精灵使用
	local parsedtable = labelparser.parse(text)
	self._parsedtable = parsedtable
	if parsedtable == nil then
		return self:printf("parser text error")
	end

	-- 将解析的字符串转化为精灵或者Label
	local containerNode = self._containerNode
	local allnodelist = self:charsToNodes_(parsedtable, containerNode)
	if not allnodelist then return
	end
	self._allnodelist = allnodelist

	-- 将精灵排版布局
	self:layout()
end 

function RichLabel:getString()
	return self._currentText
end

--[[--
-   setMaxWidth: 设置行最大宽度
	@param: maxwidth - 行的最大宽度
]]
function RichLabel:setMaxWidth(maxwidth)
	self._maxWidth = maxwidth
	self:layout()
end

function RichLabel:setAnchorPoint(anchor, anchor_y)
	if type(anchor) == "number" then
		anchor = cc.p(anchor, anchor_y)
	end
	local super_setAnchorPoint = getmetatable(self).setAnchorPoint
	super_setAnchorPoint(self, anchor)
	if self._currentText then self:layout()
	end
end

--[[--
-   getSize: 获得label的真实宽度
]]
function RichLabel:getSize()
	return cc.size(self._currentWidth, self._currentHeight)
end

--[[--
-   getLineHeight: 获得行高，取决于此行最高的元素
]]
function RichLabel:getLineHeight(rowindex)
	local line = self._alllines[rowindex]
	if not line then return 0
	end

	local maxheight = 0
	for _, node in pairs(line) do
		local box = node:getBoundingBox()
		if box.height > maxheight then
			maxheight = box.height
		end
	end
	return maxheight
end

--[[--
-   getElementWithIndex: 获得指定位置的元素
]]
function RichLabel:getElementWithIndex(index)
	return self._allnodelist[index]
end

--[[--
-   getElementWithRowCol: 获得指定位置的元素
]]
function RichLabel:getElementWithRowCol(rowindex, colindex)
	local line = self._alllines[rowindex]
	if line then return line[colindex]
	end
end

--[[--
-   getElementsWithLetter: 获取字母匹配的元素集合
]]
function RichLabel:getElementsWithLetter(letter)
	local nodelist = {}
	for _, node in pairs(self._allnodelist) do
		-- 若为Label则存在此方法
		if node.getString then
			local str = node:getString()
			-- 若存在换行符，则换行
			if str==letter then 
				table.insert(nodelist, node)
			end
		end
	end
	return nodelist
end

--[[--
-   getElementsWithGroup: 通过属性分组顺序获取一组的元素集合
]]
function RichLabel:getElementsWithGroup(groupIndex)
	return self._parsedtable[groupIndex].nodelist
end

--[[--
-   walkElements: 遍历元素
]]
function RichLabel:walkElements(callback)
	assert(callback)
	for index, node in pairs(self._allnodelist) do
		if callback(node, index) ~= nil then return 
		end
	end
end

--[[--
-   walkLineElements: 遍历并传入行号和列号
]]
function RichLabel:walkLineElements(callback)
	assert(callback)
	for rowindex, line in pairs(self._alllines) do
		for colindex, node in pairs(line) do
			if callback(node, rowindex, colindex) ~= nil then return 
			end
		end
	end
end

--
-- Animation
--

-- wordpersec: 每秒多少个字
-- callback: 每个字符出来前的回调
function RichLabel:playAnimation(wordpersec, callback)
	wordpersec = wordpersec or ANIM_WORD_PER_SEC
	if self:isAnimationPlaying() then return
	end
	local counter = 0
	local animationCreator = function(node, rowindex, colindex)
		counter = counter + 1
		return cc.Sequence:create(
				cc.DelayTime:create(counter/wordpersec),
				cc.CallFunc:create(function() 
					if callback then callback(node, rowindex, colindex) end 
				end),
				cc.FadeIn:create(0.2),
				cc.CallFunc:create(function()
					self._animationCounter = self._animationCounter - 1
				end)
			)
	end

	self:walkLineElements(function(node, rowindex, colindex)
		self._animationCounter = self._animationCounter + 1
		node:setOpacity(0)
		node:runAction(animationCreator(node, rowindex, colindex))
	end)
end

function RichLabel:isAnimationPlaying()
	return self._animationCounter > 0
end

function RichLabel:stopAnimation()
	self._animationCounter = 0 
	self:walkElements(function(node, index)
		node:setOpacity(255)
		node:stopAllActions()
	end)
end

-- 一般情况下无需手动调用，设置setMaxWidth, setString, setAnchorPoint时自动调用
-- 自动布局文本，若设置了最大宽度，将自动判断换行
-- 否则一句文本中得内容'\n'换行
function RichLabel:layout()
	local parsedtable = self._parsedtable
	local basepos = cc.p(0, 0)
	local col_idx = 0
	local row_idx = 0

	local containerNode = self._containerNode
	local allnodelist = self._allnodelist
	local linespace = self._default.lineSpace
	local charspace = self._default.charSpace
	local maxwidth = 0
	local maxheight = 0
	-- 处理所有的换行，返回换行后的数组
	local alllines = self:adjustLineBreak_(allnodelist, charspace)
	self._alllines = alllines
	for index, line in pairs(alllines) do
		local linewidth, lineheight = self:layoutLine_(basepos, line, 1, charspace)
		local offset = lineheight + linespace
		basepos.y = basepos.y - offset
		maxheight = maxheight + offset
		if maxwidth < linewidth then maxwidth = linewidth
		end
	end
	-- 减去最后多余的一个行间距
	maxheight = maxheight - linespace
	self._currentWidth = maxwidth
	self._currentHeight = maxheight

	-- 根据锚点重新定位
	local anchor = self:getAnchorPoint()
	local origin_x, origin_y = 0, maxheight
	local result_x = origin_x - anchor.x * maxwidth
	local result_y = origin_y - anchor.y * maxheight
	containerNode:setPosition(result_x, result_y)
end

--
-- Debug
--

--[[--
-   debugDraw: 绘制边框
	@param: level - 绘制级别，level<=2 只绘制整体label, level>2 绘制整体label和单个字符的范围
]]
function RichLabel:debugDraw(level)
	level = level or 2
    local containerNode = self._containerNode
	local debugdrawnodes1 = cc.utils:findChildren(containerNode, DEBUG_MARK)
	local debugdrawnodes2 = cc.utils:findChildren(self, DEBUG_MARK)
	function table_insertto(dest, src, begin)
	    if begin <= 0 then
	        begin = #dest + 1
	    end
	    local len = #src
	    for i = 0, len - 1 do
	        dest[i + begin] = src[i + 1]
	    end
	end
	table_insertto(debugdrawnodes1, debugdrawnodes2, #debugdrawnodes1+1)
	for k,v in pairs(debugdrawnodes1) do
		v:removeFromParent()
	end

	local labelSize = self:getSize()
	local anchorpoint = self:getAnchorPoint()
	local pos_x, pos_y = 0, 0
	local origin_x = pos_x-labelSize.width*anchorpoint.x
	local origin_y = pos_y-labelSize.height*anchorpoint.y
	local frame = cc.rect(origin_x, origin_y, labelSize.width, labelSize.height)
	-- 绘制整个label的边框
    self:drawrect(self, frame, 1):setName(DEBUG_MARK)
    -- 绘制label的锚点
    self:drawdot(self, cc.p(0, 0), 5):setName(DEBUG_MARK)

    -- 绘制每个单独的字符
    if level > 1 then
	    local allnodelist = self._allnodelist
	    local drawcolor = cc.c4f(0,0,1,0.5)
	    for _, node in pairs(allnodelist) do
	    	local box = node:getBoundingBox()
	    	local pos = cc.p(node:getPositionX(), node:getPositionY())
			self:drawrect(containerNode, box, 1, drawcolor):setName(DEBUG_MARK)
			self:drawdot(containerNode, pos, 2, drawcolor):setName(DEBUG_MARK)
	    end
	end
end

--
-- Internal Method
--

-- 加载标签解析器，在labels文件夹下查找
function RichLabel:loadLabelParser_(label)
	local labelparserlist = shared_parserlist
	local parser = labelparserlist[label]
	if parser then return parser
	end
	-- 组装解析器名
    local dotindex = string.find(CURRENT_MODULE, "%.%w+$")
    if not dotindex then return
    end
    local currentpath = string.sub(CURRENT_MODULE, 1, dotindex-1)
	local parserpath = string.format("%s.labels.label_%s", currentpath, label)
	-- 检测是否存在解析器
	local parser = require(parserpath)
	if parser then
		labelparserlist[label] = parser
	end
	return parser
end

-- 将文本解析后属性转化为节点(Label, Sprite, ...)
function RichLabel:charsToNodes_(parsedtable, containerNode)
	local default = self._default
	local allnodelist = {}
	for index, params in pairs(parsedtable) do
		local labelname = params.labelname
		-- 检测是否存在解析器
		local parser = self:loadLabelParser_(labelname)
		if not parser then
			return self:printf("not support label %s", labelname)
		end
		-- 调用解析器
		local nodelist = parser(self, params, default)
		params.nodelist = nodelist
		-- 连接两个表格
		for _, node in pairs(nodelist) do
			table.insert(allnodelist, node)
			-- 将label添加到容器上，才能显示出来
			containerNode:addChild(node)
		end
	end
	return allnodelist
end

-- 布局单行中的节点的位置，并返回行宽和行高
function RichLabel:layoutLine_(basepos, line, anchorpy, charspace)
	anchorpy = anchorpy or 0.5
	local pos_x = basepos.x
	local pos_y = basepos.y
	local lineheight = 0
	local linewidth = 0
	for index, node in pairs(line) do
		local box = node:getBoundingBox()
		-- 设置位置
		node:setPosition((pos_x + linewidth + box.width/2), pos_y)
		-- 累加行宽度
		linewidth = linewidth + box.width + charspace
		-- 查找最高的元素，为行高
		if lineheight < box.height then lineheight = box.height
		end
	end
	-- 重新根据排列位置排列
	-- anchorpy代表文本上下对齐的位置，0.5代表中间对齐，1代表上部对齐
	if anchorpy ~= 0.5 then
		local offset = (anchorpy-0.5)*lineheight
		for index, node in pairs(line) do
			local yy = node:getPositionY()
			node:setPositionY(yy-offset)
		end
	end
	return linewidth - charspace, lineheight
end

-- 自动适应换行处理方法，内部会根据最大宽度设置和'\n'自动换行
-- 若无最大宽度设置则不会自动换行
function RichLabel:adjustLineBreak_(allnodelist, charspace)
	-- 如果maxwidth等于0则不自动换行
	local maxwidth = self._maxWidth
	if maxwidth <= 0 then maxwidth = 999999999999
	end
	-- 存放每一行的nodes
	local alllines = {{}, {}, {}}
	-- 当前行的累加的宽度
	local addwidth = 0
	local rowindex = 1
	local colindex = 0
	for _, node in pairs(allnodelist) do
		colindex = colindex + 1
		-- 为了防止存在缩放后的node
		local box = node:getBoundingBox()
		addwidth = addwidth + box.width
		local totalwidth = addwidth + (colindex - 1) * charspace
		local breakline = false
		-- 若累加宽度大于最大宽度
		-- 则当前元素为下一行第一个元素
		if totalwidth > maxwidth then
			rowindex = rowindex + 1
			addwidth = box.width -- 累加数值置当前node宽度(为下一行第一个)
			colindex = 1
			breakline = true
		end

		-- 在当前行插入node
		local curline = alllines[rowindex] or {}
		alllines[rowindex] = curline
		table.insert(curline, node)

		-- 若还没有换行，并且换行符存在，则下一个node直接转为下一行
		if not breakline and self:adjustContentLinebreak_(node) then
			rowindex = rowindex + 1
			colindex = 0
			addwidth = 0 -- 累加数值置0
		end
	end
	return alllines
end

-- 判断是否为文本换行符
function RichLabel:adjustContentLinebreak_(node)
	-- 若为Label则有此方法
	if node.getString then
		local str = node:getString() 
		-- 查看是否为换行符
		if str == "\n" then
			return true
		end
	end
	return false
end

-- 
-- utils
--

-- 解析16进制颜色rgb值
function  RichLabel:convertColor(xstr)
	if not xstr then return 
	end
    local toTen = function (v)
        return tonumber("0x" .. v)
    end

    local b = string.sub(xstr, -2, -1) 
    local g = string.sub(xstr, -4, -3) 
    local r = string.sub(xstr, -6, -5)

    local red = toTen(r)
    local green = toTen(g)
    local blue = toTen(b)
    if red and green and blue then 
    	return cc.c4b(red, green, blue, 255)
    end
end

-- 拆分出单个字符
function RichLabel:stringToChars(str)
	-- 主要用了Unicode(UTF-8)编码的原理分隔字符串
	-- 简单来说就是每个字符的第一位定义了该字符占据了多少字节
	-- UTF-8的编码：它是一种变长的编码方式
	-- 对于单字节的符号，字节的第一位设为0，后面7位为这个符号的unicode码。因此对于英语字母，UTF-8编码和ASCII码是相同的。
	-- 对于n字节的符号（n>1），第一个字节的前n位都设为1，第n+1位设为0，后面字节的前两位一律设为10。
	-- 剩下的没有提及的二进制位，全部为这个符号的unicode码。
    local list = {}
    local len = string.len(str)
    local i = 1 
    while i <= len do
        local c = string.byte(str, i)
        local shift = 1
        if c > 0 and c <= 127 then
            shift = 1
        elseif (c >= 192 and c <= 223) then
            shift = 2
        elseif (c >= 224 and c <= 239) then
            shift = 3
        elseif (c >= 240 and c <= 247) then
            shift = 4
        end
        local char = string.sub(str, i, i+shift-1)
        i = i + shift
        table.insert(list, char)
    end
	return list, len
end

function RichLabel:split(str, delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(str, delimiter, pos, true) end do
        table.insert(arr, string.sub(str, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(str, pos))
    return arr
end

function RichLabel:printf(fmt, ...)
	return print(string.format("RichLabel# "..fmt, ...))
end

-- drawdot(self, cc.p(200, 200))
function RichLabel:drawdot(canvas, pos, radius, color4f)
    radius = radius or 2
    color4f = color4f or cc.c4f(1,0,0,0.5)
    local drawnode = cc.DrawNode:create()
    drawnode:drawDot(pos, radius, color4f)
    canvas:addChild(drawnode)
    return drawnode
end

-- drawrect(self, cc.rect(200, 200, 300, 200))
function RichLabel:drawrect(canvas, rect, borderwidth, color4f, isfill)
    local bordercolor = color4f or cc.c4f(1,0,0,0.5)
    local fillcolor = isfill and bordercolor or cc.c4f(0,0,0,0)
    borderwidth = borderwidth or 2

    local posvec = {
        cc.p(rect.x, rect.y),
        cc.p(rect.x, rect.y + rect.height),
        cc.p(rect.x + rect.width, rect.y + rect.height),
        cc.p(rect.x + rect.width, rect.y)
    }
    local drawnode = cc.DrawNode:create()
    drawnode:drawPolygon(posvec, 4, fillcolor, borderwidth, bordercolor)
    canvas:addChild(drawnode)
    return drawnode
end

-- 创建精灵，现在帧缓存中找，没有则直接加载
-- 屏蔽了使用图集和直接使用碎图创建精灵的不同
function RichLabel:getSprite(filename)
	local spriteFrameCache = cc.SpriteFrameCache:getInstance()
    local spriteFrame = spriteFrameCache:getSpriteFrameByName(filename)

	if spriteFrame then
		return cc.Sprite:createWithSpriteFrame(spriteFrame)
	end
	return cc.Sprite:create(filename)
end


return RichLabel
