package mindscriptact.mvcExpressLogger {
import flash.display.Stage;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.utils.Dictionary;
import flash.utils.setTimeout;

import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_Label;
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_Style;
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_Window;
import mindscriptact.mvcExpressLogger.visualizer.VisualizerManager;

import mvcexpress.core.namespace.pureLegsCore;

/**
 * Class to control logger view.
 * Implements function chaining.
 */
public class LoggerViewManager {

	private const logWindow:LoggerMvceWindow = new LoggerMvceWindow();

	private var stage:Stage;

	private var openKeyCode:int;
	private var isCtrlKeyNeeded:Boolean;
	private var isShiftKeyNeeded:Boolean;
	private var isAltKeyNeeded:Boolean;

	private var isInitialized:Boolean = false;

	private var isLogShown:Boolean = false;


	private var mvcExpressClass:Class;
	private var moduleManagerClass:Class;

	static private var classesToIgnore:Dictionary = new Dictionary();
	static private var messageTypesToIgnore:Dictionary = new Dictionary();

	private var visualizerManager:VisualizerManager = new VisualizerManager();


	public function LoggerViewManager() {
		Mvce_Style.setStyle(Mvce_Style.DARK);
		Mvce_Style.LABEL_TEXT = 0xFFFFFF;
	}

	// REFACTOR: think about removing classes...
	internal function init(stage:Stage, mvcExpressClass:Class, moduleManagerClass:Class, autoShow:Boolean):void {

		if (stage && stage.root.hasEventListener(KeyboardEvent.KEY_DOWN)) {
			stage.root.removeEventListener(KeyboardEvent.KEY_DOWN, handleKeyPress);
		}

		this.stage = stage;

		this.mvcExpressClass = mvcExpressClass;
		this.moduleManagerClass = moduleManagerClass;

		stage.root.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyPress);

		if (autoShow || isLogShown) {
			showLogger();
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

	internal function showLogger():void {
		isLogShown = true;

		if (!isInitialized) {
			isInitialized = true;
			logWindow.initialize(mvcExpressClass, moduleManagerClass, visualizerManager);
			logWindow.addEventListener(Event.CLOSE, hideLogger);
		}

		if (stage) {
			if (!stage.contains(logWindow)) {
				stage.addChild(logWindow);
			}
		}


		// TODO : check if we can remove it, looks like it in delayedAutoButtonClick function.
		logWindow.resolveCurrentModuleName();

		logWindow.delayedAutoButtonClick()
	}

	internal function hideLogger(event:Event = null):void {
		isLogShown = false;
		if (stage) {
			if (stage.contains(logWindow)) {
				stage.removeChild(logWindow);
			}
		}
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
			logWindow.showError(traceObj.errorMessage);
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
				logWindow.appendLogText(traceObj.toString());
			}

			if (isLogShown) {
				var logType:String = String(traceObj).substr(0, 2);
				logWindow.dataChange(logType);
			}
		}
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
		logWindow.initTab = initTab;
		return this;
	}

	public function setToggleKey(openKeyCode:int, isCtrlKeyNeeded:Boolean, isShiftKeyNeeded:Boolean, isAltKeyNeeded:Boolean):LoggerViewManager {
		this.openKeyCode = openKeyCode;
		this.isCtrlKeyNeeded = isCtrlKeyNeeded;
		this.isShiftKeyNeeded = isShiftKeyNeeded;
		this.isAltKeyNeeded = isAltKeyNeeded;
		return this;
	}


	internal function setCustomLoggingEnabled(value:Boolean):void {
		logWindow.setCustomLoggingEnabled(value);
	}

	internal function customLog(debugText:String):void {
		logWindow.customLog(debugText);
	}

	////////////
	// TODO: DOUBLE CHECK HOW THIS IS USED...
	pureLegsCore function getLoggerView():Mvce_Window {
		return logWindow;
	}
}
}
