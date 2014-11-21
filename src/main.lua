require "Cocos2d"
require "Cocos2dConstants"

-- cclog
cclog = function(...)
    print(string.format(...))
end

-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    cclog("----------------------------------------")
    cclog("LUA ERROR: " .. tostring(msg) .. "\n")
    cclog(debug.traceback())
    cclog("----------------------------------------")
    return msg
end

local function main()
    collectgarbage("collect")
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)
    local director = cc.Director:getInstance()
    local glview = director:getOpenGLView()
    if nil == glview then
        glview = cc.GLView:createWithRect("HelloLua", cc.rect(0,0,900,640))
        director:setOpenGLView(glview)
    end
    glview:setDesignResolutionSize(960, 640, cc.ResolutionPolicy.NO_BORDER)
    director:setDisplayStats(true)
    director:setAnimationInterval(1.0 / 60)
	cc.FileUtils:getInstance():addSearchPath("src")
	cc.FileUtils:getInstance():addSearchPath("res")

    -- run
    local sceneGame = cc.Scene:create()
    local layer = cc.LayerColor:create(cc.c4b(25, 255, 255, 100))
    sceneGame:addChild(layer)

	if cc.Director:getInstance():getRunningScene() then
		cc.Director:getInstance():replaceScene(sceneGame)
	else
		cc.Director:getInstance():runWithScene(sceneGame)
	end

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
    
end


local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    error(msg)
end
