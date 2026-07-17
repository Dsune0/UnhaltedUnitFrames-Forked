local _, UUF = ...
local AG = UUF.AG
UUF.GUIWidgets = {}

local function DeepDisable(widget, disabled, skipWidget)
    if widget == skipWidget then return end
    if widget.SetDisabled then widget:SetDisabled(disabled) end
    if widget.children then
        for _, child in ipairs(widget.children) do
            DeepDisable(child, disabled, skipWidget)
        end
    end
end

UUF.GUIWidgets.DeepDisable = DeepDisable

local function CreateInformationTag(containerParent, labelDescription, textJustification)
    local informationLabel = AG:Create("Label")
    informationLabel:SetText(UUF.INFOBUTTON .. labelDescription)
    informationLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    informationLabel:SetFullWidth(true)
    informationLabel:SetJustifyH(textJustification or "CENTER")
    informationLabel:SetHeight(24)
    informationLabel:SetJustifyV("MIDDLE")
    containerParent:AddChild(informationLabel)
    return informationLabel
end

UUF.GUIWidgets.CreateInformationTag = CreateInformationTag

local SCROLL_GUTTER = 3

local function UpdateScrollBarVisual(widget)
	local scrollBar = widget.scrollbar
	local thumb = scrollBar.UUFThumbTexture
	if not thumb then return end
	local status = widget.status or widget.localstatus
	local scrollValue = status and status.scrollvalue or 0
	local scrollBarHeight = scrollBar:GetHeight()
	local thumbHeight = widget.UUFThumbHeight or math.max(scrollBarHeight * 0.25, 24)
	local offset = math.max(scrollBarHeight - thumbHeight, 0) * math.min(math.max(scrollValue / 1000, 0), 1)
	thumb:ClearAllPoints()
	thumb:SetPoint("TOP", scrollBar, "TOP", 0, -offset)
	thumb:SetSize(SCROLL_GUTTER, thumbHeight)
	thumb:SetShown(widget.scrollBarShown and true or false)
end

local function SetScrollBarValue(widget, scrollValue)
	widget.scrollbar:SetValue(1000 - scrollValue)
	UpdateScrollBarVisual(widget)
end

local function ScrollBar_OnValueChanged(scrollbar, value)
	local widget = scrollbar.obj
	widget:SetScroll(1000 - value)
	UpdateScrollBarVisual(widget)
end

local function MoveScrollFrame(widget, value)
	local status = widget.status or widget.localstatus
	local height, viewheight = widget.scrollframe:GetHeight(), widget.content:GetHeight()

	if widget.scrollBarShown then
		local diff = height - viewheight
		local delta = value < 0 and -1 or 1
		local scrollValue = math.min(math.max((status.scrollvalue or 0) + delta * (1000 / (diff / 45)), 0), 1000)
		SetScrollBarValue(widget, scrollValue)
	end
end

local function ScrollFrame_OnMouseWheel(frame, value)
	frame.obj:MoveScroll(value)
end

local function FixScrollFrame(widget)
	if widget.updateLock then return end
	widget.updateLock = true
	local status = widget.status or widget.localstatus
	local contentHeight = widget.content:GetHeight()
	local scrollFrameHeight = widget.scrollframe:GetHeight()
	local scrollable = contentHeight > scrollFrameHeight + 2
	widget.scrollBarShown = scrollable or nil
	widget.scrollbar:SetShown(scrollable)
	if scrollable then
		widget.UUFThumbHeight = math.max(widget.scrollbar:GetHeight() * scrollFrameHeight / contentHeight, 24)
		local nativeThumb = widget.scrollbar.UUFNativeThumbTexture or (widget.scrollbar.GetThumbTexture and widget.scrollbar:GetThumbTexture()) or widget.scrollbar.ThumbTexture
		if nativeThumb then nativeThumb:SetHeight(widget.UUFThumbHeight) end
	end
	SetScrollBarValue(widget, scrollable and (status.scrollvalue or 0) or 0)
	widget:SetScroll(scrollable and (status.scrollvalue or 0) or 0)
	UpdateScrollBarVisual(widget)
	widget.updateLock = nil
