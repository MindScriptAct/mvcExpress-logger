package com.mindscriptact.mvcExpressLogger.screens
{
    import com.mindscriptact.mvcExpressLogger.LogEntryVO;
    import com.mindscriptact.mvcExpressLogger.MvcExpressLogger;
    import com.mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_Panel;
    import com.mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_PushButton;
    import com.mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_ScrollBar;
    import com.mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_Slider;
    import com.mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_TextArea;

    import flash.display.Shape;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.filters.GlowFilter;

    /**
     * COMMENT
     * @author Raimundas Banevicius (http://www.mindscriptact.com/)
     */
    public class MvcExpressTimelineScreen extends MvcExpressVisualizerScreen
    {
        private var screenWidth:int;
        private var screenHeight:int;

        private var timelinePanel:Mvce_Panel;
        private var txt:Mvce_TextArea;
        private var _currentFrame:uint = 0;
        private var _highestCount:uint = 0;
        private var bar:Mvce_ScrollBar;

        public function MvcExpressTimelineScreen(screenWidth:int, screenHeight:int)
        {
            super(screenWidth, screenHeight);
            this.screenWidth = screenWidth;
            this.screenHeight = screenHeight;

            this.graphics.lineStyle(0.1, 0x393939);
            this.graphics.moveTo(0, 0);
            this.graphics.lineTo(1500, 0);
            this.graphics.lineStyle(0.1, 0x494949);
            this.graphics.moveTo(0, 1);
            this.graphics.lineTo(1500, 1);
            timelinePanel = new Mvce_Panel();
            timelinePanel.width = screenWidth;
            timelinePanel.height = 80;
            bar = new Mvce_ScrollBar(Mvce_Slider.HORIZONTAL, timelinePanel, 0, 60, handleScroll);
            bar.width = screenWidth;
            timelinePanel.addRawChild(bar);
            this.addChild(timelinePanel);

            txt = new Mvce_TextArea(this);
            txt.width = screenWidth;
            txt.height = screenHeight - 80;
            txt.editable = false;
            txt.y = 80;
            this.addChild(txt);
            this.addEventListener(Event.EXIT_FRAME, handleEnterFrame);
        }

        private function handleScroll(e:Event):void
        {
            timelinePanel.content.x = -bar.value;

        }

        private function handleEnterFrame(event:Event):void
        {
            if (_currentFrame < MvcExpressLogger.frameCounter)
            {
                while (_currentFrame < MvcExpressLogger.frameCounter)
                {
                    if (MvcExpressLogger.frameDictionary[_currentFrame].length)
                    {

                        var button:Mvce_PushButton = new Mvce_PushButton(timelinePanel, 10 * timelinePanel.content.numChildren, 0, _currentFrame.toString(), handleTimelineClick);
                        var frameLog:Vector.<LogEntryVO> = MvcExpressLogger.frameDictionary[_currentFrame];

                        for each(var entry:LogEntryVO in frameLog)
                        {
                            if (entry.logMSG.split("•> Messenger.send > type : SHOW_COMBAT, params :").length >= 2)
                            {
                                button.filters=[new GlowFilter(0xFFFF00, 1, 6, 6, 20, 1, true)];
                            }
                        }

                        button.width = 10;
                        button.height = 60;
                        timelinePanel.addChild(button);
                    }
                    _currentFrame++;
                }
            }
            bar.setSliderParams(0, timelinePanel.content.width - timelinePanel.content.mask.width, Math.abs(timelinePanel.content.x));
            bar.setThumbPercent(timelinePanel.content.mask.width / timelinePanel.content.width);
        }

        private function handleTimelineClick(event:MouseEvent = null):void
        {
            if (event)
            {
                var target:Mvce_PushButton = event.target as Mvce_PushButton;
                var frameNumber:uint = uint(target.label);
                var frameLog:Vector.<LogEntryVO> = MvcExpressLogger.frameDictionary[frameNumber];
                if (frameLog && frameLog.length)
                {
                    txt.text = "";
                    for each(var entry:LogEntryVO in frameLog)
                    {
                        txt.text += entry.logMSG + "\n";
                    }
                }
            }
        }

        override public function updateProxies(listMappedProxies:String):void
        {

        }

        //----------------------------------
        //     module
        //----------------------------------

        override public function showModule(currentModuleName:String):void
        {


        }

        //----------------------------------
        //     mediators
        //----------------------------------

        override public function addMediators(mediators:Vector.<Object>):void
        {

        }

        override public function addMediator(mediatorLogObj:Object):void
        {

        }

        override public function removeMediatorFromPossition(possition:int):void
        {

        }


        override public function drawMediatorDependency(mediatorObject:Object, injectedObject:Object):void
        {

        }

        override public function drawMessageToMediator(messageLogObj:Object, possition:int):void
        {

        }

        private function hideShape(shape:Shape):void
        {

        }

        //----------------------------------
        //     proxies
        //----------------------------------

        override public function addProxies(proxies:Vector.<Object>):void
        {

        }

        override public function addProxy(proxyLogObj:Object):void
        {

        }

        override public function removeProxyFromPossition(possition:int):void
        {

        }

        private function redrawProxyDependencies(proxyObject:Object):void
        {

        }

        override public function drawProxyDependency(proxyObject:Object, injectedObject:Object):void
        {

        }

        //----------------------------------
        //     commands
        //----------------------------------

        override public function addCommand(commandLogObj:Object):void
        {

        }

        private function removeObject(commandPosition:int, commandLogObj:Object):void
        {


        }

        override public function clearCommands():void
        {

        }

        override public function drawCommandDependency(commandObject:Object, injectedObject:Object):void
        {

        }

    }
}