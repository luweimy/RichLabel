富文本标签
---
RichLabel基于Cocos2dx+Lua v3.x  
扩展标签极其简单，只需添加一个遵守规则的标签插件即可，无需改动已存在代码！！   
如果不喜欢当前的富文本语法，也可以自己写标签解析器，只要转为指定的中间格式交给RichLabel处理即可！！   
[详细介绍](http://www.cnblogs.com/luweimy/p/4114449.html) | [中间格式参考标签解析器](https://github.com/Luweimy/labelparser)       
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
![Alt text](https://raw.githubusercontent.com/Luweimy/RichLabel/master/snapshot/4.png)