end

local function SetScrollFrameWidth(widget, width)
	widget.content.width = math.max(width - SCROLL_GUTTER, 0)
	widget.content.original_width = width
	widget.scrollframe:SetPoint("BOTTOMRIGHT", -SCROLL_GUTTER, 0)
end

local function StyleScrollFrame(widget)
	local scrollBar = widget.scrollbar
	widget.MoveScroll = MoveScrollFrame
	widget.scrollframe:EnableMouseWheel(true)
	widget.scrollframe:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel)
	scrollBar:SetScript("OnValueChanged", ScrollBar_OnValueChanged)

	if widget.UUFMinimalScrollBar then
		UpdateScrollBarVisual(widget)
		return
	end

	scrollBar.ScrollUpButton:Hide()
	scrollBar.ScrollDownButton:Hide()
	scrollBar:ClearAllPoints()
	scrollBar:SetPoint("TOPRIGHT", widget.frame, "TOPRIGHT")
	scrollBar:SetPoint("BOTTOMRIGHT", widget.frame, "BOTTOMRIGHT")
	scrollBar:SetWidth(SCROLL_GUTTER)
	scrollBar:SetHitRectInsets(-4, -4, 0, 0)
	scrollBar:SetFrameLevel(widget.frame:GetFrameLevel() + 2)
	scrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
	local nativeThumb = (scrollBar.GetThumbTexture and scrollBar:GetThumbTexture()) or scrollBar.ThumbTexture
	scrollBar.UUFNativeThumbTexture = nativeThumb
	if nativeThumb then
		nativeThumb:SetAlpha(0)
		nativeThumb:SetWidth(SCROLL_GUTTER)
		nativeThumb:SetTexCoord(0, 1, 0, 1)
	end
	scrollBar.UUFThumbTexture = scrollBar:CreateTexture(nil, "OVERLAY")
	scrollBar.UUFThumbTexture:SetColorTexture(0.5, 0.5, 1, 0.85)
	scrollBar.UUFThumbTexture:SetWidth(SCROLL_GUTTER)
	local scrollTrack = scrollBar:CreateTexture(nil, "BACKGROUND")
	scrollTrack:SetAllPoints()
	scrollTrack:SetColorTexture(1, 1, 1, 0.12)
	widget.UUFMinimalScrollBar = true
end

local function CreateScrollFrame(containerParent)
    local scrollFrame = AG:Create("ScrollFrame")
	StyleScrollFrame(scrollFrame)
	scrollFrame.FixScroll = FixScrollFrame
	scrollFrame.OnWidthSet = SetScrollFrameWidth
    scrollFrame:SetLayout("Flow")
    scrollFrame:SetFullWidth(true)
    containerParent:AddChild(scrollFrame)
    return scrollFrame
end

UUF.GUIWidgets.CreateScrollFrame = CreateScrollFrame

local function CreateInlineGroup(containerParent, containerTitle)
    local inlineGroup = AG:Create("InlineGroup")
    inlineGroup:SetTitle("|cFFFFFFFF" .. containerTitle .. "|r")
    inlineGroup:SetFullWidth(true)
    inlineGroup:SetLayout("Flow")
    containerParent:AddChild(inlineGroup)
    return inlineGroup
end

UUF.GUIWidgets.CreateInlineGroup = CreateInlineGroup

local function CreateHeader(containerParent, headerTitle)
    local headingText = AG:Create("Heading")
    headingText:SetText("|cFF8080FF" .. headerTitle .. "|r")
    headingText:SetFullWidth(true)
    containerParent:AddChild(headingText)
    return headingText
end

UUF.GUIWidgets.CreateHeader = CreateHeader
