---
--- Generated by MLN Team (http://www.immomo.com)
--- Created by MLN Team.
--- DateTime: 2019-09-05 12:05
---

local _class = {
    _name = "TabContainerView",
    _version = "1.0",
    _subViews = { },
    _subViewNames = { 'MMLuaKitGallery.HomePagerView',
                      'MMLuaKitGallery.DiscoverPagerView',
                      'MMLuaKitGallery.PlaceholderPagerView',
                      'MMLuaKitGallery.MessagePagerView',
                      'MMLuaKitGallery.MinePagerView' },
}

---入口
---@public
function _class:setup()
    self:loadExtensions()
    self:setupContainerView()
    self:setupTabar()
end

---优先加载其他辅助文件
---@private
function _class:loadExtensions()
    require("MMLuaKitGallery.Constant")
end

---布局view
---@private
function _class:setupContainerView()
    local containerView = LinearLayout(LinearType.VERTICAL)
            :width(MeasurementType.MATCH_PARENT):height(MeasurementType.MATCH_PARENT)
    self.containerView = containerView
    window:addView(containerView)

    local contentView = View():width(MeasurementType.MATCH_PARENT):height(MeasurementType.MATCH_PARENT):setGravity(Gravity.CENTER_HORIZONTAL)
    if System:iOS() then
        contentView:marginTop(window:statusBarHeight())
    end

    self.contentView = contentView
    containerView:addView(contentView)

    --默认展示第一页
    self:display(1)
end

---配置tabBar
---@private
function _class:setupTabar()
    local normalImages = Array()
    normalImages:add("hom")
    normalImages:add("disc")
    normalImages:add("plus")
    normalImages:add("msg")
    normalImages:add("min")

    local selectImages = Array()
    selectImages:add("hom_d")
    selectImages:add("disc_d")
    selectImages:add("plus")
    selectImages:add("msg_d")
    selectImages:add("min_d")

    self.tabbar = require('MMLuaKitGallery.TabToolBar'):new()
    self.tabbar:setupItems(normalImages, selectImages, function(idx)
        if idx == 3 then
            Toast("打开照相机📷", 1)
        else
            self:display(idx)
        end
    end)
    self.containerView:addView(self.tabbar.contentView)
end

---展示View逻辑
---@private
function _class:display(index)
    if self.prevSelectedView then
        self.prevSelectedView:rootView():removeFromSuper()
    end
    self.prevSelectedView = self._subViews[index]

    if not self.prevSelectedView then
        self.prevSelectedView = require(self._subViewNames[index]):new()
        self._subViews[index] = self.prevSelectedView
    end
    self.contentView:addView(self.prevSelectedView:rootView())
end

return _class





