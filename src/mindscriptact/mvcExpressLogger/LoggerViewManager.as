package mindscriptact.mvcExpressLogger {
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.utils.Dictionary;
import flash.utils.setTimeout;

import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_CheckBox;
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_Label;
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_NumericStepper;
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_PushButton;
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_Text;
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_Window;
import mindscriptact.mvcExpressLogger.screens.MvcExpressLogScreen;
import mindscriptact.mvcExpressLogger.screens.MvcExpressVisualizerScreen;
import mindscriptact.mvcExpressLogger.visualizer.VisualizerManager;

import mvcexpress.core.namespace.pureLegsCore;

/**
 * Class to control logger view.
 * Implements function chaining.
 */
public class LoggerViewManager {

	private const logWindow:Mvce_Window = new Mvce_Window();

	private var stage:Stage;

	private var openKeyCode:int;
	private var isCtrlKeyNeeded:Boolean;
	private var isShiftKeyNeeded:Boolean;
	private var isAltKeyNeeded:Boolean;


	private var isInitialized:Boolean = false;
	private var isLogShown:Boolean = false;


	private var currentScreen:Sprite;
	private var currentTogleButton:Mvce_PushButton;
	// FIXME : should be priveta.
	internal var currentTabButtonName:String;
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

	private var mvcExpressClass:Class;
	private var moduleManagerClass:Class;

	private static var _isCustomLoggingEnabled:Boolean;

	internal var customLogText:String = "";

	static private var classesToIgnore:Dictionary = new Dictionary();
	static private var messageTypesToIgnore:Dictionary = new Dictionary();


	private var allButtons:Vector.<Mvce_PushButton>;

	private var visualizerManager:VisualizerManager;


	public function LoggerViewManager() {
	}

	internal function setStage(stage:Stage):void {
		this.stage = stage;
	}

	internal function init(mvcExpressClass:Class, moduleManagerClass:Class):void {

		this.mvcExpressClass = mvcExpressClass;
		this.moduleManagerClass = moduleManagerClass;

		visualizerManager = new VisualizerManager();

		stage.root.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyPress);
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

	internal function showLogger():void {
		isLogShown = true;
		if (!isInitialized) {
			isInitialized = true;

			var debugCompile:Boolean = (mvcExpressClass["DEBUG_COMPILE"] as Boolean);

			var version:String = "    [" + mvcExpressClass["VERSION"] + " - " + (debugCompile ? "DEBUG COMPILE!!!" : "Release.") + "]";
			logWindow.width = logWindow.width;
			logWindow.height = logWindow.height;
			logWindow.alpha = logWindow.alpha;
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

			var logButton:Mvce_PushButton = new Mvce_PushButton(logWindow, 0, -0, MvcExpressLogger.LOG_TAB, handleButtonClick);
			logButton.toggle = true;
			logButton.width = 50;
			logButton.x = moduleStepper.x + moduleStepper.width + 10;
			allButtons.push(logButton);

			var messageMapingButton:Mvce_PushButton = new Mvce_PushButton(logWindow, 0, -0, MvcExpressLogger.MESSAGES_TAB, handleButtonClick);
			messageMapingButton.toggle = true;
			messageMapingButton.width = 60;
			messageMapingButton.x = allButtons[allButtons.length - 1].x + allButtons[allButtons.length - 1].width + 5;
			allButtons.push(messageMapingButton);

			var mediatorMapingButton:Mvce_PushButton = new Mvce_PushButton(logWindow, 0, -0, MvcExpressLogger.MEDIATORS_TAB, handleButtonClick);
			mediatorMapingButton.toggle = true;
			mediatorMapingButton.width = 60;
			mediatorMapingButton.x = allButtons[allButtons.length - 1].x + allButtons[allButtons.length - 1].width + 5;
			allButtons.push(mediatorMapingButton);

			var proxyMapingButton:Mvce_PushButton = new Mvce_PushButton(logWindow, 0, -0, MvcExpressLogger.PROXIES_TAB, handleButtonClick);
			proxyMapingButton.toggle = true;
			proxyMapingButton.width = 50;
			proxyMapingButton.x = allButtons[allButtons.length - 1].x + allButtons[allButtons.length - 1].width + 5;
			allButtons.push(proxyMapingButton);

			var commandMapingButton:Mvce_PushButton = new Mvce_PushButton(logWindow, 0, -0, MvcExpressLogger.COMMANDS_TAB, handleButtonClick);
			commandMapingButton.toggle = true;
			commandMapingButton.width = 60;
			commandMapingButton.x = allButtons[allButtons.length - 1].x + allButtons[allButtons.length - 1].width + 5;
			allButtons.push(commandMapingButton);

			//
			//if (moduleManagerClass["listMappedProcesses"] != null) {
			//	if (moduleManagerClass["listMappedProcesses"]() != "Not supported.") {
			var processMapingButton:Mvce_PushButton = new Mvce_PushButton(logWindow, 0, -0, MvcExpressLogger.ENGINE_TAB, handleButtonClick);
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

			var visualizerButton:Mvce_PushButton = new Mvce_PushButton(logWindow, 0, -0, MvcExpressLogger.VISUALIZER_TAB, handleButtonClick);
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
		stage.addChild(logWindow);

		resolveCurrentModuleName();

		delayedAutoButtonClick()
	}

	internal function hideLogger(event:Event = null):void {
		isLogShown = false;
		stage.removeChild(logWindow);
	}

	internal function showNoFrameworkError():void {

		logWindow.titleLeft = "mvcExpress logger ERROR!";
		logWindow.width = 200;
		logWindow.hasCloseButton = true;

		var erorLabel:Mvce_Label = new Mvce_Label();
		erorLabel.x = 10;
		erorLabel.y = 10;
		erorLabel.text = "mvcExpress classes not found.\n\nStart using mvcExpress framework!\n        Have fun!.";
		logWindow.addChild(erorLabel);

		logWindow.addEventListener(Event.CLOSE, hideErrorWindow);

		stage.addChild(logWindow);

	}

	private function hideErrorWindow(event:Event):void {
		stage.removeChild(event.target as Mvce_Window);
	}


	////////////////////////

	// FIXME: move to logger parser.
	internal function debugMvcExpress(traceObj:Object):void {
		//
		visualizerManager.logMvcExpress(traceObj);
		//
		if (traceObj.action == "ERROR!") {
			//logWindow
			if (!errorText) {
				errorText = new Mvce_Text();
				logWindow.addChild(errorText);
				errorText.width = logWindow.width;
				errorText.height = logWindow.height;
				errorText.editable = false;
			}
			errorText.text += "\n" + traceObj.errorMessage;
		}
		//
		if (traceObj.canPrint) {

			var doLogTrace:Boolean = true;

			var mvcClass:Class;
			if (traceObj.action == "Messenger.send") {
				if (messageTypesToIgnore[traceObj.type] != null) {
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

			if (mvcClass != null && classesToIgnore[mvcClass] == true) {
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
						case MvcExpressLogger.LOG_TAB:
							render();
							break;
						case MvcExpressLogger.MESSAGES_TAB:
							if (logType == "••" || logType == "•>") {
								if (!isRenderWaiting) {
									isRenderWaiting = true;
									setTimeout(render, 1);
								}
							}
							break;
						case MvcExpressLogger.MEDIATORS_TAB:
							if (logType == "§§") {
								if (!isRenderWaiting) {
									isRenderWaiting = true;
									setTimeout(render, 1);
								}
							}
							break;
						case MvcExpressLogger.PROXIES_TAB:
							if (logType == "¶¶") {
								if (!isRenderWaiting) {
									isRenderWaiting = true;
									setTimeout(render, 1);
								}
							}
							break;
						case MvcExpressLogger.COMMANDS_TAB:
							if (logType == "©©") {
								if (!isRenderWaiting) {
									isRenderWaiting = true;
									setTimeout(render, 1);
								}
							}
							break;
						case MvcExpressLogger.ENGINE_TAB:
							if (logType == "ÆÆ") {
								if (!isRenderWaiting) {
									isRenderWaiting = true;
									setTimeout(render, 1);
								}
							}
							break;
						case MvcExpressLogger.VISUALIZER_TAB:
							break;
						default:
					}
				}
			}
		}
	}

	////////////////////////


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
			autoLogCheckBox.visible = (currentTabButtonName == MvcExpressLogger.LOG_TAB) || (currentTabButtonName == MvcExpressLogger.CUSTOM_LOGGING_TAB);

			switch (currentTabButtonName) {
				case MvcExpressLogger.VISUALIZER_TAB:
					currentScreen = new MvcExpressVisualizerScreen(logWindow.width - 6, logWindow.height - 52);
					currentScreen.x = 3;
					currentScreen.y = 25;
					visualizerManager.manageThisScreen(currentModuleName, currentScreen as MvcExpressVisualizerScreen);
					break;
				default:
					currentScreen = new MvcExpressLogScreen(logWindow.width - 6, logWindow.height - 52);
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
	// FIXME: should not be internal
	internal function render():void {
		isRenderWaiting = false;
		switch (currentTabButtonName) {
			case MvcExpressLogger.LOG_TAB:
				(currentScreen as MvcExpressLogScreen).showLog(logText);
				(currentScreen as MvcExpressLogScreen).scrollDown(useAutoScroll);
				break;
			case MvcExpressLogger.MESSAGES_TAB:
				(currentScreen as MvcExpressLogScreen).showLog(moduleManagerClass["listMappedMessages"](currentModuleName));
				(currentScreen as MvcExpressLogScreen).scrollDown(false);
				break;
			case MvcExpressLogger.MEDIATORS_TAB:
				(currentScreen as MvcExpressLogScreen).showLog(moduleManagerClass["listMappedMediators"](currentModuleName));
				(currentScreen as MvcExpressLogScreen).scrollDown(false);
				break;
			case MvcExpressLogger.PROXIES_TAB:
				(currentScreen as MvcExpressLogScreen).showLog(moduleManagerClass["listMappedProxies"](currentModuleName));
				(currentScreen as MvcExpressLogScreen).scrollDown(false);
				break;
			case MvcExpressLogger.COMMANDS_TAB:
				(currentScreen as MvcExpressLogScreen).showLog(moduleManagerClass["listMappedCommands"](currentModuleName));
				(currentScreen as MvcExpressLogScreen).scrollDown(false);
				break;
			case MvcExpressLogger.ENGINE_TAB:
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
			case MvcExpressLogger.CUSTOM_LOGGING_TAB:
				(currentScreen as MvcExpressLogScreen).showLog(customLogText);
				(currentScreen as MvcExpressLogScreen).scrollDown(useAutoScroll);
				break;
			default:
		}
	}


////////////////////////

	private var customLoggingButton:Mvce_PushButton;

// FIXME: move to view controller
	internal function renderCustomLoggingButton():void {
		if (_isCustomLoggingEnabled) {
			if (!customLoggingButton) {
				customLoggingButton = new Mvce_PushButton(logWindow, 0, 0, MvcExpressLogger.CUSTOM_LOGGING_TAB, handleButtonClick);
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


////////////////////////


	pureLegsCore function getLoggerView():Mvce_Window {
		return logWindow;
	}

	public function moveTo(x:int, y:int):LoggerViewManager {
		logWindow.x = x;
		logWindow.y = y;
		return this;
	}

	public function resize(width:int, height:int):LoggerViewManager {
		logWindow.width = width;
		logWindow.height = height;
		return this;
	}

	public function setAlpha(alpha:Number):LoggerViewManager {
		logWindow.alpha = alpha;
		return this;
	}

	public function showTab(initTab:String):LoggerViewManager {
		this.initTab = initTab;
		return this;
	}

	public function setToggleKey(openKeyCode:int, isCtrlKeyNeeded:Boolean, isShiftKeyNeeded:Boolean, isAltKeyNeeded:Boolean):LoggerViewManager {
		this.openKeyCode = openKeyCode;
		this.isCtrlKeyNeeded = isCtrlKeyNeeded;
		this.isShiftKeyNeeded = isShiftKeyNeeded;
		this.isAltKeyNeeded = isAltKeyNeeded;
		return this;
	}


}
}
