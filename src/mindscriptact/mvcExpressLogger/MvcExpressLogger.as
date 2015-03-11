package mindscriptact.mvcExpressLogger {
import flash.display.Stage;
import flash.utils.Dictionary;
import flash.utils.getDefinitionByName;

import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_Style;
import mindscriptact.mvcExpressLogger.minimalComps.components.Mvce_Window;

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


	// Core elements.
	static private const logViewManager:LoggerViewManager = new LoggerViewManager();

	static private const logWindow:Mvce_Window = logViewManager.pureLegsCore::getLoggerView();

	static private const logParser:LoggerTraceParser = new LoggerTraceParser(logViewManager);

	// FIXME: LATER - deprecated. MvcExpressLogger should not be used an object, and should not contain non static variables.

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

			try {
				mvcExpressClass = getDefinitionByName("mvcexpress::MvcExpress") as Class;
				moduleManagerClass = getDefinitionByName("mvcexpress.core::ModuleManager") as Class;
			} catch (error:Error) {
			}

			logViewManager.setStage(stage);

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

					//

					logViewManager.init(mvcExpressClass, moduleManagerClass);


					logViewManager.moveTo(x, y);
					logViewManager.resize(width, height);
					logViewManager.setAlpha(alpha);

					logViewManager.showTab(initTab);

					logViewManager.setToggleKey(openKeyCode, isCtrlKeyNeeded, isShiftKeyNeeded, isAltKeyNeeded);

				}

				use namespace pureLegsCore;

				mvcExpressClass["loggerFunction"] = logViewManager.debugMvcExpress;

				if (autoShow) {
					logViewManager.showLogger();
				}
			} else {
				logViewManager.showNoFrameworkError();
			}
		} else {
			throw Error("Stage must be provided for mvcExpress logger to work properly.");
		}

		// for function chaining.
		return logViewManager;
	}

	static public function show():void {
		if (instance) {
			logViewManager.showLogger();
		} else {
			trace("WARNING: MvcExpressLogger must be MvcExpressLogger.init(); before you can use this function.");
		}
	}

	static public function hide():void {
		// FIXME: use view manager.
		if (instance) {
			logViewManager.hideLogger();
		} else {
			trace("WARNING: MvcExpressLogger must be MvcExpressLogger.init(); before you can use this function.");
		}
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
			logViewManager.renderCustomLoggingButton();
		}
	}

	public static function log(debugText:String):void {
		// FIXME: move to view controller
		if (instance.customLogText != "") {
			instance.customLogText += "\n";
		}
		instance.customLogText += debugText;
		if (logViewManager.currentTabButtonName == CUSTOM_LOGGING_TAB) {
			logViewManager.render();
		}
	}

	//////////////////////////////
	//   Ignore stuff from logging.
	//////////////////////////////

	public static function ignoreClasses(ignoreClass:Class, ...moreIgnoreClasses:Array):void {
		CONFIG::debug {
			for (var i:int = 0; i < moreIgnoreClasses.length; i++) {
				if (!(moreIgnoreClasses[i] is Class)) {
					throw Error("You can only ignore classes, but you provided:" + moreIgnoreClasses[i]);
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
			for (var i:int = 0; i < moreIgnoreClasses.length; i++) {
				if (!(moreIgnoreClasses[i] is Class)) {
					throw Error("You can only ignore classes, but you provided:" + moreIgnoreClasses[i]);
				}
			}
		}
		moreIgnoreClasses.unshift(ignoreClass);
		for (i = 0; i < moreIgnoreClasses.length; i++) {
			delete classesToIgnore[moreIgnoreClasses[i]];
		}
	}

	public static function ignoreMessages(ignoreMessageType:String, ...moreIgnoreMessageTypes:Array):void {
		CONFIG::debug {
			for (var i:int = 0; i < moreIgnoreMessageTypes.length; i++) {
				if (!(moreIgnoreMessageTypes[i] is String)) {
					throw Error("You can only ignore Strings as message types, but you provided:" + moreIgnoreMessageTypes[i]);
				}
			}
		}
		moreIgnoreMessageTypes.unshift(ignoreMessageType);
		for (i = 0; i < moreIgnoreMessageTypes.length; i++) {
			messageTypesToIgnore[moreIgnoreMessageTypes[i]] = true;
		}
	}

	public static function unignoreMessages(ignoreMessageType:String, ...moreIgnoreMessageTypes:Array):void {
		CONFIG::debug {
			for (var i:int = 0; i < moreIgnoreMessageTypes.length; i++) {
				if (!(moreIgnoreMessageTypes[i] is String)) {
					throw Error("You can only ignore Strings as message types, but you provided:" + moreIgnoreMessageTypes[i]);
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
		return logViewManager.resize(width, height);
	}

	public static function setAlpha(alpha:Number):LoggerViewManager {
		return logViewManager.setAlpha(alpha);
	}

	public static function autoShow(doAutoShow:Boolean = true):LoggerViewManager {
		// FIXME : Implement.
		return null;
	}

	public static function showTab(tabName:String):LoggerViewManager {
		return logViewManager.showTab(tabName);
		;
	}

	public static function setToggleKey(openKeyCode:int = 192, isCtrlKeyNeeded:Boolean = true, isShiftKeyNeeded:Boolean = false, isAltKeyNeeded:Boolean = false):LoggerViewManager {
		return logViewManager.setToggleKey(openKeyCode, isCtrlKeyNeeded, isShiftKeyNeeded, isAltKeyNeeded);
	}
}
}