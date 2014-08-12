package mindscriptact.mvcExpressLogger {
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_CheckBox;
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_Label;
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_NumericStepper;
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_PushButton;
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_Style;
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_Text;
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_Window;
import mindscriptact.mvcExpressLogger.screens.MvcExpressLogScreen;
import mindscriptact.mvcExpressLogger.screens.MvcExpressVisualizerScreen;
import mindscriptact.mvcExpressLogger.visualizer.VisualizerManager;

import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.utils.Dictionary;
import flash.utils.getDefinitionByName;
import flash.utils.setTimeout;

import mvcexpress.core.namespace.pureLegsCore;

/**
 * COMMENT
 * @author Raimundas Banevicius (http://mvcexpress.org/)
 */
public class MvcExpressLogger {

	static public const LOG_TAB:String = "LOG";
	static public const MESSAGES_TAB:String = "MESSAGES";
	static public const MEDIATORS_TAB:String = "MEDIATORS";
	static public const PROXIES_TAB:String = "PROXIES";
	static public const COMMANDS_TAB:String = "COMMANDS";
	static public const VISUALIZER_TAB:String = "VISUALIZER";
	static public const ENGINE_TAB:String = "ENGINE";
	static public const CUSTOM_LOGGING_TAB:String = "custom logging";
	//
	static private var allowInstantiation:Boolean;
	static private var instance:MvcExpressLogger;
	static private var visualizerManager:VisualizerManager;

	// view params

	// FIXME : Remove, Move to view manager
	private var width:int;
	private var height:int;
	private var alpha:Number;
	private var openKeyCode:int;
	private var isCtrlKeyNeeded:Boolean;
	private var isShiftKeyNeeded:Boolean;
	private var isAltKeyNeeded:Boolean;

	// Core elements.
	static private const logViewManager:LoggerViewManager = new LoggerViewManager();
	static private const logWindow:Mvce_Window = logViewManager.pureLegsCore::getLoggerView();
	static private const logParser:LoggerTraceParser = new LoggerTraceParser(logWindow);


	// FIXME: LATER - deprecated. MvcExpressLogger should not be used an object, and should not contain non static variables.

	private var isInitialized:Boolean = false;
	private var isLogShown:Boolean = false;
	private var allButtons:Vector.<Mvce_PushButton>;
	private var currentScreen:Sprite;
	private var currentTogleButton:Mvce_PushButton;
	private var currentTabButtonName:String;
	//
	private var logText:String = "";
	private var currentModuleName:String = "";
	private var moduleStepper:Mvce_NumericStepper;
	private var allModuleNames:Array;
	private var isRenderWaiting:Boolean = false;
	private var autoLogCheckBox:Mvce_CheckBox;
	private var useAutoScroll:Boolean = true;
	private var initTab:String;

	private var errorText:Mvce_Text;

	static private var stage:Stage;

	static private var mvcExpressClass:Class;
	static private var moduleManagerClass:Class;

	private static var _isCustomLoggingEnabled:Boolean;

	internal var customLogText:String = "";

	static private var classesToIgnore:Dictionary = new Dictionary();
	static private var messageTypesToIgnore:Dictionary = new Dictionary();

	// FIXME: LATER - deprecated. MvcExpressLogger should not be used an object.
	public function MvcExpressLogger() {
		if (!allowInstantiation) {
			throw Error("MvcExpressLogger is singleton and will be instantiated with first use or MvcExpressLogger.init()");
		}
	}

	static public function init(stage:Stage, x:int = 0, y:int = 0, width:int = 900, height:int = 400, alpha:Number = 0.9, autoShow:Boolean = false, initTab:String = "LOG", openKeyCode:int = 192, isCtrlKeyNeeded:Boolean = true, isShiftKeyNeeded:Boolean = false, isAltKeyNeeded:Boolean = false):LoggerViewManager {

		if (stage) {

			// FIXME: move stage to view manager.
			MvcExpressLogger.stage = stage;

			try {
				mvcExpressClass = getDefinitionByName("mvcexpress::MvcExpress") as Class;
				moduleManagerClass = getDefinitionByName("mvcexpress.core::ModuleManager") as Class;
			} catch (error:Error) {
			}

			// FIXME: move out.
			Mvce_Style.setStyle(Mvce_Style.DARK);
			Mvce_Style.LABEL_TEXT = 0xFFFFFF;

			if (mvcExpressClass && moduleManagerClass) {
				// FIXME: move to view manager.
				if (!instance) {
					allowInstantiation = true;
					// FIXME: LATER - deprecated. MvcExpressLogger should not be used an object. Its only static API.
					instance = new MvcExpressLogger();
					allowInstantiation = false;
					//
					visualizerManager = new VisualizerManager();
					//
					MvcExpressLogger.stage.root.addEventListener(KeyboardEvent.KEY_DOWN, instance.handleKeyPress);

					logViewManager.moveTo(x, y);

					// FIXME : replace with view manager functions.
					instance.width = width;
					instance.height = height;
					instance.alpha = alpha;
					instance.initTab = initTab;
					instance.openKeyCode = openKeyCode;
					instance.isCtrlKeyNeeded = isCtrlKeyNeeded;
					instance.isShiftKeyNeeded = isShiftKeyNeeded;
					instance.isAltKeyNeeded = isAltKeyNeeded;

				}

				// FIXME: get parse function from logger parser.
				use namespace pureLegsCore;
				mvcExpressClass["loggerFunction"] = instance.debugMvcExpress;

				if (autoShow) {
					instance.showLogger();
				}
			} else {

				// FIXME: move showing error window to view manager.

				logWindow.titleLeft = "mvcExpress logger ERROR!";
				logWindow.width = 200;
				logWindow.hasCloseButton = true;

				var erorLabel:Mvce_Label = new Mvce_Label();
				erorLabel.x = 10;
				erorLabel.y = 10;
				erorLabel.text = "mvcExpress classes not found.\n\nStart using mvcExpress framework!\n        Have fun!.";
				logWindow.addChild(erorLabel);

				logWindow.addEventListener(Event.CLOSE, hideErrorWindow);

				MvcExpressLogger.stage.addChild(logWindow);

			}
		} else {
			throw Error("Stage must be provided for mvcExpress logger to work properly.");
		}

		// for function chaining.
		return logViewManager;
	}

	// FIXME: move to view manager.
	static private function hideErrorWindow(event:Event):void {
		MvcExpressLogger.stage.removeChild(event.target as Mvce_Window);
	}

	static public function show():void {
		// FIXME: use view manager.
		if (instance) {
			instance.showLogger();
		} else {
			trace("WARNING: MvcExpressLogger must be MvcExpressLogger.init(); before you can use this function.");
		}
	}

	static public function hide():void {
		// FIXME: use view manager.
		if (instance) {
			instance.hideLogger();
		} else {
			trace("WARNING: MvcExpressLogger must be MvcExpressLogger.init(); before you can use this function.");
		}
	}

	// FIXME: move to logger parser.
	private function debugMvcExpress(traceObj:Object):void {
		//
		visualizerManager.logMvcExpress(traceObj);
		//
		if (traceObj.action == "ERROR!") {
			//logWindow
			if (!errorText) {
				errorText = new Mvce_Text();
				logWindow.addChild(errorText);
				errorText.width = width;
				errorText.height = height;
				errorText.editable = false;
			}
			errorText.text += "\n" + traceObj.errorMessage;
		}
		//
		if (traceObj.canPrint) {

			var doLogTrace:Boolean = true;

			var mvcClass:Class;
			if(traceObj.action == "Messenger.send"){
				if(messageTypesToIgnore[traceObj.type] != null){
					doLogTrace = false;
				} else {
					mvcClass = visualizerManager.getTopObjectClass();
				}
			} else {
				if (traceObj.hasOwnProperty("commandClass")) {
					mvcClass = traceObj.commandClass;
				} else if (traceObj.hasOwnProperty("mediatorClass")) {
					mvcClass = traceObj.mediatorClass;
				} else if (traceObj.hasOwnProperty("proxyClass")) {
					mvcClass = traceObj.proxyClass;
				}
			}

			if(mvcClass != null && classesToIgnore[mvcClass] == true){
				doLogTrace = false;
			}

			if (doLogTrace) {
				logText += traceObj + "\n";
			}

			if (isLogShown) {

				var logType:String = String(traceObj).substr(0, 2);

				if (logType == "##") {
					setTimeout(resolveCurrentModuleName, 1);
				} else {
					switch (currentTabButtonName) {
						case LOG_TAB:
							render();
							break;
						case MESSAGES_TAB:
							if (logType == "••" || logType == "•>") {
								if (!isRenderWaiting) {
									isRenderWaiting = true;
									setTimeout(render, 1);
								}
							}
							break;
						case MEDIATORS_TAB:
							if (logType == "§§") {
								if (!isRenderWaiting) {
									isRenderWaiting = true;
									setTimeout(render, 1);
								}
							}
							break;
						case PROXIES_TAB:
							if (logType == "¶¶") {
								if (!isRenderWaiting) {
									isRenderWaiting = true;
									setTimeout(render, 1);
								}
							}
							break;
						case COMMANDS_TAB:
							if (logType == "©©") {
								if (!isRenderWaiting) {
									isRenderWaiting = true;
									setTimeout(render, 1);
								}
							}
							break;
						case ENGINE_TAB:
							if (logType == "ÆÆ") {
								if (!isRenderWaiting) {
									isRenderWaiting = true;
									setTimeout(render, 1);
								}
							}
							break;
						case VISUALIZER_TAB:
							break;
						default:
					}
				}
			}
		}
	}

	// FIXME: move to view controller
	private function handleKeyPress(event:KeyboardEvent):void {
		//trace("MvcExpressLogger.handleKeyPress > event : " + event);
		if (event.keyCode == openKeyCode && event.ctrlKey == isCtrlKeyNeeded && event.shiftKey == isShiftKeyNeeded && event.altKey == isAltKeyNeeded) {
			if (!isLogShown) {
				showLogger();
			} else {
				hideLogger();
			}
		}
	}

	// FIXME: move to view controller
	private function showLogger():void {
		isLogShown = true;
		if (!isInitialized) {
			isInitialized = true;

			var debugCompile:Boolean = (mvcExpressClass["DEBUG_COMPILE"] as Boolean);

			var version:String = "    [" + mvcExpressClass["VERSION"] + " - " + (debugCompile ? "DEBUG COMPILE!!!" : "Release.") + "]";
			logWindow.width = width;
			logWindow.height = height;
			logWindow.alpha = alpha;
			logWindow.hasCloseButton = true;
			logWindow.addEventListener(Event.CLOSE, hideLogger);
			logWindow.titleRight = mvcExpressClass["NAME"] + " logger" + version;
			//
			logWindow.refreshFonts();

			moduleStepper = new Mvce_NumericStepper(logWindow, 10, 5, handleModuleChange);
			moduleStepper.width = 32;
			moduleStepper.minimum = 0;
			moduleStepper.isCircular = true;

			allButtons = new Vector.<Mvce_PushButton>();

			var logButton:Mvce_PushButton = new Mvce_PushButton(logWindow, 0, -0, LOG_TAB, handleButtonClick);
			logButton.toggle = true;
			logButton.width = 50;
			logButton.x = moduleStepper.x + moduleStepper.width + 10;
			allButtons.push(logButton);

			var messageMapingButton:Mvce_PushButton = new Mvce_PushButton(logWindow, 0, -0, MESSAGES_TAB, handleButtonClick);
			messageMapingButton.toggle = true;
			messageMapingButton.width = 60;
			messageMapingButton.x = allButtons[allButtons.length - 1].x + allButtons[allButtons.length - 1].width + 5;
			allButtons.push(messageMapingButton);

			var mediatorMapingButton:Mvce_PushButton = new Mvce_PushButton(logWindow, 0, -0, MEDIATORS_TAB, handleButtonClick);
			mediatorMapingButton.toggle = true;
			mediatorMapingButton.width = 60;
			mediatorMapingButton.x = allButtons[allButtons.length - 1].x + allButtons[allButtons.length - 1].width + 5;
			allButtons.push(mediatorMapingButton);

			var proxyMapingButton:Mvce_PushButton = new Mvce_PushButton(logWindow, 0, -0, PROXIES_TAB, handleButtonClick);
			proxyMapingButton.toggle = true;
			proxyMapingButton.width = 50;
			proxyMapingButton.x = allButtons[allButtons.length - 1].x + allButtons[allButtons.length - 1].width + 5;
			allButtons.push(proxyMapingButton);

			var commandMapingButton:Mvce_PushButton = new Mvce_PushButton(logWindow, 0, -0, COMMANDS_TAB, handleButtonClick);
			commandMapingButton.toggle = true;
			commandMapingButton.width = 60;
			commandMapingButton.x = allButtons[allButtons.length - 1].x + allButtons[allButtons.length - 1].width + 5;
			allButtons.push(commandMapingButton);

			//
			//if (moduleManagerClass["listMappedProcesses"] != null) {
			//	if (moduleManagerClass["listMappedProcesses"]() != "Not supported.") {
			var processMapingButton:Mvce_PushButton = new Mvce_PushButton(logWindow, 0, -0, ENGINE_TAB, handleButtonClick);
			processMapingButton.toggle = true;
			processMapingButton.width = 60;
			processMapingButton.x = allButtons[allButtons.length - 1].x + allButtons[allButtons.length - 1].width + 5;
			allButtons.push(processMapingButton);
			//	}
			//}

			var clearButton:Mvce_PushButton = new Mvce_PushButton(logWindow, 0, 5, "clear log", handleClearLog);
			clearButton.x = allButtons[allButtons.length - 1].x + allButtons[allButtons.length - 1].width + 10;
			clearButton.width = 50;
			clearButton.height = 15;

			autoLogCheckBox = new Mvce_CheckBox(logWindow, 0, 5, "autoScroll", handleAutoScrollToggle);
			autoLogCheckBox.x = allButtons[allButtons.length - 1].x + allButtons[allButtons.length - 1].width + 70;
			autoLogCheckBox.selected = true;

			var visualizerButton:Mvce_PushButton = new Mvce_PushButton(logWindow, 0, -0, VISUALIZER_TAB, handleButtonClick);
			visualizerButton.toggle = true;
			visualizerButton.width = 60;
			visualizerButton.x = 555;
			allButtons.push(visualizerButton);

			if (!debugCompile) {
				logButton.visible = false;
				clearButton.visible = false;
				visualizerButton.visible = false;
			}

		}
		//forceThisOnTop();
		MvcExpressLogger.stage.addChild(logWindow);

		resolveCurrentModuleName();

		delayedAutoButtonClick()
	}

	// FIXME: move to view controller
	private function delayedAutoButtonClick():void {
		if (!currentTabButtonName) {
			resolveCurrentModuleName();
			if (currentModuleName != "") {
				handleButtonClick();
			} else {
				setTimeout(delayedAutoButtonClick, 100);
			}
		}

	}

	// FIXME: move to view controller
	private function handleClearLog(event:MouseEvent):void {
		//trace("MvcExpressLogger.handleClearLog > event : " + event);
		logText = "";
		customLogText = "";
		render();
	}

	// FIXME: move to view controller
	private function handleAutoScrollToggle(event:MouseEvent):void {
		//trace("MvcExpressLogger.handleAutoScrollTogle > event : " + event);
		useAutoScroll = (event.target as Mvce_CheckBox).selected;
		(currentScreen as MvcExpressLogScreen).scrollDown(useAutoScroll);
	}

	// FIXME: move to view controller
	private function resolveCurrentModuleName():void {
		var moduleNameList:String = moduleManagerClass["listModules"]();
		var namesOnly:Array = moduleNameList.split(":");
		if (namesOnly.length > 1) {
			allModuleNames = namesOnly[1].split(",");
			if (currentModuleName) {
				if (moduleStepper.value > 0) {
					if (allModuleNames[moduleStepper.value - 1] == currentModuleName) {
						moduleStepper.value -= 1;
					} else if (moduleStepper.value >= allModuleNames.length || allModuleNames[moduleStepper.value] != currentModuleName) {
						moduleStepper.value = 0;
						currentModuleName = allModuleNames[0];
					}
				}
			} else {
				currentModuleName = allModuleNames[0];
			}
			if (currentModuleName) {
				logWindow.titleLeft = "Module:    " + currentModuleName + getModuleExtensions(currentModuleName);
			} else {
				logWindow.titleLeft = "Module: mvcExpress MODULES NOT FOUND.";
			}
		}
		moduleStepper.maximum = allModuleNames.length - 1;
		currentModuleName = currentModuleName;

		render();
	}

	// FIXME: move to view controller
	private function handleModuleChange(event:Event):void {
		currentModuleName = allModuleNames[moduleStepper.value];
		logWindow.titleLeft = "Module:    " + currentModuleName + getModuleExtensions(currentModuleName);
		visualizerManager.manageThisScreen(currentModuleName, currentScreen as MvcExpressVisualizerScreen);
		render();
	}

	// FIXME: move to view controller
	private function getModuleExtensions(moduleName:String):String {
		var retVal:String = "";
		if (moduleName) {

			CONFIG::debug {

				var debugCompile:Boolean = mvcExpressClass["DEBUG_COMPILE"];
				if (debugCompile) {
					retVal += "    {";

					use namespace pureLegsCore;

					var module:Object = moduleManagerClass["getModule"](moduleName);
					retVal += module["listExtensions"]();
					retVal += "}";
				}
			}
		}
		return retVal;
	}

	// FIXME: move to view controller
	private function handleButtonClick(event:MouseEvent = null):void {
		if (event) {
			var targetButton:Mvce_PushButton = (event.target as Mvce_PushButton);
		} else {
			// select first button by default.
			targetButton = allButtons[0];
			targetButton.selected = true;
			// if initTab properly passed - start with that tab.
			for (var j:int = 0; j < allButtons.length; j++) {
				if (allButtons[j].label == initTab) {
					targetButton = allButtons[j];
					targetButton.selected = true;
					break;
				}
			}
		}

		if (currentTogleButton != targetButton) {
			currentTogleButton = targetButton;
			for (var i:int = 0; i < allButtons.length; i++) {
				if (allButtons[i] != targetButton) {
					allButtons[i].selected = false;
				}
			}
			if (currentScreen) {
				logWindow.removeChild(currentScreen);
				currentScreen = null;
			}
			currentTabButtonName = targetButton.label;
			autoLogCheckBox.visible = (currentTabButtonName == LOG_TAB) || (currentTabButtonName == CUSTOM_LOGGING_TAB);

			switch (currentTabButtonName) {
				case VISUALIZER_TAB:
					currentScreen = new MvcExpressVisualizerScreen(width - 6, height - 52);
					currentScreen.x = 3;
					currentScreen.y = 25;
					visualizerManager.manageThisScreen(currentModuleName, currentScreen as MvcExpressVisualizerScreen);
					break;
				default:
					currentScreen = new MvcExpressLogScreen(width - 6, height - 52);
					currentScreen.x = 3;
					currentScreen.y = 25;
					visualizerManager.manageNothing();
					break;
			}
			render();
			if (currentScreen) {
				logWindow.addChild(currentScreen);
			}
		} else {
			currentTogleButton.selected = true;
		}
		if (errorText) {
			logWindow.removeChild(errorText);
			logWindow.addChild(errorText);
		}
	}

	// FIXME: move to view controller
	private function render():void {
		isRenderWaiting = false;
		switch (currentTabButtonName) {
			case LOG_TAB:
				(currentScreen as MvcExpressLogScreen).showLog(logText);
				(currentScreen as MvcExpressLogScreen).scrollDown(useAutoScroll);
				break;
			case MESSAGES_TAB:
				(currentScreen as MvcExpressLogScreen).showLog(moduleManagerClass["listMappedMessages"](currentModuleName));
				(currentScreen as MvcExpressLogScreen).scrollDown(false);
				break;
			case MEDIATORS_TAB:
				(currentScreen as MvcExpressLogScreen).showLog(moduleManagerClass["listMappedMediators"](currentModuleName));
				(currentScreen as MvcExpressLogScreen).scrollDown(false);
				break;
			case PROXIES_TAB:
				(currentScreen as MvcExpressLogScreen).showLog(moduleManagerClass["listMappedProxies"](currentModuleName));
				(currentScreen as MvcExpressLogScreen).scrollDown(false);
				break;
			case COMMANDS_TAB:
				(currentScreen as MvcExpressLogScreen).showLog(moduleManagerClass["listMappedCommands"](currentModuleName));
				(currentScreen as MvcExpressLogScreen).scrollDown(false);
				break;
			case ENGINE_TAB:
				try {
					var result:String = moduleManagerClass["invokeModuleFunction"](currentModuleName, "listMappedProcesses") as String;
				} catch (error:Error) {
					result = "This module does not support Processes. Please use mvcExpress live extension class: ModuleLive for this feature."
				}
				if (result.substr(0, 72) == "Failed to invoke blankModule module function, named: listMappedProcesses") {
					result = "This module does not support Processes. Please use mvcExpress live extension class: ModuleLive for this feature."
				}
				(currentScreen as MvcExpressLogScreen).showLog(result);
				(currentScreen as MvcExpressLogScreen).scrollDown(false);
				break;
			case CUSTOM_LOGGING_TAB:
				(currentScreen as MvcExpressLogScreen).showLog(customLogText);
				(currentScreen as MvcExpressLogScreen).scrollDown(useAutoScroll);
				break;
			default:
		}
	}

	// FIXME: move to view controller
	private function hideLogger(event:Event = null):void {
		isLogShown = false;
		MvcExpressLogger.stage.removeChild(logWindow);
	}

	//------------------------------
	//  custom logging
	//------------------------------

	public static function get isCustomLoggingEnabled():Boolean {
		return _isCustomLoggingEnabled;
	}

	public static function set isCustomLoggingEnabled(value:Boolean):void {
		_isCustomLoggingEnabled = value;
		if (!_isCustomLoggingEnabled) {
			instance.customLogText = "";
		}
		if (instance != null) {
			instance.renderCustomLoggingButton();
		}
	}

	public static function log(debugText:String):void {
		// FIXME: move to view controller
		if (instance.customLogText != "") {
			instance.customLogText += "\n";
		}
		instance.customLogText += debugText;
		if (instance.currentTabButtonName == CUSTOM_LOGGING_TAB) {
			instance.render();
		}
	}

	private var customLoggingButton:Mvce_PushButton;

	// FIXME: move to view controller
	public function renderCustomLoggingButton():void {
		if (_isCustomLoggingEnabled) {
			if (!customLoggingButton) {
				customLoggingButton = new Mvce_PushButton(logWindow, 0, 0, CUSTOM_LOGGING_TAB, handleButtonClick);
				customLoggingButton.toggle = true;
				//customLoggingButton.width = 60;
				customLoggingButton.x = 650;
			}
		} else {
			if (customLoggingButton) {
				logWindow.removeChild(customLoggingButton);
				customLoggingButton = null;
			}
		}
	}

	//////////////////////////////
	//   Ignore stuff from logging.
	//////////////////////////////

	public static function ignoreClasses(ignoreClass:Class, ...moreIgnoreClasses:Array):void {
		CONFIG::debug {
			for(var i:int = 0; i < moreIgnoreClasses.length; i++) {
			    if(!(moreIgnoreClasses[i] is Class)){
			        throw Error("You can only ignore classes, but you provided:"+moreIgnoreClasses[i]);
			    }
			}
		}
		moreIgnoreClasses.unshift(ignoreClass);
		for (i = 0; i < moreIgnoreClasses.length; i++) {
			classesToIgnore[moreIgnoreClasses[i]] = true;
		}
	}

	public static function unignoreClasses(ignoreClass:Class, ...moreIgnoreClasses:Array):void {
		CONFIG::debug {
			for(var i:int = 0; i < moreIgnoreClasses.length; i++) {
				if(!(moreIgnoreClasses[i] is Class)){
					throw Error("You can only ignore classes, but you provided:"+moreIgnoreClasses[i]);
				}
			}
		}
		moreIgnoreClasses.unshift(ignoreClass);
		for (i = 0; i < moreIgnoreClasses.length; i++) {
			delete classesToIgnore[moreIgnoreClasses[i]];
		}
	}

	public static function ignoreMessages(ignoreMessageType : String, ...moreIgnoreMessageTypes:Array) : void {
		CONFIG::debug {
			for(var i:int = 0; i < moreIgnoreMessageTypes.length; i++) {
				if(!(moreIgnoreMessageTypes[i] is String)){
					throw Error("You can only ignore Strings as message types, but you provided:"+moreIgnoreMessageTypes[i]);
				}
			}
		}
		moreIgnoreMessageTypes.unshift(ignoreMessageType);
		for (i = 0; i < moreIgnoreMessageTypes.length; i++) {
			messageTypesToIgnore[moreIgnoreMessageTypes[i]] = true;
		}
	}

	public static function unignoreMessages(ignoreMessageType : String, ...moreIgnoreMessageTypes:Array) : void {
		CONFIG::debug {
			for(var i:int = 0; i < moreIgnoreMessageTypes.length; i++) {
				if(!(moreIgnoreMessageTypes[i] is String)){
					throw Error("You can only ignore Strings as message types, but you provided:"+moreIgnoreMessageTypes[i]);
				}
			}
		}
		moreIgnoreMessageTypes.unshift(ignoreMessageType);
		for (i = 0; i < moreIgnoreMessageTypes.length; i++) {
			delete messageTypesToIgnore[moreIgnoreMessageTypes[i]];
		}
	}

	///////////////////
	//  User API.
	///////////////////

	public static function moveTo(x:int, y:int):LoggerViewManager {
		return logViewManager.moveTo(x, y);
	}

	public static function resize(width:int, height:int):LoggerViewManager {
		// FIXME : Implement.
		return null;
	}

	public static function setAlpha(alpha:Number):LoggerViewManager {
		// FIXME : Implement.
		return null;
	}

	public static function autoShow(doAutoShow:Boolean = true):LoggerViewManager {
		// FIXME : Implement.
		return null;
	}

	public static function showTab(tabName:String):LoggerViewManager {
		// FIXME : Implement.
		return null;
	}

	public static function setToggleKey(openKeyCode:int = 192, isCtrlKeyNeeded:Boolean = true, isShiftKeyNeeded:Boolean = false, isAltKeyNeeded:Boolean = false):LoggerViewManager {
		// FIXME : Implement.
		return null;
	}
}
}