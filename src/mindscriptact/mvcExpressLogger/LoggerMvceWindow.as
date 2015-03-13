package mindscriptact.mvcExpressLogger {
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.utils.setTimeout;

import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_CheckBox;
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_NumericStepper;
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_PushButton;
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_Text;
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_Window;
import mindscriptact.mvcExpressLogger.screens.MvcExpressLogScreen;
import mindscriptact.mvcExpressLogger.screens.MvcExpressVisualizerScreen;
import mindscriptact.mvcExpressLogger.visualizer.VisualizerManager;

import mvcexpress.core.namespace.pureLegsCore;

public class LoggerMvceWindow extends Mvce_Window {

	private var moduleManagerClass:Class;
	private var mvcExpressClass:Class;

	private var visualizerManager:VisualizerManager;


	private var allButtons:Vector.<Mvce_PushButton>;

	private var moduleStepper:Mvce_NumericStepper;

	private var autoLogCheckBox:Mvce_CheckBox;

	private var currentScreen:Sprite;


	internal var currentTabButtonName:String;

	private var currentTogleButton:Mvce_PushButton;
	private var currentModuleName:String = "";
	private var allModuleNames:Array;
	private var useAutoScroll:Boolean = true;
	internal var customLogText:String = "";


	private var errorText:Mvce_Text;

	//
	private var logText:String = "";

	private var isRenderWaiting:Boolean = false;

	internal var initTab:String;

	internal static var isCustomLoggingEnabled:Boolean;

	private var customLoggingButton:Mvce_PushButton;

	public function LoggerMvceWindow() {
	}

	public function initialize(mvcExpressClass:Class, moduleManagerClass:Class, visualizerManager:VisualizerManager):void {
		this.mvcExpressClass = mvcExpressClass;
		this.moduleManagerClass = moduleManagerClass;
		this.visualizerManager = visualizerManager;

		var debugCompile:Boolean = (mvcExpressClass["DEBUG_COMPILE"] as Boolean);

		var version:String = "    [" + mvcExpressClass["VERSION"] + " - " + (debugCompile ? "DEBUG COMPILE!!!" : "Release.") + "]";
		this.hasCloseButton = true;
		this.titleRight = mvcExpressClass["NAME"] + " logger" + version;
		//
		this.refreshFonts();

		moduleStepper = new Mvce_NumericStepper(this, 10, 5, handleModuleChange);
		moduleStepper.width = 32;
		moduleStepper.minimum = 0;
		moduleStepper.isCircular = true;

		allButtons = new Vector.<Mvce_PushButton>();

		var logButton:Mvce_PushButton = new Mvce_PushButton(this, 0, -0, MvcExpressLogger.LOG_TAB, handleButtonClick);
		logButton.toggle = true;
		logButton.width = 50;
		logButton.x = moduleStepper.x + moduleStepper.width + 10;
		allButtons.push(logButton);

		var messageMapingButton:Mvce_PushButton = new Mvce_PushButton(this, 0, -0, MvcExpressLogger.MESSAGES_TAB, handleButtonClick);
		messageMapingButton.toggle = true;
		messageMapingButton.width = 60;
		messageMapingButton.x = allButtons[allButtons.length - 1].x + allButtons[allButtons.length - 1].width + 5;
		allButtons.push(messageMapingButton);

		var mediatorMapingButton:Mvce_PushButton = new Mvce_PushButton(this, 0, -0, MvcExpressLogger.MEDIATORS_TAB, handleButtonClick);
		mediatorMapingButton.toggle = true;
		mediatorMapingButton.width = 60;
		mediatorMapingButton.x = allButtons[allButtons.length - 1].x + allButtons[allButtons.length - 1].width + 5;
		allButtons.push(mediatorMapingButton);

		var proxyMapingButton:Mvce_PushButton = new Mvce_PushButton(this, 0, -0, MvcExpressLogger.PROXIES_TAB, handleButtonClick);
		proxyMapingButton.toggle = true;
		proxyMapingButton.width = 50;
		proxyMapingButton.x = allButtons[allButtons.length - 1].x + allButtons[allButtons.length - 1].width + 5;
		allButtons.push(proxyMapingButton);

		var commandMapingButton:Mvce_PushButton = new Mvce_PushButton(this, 0, -0, MvcExpressLogger.COMMANDS_TAB, handleButtonClick);
		commandMapingButton.toggle = true;
		commandMapingButton.width = 60;
		commandMapingButton.x = allButtons[allButtons.length - 1].x + allButtons[allButtons.length - 1].width + 5;
		allButtons.push(commandMapingButton);

		//
		//if (moduleManagerClass["listMappedProcesses"] != null) {
		//	if (moduleManagerClass["listMappedProcesses"]() != "Not supported.") {
		var processMapingButton:Mvce_PushButton = new Mvce_PushButton(this, 0, -0, MvcExpressLogger.ENGINE_TAB, handleButtonClick);
		processMapingButton.toggle = true;
		processMapingButton.width = 60;
		processMapingButton.x = allButtons[allButtons.length - 1].x + allButtons[allButtons.length - 1].width + 5;
		allButtons.push(processMapingButton);
		//	}
		//}

		var clearButton:Mvce_PushButton = new Mvce_PushButton(this, 0, 5, "clear log", handleClearLog);
		clearButton.x = allButtons[allButtons.length - 1].x + allButtons[allButtons.length - 1].width + 10;
		clearButton.width = 50;
		clearButton.height = 15;

		autoLogCheckBox = new Mvce_CheckBox(this, 0, 5, "autoScroll", handleAutoScrollToggle);
		autoLogCheckBox.x = allButtons[allButtons.length - 1].x + allButtons[allButtons.length - 1].width + 70;
		autoLogCheckBox.selected = true;

		var visualizerButton:Mvce_PushButton = new Mvce_PushButton(this, 0, -0, MvcExpressLogger.VISUALIZER_TAB, handleButtonClick);
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

	// TODO: check if delay is needed. (all views are created on statics...)
	internal function delayedAutoButtonClick():void {
		if (!currentTabButtonName) {
			resolveCurrentModuleName();
			if (currentModuleName != "") {
				handleButtonClick();
			} else {
				setTimeout(delayedAutoButtonClick, 100);
			}
		}
	}

	private function handleClearLog(event:MouseEvent):void {
		//trace("MvcExpressLogger.handleClearLog > event : " + event);
		logText = "";
		customLogText = "";
		render();
	}

	private function handleAutoScrollToggle(event:MouseEvent):void {
		//trace("MvcExpressLogger.handleAutoScrollTogle > event : " + event);
		useAutoScroll = (event.target as Mvce_CheckBox).selected;
		(currentScreen as MvcExpressLogScreen).scrollDown(useAutoScroll);
	}

	internal function resolveCurrentModuleName():void {
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
				this.titleLeft = "Module:    " + currentModuleName + getModuleExtensions(currentModuleName);
			} else {
				this.titleLeft = "Module: mvcExpress MODULES NOT FOUND.";
			}
		}
		moduleStepper.maximum = allModuleNames.length - 1;
		currentModuleName = currentModuleName;

		render();
	}

	// FIXME: move to view controller
	private function handleModuleChange(event:Event):void {
		currentModuleName = allModuleNames[moduleStepper.value];
		this.titleLeft = "Module:    " + currentModuleName + getModuleExtensions(currentModuleName);
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
				this.removeChild(currentScreen);
				currentScreen = null;
			}
			currentTabButtonName = targetButton.label;
			autoLogCheckBox.visible = (currentTabButtonName == MvcExpressLogger.LOG_TAB) || (currentTabButtonName == MvcExpressLogger.CUSTOM_LOGGING_TAB);

			switch (currentTabButtonName) {
				case MvcExpressLogger.VISUALIZER_TAB:
					currentScreen = new MvcExpressVisualizerScreen(this.width - 6, this.height - 52);
					currentScreen.x = 3;
					currentScreen.y = 25;
					visualizerManager.manageThisScreen(currentModuleName, currentScreen as MvcExpressVisualizerScreen);
					break;
				default:
					currentScreen = new MvcExpressLogScreen(this.width - 6, this.height - 52);
					currentScreen.x = 3;
					currentScreen.y = 25;
					visualizerManager.manageNothing();
					break;
			}
			render();
			if (currentScreen) {
				this.addChild(currentScreen);
			}
		} else {
			currentTogleButton.selected = true;
		}
		if (errorText) {
			this.removeChild(errorText);
			this.addChild(errorText);
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


	internal function showError(errorMessage:String):void {
		if (!errorText) {
			errorText = new Mvce_Text();
			this.addChild(errorText);
			errorText.width = this.width;
			errorText.height = this.height;
			errorText.editable = false;
		}
		errorText.text += "\n" + errorMessage;
	}


	internal function setCustomLoggingEnabled(value:Boolean):void {
		isCustomLoggingEnabled = value;
		if (!isCustomLoggingEnabled) {
			customLogText = "";
		}
		renderCustomLoggingButton();
	}

	private function renderCustomLoggingButton():void {
		if (isCustomLoggingEnabled) {
			if (!customLoggingButton) {
				customLoggingButton = new Mvce_PushButton(this, 0, 0, MvcExpressLogger.CUSTOM_LOGGING_TAB, handleButtonClick);
				customLoggingButton.toggle = true;
				//customLoggingButton.width = 60;
				customLoggingButton.x = 650;
			}
		} else {
			if (customLoggingButton) {
				this.removeChild(customLoggingButton);
				customLoggingButton = null;
			}
		}
	}

	internal function customLog(debugStr:String):void {
		if (customLogText != "") {
			customLogText += "\n";
		}
		customLogText += debugStr;
		if (currentTabButtonName == MvcExpressLogger.CUSTOM_LOGGING_TAB) {
			render();
		}
	}

	internal function appendLogText(logStr:String):void {
		logText += logStr + "\n";
	}

	internal function dataChange(logType:String):void {

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
